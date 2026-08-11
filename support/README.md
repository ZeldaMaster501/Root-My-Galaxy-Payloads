# Support feed schema

`targets-v4.json` keeps one entry for each shared exploit and KernelSU payload.
Automatic selection always matches the exact device model and three-part
kernel version, such as `6.6.98`. Profiles with firmware-specific offsets must
also declare exact kernel releases and display builds.

Each entry contains only:

- `payloadId` and `displayName`;
- one or more exact `Build.MODEL` values in `models`;
- one or more versions in `kernelVersions`;
- `url` and `size` for the exploit and KernelSU artifacts.

Firmware-specific entries may add `kernelReleases` and `buildIds`. When
present, both are hard compatibility gates, including for manual advanced-mode
selection. They cannot be overridden in the UI.

An entry may set `exploitAttempts` from 1 through 24. Experimental profiles
should begin with one fail-closed attempt; the default remains 24 for existing
entries.

An entry may additionally set `requiresFreshP0Session` to `true` when slide
discovery and exploitation must run in the same payload process. The app then
disables its per-boot P0 cache for that profile. The field defaults to `false`,
so existing profiles retain cached behavior.

The app extracts the leading numeric version from `uname -r`. For profiles
that declare exact gates, the complete `uname -r` value and `Build.DISPLAY`
must also match.

`targets-v2.json` remains unchanged for released 0.2.3 clients. Version 3
clients do not understand exact-build gates, so `targets-v3.json` deliberately
omits E3Q/SM-S928U profiles rather than allowing a coarse kernel match. Updated
clients read only schema version 4.
