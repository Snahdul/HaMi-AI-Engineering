#requires -Version 7.4
[CmdletBinding()]
param(
    [ValidateSet('Check','Plan','Apply')][string]$Mode = 'Check',
    [string]$Repository,
    [string]$ApprovedPlanHash
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
$script:PolicyFile = Join-Path $PSScriptRoot '../../policies/github/protect-main.json'

# Canonical representation of the supported set-valued policy fields.
function Canon($Value) {
    if ($Value -is [System.Collections.IDictionary]) {
        [string[]]$keys = @($Value.Keys)
        [Array]::Sort($keys, [StringComparer]::Ordinal)
        $parts = foreach ($k in $keys) {
            (ConvertTo-Json -InputObject $k -Compress) + ':' + (Canon $Value[$k])
        }
        return '{' + ($parts -join ',') + '}'
    }
    if ($Value -is [System.Collections.IList]) {
        [string[]]$parts = @(foreach ($item in $Value) { Canon $item })
        [Array]::Sort($parts, [StringComparer]::Ordinal)
        return '[' + ($parts -join ',') + ']'
    }
    return (ConvertTo-Json -InputObject $Value -Compress -Depth 50)
}
function Equal($A, $B) { (Canon $A) -ceq (Canon $B) }
function Assert-That([bool]$Condition, [string]$Reason) {
    if (-not $Condition) { throw "HAMI_RULESET: $Reason" }
}
function Assert-Keys($Object, [string[]]$Keys) {
    Assert-That ($Object -is [System.Collections.IDictionary]) 'INVALID_OBJECT'
    Assert-That (Equal @($Object.Keys) $Keys) 'UNSUPPORTED_OR_MISSING_FIELDS'
}
function Get-Hash([string]$Value) {
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Value))).ToLowerInvariant()
}
function Get-Desired($Policy, [string]$Repo) {
    Assert-Keys $Policy @('schemaVersion','ruleset','repositories')
    Assert-That ($Policy.schemaVersion -eq 1) 'UNSUPPORTED_POLICY_VERSION'
    Assert-That ($Repo -cmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') 'INVALID_REPOSITORY'
    Assert-That ($Policy.repositories -is [System.Collections.IDictionary] -and $Policy.repositories.Contains($Repo)) 'UNREGISTERED_REPOSITORY'
    $profile = $Policy.repositories[$Repo]
    Assert-Keys $profile @('requireExtraApprovalForUnattributedChanges','requiredStatusChecks')
    Assert-That ($profile.requireExtraApprovalForUnattributedChanges -is [bool] -and $profile.requiredStatusChecks -is [System.Collections.IList]) 'INVALID_PROFILE'
    $desired = (ConvertTo-Json -InputObject $Policy.ruleset -Depth 50 -Compress) | ConvertFrom-Json -AsHashtable -NoEnumerate
    Assert-Keys $desired @('name','target','enforcement','bypass_actors','conditions','rules')
    Assert-That ($desired.name -ceq 'protect-main' -and $desired.target -ceq 'branch' -and $desired.enforcement -ceq 'active') 'INVALID_BASELINE'
    Assert-That (Equal $desired.bypass_actors @()) 'POLICY_BYPASS_FORBIDDEN'
    Assert-That (Equal $desired.conditions @{ref_name=@{include=@('~DEFAULT_BRANCH');exclude=@()}}) 'INVALID_BRANCH_SCOPE'
    Assert-That (Equal @($desired.rules | ForEach-Object { $_.type }) @('deletion','non_fast_forward','pull_request')) 'INVALID_BASE_RULES'
    foreach ($rule in $desired.rules) {
        if ($rule.type -ceq 'pull_request') {
            Assert-Keys $rule @('type','parameters')
            $p = $rule.parameters
            Assert-Keys $p @('required_approving_review_count','dismiss_stale_reviews_on_push','required_reviewers','require_code_owner_review','require_last_push_approval','required_review_thread_resolution','require_extra_approval_for_unattributed_changes','allowed_merge_methods')
            Assert-That (Equal $p @{required_approving_review_count=0;dismiss_stale_reviews_on_push=$false;required_reviewers=@();require_code_owner_review=$false;require_last_push_approval=$false;required_review_thread_resolution=$true;require_extra_approval_for_unattributed_changes=$false;allowed_merge_methods=@('merge','squash','rebase')}) 'UNSUPPORTED_BASELINE_PARAMETERS'
            $p.require_extra_approval_for_unattributed_changes = $profile.requireExtraApprovalForUnattributedChanges
        } else { Assert-Keys $rule @('type') }
    }
    $names = @()
    foreach ($check in $profile.requiredStatusChecks) {
        Assert-Keys $check @('context','integration_id')
        Assert-That ($check.context -is [string] -and $check.context -cmatch '^[A-Za-z0-9 ._()/:-]{1,100}$' -and $check.integration_id -is [long] -and $check.integration_id -gt 0) 'INVALID_CHECK'
        Assert-That ($names -cnotcontains $check.context) 'DUPLICATE_CHECK'
        $names += $check.context
    }
    if ($names.Count -gt 0) {
        $desired.rules = @($desired.rules) + @(@{type='required_status_checks';parameters=@{required_status_checks=$profile.requiredStatusChecks;strict_required_status_checks_policy=$false;do_not_enforce_on_create=$false}})
    }
    return $desired
}

# The production transport uses only GitHub REST, a separately supplied SecureString,
# and fixed endpoint paths. No retries, redirect, credential fallback or response dumps.
function Invoke-GitHub([string]$Method, [string]$Path, $Body) {
    $options = @{
        Uri = 'https://api.github.com' + $Path
        Method = $Method
        Authentication = 'Bearer'
        Token = $script:AdminCredential
        Headers = @{Accept='application/vnd.github+json';'X-GitHub-Api-Version'='2026-03-10'}
        MaximumRedirection = 0
        SkipHttpErrorCheck = $true
        TimeoutSec = 30
        ErrorAction = 'Stop'
    }
    if ($Method -ne 'GET') {
        $options.ContentType = 'application/json'
        $options.Body = ConvertTo-Json -InputObject $Body -Depth 50 -Compress
    }
    try {
        $response = Invoke-WebRequest @options
    } catch { throw 'HAMI_RULESET: TRANSPORT_ERROR_RECONCILE_BEFORE_RETRY' }
    $status = [int]$response.StatusCode
    if ($status -eq 404 -and $Method -ceq 'GET' -and $Path.EndsWith('/protection')) {
        return @{status=404;data=$null}
    }
    $expected = if ($Method -ceq 'POST') { 201 } else { 200 }
    Assert-That ($status -eq $expected) "HTTP_$status"
    Assert-That (-not ([string]($response.Headers['Link'] -join ',') -match 'rel="next"')) 'PAGINATION_REQUIRES_REVIEW'
    try {
        $data = ConvertFrom-Json -InputObject $response.Content -AsHashtable -NoEnumerate -Depth 50
    } catch { throw 'HAMI_RULESET: INVALID_API_RESPONSE' }
    return @{status=$status;data=$data}
}

function Get-RulesetPayload($Detail) {
    $fields = @('name','target','enforcement','bypass_actors','conditions','rules')
    $metadata = @('id','source_type','source','node_id','created_at','updated_at','current_user_can_bypass','_links')
    foreach ($key in $Detail.Keys) {
        Assert-That (($fields + $metadata) -ccontains $key) 'UNKNOWN_RULESET_FIELD'
    }
    $result = @{}
    foreach ($key in $fields) {
        Assert-That ($Detail.Contains($key)) 'RULESET_FIELD_NOT_VISIBLE'
        $result[$key] = $Detail[$key]
    }
    return $result
}

function Get-Snapshot([string]$Repo, [scriptblock]$Request) {
    $path = "/repos/$Repo"
    $repoInfo = (& $Request 'GET' $path $null).data
    Assert-That ($repoInfo.full_name -ceq $Repo -and $repoInfo.id -gt 0 -and $repoInfo.permissions.admin -ceq $true -and $repoInfo.archived -ceq $false) 'REPOSITORY_IDENTITY_OR_ADMIN_NOT_VERIFIED'
    $branch = $repoInfo.default_branch
    Assert-That ($branch -is [string] -and $branch -cmatch '^[A-Za-z0-9._/-]+$' -and $branch -notmatch '\.\.') 'INVALID_DEFAULT_BRANCH'
    $encoded = [Uri]::EscapeDataString($branch)
    $branchInfo = (& $Request 'GET' "$path/branches/$encoded" $null).data
    Assert-That ($branchInfo.name -ceq $branch -and $branchInfo.protection.enabled -ceq $false -and $branchInfo.protected -is [bool]) 'LEGACY_OR_UNKNOWN_BRANCH_PROTECTION'
    $legacy = & $Request 'GET' "$path/branches/$encoded/protection" $null
    Assert-That ($legacy.status -eq 404) 'LEGACY_BRANCH_PROTECTION_PRESENT'
    $list = (& $Request 'GET' "$path/rulesets?includes_parents=true&per_page=100" $null).data
    Assert-That ($list -is [System.Collections.IList] -and $list.Count -le 1) 'OTHER_OR_AMBIGUOUS_RULESETS'
    $effective = (& $Request 'GET' "$path/rules/branches/$encoded?per_page=100" $null).data
    Assert-That ($effective -is [System.Collections.IList] -and $effective.Count -lt 100) 'UNKNOWN_EFFECTIVE_RULES'
    $current = $null
    $id = $null
    $updated = $null
    if ($list.Count -eq 1) {
        $entry = $list[0]
        Assert-That ($entry.name -ceq 'protect-main' -and $entry.source_type -ceq 'Repository' -and $entry.source -ceq $Repo -and $entry.id -gt 0) 'UNMANAGED_RULESET'
        $id = $entry.id
        $detail = (& $Request 'GET' "$path/rulesets/$id" $null).data
        Assert-That ($detail.id -eq $id -and $detail.source_type -ceq 'Repository' -and $detail.source -ceq $Repo -and $detail.name -ceq $entry.name -and $detail.enforcement -ceq $entry.enforcement) 'RULESET_IDENTITY_CHANGED'
        $current = Get-RulesetPayload $detail
        Assert-That ($detail.current_user_can_bypass -ceq 'never' -and (Equal $current.bypass_actors @())) 'BYPASS_OR_BYPASS_VISIBILITY'
        $updated = $detail.updated_at
        Assert-That (-not [string]::IsNullOrWhiteSpace($updated)) 'MISSING_RULESET_VERSION'
    }
    $activeRules = @()
    if ($null -ne $current -and $current.enforcement -ceq 'active') { $activeRules = @($current.rules) }
    $effectiveRules = @(foreach ($rule in $effective) {
        Assert-That ($null -ne $id -and $rule.ruleset_id -eq $id -and $rule.ruleset_source_type -ceq 'Repository' -and $rule.ruleset_source -ceq $Repo) 'UNMANAGED_EFFECTIVE_RULE'
        $projected = @{}
        foreach ($key in $rule.Keys) {
            if (@('type','parameters') -ccontains $key) { $projected[$key] = $rule[$key] }
            else { Assert-That (@('ruleset_id','ruleset_source_type','ruleset_source') -ccontains $key) 'UNKNOWN_EFFECTIVE_FIELD' }
        }
        $projected
    })
    Assert-That (Equal $activeRules $effectiveRules) 'EFFECTIVE_RULES_MISMATCH'
    Assert-That ($branchInfo.protected -eq ($activeRules.Count -gt 0)) 'BRANCH_PROTECTION_MISMATCH'
    return @{repository=$Repo;repositoryId=$repoInfo.id;defaultBranch=$branch;rulesetId=$id;updatedAt=$updated;current=$current}
}

# Only monotonic, explicitly supported changes are possible. Unknown, additional
# or stronger rules are not normalized away. They require a separately reviewed policy.
function Get-Action($Current, $Desired) {
    if ($null -eq $Current) { return 'Create' }
    Assert-Keys $Current @('name','target','enforcement','bypass_actors','conditions','rules')
    foreach ($key in @('name','target','conditions','bypass_actors')) {
        Assert-That (Equal $Current[$key] $Desired[$key]) "RULESET_SCOPE_OR_BYPASS_MISMATCH_$key"
    }
    Assert-That (@('active','disabled','evaluate') -ccontains $Current.enforcement) 'UNKNOWN_ENFORCEMENT'
    Assert-That ($Current.rules -is [System.Collections.IList]) 'INVALID_RULE_LIST'
    $seen = @()
    foreach ($rule in $Current.rules) {
        $type = $rule.type
        Assert-That ($seen -cnotcontains $type) 'DUPLICATE_RULE'
        $seen += $type
        $matches = @($Desired.rules | Where-Object { $_.type -ceq $type })
        Assert-That ($matches.Count -eq 1) 'ADDITIONAL_OR_UNSUPPORTED_RULE'
        $target = $matches[0]
        if (Equal $rule $target) { continue }
        Assert-Keys $rule @('type','parameters')
        if ($type -ceq 'pull_request') {
            Assert-Keys $rule.parameters @($target.parameters.Keys)
            foreach ($key in $target.parameters.Keys) {
                if (Equal $rule.parameters[$key] $target.parameters[$key]) { continue }
                $strengthen = @('required_review_thread_resolution','require_extra_approval_for_unattributed_changes') -ccontains $key
                Assert-That ($strengthen -and $rule.parameters[$key] -is [bool] -and -not $rule.parameters[$key] -and $target.parameters[$key] -eq $true) 'PR_PARAMETER_MISMATCH_REVIEW_REQUIRED'
            }
        } elseif ($type -ceq 'required_status_checks') {
            Assert-Keys $rule.parameters @($target.parameters.Keys)
            foreach ($key in @('strict_required_status_checks_policy','do_not_enforce_on_create')) {
                Assert-That (Equal $rule.parameters[$key] $target.parameters[$key]) 'STATUS_CHECK_PARAMETER_MISMATCH'
            }
            Assert-That ($rule.parameters.required_status_checks -is [System.Collections.IList]) 'INVALID_STATUS_CHECKS'
            $contexts = @()
            foreach ($check in $rule.parameters.required_status_checks) {
                Assert-Keys $check @('context','integration_id')
                Assert-That ($contexts -cnotcontains $check.context) 'DUPLICATE_EXISTING_CHECK'
                $contexts += $check.context
                $found = @($target.parameters.required_status_checks | Where-Object { Equal $_ $check })
                Assert-That ($found.Count -eq 1) 'EXISTING_CHECK_NOT_IN_POLICY'
            }
        } else { throw 'HAMI_RULESET: UNSUPPORTED_RULE_CHANGE' }
    }
    if (Equal $Current $Desired) { return 'None' }
    return 'Update'
}

function New-Plan($Snapshot, $Desired, [string]$PolicyHash, [string]$ScriptHash) {
    $action = Get-Action $Snapshot.current $Desired
    $plan = @{schemaVersion=1;action=$action;snapshot=$Snapshot;desired=$Desired;policyHash=$PolicyHash;scriptHash=$ScriptHash}
    return @{plan=$plan;planHash=(Get-Hash (Canon $plan))}
}

function Invoke-Sync([string]$Operation, [string]$Repo, $Desired, [string]$PolicyHash, [string]$ScriptHash, [string]$Approval, [scriptblock]$Request) {
    $snapshot = Get-Snapshot $Repo $Request
    $result = New-Plan $snapshot $Desired $PolicyHash $ScriptHash
    if ($result.plan.action -ceq 'None') {
        return @{status='Conformant';changed=$false;repository=$Repo;planHash=$result.planHash;rulesetId=$snapshot.rulesetId}
    }
    if ($Operation -cne 'Apply') {
        return @{status='Drift';changed=$false;planHash=$result.planHash;plan=$result.plan}
    }
    Assert-That ($Approval -cmatch '^[0-9a-f]{64}$' -and $Approval -ceq $result.planHash) 'APPROVED_PLAN_HASH_REQUIRED_OR_STALE'
    # Refresh immediately before the single write. GitHub does not provide a
    # documented conditional ruleset update; this cannot eliminate the final race.
    $fresh = Get-Snapshot $Repo $Request
    $freshPlan = New-Plan $fresh $Desired $PolicyHash $ScriptHash
    Assert-That ($freshPlan.planHash -ceq $Approval) 'STATE_CHANGED_BEFORE_WRITE'
    $path = "/repos/$Repo/rulesets"
    $method = 'POST'
    if ($result.plan.action -ceq 'Update') {
        $method = 'PUT'
        $path += "/$($snapshot.rulesetId)"
    }
    try {
        $written = (& $Request $method $path $Desired).data
        Assert-That ($written.id -gt 0) 'WRITE_ID_MISSING'
        if ($method -ceq 'PUT') { Assert-That ($written.id -eq $snapshot.rulesetId) 'WRITE_ID_MISMATCH' }
        $after = Get-Snapshot $Repo $Request
        Assert-That ($after.repositoryId -eq $snapshot.repositoryId -and $after.defaultBranch -ceq $snapshot.defaultBranch -and $after.rulesetId -eq $written.id -and (Equal $after.current $Desired)) 'READBACK_MISMATCH'
    } catch {
        throw 'HAMI_RULESET: WRITE_OR_READBACK_UNVERIFIED_STOP_AND_RECONCILE'
    }
    return @{status='Verified';changed=$true;repository=$Repo;rulesetId=$after.rulesetId;approvedPlanHash=$Approval;policyHash=$PolicyHash;scriptHash=$ScriptHash}
}

# Dot-sourcing exposes pure functions to offline tests; it never invokes the API.
if ($MyInvocation.InvocationName -ne '.') {
    try {
        Assert-That (-not [string]::IsNullOrWhiteSpace($Repository)) 'REPOSITORY_REQUIRED'
        Assert-That ($Mode -ceq 'Apply' -or [string]::IsNullOrEmpty($ApprovedPlanHash)) 'APPROVAL_ONLY_WITH_APPLY'
        $raw = Get-Content -LiteralPath $script:PolicyFile -Raw -Encoding utf8
        $policy = ConvertFrom-Json -InputObject $raw -AsHashtable -NoEnumerate -Depth 50
        $desired = Get-Desired $policy $Repository
        $policyHash = Get-Hash $raw
        $scriptHash = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()
        # Explicit local input. Do not use a credential from a development session.
        $script:AdminCredential = Read-Host 'Repository administration token (secure input)' -AsSecureString
        Assert-That ($script:AdminCredential.Length -gt 0) 'CREDENTIAL_REQUIRED'
        $report = Invoke-Sync $Mode $Repository $desired $policyHash $scriptHash $ApprovedPlanHash { param($m,$p,$b) Invoke-GitHub $m $p $b }
        ConvertTo-Json -InputObject $report -Depth 50
        if ($report.status -ceq 'Drift') { exit 1 }
        exit 0
    } catch {
        # Never print arbitrary exception messages, request bodies or response headers.
        $message = $_.Exception.Message
        if ($message -cmatch '^HAMI_RULESET: [A-Z0-9_]+$') { [Console]::Error.WriteLine($message) }
        else { [Console]::Error.WriteLine('HAMI_RULESET: UNEXPECTED_ERROR_STOP') }
        exit 2
    } finally {
        if (Test-Path variable:script:AdminCredential) {
            if ($null -ne $script:AdminCredential) { $script:AdminCredential.Dispose() }
            Remove-Variable AdminCredential -Scope Script -ErrorAction SilentlyContinue
        }
    }
}
