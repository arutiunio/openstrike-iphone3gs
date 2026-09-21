# v0.1.0-alpha — First working iPhone 3GS build

First experimental public build of OpenStrike for the iPhone 3GS.

Tested on a physical **iPhone 3GS** running **iOS 6.1.6**.

## Included

- Native ARMv7 executable
- OpenGL ES 2.0 rendering
- 480×320 native landscape output
- Pocket3D renderer
- Multi-touch gameplay input
- Touch movement
- Drag-to-look camera control
- Fire / jump / reload touch actions
- iOS 6.0 minimum deployment target

## Important

This release intentionally contains **no Counter-Strike maps or other Valve game assets**.

To use GoldSrc maps, provide your own legally obtained BSP/WAD files and cook them locally with Pocket3D. See [BUILDING.md](BUILDING.md).

The clean release IPA was inspected directly: its embedded PocketJS PAK contains only UI fonts/styles and no `.p3d` map entries.

## Installation

This build targets a jailbroken iPhone 3GS / iOS 6 environment with AppSync-compatible application installation.

Bundle ID:

```text
dev.pocket-stack.openstrike.iphone3gs
```

## Artifact

```text
OpenStrike3GS-v0.1.0-alpha.ipa
SHA-256: 26f70d8d1e71ce8259587dd2331cbf102eea81d8430768e92900b69ff8653d20
```

## Status

This is an early alpha. The core port works, but visual fidelity, map packaging, mobile HUD polish, multiplayer and performance profiling are still in progress.
