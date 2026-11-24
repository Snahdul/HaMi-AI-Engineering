#requires -Version 7.4
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Sync-RepositoryRulesets.ps1')
function Clone($Value) {
    return (ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject $Value -Depth 50 -Compress) -AsHashtable -NoEnumerate)
}
function Expect([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw "FAIL: $Name" }
    Write-Host "PASS: $Name"
}
function Reject([scriptblock]$Action, [string]$Reason) {
    $caught = $false
    try { & $Action | Out-Null }
    catch {
        if ($_.Exception.Message -cnotmatch [regex]::Escape($Reason)) { throw }
        $caught = $true
    }
    Expect $caught "reject $Reason"
}
$policy = ConvertFrom-Json -InputObject (Get-Content -LiteralPath $script:PolicyFile -Raw) -AsHashtable -NoEnumerate
$repo = 'Snahdul/HaMi-AI-Engineering-Agent'
$desired = Get-Desired $policy $repo
$methodRepo = Get-Desired $policy 'Snahdul/HaMi-AI-Engineering'
$actual = Clone $desired
$actual.rules = @($actual.rules | Where-Object { $_.type -cne 'required_status_checks' })
Expect ($methodRepo.rules.Count -eq 3 -and $desired.rules.Count -eq 4) 'repository profiles'
Expect (($desired.rules | Where-Object type -eq 'pull_request').parameters.require_extra_approval_for_unattributed_changes) 'Agent additional review protection retained'
Reject { Get-Desired $policy 'Snahdul/unknown' } 'UNREGISTERED_REPOSITORY'

function Reset-Fixture($Current) {
    $script:fixtureCurrent = if ($null -eq $Current) { $null } else { Clone $Current }
    $script:fixtureId = 27473232
    $script:fixtureVersion = '2026-11-24T12:00:00Z'
    $script:writeCalls = 0
    $script:repoReads = 0
    $script:fail = ''
}
function Fake-Request([string]$Method,[string]$Path,$Body) {
    $root = "/repos/$repo"
    if ($Method -cne 'GET') {
        $script:writeCalls++
        if ($script:fail -ceq 'write') { throw 'HAMI_RULESET: HTTP_403' }
        if ($Method -ceq 'POST' -and $Path -ceq "$root/rulesets" -and $null -eq $script:fixtureCurrent) {
            $script:fixtureId = 333
        } elseif ($Method -cne 'PUT' -or $Path -cne "$root/rulesets/$script:fixtureId" -or $null -eq $script:fixtureCurrent) {
            throw 'Unexpected write'
        }
        if ($script:fail -cne 'readback') {
            $script:fixtureCurrent = Clone $Body
            $script:fixtureVersion = '2026-11-24T12:01:00Z'
        }
        return @{status=200;data=@{id=$script:fixtureId}}
    }
    $active = $null -ne $script:fixtureCurrent -and $script:fixtureCurrent.enforcement -ceq 'active'
    switch -CaseSensitive ($Path) {
        $root {
            $script:repoReads++
            if ($script:fail -ceq 'race' -and $script:repoReads -ge 2) {
                $script:fixtureVersion = '2026-11-24T12:02:00Z'
            }
            return @{status=200;data=@{full_name=$repo;id=1461651272;default_branch='main';permissions=@{admin=$true};archived=$false}}
        }
        "$root/branches/main" {
            return @{status=200;data=@{name='main';protected=$active;protection=@{enabled=$false}}}
        }
        "$root/branches/main/protection" {
            if ($script:fail -ceq 'permission') { throw 'HAMI_RULESET: HTTP_403' }
            if ($script:fail -ceq 'legacy') { return @{status=200;data=@{}} }
            return @{status=404;data=$null}
        }
        "$root/rulesets?includes_parents=true&per_page=100" {
            $entries = @()
            if ($null -ne $script:fixtureCurrent) {
                $entries += @{id=$script:fixtureId;name='protect-main';source_type='Repository';source=$repo;enforcement=$script:fixtureCurrent.enforcement}
            }
            if ($script:fail -ceq 'foreign') { $entries += @{id=999;name='other';source_type='Repository';source=$repo;enforcement='active'} }
            return @{status=200;data=$entries}
        }
        "$root/rulesets/$script:fixtureId" {
            $detail = Clone $script:fixtureCurrent
            $detail.id = $script:fixtureId
            $detail.source_type = 'Repository'
            $detail.source = $repo
            $detail.updated_at = $script:fixtureVersion
            $detail.current_user_can_bypass = 'never'
            if ($script:fail -ceq 'hidden') { $detail.Remove('bypass_actors') | Out-Null }
            return @{status=200;data=$detail}
        }
        "$root/rules/branches/main?per_page=100" {
            $rules = @()
            if ($active) {
                foreach ($rule in $script:fixtureCurrent.rules) {
                    $entry = Clone $rule
                    $entry.ruleset_id = $script:fixtureId
                    $entry.ruleset_source_type = 'Repository'
                    $entry.ruleset_source = $repo
                    $rules += $entry
                }
            }
            if ($script:fail -ceq 'effective') { $rules = @() }
            return @{status=200;data=$rules}
        }
        default { throw "Unexpected fixture path: $Path" }
    }
}
function Run([string]$Mode,[string]$Hash='') {
    Invoke-Sync $Mode $repo $desired 'test-policy' 'test-script' $Hash { param($m,$p,$b) Fake-Request $m $p $b }
}

Reset-Fixture $desired
$result = Run Check
Expect ($result.status -ceq 'Conformant' -and $script:writeCalls -eq 0) 'conformant Check no write'
$result = Run Apply
Expect ($result.status -ceq 'Conformant' -and $script:writeCalls -eq 0) 'conformant Apply no write'
Reset-Fixture $actual
$result = Run Check
Expect ($result.status -ceq 'Drift' -and $result.action -ceq 'Update' -and $script:writeCalls -eq 0) 'drift Check no write'
$plan = Run Plan
Expect ($plan.plan.action -ceq 'Update' -and $script:writeCalls -eq 0) 'missing checks Plan'
Expect ((Run Plan).planHash -ceq $plan.planHash) 'deterministic hash'
Reject { Run Apply } 'APPROVED_PLAN_HASH_REQUIRED_OR_STALE'
Reject { Run Apply ('0' * 64) } 'APPROVED_PLAN_HASH_REQUIRED_OR_STALE'
Expect ($script:writeCalls -eq 0) 'unapproved Apply no write'
$result = Run Apply $plan.planHash
Expect ($result.status -ceq 'Verified' -and $result.changed -and $script:writeCalls -eq 1) 'one update and readback'
$result = Run Apply $plan.planHash
Expect ($result.status -ceq 'Conformant' -and $script:writeCalls -eq 1) 'repeat Apply idempotent'
Reset-Fixture $null
$plan = Run Plan
Expect ($plan.plan.action -ceq 'Create' -and $script:writeCalls -eq 0) 'new repository plan'
$result = Run Apply $plan.planHash
Expect ($result.status -ceq 'Verified' -and $script:writeCalls -eq 1) 'one create and readback'
Reset-Fixture $actual
$stronger = Clone $actual
($stronger.rules | Where-Object type -eq 'pull_request').parameters.required_approving_review_count = 1
Reset-Fixture $stronger
Reject { Run Plan } 'PR_PARAMETER_MISMATCH_REVIEW_REQUIRED'
Expect ($script:writeCalls -eq 0) 'stronger review protection not weakened'
$unknown = Clone $actual
$unknown.rules = @($unknown.rules) + @(@{type='required_signatures'})
Reset-Fixture $unknown
Reject { Run Apply ('0' * 64) } 'ADDITIONAL_OR_UNSUPPORTED_RULE'
Expect ($script:writeCalls -eq 0) 'unknown stronger rule not deleted'
foreach ($case in @(
    @('permission','HTTP_403'),
    @('legacy','LEGACY_BRANCH_PROTECTION_PRESENT'),
    @('foreign','OTHER_OR_AMBIGUOUS_RULESETS'),
    @('hidden','RULESET_FIELD_NOT_VISIBLE'),
    @('effective','EFFECTIVE_RULES_MISMATCH')
)) {
    Reset-Fixture $actual
    $script:fail = $case[0]
    Reject { Run Plan } $case[1]
    Expect ($script:writeCalls -eq 0) "no writes for $($case[0])"
}
Reset-Fixture $actual
$plan = Run Plan
$script:fixtureVersion = '2026-11-24T13:00:00Z'
Reject { Run Apply $plan.planHash } 'APPROVED_PLAN_HASH_REQUIRED_OR_STALE'
Expect ($script:writeCalls -eq 0) 'changed snapshot requires new approval'
Reset-Fixture $actual
$plan = Run Plan
$script:repoReads = 0
$script:fail = 'race'
Reject { Run Apply $plan.planHash } 'STATE_CHANGED_BEFORE_WRITE'
Expect ($script:writeCalls -eq 0) 'fresh read detects race before write'
foreach ($case in @('write','readback')) {
    Reset-Fixture $actual
    $plan = Run Plan
    $script:fail = $case
    Reject { Run Apply $plan.planHash } 'WRITE_OR_READBACK_UNVERIFIED_STOP_AND_RECONCILE'
    Expect ($script:writeCalls -eq 1) "no automatic retry after $case"
}
Write-Host 'PASS: offline repository ruleset scenarios (fake transport; no GitHub writes).'
