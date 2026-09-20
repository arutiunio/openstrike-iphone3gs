# Recovered changes from the successful terminal session

The complete local source snapshot has not yet been pushed, but the terminal transcript preserves the final successful changes and identifies the required porting areas.

## PocketJS / iPhone host

The working tree included changes in:

- `tools/ipodtouch4-toolchain.ts`
  - iPhone 3GS identity: `iPhone2,1 / N88AP`
- `tools/ipodtouch4-profile.ts`
  - 320×480 physical display
  - raster density 1
  - touch + button capability
- `tools/ipodtouch4.ts`
  - accepts `WildcardActivated`
  - iPhone 3GS device doctor identity
  - external OpenStrike Rust static library support
  - QuickJS static wrapper object in the final link
  - GLES2 status validation
  - 16-byte `__pocket_pak` section alignment
  - iPhone-specific touch mapper build define
- `hosts/ipodtouch4/runtime.c`
  - selects EAGL OpenGL ES 2.0
  - requests a depth buffer
- `hosts/ios-legacy/runtime.c`
  - GLES2 framebuffer/renderbuffer support
  - 16-bit depth renderbuffer
  - multi-touch delivery
- `engine/quickjs-c/pocket_runtime.c`
  - native extension render before PocketJS overlay
  - stage-specific renderer diagnostics
  - native touch-to-gamepad bridge
- `engine/ui-cabi/include/pocket_ui_cabi.h`
  - declares `ui_gl_render_over`

## Pocket3D

The real GLES2 backend under:

```text
engine/pocket3d/crates/pocket3d-gles2/src/
```

was enabled for `target_os = "ios"`.

Relevant files:

- `lib.rs`
- `world.rs`
- `mesh.rs`

## OpenStrike native shim

The working tree also changed:

- `crates/openstrike-symbian/Cargo.toml`
- `crates/openstrike-symbian/src/quickjs.rs`
- `crates/openstrike-symbian/src/lib.rs`
- `crates/openstrike-symbian/src/input.rs`

These cover the bare-platform GLES2 path, current shared HostCmd API, QuickJS property wrappers, iOS 60 Hz simulation, map/GPU diagnostics and packed touch input.

## iPhone app files

The successful tree contained:

- `iphone3gs.json`
- `pocket.iphone3gs.json`
- `game/pak.json`

See `examples/` for sanitized versions.

## Why this is not yet a literal patch file

The transcript contains failed/intermediate edits as well as the final successful state. Reconstructing a literal patch blindly could reintroduce an intermediate version.

The preferred next step is to export the diff from the still-working local checkout and commit that exact diff here.
