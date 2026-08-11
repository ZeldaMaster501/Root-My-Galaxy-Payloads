#!/bin/sh
set -eu

# Build the compact Android/AArch64 app payload without a complete NDK.
#
# Required environment:
#   ZIG         path to a Zig 0.12 compiler
#   BIONIC_DIR  AOSP platform/bionic checkout
#
# Optional environment:
#   TARGET      target directory below src/targets
#   OUTPUT      final padded shared-object path
#   API         Android API level used for Bionic declarations

: "${ZIG:?set ZIG to the Zig compiler path}"
: "${BIONIC_DIR:?set BIONIC_DIR to an AOSP platform/bionic checkout}"

TARGET=${TARGET:-e3q-S928USQS6DZG1}
OUTPUT=${OUTPUT:-build-zig/$TARGET/cve-2026-43499-app.release.so}
API=${API:-35}
RELEASE_SIZE=104128

case "$OUTPUT" in
  /*) output_path=$OUTPUT ;;
  *) output_path=$PWD/$OUTPUT ;;
esac

target_header=src/targets/$TARGET/target.h
test -f "$target_header" || {
  echo "missing target header: $target_header" >&2
  exit 1
}
test -x "$ZIG" || {
  echo "ZIG is not executable: $ZIG" >&2
  exit 1
}
test -f "$BIONIC_DIR/libc/include/android/versioning.h" || {
  echo "BIONIC_DIR is not a platform/bionic checkout: $BIONIC_DIR" >&2
  exit 1
}

build_tmp=$(mktemp -d /tmp/root-my-galaxy-zig.XXXXXX)
trap 'rm -rf -- "$build_tmp"' EXIT HUP INT TERM
obj_dir=$build_tmp/obj
mkdir -p "$obj_dir" "$(dirname "$output_path")"

# Keep Zig's caches in the disposable build area. This also makes the helper
# work in restricted workspaces where the compiler's default cache is read-only.
export ZIG_GLOBAL_CACHE_DIR=$build_tmp/global-cache
export ZIG_LOCAL_CACHE_DIR=$build_tmp/local-cache

sources='src/main.c src/util.c src/slide_app.c src/fops.c src/pipe.c src/root.c src/preload.c'
for source in $sources; do
  object=$obj_dir/$(basename "$source" .c).o
  "$ZIG" cc -target aarch64-linux-android \
    -D__ANDROID_API__="$API" -DAPP_PAYLOAD=1 \
    -fPIC -Oz -g0 -fno-builtin -fno-stack-protector \
    -fvisibility=hidden -mno-outline-atomics \
    -fno-unwind-tables -fno-asynchronous-unwind-tables \
    -ffunction-sections -fdata-sections \
    -Wall -Wextra -Wno-unused-parameter -Wno-sign-compare \
    -Isrc \
    -I"$BIONIC_DIR/libc/include" \
    -I"$BIONIC_DIR/libc/kernel/uapi/asm-arm64" \
    -I"$BIONIC_DIR/libc/kernel/uapi" \
    -I"$BIONIC_DIR/libc/kernel/android/uapi" \
    -DTARGET_HEADER="\"targets/$TARGET/target.h\"" \
    -c "$source" -o "$object"
done

# Zig supplies the compiler and linker, while Bionic supplies Android's ABI
# declarations. Empty link-only DSOs add the normal Android DT_NEEDED entries;
# no stub library is included in the published payload.
"$ZIG" cc -target aarch64-linux-android -c -x c /dev/null \
  -o "$build_tmp/empty.o"
"$ZIG" ld.lld -shared -soname libdl.so \
  -o "$build_tmp/libdl.so" "$build_tmp/empty.o"
"$ZIG" ld.lld -shared -soname libc.so \
  -o "$build_tmp/libc.so" "$build_tmp/empty.o"

"$ZIG" ld.lld -shared -z now -z relro -z max-page-size=16384 \
  --gc-sections --hash-style=gnu --no-as-needed \
  -o "$build_tmp/payload.so" "$obj_dir"/*.o \
  "$build_tmp/libdl.so" "$build_tmp/libc.so"
"$ZIG" objcopy --strip-all "$build_tmp/payload.so" "$output_path"

actual_size=$(wc -c < "$output_path")
if [ "$actual_size" -gt "$RELEASE_SIZE" ]; then
  echo "payload is $actual_size bytes; release slot is $RELEASE_SIZE" >&2
  exit 1
fi
truncate -s "$RELEASE_SIZE" "$output_path"
chmod 755 "$output_path"

sha256sum "$output_path"
