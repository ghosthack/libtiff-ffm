#!/bin/sh
# Generate the curated libtiff 4.7 FFM surface, then point its symbol lookup at
# the runtime extractor/loader. Run on macOS after macos-arm64.sh.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JX="${JEXTRACT:-$ROOT/../ffmpeg-ffm/tools/jextract-22/bin/jextract}"
PREFIX="${TIFF_PREFIX:-$ROOT/build/prefix-macos-arm64}"
OUT="$ROOT/core/src/main/java"
PKG="io.github.ghosthack.libtiffffm.libtiff"
SDK="$(xcrun --show-sdk-path)"
GEN_DIR="$OUT/$(printf '%s' "$PKG" | tr . /)"

[ -x "$JX" ] || { echo "jextract not found at $JX (set JEXTRACT=)"; exit 1; }
[ -d "$PREFIX/include" ] || { echo "run build-natives/macos-arm64.sh first (or set TIFF_PREFIX)"; exit 1; }

rm -rf "$GEN_DIR"

set -- \
  --include-function TIFFGetVersion \
  --include-function TIFFOpen \
  --include-function TIFFOpenExt \
  --include-function TIFFClose \
  --include-function TIFFCleanup \
  --include-function TIFFFlush \
  --include-function TIFFFlushData \
  --include-function TIFFGetField \
  --include-function TIFFGetFieldDefaulted \
  --include-function TIFFSetField \
  --include-function TIFFUnsetField \
  --include-function TIFFReadDirectory \
  --include-function TIFFLastDirectory \
  --include-function TIFFSetDirectory \
  --include-function TIFFSetSubDirectory \
  --include-function TIFFNumberOfDirectories \
  --include-function TIFFCurrentDirectory \
  --include-function TIFFCurrentDirOffset \
  --include-function TIFFCurrentRow \
  --include-function TIFFCurrentStrip \
  --include-function TIFFCurrentTile \
  --include-function TIFFWriteDirectory \
  --include-function TIFFCheckpointDirectory \
  --include-function TIFFRewriteDirectory \
  --include-function TIFFScanlineSize \
  --include-function TIFFScanlineSize64 \
  --include-function TIFFRasterScanlineSize \
  --include-function TIFFRasterScanlineSize64 \
  --include-function TIFFStripSize \
  --include-function TIFFStripSize64 \
  --include-function TIFFTileSize \
  --include-function TIFFTileSize64 \
  --include-function TIFFTileRowSize \
  --include-function TIFFTileRowSize64 \
  --include-function TIFFDefaultStripSize \
  --include-function TIFFDefaultTileSize \
  --include-function TIFFIsTiled \
  --include-function TIFFIsByteSwapped \
  --include-function TIFFIsBigEndian \
  --include-function TIFFIsBigTIFF \
  --include-function TIFFReadScanline \
  --include-function TIFFWriteScanline \
  --include-function TIFFReadRGBAImage \
  --include-function TIFFReadRGBAImageOriented \
  --include-function TIFFReadRGBAStrip \
  --include-function TIFFReadRGBATile \
  --include-function TIFFComputeStrip \
  --include-function TIFFNumberOfStrips \
  --include-function TIFFReadEncodedStrip \
  --include-function TIFFReadRawStrip \
  --include-function TIFFWriteEncodedStrip \
  --include-function TIFFWriteRawStrip \
  --include-function TIFFComputeTile \
  --include-function TIFFCheckTile \
  --include-function TIFFNumberOfTiles \
  --include-function TIFFReadTile \
  --include-function TIFFWriteTile \
  --include-function TIFFReadEncodedTile \
  --include-function TIFFReadRawTile \
  --include-function TIFFWriteEncodedTile \
  --include-function TIFFWriteRawTile \
  --include-function TIFFGetStrileOffset \
  --include-function TIFFGetStrileByteCount \
  --include-function TIFFFileName \
  --include-function TIFFSetFileName \
  --include-function TIFFGetTagListCount \
  --include-function TIFFGetTagListEntry \
  --include-function TIFFFieldWithTag \
  --include-function TIFFFieldWithName \
  --include-function TIFFFieldTag \
  --include-function TIFFFieldName \
  --include-function TIFFFieldDataType \
  --include-function TIFFFieldPassCount \
  --include-function TIFFFieldReadCount \
  --include-function TIFFFieldWriteCount \
  --include-function TIFFFindCODEC \
  --include-function TIFFIsCODECConfigured \
  --include-function TIFFGetConfiguredCODECs \
  --include-function TIFFOpenOptionsAlloc \
  --include-function TIFFOpenOptionsFree \
  --include-function TIFFOpenOptionsSetMaxSingleMemAlloc \
  --include-function TIFFOpenOptionsSetMaxCumulatedMemAlloc \
  --include-function TIFFOpenOptionsSetWarnAboutUnknownTags \
  --include-function TIFFOpenOptionsSetErrorHandlerExtR \
  --include-function TIFFOpenOptionsSetWarningHandlerExtR \
  --include-function TIFFClientOpen \
  --include-function TIFFClientOpenExt \
  --include-function TIFFSwabShort \
  --include-function TIFFSwabLong \
  --include-function TIFFSwabLong8 \
  --include-function TIFFSwabFloat \
  --include-function TIFFSwabDouble \
  --include-function TIFFSwabArrayOfShort \
  --include-function TIFFSwabArrayOfLong \
  --include-function TIFFSwabArrayOfLong8 \
  --include-function TIFFSwabArrayOfFloat \
  --include-function TIFFSwabArrayOfDouble \
  --include-function TIFFReverseBits \
  --include-function _TIFFmalloc \
  --include-function _TIFFcalloc \
  --include-function _TIFFrealloc \
  --include-function _TIFFfree \
  --include-typedef TIFFCodec \
  --include-typedef TIFFDataType \
  --include-typedef TIFFReadWriteProc \
  --include-typedef TIFFSeekProc \
  --include-typedef TIFFCloseProc \
  --include-typedef TIFFSizeProc \
  --include-typedef TIFFMapFileProc \
  --include-typedef TIFFUnmapFileProc \
  --include-typedef TIFFErrorHandlerExtR \
  --include-constant TIFF_VERSION_CLASSIC \
  --include-constant TIFF_VERSION_BIG \
  --include-constant TIFFTAG_SUBFILETYPE \
  --include-constant TIFFTAG_IMAGEWIDTH \
  --include-constant TIFFTAG_IMAGELENGTH \
  --include-constant TIFFTAG_BITSPERSAMPLE \
  --include-constant TIFFTAG_COMPRESSION \
  --include-constant TIFFTAG_PHOTOMETRIC \
  --include-constant TIFFTAG_FILLORDER \
  --include-constant TIFFTAG_DOCUMENTNAME \
  --include-constant TIFFTAG_IMAGEDESCRIPTION \
  --include-constant TIFFTAG_MAKE \
  --include-constant TIFFTAG_MODEL \
  --include-constant TIFFTAG_ORIENTATION \
  --include-constant TIFFTAG_SAMPLESPERPIXEL \
  --include-constant TIFFTAG_ROWSPERSTRIP \
  --include-constant TIFFTAG_XRESOLUTION \
  --include-constant TIFFTAG_YRESOLUTION \
  --include-constant TIFFTAG_PLANARCONFIG \
  --include-constant TIFFTAG_RESOLUTIONUNIT \
  --include-constant TIFFTAG_SOFTWARE \
  --include-constant TIFFTAG_DATETIME \
  --include-constant TIFFTAG_PREDICTOR \
  --include-constant TIFFTAG_COLORMAP \
  --include-constant TIFFTAG_TILEWIDTH \
  --include-constant TIFFTAG_TILELENGTH \
  --include-constant TIFFTAG_EXTRASAMPLES \
  --include-constant TIFFTAG_SAMPLEFORMAT \
  --include-constant TIFFTAG_ICCPROFILE \
  --include-constant COMPRESSION_NONE \
  --include-constant COMPRESSION_CCITTRLE \
  --include-constant COMPRESSION_CCITTFAX3 \
  --include-constant COMPRESSION_CCITTFAX4 \
  --include-constant COMPRESSION_LZW \
  --include-constant COMPRESSION_JPEG \
  --include-constant COMPRESSION_ADOBE_DEFLATE \
  --include-constant COMPRESSION_DEFLATE \
  --include-constant COMPRESSION_PACKBITS \
  --include-constant COMPRESSION_LZMA \
  --include-constant COMPRESSION_ZSTD \
  --include-constant COMPRESSION_WEBP \
  --include-constant PHOTOMETRIC_MINISWHITE \
  --include-constant PHOTOMETRIC_MINISBLACK \
  --include-constant PHOTOMETRIC_RGB \
  --include-constant PHOTOMETRIC_PALETTE \
  --include-constant PHOTOMETRIC_SEPARATED \
  --include-constant PHOTOMETRIC_YCBCR \
  --include-constant ORIENTATION_TOPLEFT \
  --include-constant ORIENTATION_TOPRIGHT \
  --include-constant ORIENTATION_BOTRIGHT \
  --include-constant ORIENTATION_BOTLEFT \
  --include-constant ORIENTATION_LEFTTOP \
  --include-constant ORIENTATION_RIGHTTOP \
  --include-constant ORIENTATION_RIGHTBOT \
  --include-constant ORIENTATION_LEFTBOT \
  --include-constant PLANARCONFIG_CONTIG \
  --include-constant PLANARCONFIG_SEPARATE \
  --include-constant FILLORDER_MSB2LSB \
  --include-constant FILLORDER_LSB2MSB \
  --include-constant RESUNIT_NONE \
  --include-constant RESUNIT_INCH \
  --include-constant RESUNIT_CENTIMETER \
  --include-constant EXTRASAMPLE_UNSPECIFIED \
  --include-constant EXTRASAMPLE_ASSOCALPHA \
  --include-constant EXTRASAMPLE_UNASSALPHA \
  --include-constant SAMPLEFORMAT_UINT \
  --include-constant SAMPLEFORMAT_INT \
  --include-constant SAMPLEFORMAT_IEEEFP \
  --include-constant SAMPLEFORMAT_VOID \
  --include-constant PREDICTOR_NONE \
  --include-constant PREDICTOR_HORIZONTAL \
  --include-constant PREDICTOR_FLOATINGPOINT

"$JX" --output "$OUT" -t "$PKG" \
  --header-class-name LibTiff \
  -I "$SDK/usr/include" \
  -I "$PREFIX/include" \
  -l ":$PREFIX/lib/libtiff.dylib" \
  "$@" \
  "$ROOT/jextract/libtiff_api.h"

perl -0777 -pi -e \
  's/static final SymbolLookup SYMBOL_LOOKUP = .*?;/static final SymbolLookup SYMBOL_LOOKUP = io.github.ghosthack.libtiffffm.LibTiffLibs.lookup();/s' \
  "$GEN_DIR/LibTiff.java"

# jextract 22 leaves an extra blank line at EOF; keep regenerated sources
# clean so `git diff --check` remains useful in reviews and CI.
find "$GEN_DIR" -type f -name '*.java' -exec perl -0777 -pi -e 's/\s+\z/\n/' {} \;

grep -q "LibTiffLibs.lookup()" "$GEN_DIR/LibTiff.java" || {
  echo "ERROR: runtime symbol-lookup patch did not apply"; exit 1;
}
if grep -rn "$PREFIX" "$GEN_DIR" >/dev/null; then
  echo "ERROR: generation-machine paths survived in generated sources"; exit 1;
fi

echo "Generated $(find "$GEN_DIR" -type f | wc -l | tr -d ' ') files in $GEN_DIR"
