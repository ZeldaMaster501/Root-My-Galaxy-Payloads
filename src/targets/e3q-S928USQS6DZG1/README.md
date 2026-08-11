# e3q-S928USQS6DZG1 compatibility status

This directory is an offline-derived diagnostic target for the exact
SM-S928U DZG1 firmware. It is only partially hardware-validated. The candidate
support profile is exact-build gated, requests a fresh P0 session, and permits
only one outer exploit attempt.

The exact DZG1 kernel keeps all named offsets used by the DZF2 target, and its
complete detached BTF blob is byte-identical to DZF2. The target therefore
inherits the audited DZF2 structural constants. DZG1's kernel Image and P0
fingerprints are different, so `p0_fingerprint.h` was regenerated from the
exact DZG1 raw Image and independently read back at all 256 source qwords.

See `docs/SM-S928U-S928USQS6DZG1.md` for hashes, derivation evidence, and the
remaining hardware-validation boundary. Matching exploit and KernelSU
artifacts are now reproducibly built. Hardware testing reached the physical P0
write trigger at 20, 25, 30, and 50 ms with a successful scheduler call while
`pselect` reported a timeout. The fork-only diagnostic now uses one 25 ms call
and the exact pipe marker as downstream verification. It remains experimental
until the later fingerprint, physical read/write, and KernelSU stages are
validated.
