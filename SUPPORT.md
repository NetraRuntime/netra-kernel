# Support

Netra Kernel is specialized systems software. Community support is provided on
a best-effort basis through GitHub Issues.

Use the issue templates for:

- reproducible compiler or runtime defects;
- incorrect contract, schema, or profile behavior;
- a bounded kernel/tactic proposal;
- documentation or build-tool problems.

Include the repository revision, target architecture, ROCm version, exact
command, complete contract/profile, and sanitized logs. For performance
reports, include raw repeated samples and the baseline measured under the same
configuration.

The project cannot provide checkpoints, private tensor captures, access to
MI350X hardware, or support for unlisted GPU targets. Unsupported shapes and
contracts are expected to use their declared framework fallback.

Security issues must follow [SECURITY.md](SECURITY.md), not the public tracker.
