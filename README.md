# VS Hex V3 — Android port (Psych Engine Mobile)

Unofficial Android port of [VS Hex V3](https://github.com/Kade-github/Hex-V3) running on Psych Engine Mobile 1.0.4.
Download the APK from [Releases](../../releases).

- Hex's own menus (`source/kade/hex`) are compiled from the mod's source through a small `funkin.*` compatibility layer (`source/funkin`).
- Hex's V-Slice data (charts, characters, stages, note styles, events) is read directly from the `hex-src` submodule by `source/hex/*`.
- Touch controls, hitbox and optimization settings come from Psych Engine Mobile (Options → Engine Settings).

## Building
```
git submodule update --init
python3 setup/install_haxelibs.py
haxelib run lime build android -release
```
CI (`.github/workflows/android.yml`) builds the APK and publishes a release when run with a `release-tag` input.

Not included: Kade's unreleased `modchart-engine`, so modcharts don't play.

Psych Engine's original README: [docs/PSYCH_ENGINE_README.md](docs/PSYCH_ENGINE_README.md).
