# Security policy

## Reporting a vulnerability

Do not open a public issue for a security vulnerability. Use GitHub's private
vulnerability reporting for this repository:

1. Open the repository's **Security** tab.
2. Choose **Report a vulnerability**.
3. Include affected revisions, deployment assumptions, reproduction steps,
   impact, and any proposed mitigation.

If private reporting is not enabled, contact the NetraRuntime organization
owners through GitHub before disclosing details publicly.

Maintainers will acknowledge a complete report, assess affected contracts and
releases, coordinate a fix, and credit the reporter when requested and safe.
No response-time guarantee is made for unsupported hardware, rejected tactics,
or unmodified third-party components.

## Scope

Security-sensitive areas include:

- engine manifest and code-object validation;
- path traversal or unsafe artifact loading;
- kernarg size, pointer binding, and workspace bounds;
- device/context ownership and destruction races;
- checkpoint or repack parsing;
- CI, build, and release supply-chain integrity.

Performance regressions and numerical discrepancies without a security impact
belong in the public issue tracker.

## Supported versions

Security fixes target the latest released version and the default development
branch. Historical benchmark snapshots and rejected experimental tactics are
evidence, not supported releases.
