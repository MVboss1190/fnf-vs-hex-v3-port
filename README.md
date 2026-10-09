# VS Hex V3 — Android port

Android (APK) port of [VS Hex V3](https://github.com/Kade-github/Hex-V3) for Friday Night Funkin'.

Hex V3 is a Polymod mod for the official FNF engine (with cppia scripting), so this repo is the
FunkinCrew engine (`preview/cppia` branch) built for Android with the mod packed into the APK:

- `bundled-mods/hex` – the mod itself (submodule, Kade-github/Hex-V3).
- On first launch the preloader unpacks the bundled mods into the app data folder
  (`source/funkin/external/android/java/funkin/util/BundledModUtil.java`) and Hex is enabled automatically.
- Touch controls come from the engine's mobile code (hitbox / arrows in gameplay, back button), and
  Hex's own menus already support touch (`HexTouch`).
- `scripts/mobile/build_android.sh` builds the game, compiles Hex's `cppia-src` into `HexMenus.cppia`,
  converts the mod's textures to ASTC (as Hex's `build-mobile.ps1` does) and packs everything into the APK.

## Downloads

See [Releases](../../releases). APKs are built by the `Build Android APK` GitHub Actions workflow
(run it manually with a `release-tag`, or push a `v*` tag).

## Building locally

```sh
git submodule update --init --depth 1
python3 scripts/mobile/install_haxelibs.py
(cd .haxelib/hxcpp/git/tools/hxcpp && haxe compile.hxml)
haxelib run lime rebuild cpp -64 -release -nocffi   # host tools for the Lime fork
haxelib run lime config ANDROID_SDK ... ; haxelib run lime config ANDROID_NDK_ROOT ...  # NDK 29.0.13113456
bash scripts/mobile/build_android.sh
```

Use `HAXELIB_PATH=$PWD/.haxelib`. The APK ends up in `export/out/VS-Hex-V3.apk`.

## Known limitations

Hex's modcharts need Kade's separate modchart engine (mod id `mod-engine`), which isn't public. Without it
the build makes that dependency optional, ships stand-ins for the notefield classes Hex's HUD calls
(`mobile/compat-src`, compiled to `HexCompat.cppia`) and leaves out the Eye2Eye 3D scene. Songs play,
modcharts don't. If the engine becomes available, put it in `bundled-mods/` and rebuild — the stand-ins
are then skipped automatically.

Friday Night Funkin' © FunkinCrew, VS Hex © its authors.
