# Troubleshooting

These notes come from the real iPhone 3GS porting session.

## ld-classic not found

Check:

```bash
DEVELOPER_DIR=/Applications/Xcode-26.6.app/Contents/Developer \
  xcrun --find ld-classic
```

## rust-src missing

```bash
rustup component add rust-src --toolchain nightly-2026-07-02
rustup component add llvm-tools-preview --toolchain nightly-2026-07-02
```

## Undefined QuickJS *_real symbols

The ARMv7 final link initially failed with symbols including:

```text
_JS_FreeValue_real
_JS_IsUndefined_real
_JS_NewBool_real
_JS_NewFloat64_real
_JS_NewInt32_real
_JS_ValueGetTag_real
_JS_SetProperty
```

The working port uses QuickJS's static wrapper functions and includes the corresponding `static-functions.c` object in the legacy iPhone build. The OpenStrike Rust FFI wrapper maps `JS_SetProperty` through `JS_SetProperty_real`.

## ui_gl_render_over is undeclared

Observed compiler error:

```text
call to undeclared function 'ui_gl_render_over'
```

The iPhone port renders the native OpenStrike/Pocket3D pass first and the PocketJS UI on top, so the C ABI header must declare `ui_gl_render_over(...)`.

## Pocket3D returns UnsupportedHost

Pocket3D's GLES2 backend was originally gated to:

```rust
#[cfg(target_os = "none")]
```

The custom iPhone target reports `target_os = "ios"`. The real GLES2 paths in `pocket3d-gles2` therefore also need to be compiled for iOS.

## Launcher expects GLES1 while the app runs GLES2

An early successful GLES2 build was rejected only by the deployment/status validator:

```text
expected GLES1 ... got gles2 480x320 @1x
```

The validator was updated to accept GLES2 for the reused legacy target.

## P3D verifies on macOS but fails on ARMv7

Before the fix:

```text
sectname __pocket_pak
segname __DATA
align 2^0 (1)
```

Pocket3D performs zero-copy typed reads from the embedded PAK, so the PAK base must be aligned.

Fix:

```text
-sectalign __DATA __pocket_pak 0x10
```

Verify:

```bash
xcrun otool-classic -l \
  vendor/pocketjs/dist/ipodtouch4/OpenStrike3GS.app/OpenStrike3GS \
  | grep -A8 -B2 'sectname __pocket_pak'
```

Expected:

```text
align 2^4 (16)
```

## The map is mostly checkerboards

Re-cook with the required WAD directories:

```bash
cargo run --release -q -p pocket3d-cook -- \
  /path/to/de_dust2.bsp \
  --wads /path/to/cstrike \
  --wads /path/to/valve \
  --subdivide 32 \
  -o /path/to/open-strike/dist/maps/de_dust2.p3d \
  --verify
```

Remaining `unresolved texture ... cooking placeholder` messages correspond to checkerboard surfaces.

## Menu touch works but gameplay touch does not

The iPhone port bridges touch contacts into the native extension's existing `analog` and `native_keys` fields:

```text
bits  8..15  movement X
bits  0..7   movement Y
bits 24..31  relative look X
bits 16..23  relative look Y
```

128 is the center value. Action bits carry fire, jump and reload.

## Root filesystem is full

Check:

```sh
df -h /
df -h /var
```

On the tested device, Cydia's existing helper:

```sh
/usr/libexec/cydia/free.sh
```

stashed `/Applications` and freed rootfs space. This is a jailbreak/device preparation issue rather than an OpenStrike-specific issue.
