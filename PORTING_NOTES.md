# iPhone 3GS Porting Notes

Technical notes from bringing OpenStrike to a physical iPhone 3GS running iOS 6.1.6.

## Build environment

The working setup uses:

- macOS on Apple Silicon
- Xcode 26.6 command-line tools
- iOS 6.1.3 ARMv7 sysroot extracted locally from an IPSW
- Rust nightly `nightly-2026-07-02`
- `rust-src`
- `llvm-tools-preview`
- Bun
- jailbreak-side OpenSSH
- `ldid`

The iOS 6.1.3 firmware image is used only as a build sysroot. It is not intended to be flashed to an iPhone 3GS.

## Rust target

The native OpenStrike static library is built against:

```text
vendor/pocketjs/hosts/ipodtouch4/armv7-apple-ios.json
```

with:

```sh
IPHONEOS_DEPLOYMENT_TARGET=6.0 \
cargo +nightly-2026-07-02 build \
  --manifest-path crates/openstrike-symbian/Cargo.toml \
  --release \
  --locked \
  --target "$PWD/vendor/pocketjs/hosts/ipodtouch4/armv7-apple-ios.json" \
  -Z json-target-spec \
  -Z build-std=core,alloc,compiler_builtins \
  -Z build-std-features=compiler-builtins-mem
```

Current Rust warns that iOS 6 is below its supported deployment minimum. The resulting executable is nevertheless linked with the correct legacy minimum-version load command and has been verified on real iOS 6.1.6 hardware.

## Native extension

The OpenStrike native extension uses the existing PocketJS extension ABI rather than moving the simulation into JavaScript.

Relevant callbacks:

- boot
- shutdown
- before_guest
- after_guest
- resize
- render

## GLES2

The legacy iOS host was adapted from a GLES1-oriented path to:

- OpenGL ES 2.0
- GLES2 framebuffer/renderbuffer calls
- a 16-bit depth attachment
- native 3D rendering plus PocketJS overlay rendering

## Pocket3D target gating

The Pocket3D GLES2 backend originally compiled its real GPU path only for `target_os = "none"`.

The custom ARMv7 Apple target reports `target_os = "ios"`, so the backend returned `UnsupportedHost` even with a valid GLES2 EAGL context.

The port enables the same GLES2 implementation for iOS.

## Map-load diagnostics

The initial error:

```text
OpenStrike render: map load/GPU init failed
```

was split into individual stages. This isolated the failure to:

```text
OpenStrike load: P3D/simulation creation failed
```

That ruled out GLES2 initialization and led to the cooked-map memory layout.

## PAK alignment bug

Before the fix:

```text
sectname __pocket_pak
segname __DATA
addr 0x0026c259
align 2^0 (1)
```

The PAK aligned its own blob offsets, but the entire Mach-O section itself began at an unaligned address.

Because the P3D reader borrows typed data directly from the source buffer, the section base must also be aligned.

Fix:

```text
-sectalign __DATA __pocket_pak 0x10
```

After rebuilding:

```text
sectname __pocket_pak
segname __DATA
addr 0x0026c260
align 2^4 (16)
```

The map then loaded successfully on the physical iPhone.

## Touch input

The existing iOS runtime already samples multiple simultaneous contacts.

The port reuses the native extension's existing `analog` and `native_keys` fields instead of changing the ABI.

Current iPhone-specific packed analog layout:

```text
bits  8..15 : movement X, center 128
bits  0..7  : movement Y, center 128
bits 24..31 : relative look X, center 128
bits 16..23 : relative look Y, center 128
```

Native key bits carry fire, jump and reload.

Touch roles are captured on touch-down and retained until release.

## Current texture issue

The first working `de_dust2` cook was produced without the complete required WAD set.

Therefore many surfaces currently use Pocket3D's unresolved-texture checkerboard placeholder. The fix is to re-cook with the correct Counter-Strike / Half-Life WAD directories supplied through repeated `--wads` arguments.

## Files that must never be published

```text
*.bsp
*.wad
*.p3d
*.ipsw
*.ipa
.pocket-build/
dist/maps/
```

Also keep out:

- device UDIDs
- SSH private keys
- absolute local user paths
- Apple SDK/sysroot contents
- Valve game assets
