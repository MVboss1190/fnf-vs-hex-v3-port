#!/usr/bin/env bash
# Builds the VS Hex Android APK.
#
# Needs: Haxe 4.3.7, the libraries from hmm.json in ./.haxelib (scripts/mobile/install_haxelibs.py),
# Lime configured for Android (ANDROID_SDK, ANDROID_NDK_ROOT, JAVA_HOME), and the submodules checked out.
#
# Steps:
#   1. Build the game for Android. Compiling with -D scriptable also writes export_classes.info.
#   2. Compile Hex's cppia-src into HexMenus.cppia against that host (same as Hex's build.ps1).
#   3. Stage every mod in bundled-mods/ (ASTC textures, like Hex's build-mobile.ps1) into the APK assets.
#   4. Run the Android build again so Gradle packs the staged mods into the APK.
#
# Usage: scripts/mobile/build_android.sh [extra lime flags...]

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

export HAXELIB_PATH="${HAXELIB_PATH:-$ROOT/.haxelib}"

DEFINES=(
	-DNO_FEATURE_MOBILE_ADVERTISEMENTS
	-DNO_FEATURE_MOBILE_IAP
	-DNO_FEATURE_MOBILE_IAR
	-DNO_FEATURE_MOBILE_AGESIGNALS
	-DNO_FEATURE_NEWGROUNDS
	"$@"
)

BUILD_DIR="$ROOT/export/release/android"
WORK="$ROOT/export/hex-mobile"
SDK="$WORK/cppia-sdk"
CPPIA="$WORK/HexMenus.cppia"
STAGED="$WORK/bundled_mods"
APK_ASSETS="$BUILD_DIR/bin/app/src/main/assets"

mkdir -p "$WORK"

# Release signing. Uses the keystore committed in mobile/keystore unless the environment overrides it.
if [ ! -f .env ]; then
	{
		echo "KEYSTORE_PATH=${KEYSTORE_PATH:-$ROOT/mobile/keystore/vshex.keystore}"
		echo "KEYSTORE_ALIAS=${KEYSTORE_ALIAS:-vshex}"
		echo "KEYSTORE_PASSWORD=${KEYSTORE_PASSWORD:-vshexport}"
	} > .env
fi

echo "::group::Build game (pass 1)"
rm -f export_classes.info
haxelib run lime build android -release "${DEFINES[@]}"
echo "::endgroup::"

echo "::group::Build HexMenus.cppia"
if [ ! -f export_classes.info ]; then
	echo "export_classes.info was not written by the build, is FEATURE_CPPIA on?" >&2
	exit 1
fi
mkdir -p "$SDK"
haxelib run lime display android -release "${DEFINES[@]}" \
	| grep -v '^-main ' \
	| grep -v '^-cpp ' \
	| grep -v '^--no-output$' \
	| grep -v '^-D scriptable$' \
	| grep -v '^--macro keep(' \
	| sed -e "s|$ROOT|\${FUNKIN_ROOT}|g" \
	| sed -E "s|^-cp ([^\$/][^:]*)$|-cp \${FUNKIN_ROOT}/\1|" \
	> "$SDK/cppia.hxml"
cp export_classes.info "$SDK/export_classes.info"
# Same as Hex's build.ps1: let the scripts carry their own json2object parser/writer classes.
python3 - "$SDK/export_classes.info" <<'EOF'
import sys
path = sys.argv[1]
lines = open(path, encoding='utf-8').read().splitlines()
have = set(lines)
extra = [f'class {kind}_{n}' for kind in ('JsonParser', 'JsonWriter') for n in range(1024) if f'class {kind}_{n}' not in have]
open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines + extra) + '\n')
EOF
bash scripts/cppia/build_cppia.sh --sdk "$SDK" --target android "$ROOT" bundled-mods/hex/cppia-src "$CPPIA"
echo "::endgroup::"

echo "::group::Stage bundled mods"
STAMP="$(git rev-parse --short HEAD 2>/dev/null || echo dev)-$(date -u +%Y%m%d%H%M%S)"
ASTCENC="$HAXELIB_PATH/astc-compressor/git/plugins/Linux/x64/astcenc-sse2"
chmod +x "$ASTCENC"
MODS=()
for dir in bundled-mods/*/; do
	[ -f "$dir/_polymod_meta.json" ] && MODS+=("${dir%/}")
done
python3 scripts/mobile/stage_mods.py "$STAGED" "${MODS[@]}" \
	--astcenc "$ASTCENC" --stamp "$STAMP" \
	--add "hex/ui/scripts/menus/HexMenus.cppia=$CPPIA"
rm -rf "$APK_ASSETS/bundled_mods"
mkdir -p "$APK_ASSETS"
cp -r "$STAGED" "$APK_ASSETS/bundled_mods"
echo "::endgroup::"

echo "::group::Build game (pass 2, packs the mods)"
haxelib run lime build android -release "${DEFINES[@]}"
echo "::endgroup::"

APK="$(find "$BUILD_DIR/bin/app/build/outputs/apk" -name '*.apk' | head -n 1)"
if [ -z "$APK" ]; then
	echo "No APK was produced." >&2
	exit 1
fi
mkdir -p "$ROOT/export/out"
cp "$APK" "$ROOT/export/out/VS-Hex-V3.apk"
ls -lh "$ROOT/export/out/VS-Hex-V3.apk"
