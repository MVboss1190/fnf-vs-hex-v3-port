#!/usr/bin/env bash
# Builds the VS Hex Android APK.
#
# Needs: Haxe 4.3.7, the libraries from hmm.json in ./.haxelib (scripts/mobile/install_haxelibs.py),
# Lime configured for Android (ANDROID_SDK, ANDROID_NDK_ROOT, JAVA_HOME), and the submodules checked out.
#
# Steps:
#   1. Build the game for Android (Hex's cppia-src is compiled into it).
#   2. Stage every mod in bundled-mods/ (ASTC textures, like Hex's build-mobile.ps1) into the APK assets.
#   3. Run the Android build again so Gradle packs the staged mods into the APK.
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
haxelib run lime build android -release "${DEFINES[@]}"
echo "::endgroup::"

# Hex's compiled-script classes (cppia-src) and the modchart-engine stand-ins (mobile/compat-src) are
# built into the game itself (see project.hxp and funkin.modding.HexClasses), so no .cppia is shipped.
# The Eye2Eye 3D scene script needs Kade's unreleased modchart engine, leave it out.
STAGE_EXTRA=(--exclude "hex/gameplay/songs/eye2eye/eye2eye-scene.hxc")

echo "::group::Stage bundled mods"
STAMP="$(git rev-parse --short HEAD 2>/dev/null || echo dev)-$(date -u +%Y%m%d%H%M%S)"
ASTCENC="$HAXELIB_PATH/astc-compressor/git/plugins/Linux/x64/astcenc-sse2"
chmod +x "$ASTCENC"
MODS=()
for dir in bundled-mods/*/; do
	[ -f "$dir/_polymod_meta.json" ] && MODS+=("${dir%/}")
done
python3 scripts/mobile/stage_mods.py "$STAGED" "${MODS[@]}" \
	--astcenc "$ASTCENC" --stamp "$STAMP" "${STAGE_EXTRA[@]}"
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
