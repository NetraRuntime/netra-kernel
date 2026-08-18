# Governance

Netra Kernel uses maintainer review with evidence-based promotion gates.

Repository maintainers are responsible for:

- reviewing and merging changes;
- maintaining schemas, ABI versions, and release tags;
- assigning tactic maturity and accepting promotion evidence;
- operating protected hardware validation environments;
- coordinating security reports and releases.

Ordinary changes are accepted through reviewed pull requests. Changes to the
engine format, public C ABI, numerical contracts, tactic maturity, deployment
defaults, or security policy require explicit maintainer approval and must not
be merged solely by an automated process.

Hardware performance decisions must cite machine-readable evidence. When
reviewers disagree, the conservative outcome applies: preserve the existing
path and fallback until the missing evidence is produced.

Maintainer access and branch protection are administered through the
NetraRuntime GitHub organization. This document describes project process; it
does not grant repository permissions.
