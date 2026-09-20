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
