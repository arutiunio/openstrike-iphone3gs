# Release / IPA notes

The legacy PocketJS builder produces:

```text
vendor/pocketjs/dist/ipodtouch4/OpenStrike3GS.app
```

The real porting session confirmed that this bundle contains a native ARMv7 Mach-O application.

## Local IPA packaging

For a jailbroken/AppSync device, wrap the app in the standard IPA directory layout:

```bash
cd ~/Downloads/open-strike

APP="$PWD/vendor/pocketjs/dist/ipodtouch4/OpenStrike3GS.app"
OUT="$PWD/OpenStrike3GS-local.ipa"

rm -rf .ipa-stage
mkdir -p .ipa-stage/Payload
cp -R "$APP" .ipa-stage/Payload/

(
  cd .ipa-stage
  /usr/bin/zip -qry "$OUT" Payload
)

rm -rf .ipa-stage
ls -lh "$OUT"
```

## Do not publish the current map-bearing test IPA

The successful development build embeds the PocketJS PAK directly into the Mach-O. During testing, that PAK contained a cooked `de_dust2.p3d` derived from Counter-Strike assets.

A public GitHub Release must therefore be rebuilt with redistributable assets only.

Do not include:

- Valve BSP files
- Valve WAD files
- cooked P3D files derived from Valve maps/textures
- Valve models, sounds or sprites
- Apple IPSW/SDK content

A local/private IPA made from legally obtained assets is appropriate for personal testing. The public release should contain only redistributable code and assets.

## Verified clean alpha artifact

A clean map-free IPA produced from the working iPhone 3GS port has been inspected successfully.

```text
File: OpenStrike3GS.ipa
App: OpenStrike
Bundle ID: dev.pocket-stack.openstrike.iphone3gs
Version: 0.1.0
Architecture: ARMv7
MinimumOSVersion: 6.0
Mach-O SDK: iOS 6.1.3
Embedded PocketJS PAK: 1,054,752 bytes
PAK entries: 11 (UI fonts + styles only)
Map/P3D entries: 0
SHA-256: 26f70d8d1e71ce8259587dd2331cbf102eea81d8430768e92900b69ff8653d20
```

The embedded PAK was inspected directly from the Mach-O `__DATA,__pocket_pak` section. It contains no `.p3d` map entries. The binary still contains the string `maps/de_dust2.p3d` because that is a compiled map-key constant in the program, not bundled map data.

The final app icons are 57×57 and 114×114 and the metadata now reports `CFBundleDisplayName = OpenStrike`, `CFBundleName = OpenStrike`, and version `0.1.0`.
