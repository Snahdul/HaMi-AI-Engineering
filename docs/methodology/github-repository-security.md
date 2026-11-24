# GitHub repository security: policy as code

Status: implementation and policy proposal for #22; not approved for administrative execution until reviewed and merged. Live readback and acceptance remain mandatory.

## Scope and ownership

The shared ruleset policy lives in `policies/github/protect-main.json`. Its repository profiles explicitly register each repository. New repositories require a reviewed profile; no implicit policy, no wildcard administration. This covers default-branch rulesets only, not Actions permissions, repository visibility, secret scanning, collaborators, account security or other controls in #10 and Agent #1.

References: [Security baseline #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10), [Agent #1](https://github.com/Snahdul/HaMi-AI-Engineering-Agent/issues/1), [ADR-0003](https://github.com/Snahdul/HaMi-AI-Engineering-Agent/blob/main/docs/decisions/0003-security-architecture-and-credential-isolation.md), [M4 pilot #58](https://github.com/Snahdul/HaMi-AI-Engineering-Agent/issues/58), [GitHub Rules REST API](https://docs.github.com/en/rest/repos/rules?apiVersion=2026-03-10).

## Baseline and evidence (24 November 2026)

The GitHub API returned both active repository-owned protect-main rulesets (Engineering 27316867, Agent 27473232), targeting ~DEFAULT_BRANCH with no exclusions/bypass actors, required PRs, resolved discussions, zero required external approvals, deletion and force-push prevention. The Agent already has require_extra_approval_for_unattributed_changes=true; preserve it (GitHub documents the extra-approval effect for nonzero approval counts). Neither had required status checks.

Agent [PR #56](https://github.com/Snahdul/HaMi-AI-Engineering-Agent/pull/56) was merged at 3362da7f1c98e3097695151e0e981b754428f64a; [CI run 45437896386](https://github.com/Snahdul/HaMi-AI-Engineering-Agent/actions/runs/45437896386) succeeded. The PR-head check-runs API confirmed contexts build and Windows file-handle logging regression from GitHub Actions App 15368. The proposed Agent policy requires these checks with this source pin. Project board sync and third-party GitGuardian checks are not newly mandated. Strict up-to-date checks are not newly required (false); the draft does not silently add a rebase/merge requirement. A preexisting stricter setting blocks the tool.

The connector returned HTTP 403 for classic branch protection, and did not support the effective branch-rules endpoint. Local readback with the scoped operator credential is required, including those endpoints.

## Trust and authorization

Run PowerShell 7.4+ on the trusted operator workstation from the reviewed, pinned, clean checkout of the methods repository. Do not run PR code with an administrative credential, do not run this through an agent, MicroVM, issue gateway, publisher or privileged CI. Check/Plan are GET-only. Apply requires the exact plan SHA-256 produced from the repository identity, default branch, current ruleset/version, desired payload and policy/script hashes. A fresh read is performed before the single mutation; readback validates the effective rule set and identity. No delete, automatic retry, rollback, or privilege escalation.

Use a separate short-lived fine-grained PAT limited to the selected repository with Metadata read and Administration read/write. GitHub only returns bypass_actors to callers with write access to the ruleset; even Check/Plan cannot claim completeness without this visibility. See the [GET ruleset API documentation](https://docs.github.com/en/rest/repos/rules#get-a-repository-ruleset). Administration is broad inside the selected repository; script restrictions are not a token-scope restriction. Do not repurpose issue/publication credentials or the project-board token. Use the existing GitHub token mechanism; enter it only at the secure local prompt. No token in CLI arguments, environment, source, reports, history or logs. No additional service or vault. Run without transcription, debug tracing or proxy capture; do not share raw exceptions or request traces. Revoke/rotate the administrative token according to its approved lifetime.

## Offline test

From a clean review checkout, without an administrative credential:

```powershell
pwsh -NoProfile -File scripts/github/Test-RepositoryRulesets.ps1
```

The fake transport exercises GET-only behavior, policy profiles, missing checks, create/update, approved hash, stale plan, stronger/unknown settings, other rulesets, hidden bypasses, missing permissions, classic protection, effective-rule mismatch, failed write/readback and repeat Apply. It does not validate actual GitHub permissions or API behavior. Do not execute Apply before these tests and human review.

## Operator runbook

From the reviewed checkout (PowerShell terminal, do not wrap in a privileged agent):

```powershell
$script = './scripts/github/Sync-RepositoryRulesets.ps1'
$repo = 'Snahdul/HaMi-AI-Engineering'
pwsh -NoProfile -File $script -Mode Check -Repository $repo
$repo = 'Snahdul/HaMi-AI-Engineering-Agent'
pwsh -NoProfile -File $script -Mode Check -Repository $repo
pwsh -NoProfile -File $script -Mode Plan -Repository $repo
```

Exit codes: 0 conformant/verified; 1 drift with no writes; 2 blocked/unverified. Inspect the complete current and desired configuration in Plan, including CI source IDs, and obtain explicit human approval for the exact planHash. Record the approved hash and relevant redacted evidence in #22. Verify recent CI success and that no concurrent administrative operation is scheduled.

Only after that separate authorization, substitute the approved hash:

```powershell
$approved = '<approved 64-character lowercase SHA-256 plan hash>'
pwsh -NoProfile -File $script -Mode Apply -Repository $repo -ApprovedPlanHash $approved
pwsh -NoProfile -File $script -Mode Check -Repository $repo
pwsh -NoProfile -File $script -Mode Apply -Repository $repo -ApprovedPlanHash $approved
```

Expected: first Apply Verified/changed=true (or Conformant/false if already compliant), Check Conformant, second Apply Conformant/changed=false. Never use a hash from another checkout, policy, repository or prior state. Check current protection and real PR merge requirements again before authorizing Agent #58. No administrative change is authorized by this runbook itself.

## Fail-safe boundaries and limitations

V1 handles no existing ruleset or exactly one repository-owned protect-main ruleset with the supported default-branch scope. Any additional ruleset (including unrelated/tag/parent rules), classic branch protection, missing bypass visibility, inconsistent effective rules, unknown fields or stronger/different existing parameters blocks without writes. The tool only adds missing supported rules/checks, turns on supported review-resolution/extra-approval flags, and activates the matching ruleset. It does not remove bypass actors automatically; reconcile via reviewed administrative change. It does not lower approvals, remove required checks or relax merge restrictions. This intentionally conservative subset avoids guessing about precedence/overlap. A repository with a differently configured stronger policy needs a reviewed policy/script extension, not forced convergence.

The REST ruleset PUT has no documented compare-and-swap precondition. The immediate second read reduces but does not eliminate a concurrent-edit race; require exclusive human administrative operation during Apply. GitHub writes and readback are not transactional. On an ambiguous failure or readback mismatch, stop, inspect current remote state and obtain a new plan/freestanding authorization if needed; do not rerun blindly or restore a stale snapshot.

Unknown API schemas or missing fields intentionally block. API compatibility, classic branch-protection absence, actual permission behavior and final applied state must be demonstrated on the real repository. No claim that the connector readback or fake tests replace that acceptance.
