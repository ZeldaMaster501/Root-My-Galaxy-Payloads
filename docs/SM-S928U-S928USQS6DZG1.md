# SM-S928U / S928USQS6DZG1 porting record

This record freezes the offline inputs and results for the Galaxy S24 Ultra
US carrier firmware reported by the device. No artifact in this record is a
claim of hardware exploit success.

## Exact firmware identity

| Field | Verified value |
| --- | --- |
| Model / CSC | `SM-S928U` / `TMB` |
| AP/PDA | `S928USQS6DZG1` |
| Android display build | `BP4A.251205.006.S928USQS6DZG1` |
| Kernel release | `6.1.145-android14-11-33419968-abS928USQS6DZG1` |
| Kernel build time | `Mon Jul 6 04:39:52 UTC 2026` |
| Firmware package version | `S928USQS6DZG1/S928UOYN6DZG1/S928USQS6DZG1/S928USQS6DZG1` |

The firmware package was downloaded from Samsung FUS for model `SM-S928U`,
region `TMB`, and passed a complete ZIP integrity test.

## Hash-frozen inputs

| Object | Size (bytes) | SHA-256 |
| --- | ---: | --- |
| Firmware ZIP | 14,744,566,939 | `1b75c633addc9ff7c0ca9ff72d13814c46e1662ad14a1dc371181016d2cc2384` |
| AP `boot.img.lz4` | 22,105,412 | `212785f810c8e71d7864c68e865129d40abbccecd361118b93a7a5bd329f7390` |
| Decompressed `boot.img` | 100,663,296 | `2da957594365188fd3da382a16a6ab7e6b0c5262940462c7dede415f324bb5ce` |
| Raw kernel Image | 38,005,248 | `42a1f863b40652633b750698d666c9a3d6136aae87a280eff3b20ce33d6f9c60` |
| Recovered `vmlinux.elf` | 43,070,883 | `409fe5a04ebb1c412f5e24bacee39c8c3e8324863eed139c58f26a0d96e13bf5` |
| Detached BTF | 5,981,643 | `8415104c012e18942b18bcb52f401075cb6b92df837b9552a8c11070d65efe56` |
| BL `abl.elf` | 2,441,528 | `32068332f5209cb7bf063980cb52d85d50fe63a6894bdf7a02b4ee14d24da911` |

The raw kernel banner matches the device-reported release and build time
exactly.

## DZF2 compatibility comparison

The DZG1 raw kernel hash differs from DZF2 (`875b5017...80c7c5`), so treating
the two builds as interchangeable is invalid. Static analysis nevertheless
established the following narrow compatibility facts:

- all named functions and data objects used by `target.h` retain their DZF2
  virtual offsets;
- `__start_ftrace_events`, `__event_sched_blocked_reason`, and `worker_thread`
  retain the offsets used to derive event ID `106` and caller `0x000db1a0`;
- the complete BTF blob is byte-identical to DZF2, proving the required
  structure layouts are unchanged;
- all 209 undefined symbols required by the existing manual-relocation
  KernelSU module are present in the recovered DZG1 symbol table, with no
  module CRC entries to reconcile;
- all 32 DZG1 P0 fingerprint rows differ from DZF2 (256 of 256 sampled qwords)
  and were regenerated from the exact DZG1 Image at probe offset `0x1f0000`.

`src/targets/e3q-S928USQS6DZG1/target.h` therefore inherits only the
statically verified DZF2 constant set and replaces firmware identity and P0
fingerprints. The generated fingerprint header has SHA-256
`e1c598840364472c5eb49072e74872e553bf0816e02b73402494042d44371115`.

## Candidate artifacts

The app payload was built twice from the DZG1 target with Zig's Clang frontend,
AOSP Bionic headers, and LLD. Both builds were byte-identical. The KernelSU
module keeps the DZF2 module's executable bytes and changes only its
equal-length kernel release string. Its 209 undefined imports all resolve in
the recovered DZG1 symbol table, the module has no CRC entries, and the full
target BTF is byte-identical. The matching loader embeds the retargeted module
as a raw-DEFLATE stream without changing loader code or asset addresses.

| Object | Size (bytes) | SHA-256 |
| --- | ---: | --- |
| `artifacts/e3q-S928USQS6DZG1/cve-2026-43499-app.so` | 104,128 | `567ae609a125426bb8d59fe8a6596cfd8ad2f15fa8b36ae211f74fc1603e8286` |
| `kernelsu/android14-6.1_kernelsu-e3q-S928USQS6DZG1-kdp.ko` | 400,152 | `13ca83e08ef60b3645506fbbc7e62d8cb6176d0a7659fe4b202fccbde84dc9cb` |
| `kernelsu/ksud-e3q-S928USQS6DZG1-kdp` | 4,726,416 | `a5f50666f9b917edc89ba410dfac653a44dcc33c17705f732db1b9c57c5afb48` |

`tools/build_android_payload_with_zig.sh` reproduces the payload when supplied
with Zig 0.12 and an AOSP Bionic checkout.
`kernelsu/tools/retarget_embedded_module.py` verifies the source loader's
embedded module before creating the DZG1 module/loader pair.

## Remaining boundary

The candidate now has fail-closed hardware observations on the exact DZG1
device. Some runs did not obtain an `mm_struct`; other runs obtained the leak
and reached the physical P0 write trigger. That trigger scheduled successfully
at 20, 25, 30, and 50 ms but did not produce the pipe-page marker, before any
P0 fingerprint match, physical read/write installation, or KernelSU loading.

Static disassembly of the exact DZG1 `remove_waiter()` at
`0xffffffc00911fcb8` confirms the vulnerable implementation: it reads
`SP_EL0`, locks `current->pi_lock` at `+0x924`, and clears
`current->pi_blocked_on` at `+0x950`, rather than operating on
`waiter->task`. The embedded configuration also has `CONFIG_FUTEX_PI=y` and
`CONFIG_RANDOMIZE_KSTACK_OFFSET=y`.

The DZF2 porting record says its retained E3Q allocator baseline is 28 skb
fragment sends with two synchronous late-drain triggers. The inherited target
header had not encoded those settings, so DZG1 tests actually ran the shared
16-send/32-drain defaults. The next fork-only diagnostic corrects that mismatch
and raises only the pre-write KernelSnitch setup attempts from two to six. It
keeps one 25 ms scheduler trigger and requires the exact pipe-page marker to
accept a write. The v4 manifest remains exact-build gated and caps execution at
one outer exploit attempt. No result here is a claim of successful root.
