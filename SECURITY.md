# Security policy

## Supported versions

Security fixes target the latest DesktopGoldenEye prerelease and `master`.

## Reporting a vulnerability

Do not open a public issue for a vulnerability that could execute code, escape
the intended launcher/package boundary, overwrite arbitrary files, or expose a
user's ROM path/private data. Use GitHub's **Report a vulnerability** flow for
this repository instead.

Include the affected version, Windows version, reproduction steps, and impact.
Do not attach ROMs, saves, copyrighted game assets, credentials, or unrelated
personal files. You should receive an acknowledgment within seven days.

## Release trust model

v0.1 artifacts are unsigned. Verify `SHA256SUMS.txt` from the GitHub release.
The launcher accepts only exact supported-ROM fingerprints, and public packages
are tested to contain no ROM-like files, player state, prebuilt saves, or unused
legacy plugins.
