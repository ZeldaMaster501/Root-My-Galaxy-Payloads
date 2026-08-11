#!/usr/bin/env python3
"""Retarget an exact-compatible KernelSU module and its embedded ksud asset.

This helper is deliberately narrow: it changes one equal-length kernel release
string in a standalone module, then replaces the verified raw-DEFLATE module
stream in an existing ksud binary.  It does not relocate or rebuild module
code.  The caller must separately prove that the target kernel exports and BTF
layout are compatible with the source module.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import sys
import zlib


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse_int(value: str) -> int:
    return int(value, 0)


def fail(message: str) -> "NoReturn":
    raise SystemExit(f"error: {message}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_ko", type=Path)
    parser.add_argument("source_ksud", type=Path)
    parser.add_argument("output_ko", type=Path)
    parser.add_argument("output_ksud", type=Path)
    parser.add_argument("--old-release", required=True)
    parser.add_argument("--new-release", required=True)
    parser.add_argument(
        "--asset-offset",
        type=parse_int,
        required=True,
        help="file offset of the raw-DEFLATE module stream",
    )
    parser.add_argument(
        "--asset-size",
        type=parse_int,
        required=True,
        help="size of the original compressed-asset slot",
    )
    args = parser.parse_args()

    old_release = args.old_release.encode("ascii")
    new_release = args.new_release.encode("ascii")
    if len(old_release) != len(new_release):
        fail("release strings must have identical byte lengths")

    source_ko = args.source_ko.read_bytes()
    if source_ko.count(old_release) != 1:
        fail("source module must contain the old release exactly once")
    if new_release in source_ko:
        fail("source module already contains the new release")

    source_ksud = args.source_ksud.read_bytes()
    slot_start = args.asset_offset
    slot_end = slot_start + args.asset_size
    if slot_start < 0 or slot_end > len(source_ksud):
        fail("compressed-asset slot lies outside the loader")

    source_slot = source_ksud[slot_start:slot_end]
    try:
        embedded_source_ko = zlib.decompress(source_slot, wbits=-15)
    except zlib.error as error:
        fail(f"source asset is not a valid raw-DEFLATE stream: {error}")
    if embedded_source_ko != source_ko:
        fail("source loader asset does not byte-match the standalone module")

    output_ko = source_ko.replace(old_release, new_release)
    compressor = zlib.compressobj(level=9, method=zlib.DEFLATED, wbits=-15)
    compressed_ko = compressor.compress(output_ko) + compressor.flush()
    if len(compressed_ko) > args.asset_size:
        fail(
            f"new compressed module ({len(compressed_ko)} bytes) exceeds "
            f"the existing slot ({args.asset_size} bytes)"
        )

    # include-flate/libflate stops at the final DEFLATE block and ignores the
    # unused tail of its input slice.  Keeping the slot length unchanged means
    # no instruction, table, address, or later embedded asset has to move.
    replacement_slot = compressed_ko + bytes(args.asset_size - len(compressed_ko))
    if zlib.decompress(replacement_slot, wbits=-15) != output_ko:
        fail("padded replacement stream did not round-trip")

    output_ksud = bytearray(source_ksud)
    output_ksud[slot_start:slot_end] = replacement_slot

    args.output_ko.parent.mkdir(parents=True, exist_ok=True)
    args.output_ksud.parent.mkdir(parents=True, exist_ok=True)
    args.output_ko.write_bytes(output_ko)
    args.output_ksud.write_bytes(output_ksud)
    args.output_ksud.chmod(args.source_ksud.stat().st_mode & 0o777)

    print(f"module: {len(output_ko)} bytes sha256={sha256(output_ko)}")
    print(
        f"asset: {len(compressed_ko)}/{args.asset_size} bytes "
        f"sha256={sha256(compressed_ko)}"
    )
    print(f"loader: {len(output_ksud)} bytes sha256={sha256(output_ksud)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
