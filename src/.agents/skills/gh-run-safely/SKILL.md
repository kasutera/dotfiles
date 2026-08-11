---
name: gh-run-safely
description: Use whenever a task may invoke `gh` or interact with GitHub, including pull requests, issues, Actions, and releases.
---

# Run GitHub CLI safely

- Run every `gh` command with `sandbox_permissions="require_escalated"`.
- Do not first try a sandboxed `gh` command; GitHub access may require network and keyring access unavailable there.
- Let the active execpolicy rules decide whether the request is allowed, prompted, or forbidden.
- Invoke `gh` as a direct command segment when practical so prefix rules can classify it.
- Treat authentication or network failures from a sandboxed `gh` execution as inconclusive. Re-run outside the sandbox before diagnosing credentials or connectivity.
- Never run or disguise a forbidden command, and never reproduce its forbidden capability through `curl`, a browser, a shell wrapper, or another generic interface.
- Distinguish command circumvention from a legitimate alternative: replacing forbidden arbitrary authenticated API access with an allowed read-only operation is acceptable when it returns only the needed data.
- Stop and ask the user only when every suitable route requires a forbidden capability, or when the alternative would expand the task's authority, side effects, or risk.
