# OpenStrike for iPhone 3GS

Experimental iPhone 3GS / iOS 6.1.6 port of [OpenStrike](https://github.com/pocket-stack/open-strike).

The goal is to run OpenStrike natively on Apple's 2009 iPhone 3GS using ARMv7, PocketJS, QuickJS, Pocket3D and OpenGL ES 2.0.

> **Current status:** working on real hardware. The game boots, loads a cooked GoldSrc map, renders the 3D world, runs the OpenStrike simulation and accepts multi-touch gameplay input.

## Tested target

- iPhone 3GS
- Product type: `iPhone2,1`
- Hardware model: `N88AP`
- iOS 6.1.6
- ARMv7
- 480×320 landscape
- 1× raster density
- OpenGL ES 2.0
- 256 MB RAM

## Working now

- Native ARMv7 app launch on iOS 6.1.6
- PocketJS + QuickJS runtime
- OpenStrike native extension
- GLES2 rendering
- 16-bit depth buffer
- Pocket3D world rendering
- GoldSrc BSP → P3D cooking
- P3D loading from the embedded PocketJS PAK
- Collision and gameplay simulation
- HUD rendering over the 3D world
- CADisplayLink presentation
- Multi-touch gameplay input
- Touch movement
- Drag-to-look camera control
- Fire / jump / reload touch actions
- Simultaneous movement + aiming + firing
- `de_dust2` tested successfully on a physical iPhone 3GS

Early on-device testing appears to run in roughly the 30–60 FPS range depending on the scene. This is only an informal observation, not a benchmark yet.

## Current limitations

- The current iPhone build has only been validated with the present `de_dust2` test setup.
- Missing WAD files currently produce checkerboard placeholder textures on many surfaces.
- Visuals are not yet a faithful Counter-Strike 1.6 reproduction.
- Full GoldSrc entity behavior is not implemented.
- Multiplayer/networking is not implemented.
- Touch controls are functional, but the final mobile control overlay still needs to be designed.
- Performance and memory use still need proper profiling on-device.

## Important porting work

### Legacy iPhone host → iPhone 3GS

The PocketJS legacy Apple host was adapted for `iPhone2,1` / `N88AP`, iOS 6.1.6 and a 480×320 non-Retina landscape framebuffer.

### ARMv7 Rust

OpenStrike's native extension is built as an ARMv7 static library using a custom Apple iOS Rust target and a pinned nightly toolchain.

The final Mach-O uses an iOS 6 minimum deployment target and runs on real iOS 6.1.6 hardware.

### GLES2 + depth

The legacy iOS host was extended to use:

- `kEAGLRenderingAPIOpenGLES2`
- GLES2 framebuffer/renderbuffer APIs
- a `GL_DEPTH_COMPONENT16` depth renderbuffer
- native OpenStrike 3D rendering followed by the PocketJS HUD overlay

A successful runtime reports:

```text
state=running
renderer=gles2
clock=displaylink
raster_density=1
drawable_width=480
drawable_height=320
error=
```

### Pocket3D GLES2 on iOS

Pocket3D's GLES2 backend was originally gated to the constrained `target_os = "none"` target. The iPhone port enables the real GLES2 world/dynamic-renderer paths for `target_os = "ios"` as well.

### Embedded PAK alignment fix

A major ARMv7 runtime bug was traced to the Mach-O `__DATA,__pocket_pak` section being emitted with byte alignment:

```text
align 2^0 (1)
```

Pocket3D performs zero-copy reads of aligned sections such as `u16` index buffers, so a valid P3D file could fail at runtime even though it verified correctly on macOS.

The linker now forces:

```text
-sectalign __DATA __pocket_pak 0x10
```

The resulting section is 16-byte aligned, after which the same cooked map loads successfully on the iPhone 3GS.

### Multi-touch gameplay bridge

The iOS host already provides multi-contact touch sampling. The port bridges those contacts into OpenStrike's existing native input ABI.

Current control concept:

- Left side: floating movement stick
- Right side: drag to look
- Bottom-right: fire
- Lower-right secondary area: jump
- Upper-right: reload

Touch roles are captured on finger-down, so movement, aiming and firing can happen simultaneously.

## Maps and textures

Pocket3D cooks GoldSrc BSP maps into `.p3d`.

Example:

```sh
cargo run --release -q -p pocket3d-cook -- \
  /path/to/de_dust2.bsp \
  --wads /path/to/cstrike \
  --wads /path/to/valve \
  --subdivide 32 \
  -o dist/maps/de_dust2.p3d \
  --verify
```

If required WAD files are missing, unresolved surfaces are replaced by placeholder checkerboard textures.

## Legal / assets

This repository does **not** distribute Valve game assets.

Do not commit or redistribute:

- Counter-Strike / Half-Life `.bsp` maps
- Valve `.wad` files
- cooked `.p3d` files derived from Valve assets
- Valve models, sounds or sprites
- Apple IPSW files or SDKs
- device identifiers
- SSH keys or signing secrets

Users must provide legally obtained game assets themselves.

## Upstream

Based on:

- https://github.com/pocket-stack/open-strike
- https://github.com/pocket-stack/pocketjs

OpenStrike is MIT licensed. Upstream copyright and license notices are preserved.

## Next milestones

1. Re-cook maps with the correct WAD set and eliminate placeholder textures.
2. Test more classic GoldSrc maps.
3. Replace invisible touch regions with a proper mobile HUD.
4. Profile frame time and memory usage on the 3GS.
5. Improve visual fidelity: sky, models, sprites, effects, HUD and weapon presentation.
6. Explore lightweight authoritative multiplayer after the single-player port is stable.

## Disclaimer

Independent compatibility/porting project. Not affiliated with or endorsed by Valve or Apple.
