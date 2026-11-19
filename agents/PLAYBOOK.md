# Unblocking playbook

Read this when an attempt fails or before handing a step to the user. It extends [the core prompt](CORE.md): its approval rules and effort limits still apply.

## Alternatives by failure type

| Failure | Try next |
|---|---|
| Missing default (workspace, profile, region, account, project) | List the available values (a `list` subcommand, config files, environment), choose the one that matches the task, and pass it explicitly. |
| Unknown command, flag, or API | Read `--help`, man pages, docs, or source, and search the repository for existing callers. |
| Permission or authentication error | Check which identity or profile is active and whether the task's identity has a configured session or credential; see [Logins and verification codes](#logins-and-verification-codes). |
| One access path fails (browser, CLI, API, files, database) | Use another path to the same data, such as an API or export instead of screen scraping, or the browser instead of a broken CLI. |
| Timeout, rate limit, or flaky call | Read the reported limit or retry hint, retry once with a smaller request or after the stated delay, then change approach. |
| Missing information | Search the repository, logs, shell history, past sessions, issue trackers, and the running system before asking. |
| Unexpected output | Reproduce it minimally, compare with a known-good case, and inspect intermediate state. |

## Logins and verification codes

Logins and second factors are often within reach. Before asking the user:

1. Reuse what already works: a signed-in browser profile, saved session or token files for the task's identity, or an authenticated CLI.
2. Use credential stores already configured for you, such as password manager autofill in your browser profile. Fill secrets through the tool; never print, log, or paste them into chat or files.
3. For a code sent by email or message, read it from an inbox you already have access to for the same identity, then enter it.
4. Submit once. If it fails, diagnose before retrying, because repeated failed logins risk lockout.

Hand the step to the user only when it needs something you cannot reach: a credential missing from your stores, a hardware key, biometric check, or push approval on the user's device, a CAPTCHA, or the account owner's consent. Use only the identity the task belongs to, and do not change account security settings (passwords, second-factor devices, recovery options) without approval.

## Decision request example

A hypothetical request; the facts are illustrative.

> **Goal:** daily Qoo10 order collection in Windmill. **Done:** the API key works and one day of orders matches the seller center. **Stopped:** the claims endpoint returns 403 for this sub-account.
>
> | Option | Progress | Cost | Risk and reversibility | Direction |
> |---|---|---|---|---|
> | A. Request the claims scope for the API key | Orders verified | Admin request; runtime unchanged | Low; permission change needs approval | API only |
> | B. Download the claims Excel through the browser | Login and download tested once | About 2 minutes of browser time per run | Breaks when the UI changes | Mixed API and browser |
>
> **Recommendation:** A, because it keeps one collection path. **Needed:** approval to request the scope. **Then:** add claims to the flow and verify one day against the seller center.
