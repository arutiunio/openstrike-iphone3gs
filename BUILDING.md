# Building OpenStrike for iPhone 3GS (iOS 6.1.6)

This is the step-by-step build log for the working iPhone 3GS experiment.

The commands below are the same command paths used during the real porting session on a physical iPhone 3GS. The setup intentionally reuses PocketJS's existing legacy `ipodtouch4` deployment path and adapts it to `iPhone2,1 / N88AP`.

> Tested target: **iPhone 3GS, iOS 6.1.6, ARMv7, 480×320 landscape, OpenGL ES 2.0, 256 MB RAM**.

The final result boots OpenStrike, loads a cooked GoldSrc map, renders the world with Pocket3D GLES2, runs the simulation and accepts multi-touch gameplay input.

---

# 0. What this guide assumes

The base legacy iPhone environment is the same one documented in:

- https://github.com/arutiunio/pocketjs-iphone3gs

That setup provides:

- jailbreak + AppSync
- OpenSSH
- `ldid`
- `uicache`
- `uiopen`
- passwordless RSA SSH over USB
- the pinned iOS 6 ARMv7 sysroot
- Xcode 26.6 with `ld-classic`
- Rust nightly `nightly-2026-07-02`
- Bun
- libimobiledevice / iproxy

If that base setup is not working yet, complete the PocketJS iPhone 3GS guide first.

Useful host checks:

```bash
idevice_id -l

DEVELOPER_DIR=/Applications/Xcode-26.6.app/Contents/Developer \
  xcrun --find ld-classic

rustup toolchain list
```

Required Rust components:

```bash
rustup component add rust-src --toolchain nightly-2026-07-02
rustup component add llvm-tools-preview --toolchain nightly-2026-07-02
```

---

# 1. Clone OpenStrike

Start from the upstream project:

```bash
cd ~/Downloads

git clone --recurse-submodules https://github.com/pocket-stack/open-strike.git
cd open-strike

git checkout -b iphone3gs

bun run setup
```

The working port used these pinned submodules during development:

```text
vendor/pocketjs   3f419008513be55aa0319600c76341c5e9c2ad11
vendor/quickjs-rs ba5bdd0dc013518768e76cd9e05cd30ed53dd35b
vendor/rust-psp   2cbaf8c9bc72569c76240a1d9743de10731e5f6b
```

Do not blindly update PocketJS while reproducing the port. This work depended on the pinned local tree.

---

# 2. Apply the base iPhone 3GS PocketJS device patch

The device-identity/display patch from the standalone PocketJS experiment works on OpenStrike too because OpenStrike vendors PocketJS at `vendor/pocketjs`.

Clone the helper repository next to OpenStrike:

```bash
cd ~/Downloads

git clone https://github.com/arutiunio/pocketjs-iphone3gs.git
```

Apply it to the OpenStrike checkout:

```bash
python3 ~/Downloads/pocketjs-iphone3gs/scripts/apply-iphone3gs-patch.py \
  ~/Downloads/open-strike
```

This changes:

```text
iPod4,1 / N81AP
→
iPhone2,1 / N88AP
```

and:

```text
640×960 @2x
→
320×480 @1x
```

It also accepts the tested device's `WildcardActivated` activation state and keeps the working public-key SSH deployment path.

Verify:

```bash
cd ~/Downloads/open-strike

grep -nE 'productType|hardwareModel' \
  vendor/pocketjs/tools/ipodtouch4-toolchain.ts

grep -nE 'PHYSICAL_VIEWPORT|RASTER_DENSITY' \
  vendor/pocketjs/tools/ipodtouch4-profile.ts
```

Expected identity:

```text
iPhone2,1
N88AP
320×480
density 1
```

---

# 3. iPhone-specific OpenStrike app configuration

The working port uses a separate iPhone 3GS application configuration.

`iphone3gs.json`:

```json
{
  "id": "openstrike-iphone3gs",
  "projectRoot": ".",
  "manifest": "pocket.iphone3gs.json",
  "bundleId": "dev.pocket-stack.openstrike.iphone3gs",
  "bundleName": "OpenStrike3GS.app",
  "executable": "OpenStrike3GS",
  "title": "OpenStrike",
  "scheme": "openstrike-iphone3gs",
  "receiptSlug": "openstrike-iphone3gs",
  "actionName": "openstrike_action",
  "svcWire": false,
  "keepAwake": true
}
```

The iPhone game viewport is landscape:

```text
logical: 480×320
physical: 480×320
density: 1
presentation: native
```

The iPhone app manifest used in the working tree is named:

```text
pocket.iphone3gs.json
```

The source snapshot for this port should keep this manifest beside `iphone3gs.json` so it does not replace the upstream desktop/PSP/Vita configuration.

---

# 4. Prepare a GoldSrc map

The first working map was a locally supplied `de_dust2.bsp`.

Valve assets are not included in this repository.

Create the output directory:

```bash
cd ~/Downloads/open-strike
mkdir -p dist/maps
```

Cook the BSP into Pocket3D's P3D format:

```bash
cd ~/Downloads/open-strike/vendor/pocketjs/engine/pocket3d

cargo run --release -q -p pocket3d-cook -- \
  /path/to/de_dust2.bsp \
  --subdivide 32 \
  -o /path/to/open-strike/dist/maps/de_dust2.p3d \
  --verify
```

The first successful experiment produced a valid map with output similar to:

```text
verify: ... ok
1455 leaves
1201 visleaves
spawns 20/20
```

and approximately:

```text
faces 3998
verts 58029
tris 63786
batches 34
textures 44
```

## WAD textures

If you cook only the BSP, many external textures may be unresolved and Pocket3D will use checkerboard placeholders.

Supply the game WAD directories:

```bash
cargo run --release -q -p pocket3d-cook -- \
  /path/to/de_dust2.bsp \
  --wads /path/to/cstrike \
  --wads /path/to/valve \
  --subdivide 32 \
  -o /path/to/open-strike/dist/maps/de_dust2.p3d \
  --verify
```

The cooker supports repeated `--wads` arguments.

---

# 5. Add the map to the PocketJS PAK

The working test used:

`game/pak.json`:

```json
[
  {
    "key": "maps/de_dust2.p3d",
    "file": "../dist/maps/de_dust2.p3d"
  }
]
```

The native OpenStrike map key must match exactly:

```text
maps/de_dust2.p3d
```

Do not publish the resulting P3D when it is derived from proprietary Valve assets.

---

# 6. Enable the Pocket3D GLES2 backend on iOS

A major issue was that Pocket3D's real GLES2 backend was gated to:

```rust
#[cfg(target_os = "none")]
```

The custom iPhone target reports:

```text
target_os = "ios"
```

so `WorldRenderer::initialize_gpu()` returned `UnsupportedHost` even with a valid EAGL GLES2 context.

The exact patch used during the experiment:

```bash
cd ~/Downloads/open-strike

python3 - <<'PY'
from pathlib import Path

root = Path("vendor/pocketjs/engine/pocket3d/crates/pocket3d-gles2/src")

for name in ["lib.rs", "world.rs", "mesh.rs"]:
    p = root / name
    s = p.read_text()
    before = s

    s = s.replace(
        '#[cfg(any(target_os = "none", test))]',
        '#[cfg(any(target_os = "none", target_os = "ios", test))]'
    )

    s = s.replace(
        '#[cfg(not(target_os = "none"))]',
        '#[cfg(not(any(target_os = "none", target_os = "ios")))]'
    )

    s = s.replace(
        '#[cfg(target_os = "none")]',
        '#[cfg(any(target_os = "none", target_os = "ios"))]'
    )

    p.write_text(s)
    print(name, "patched" if s != before else "unchanged")
PY
```

Verify that the old gates are gone:

```bash
grep -RIn \
  'cfg(target_os = "none")\|cfg(not(target_os = "none"))\|any(target_os = "none", test)' \
  vendor/pocketjs/engine/pocket3d/crates/pocket3d-gles2/src
```

For the already-patched working tree, this command prints nothing.

---

# 7. GLES2 + depth in the legacy iOS host

The original legacy PocketJS iPhone host is GLES1-oriented. OpenStrike needs GLES2 and a depth buffer.

The working port changes the iPod-touch wrapper to request:

```c
#define POCKET_EAGL_API 2
#define POCKET_GL_DEPTH_BUFFER 1
#define POCKET_GL_RENDERER_NAME "gles2"
#define POCKET_GL_RENDERER_STATUS "Running on OpenGL ES 2.0 with depth"
```

The shared legacy host creates a `GL_DEPTH_COMPONENT16` renderbuffer, attaches it to the framebuffer and uses the GLES2 framebuffer functions.

The render order is:

```text
OpenStrike native Pocket3D pass
→
PocketJS HUD overlay
→
presentRenderbuffer
```

This source-level patch is part of the working port tree and is described in detail in [PORTING_NOTES.md](PORTING_NOTES.md).

---

# 8. Build the OpenStrike ARMv7 static library

The working Rust build command is:

```bash
cd ~/Downloads/open-strike

IPHONEOS_DEPLOYMENT_TARGET=6.0 \
cargo +nightly-2026-07-02 build \
  --manifest-path crates/openstrike-symbian/Cargo.toml \
  --release \
  --locked \
  --target "$PWD/vendor/pocketjs/hosts/ipodtouch4/armv7-apple-ios.json" \
  -Z json-target-spec \
  -Z build-std=core,alloc,compiler_builtins \
  -Z build-std-features=compiler-builtins-mem \
  --target-dir "$PWD/.pocket-build/iphone3gs-native"
```

Expected output library:

```text
.pocket-build/iphone3gs-native/armv7-apple-ios/release/libopenstrike_symbian.a
```

Current Rust prints this warning:

```text
deployment target in IPHONEOS_DEPLOYMENT_TARGET was set to 6.0,
but the minimum supported by rustc is 10.0
```

For this experiment, the warning is not fatal. The final executable is linked with the legacy iOS minimum-version load command and was verified on a real iOS 6.1.6 device.

Point the PocketJS iPod-touch builder at the OpenStrike library and app config:

```bash
export POCKETJS_IPODTOUCH4_NATIVE_LIBRARY="$PWD/.pocket-build/iphone3gs-native/armv7-apple-ios/release/libopenstrike_symbian.a"

export POCKETJS_IPODTOUCH4_APP_FILE="$PWD/iphone3gs.json"

export POCKETJS_IPODTOUCH4_UDID="$(idevice_id -l | head -n 1)"
```

---

# 9. Fix Mach-O PAK alignment

This was the key map-loading bug on ARMv7.

Before the fix, the executable contained:

```text
sectname __pocket_pak
segname __DATA
addr 0x...259
align 2^0 (1)
```

The P3D reader performs zero-copy typed reads, so this can make the P3D's `u16` sections unaligned.

Patch the linker command in `vendor/pocketjs/tools/ipodtouch4.ts`:

```bash
cd ~/Downloads/open-strike

python3 - <<'PY'
from pathlib import Path

p = Path("vendor/pocketjs/tools/ipodtouch4.ts")
s = p.read_text()

old = '''    "-sectcreate", "__DATA", "__pocket_js", embeddedJavaScript,
    "-sectcreate", "__DATA", "__pocket_pak", guestPak,
    "-framework", "UIKit",'''

new = '''    "-sectcreate", "__DATA", "__pocket_js", embeddedJavaScript,
    "-sectalign", "__DATA", "__pocket_pak", "0x10",
    "-sectcreate", "__DATA", "__pocket_pak", guestPak,
    "-framework", "UIKit",'''

if new in s:
    print("PAK alignment already installed")
elif old in s:
    p.write_text(s.replace(old, new, 1))
    print("added 16-byte Mach-O alignment for __pocket_pak")
else:
    raise SystemExit("linker section block not found")
PY
```

Build the app:

```bash
DEVELOPER_DIR=/Applications/Xcode-26.6.app/Contents/Developer \
bun vendor/pocketjs/tools/ipodtouch4.ts build
```

Verify alignment:

```bash
xcrun otool-classic -l \
  vendor/pocketjs/dist/ipodtouch4/OpenStrike3GS.app/OpenStrike3GS \
  | grep -A8 -B2 'sectname __pocket_pak'
```

Expected:

```text
sectname __pocket_pak
segname __DATA
...
align 2^4 (16)
```

The working build had an address ending in `...260`, i.e. also 16-byte aligned.

---

# 10. Native touch controls

PocketJS's iOS host already samples multiple contacts. The initial OpenStrike native input path did not receive touch coordinates, so the menu worked but the player could not move or aim.

The port reuses the existing native extension fields instead of changing the ABI:

```text
analog
native_keys
```

The iPhone-specific packed analog layout is:

```text
bits  8..15 : movement X
bits  0..7  : movement Y
bits 24..31 : relative look X
bits 16..23 : relative look Y
```

All axes use 128 as center.

Action bits carry:

```text
fire
jump
reload
```

Current touch regions:

```text
left side             floating movement stick
right/main area       drag to look
bottom-right          fire
lower-right secondary jump
upper-right           reload
```

Touch roles are captured on finger-down, which allows movement + aiming + firing simultaneously.

The exact touch bridge source patch belongs in the port source snapshot; after applying it, rebuild the Rust library with the command from section 8.

---

# 11. Build the final iPhone app

With the native library and app config environment variables still set:

```bash
cd ~/Downloads/open-strike

DEVELOPER_DIR=/Applications/Xcode-26.6.app/Contents/Developer \
bun vendor/pocketjs/tools/ipodtouch4.ts build
```

Expected:

```text
built .../OpenStrike3GS.app
.../OpenStrike3GS: Mach-O executable arm_v7
build_id=...
```

---

# 12. Deploy

```bash
DEVELOPER_DIR=/Applications/Xcode-26.6.app/Contents/Developer \
bun vendor/pocketjs/tools/ipodtouch4.ts deploy
```

Expected:

```text
deployed User app <BUILD_ID> with byte-exact readback
```

---

# 13. Launch

```bash
DEVELOPER_DIR=/Applications/Xcode-26.6.app/Contents/Developer \
bun vendor/pocketjs/tools/ipodtouch4.ts launch
```

A successful real-device run reported:

```json
{
  "schema": 2,
  "state": "running",
  "renderer": "gles2",
  "clock": "displaylink",
  "raster_density": 1,
  "drawable_width": 480,
  "drawable_height": 320,
  "error": ""
}
```

At this point OpenStrike is running natively on the iPhone 3GS.

---

# 14. Useful diagnostics

## Confirm the binary architecture

```bash
file \
  vendor/pocketjs/dist/ipodtouch4/OpenStrike3GS.app/OpenStrike3GS
```

Expected:

```text
Mach-O executable arm_v7
```

## Inspect the iOS deployment load command

```bash
xcrun otool-classic -l \
  vendor/pocketjs/dist/ipodtouch4/OpenStrike3GS.app/OpenStrike3GS \
  | grep -A5 LC_VERSION_MIN_IPHONEOS
```

## Re-check PAK alignment

```bash
xcrun otool-classic -l \
  vendor/pocketjs/dist/ipodtouch4/OpenStrike3GS.app/OpenStrike3GS \
  | grep -A8 -B2 'sectname __pocket_pak'
```

---

# 15. Errors encountered during the port

These were real failure stages from the experiment.

## `Required OpenGL ES present failed`

The generic host error hid the native renderer failure.

After adding stage-specific diagnostics, the failure became:

```text
OpenStrike native GLES2 render failed
```

and then:

```text
OpenStrike render: map load/GPU init failed
```

## Pocket3D `UnsupportedHost`

Cause:

```rust
#[cfg(target_os = "none")]
```

excluded the real GLES2 backend on iOS.

Fix: section 6.

## `P3D/simulation creation failed`

The cooked P3D verified correctly on macOS but failed on the ARMv7 device.

Cause: the entire Mach-O `__pocket_pak` section started at an unaligned address.

Fix: section 9.

## Map loads but most surfaces are purple/black checkerboards

Cause: required external WAD textures were not supplied during cooking.

Fix: use one or more `--wads` directories when running `pocket3d-cook`.

## Menu touch works but gameplay touch does nothing

Cause: contacts reached PocketJS, but OpenStrike's native extension only received the existing button/analog/native-key fields.

Fix: the native touch bridge described in section 10.

---

# 16. What not to publish

Never commit:

```text
*.bsp
*.wad
*.p3d
*.ipsw
*.ipa
.pocket-build/
dist/maps/
vendor/pocketjs/dist/
```

Also keep private:

- device UDIDs
- SSH private keys
- activation records
- Apple SDK/sysroot files
- local absolute user paths
- Valve models, sounds, sprites and other proprietary assets

---

# 17. Important note about the source snapshot

This document records the **verified build/deploy commands and the important source-level fixes** from the successful experiment.

The current public repository was created after the port was already running locally. The complete working OpenStrike/PocketJS source snapshot still needs to be pushed from that local checkout.

Until that snapshot is present, use this guide together with:

- [PORTING_NOTES.md](PORTING_NOTES.md)
- [pocketjs-iphone3gs](https://github.com/arutiunio/pocketjs-iphone3gs)

Once the source snapshot is committed here, the intended final workflow is simply:

```bash
git clone --recurse-submodules https://github.com/arutiunio/openstrike-iphone3gs.git
cd openstrike-iphone3gs

# prepare proprietary map assets locally
# build native ARMv7 library
# build/deploy through the legacy PocketJS iPhone host
```

with no Valve or Apple proprietary assets stored in the repository.
