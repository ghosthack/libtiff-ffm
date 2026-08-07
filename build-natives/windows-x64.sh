#!/bin/sh
# Build libtiff with static zlib and libjpeg-turbo support and stage its DLL.
# Run from an MSYS2 MINGW64 shell with cmake, ninja, gcc, nasm, and objdump.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TIFF_VERSION=4.7.2
ZLIB_VERSION=1.3.1
JPEG_VERSION=3.2.0
SRC="${1:-$ROOT/build/tiff-$TIFF_VERSION}"
PREFIX="$ROOT/build/prefix-windows-x64"
ZLIB_SRC="$ROOT/build/zlib-$ZLIB_VERSION"
JPEG_SRC="$ROOT/build/libjpeg-turbo-$JPEG_VERSION"
ZLIB_PREFIX="$ROOT/build/prefix-zlib-windows-x64"
JPEG_PREFIX="$ROOT/build/prefix-jpeg-windows-x64"
DEST="$ROOT/natives/src/main/resources/libtiff-natives/windows-x64"

download_tar_gz() {
  download_url=$1
  download_archive=$2
  download_attempt=1
  while [ "$download_attempt" -le 5 ]; do
    rm -f "$download_archive"
    if curl --retry 5 --retry-delay 2 --retry-all-errors -sfL \
        "$download_url" -o "$download_archive" \
        && tar tzf "$download_archive" >/dev/null 2>&1; then
      tar xzf "$download_archive" -C "$ROOT/build"
      rm -f "$download_archive"
      return 0
    fi
    echo "download attempt $download_attempt failed for $download_url" >&2
    download_attempt=$((download_attempt + 1))
    sleep 2
  done
  echo "ERROR: could not download a valid archive from $download_url" >&2
  return 1
}

mkdir -p "$ROOT/build"
if [ ! -d "$ZLIB_SRC" ]; then
  download_tar_gz "https://github.com/madler/zlib/archive/refs/tags/v$ZLIB_VERSION.tar.gz" \
    "$ROOT/build/.zlib-$ZLIB_VERSION.tar.gz"
fi
if [ ! -d "$JPEG_SRC" ]; then
  download_tar_gz "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/$JPEG_VERSION/libjpeg-turbo-$JPEG_VERSION.tar.gz" \
    "$ROOT/build/.libjpeg-turbo-$JPEG_VERSION.tar.gz"
fi

cmake -S "$ZLIB_SRC" -B "$ZLIB_SRC/build-windows-x64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$ZLIB_PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=OFF -DZLIB_BUILD_EXAMPLES=OFF
ninja -C "$ZLIB_SRC/build-windows-x64" install
cmake -S "$JPEG_SRC" -B "$JPEG_SRC/build-windows-x64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$JPEG_PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib -DENABLE_SHARED=0 -DENABLE_STATIC=1 \
  -DWITH_TURBOJPEG=0 -DWITH_TOOLS=0 -DWITH_TESTS=0
ninja -C "$JPEG_SRC/build-windows-x64" install
cmake -S "$SRC" -B "$SRC/build-windows-x64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_PREFIX_PATH="$ZLIB_PREFIX;$JPEG_PREFIX" \
  -DZLIB_ROOT="$ZLIB_PREFIX" -DZLIB_LIBRARY="$ZLIB_PREFIX/lib/libzlibstatic.a" \
  -DZLIB_LIBRARY_RELEASE="$ZLIB_PREFIX/lib/libzlibstatic.a" \
  -DZLIB_INCLUDE_DIR="$ZLIB_PREFIX/include" -DJPEG_ROOT="$JPEG_PREFIX" \
  -Dtiff-tools=OFF -Dtiff-tests=OFF -Dtiff-contrib=OFF -Dtiff-docs=OFF -Dtiff-cxx=OFF \
  -Dzlib=ON -Djpeg=ON -Dlzma=OFF -Dzstd=OFF -Dwebp=OFF -Djbig=OFF -Dlerc=OFF -Dlibdeflate=OFF -Dopengl=OFF
ninja -C "$SRC/build-windows-x64" install

rm -rf "$DEST"
mkdir -p "$DEST"
dll="$(find "$PREFIX/bin" -maxdepth 1 -iname '*tiff*.dll' | head -1)"
[ -n "$dll" ] || { echo "ERROR: installed libtiff DLL not found"; exit 1; }

: > "$DEST/manifest.txt"
for runtime in libwinpthread-1.dll libgcc_s_seh-1.dll; do
  if [ -f "/mingw64/bin/$runtime" ] && objdump -p "$dll" | grep -qi "DLL Name: $runtime"; then
    cp "/mingw64/bin/$runtime" "$DEST/$runtime"
    echo "$runtime" >> "$DEST/manifest.txt"
  fi
done
base="$(basename "$dll")"
cp "$dll" "$DEST/$base"
echo "$base" >> "$DEST/manifest.txt"

ALLOWED='tiff|libwinpthread|libgcc_s_seh|KERNEL32|USER32|ADVAPI32|msvcrt|ntdll|api-ms-|ucrtbase'
for file in "$DEST"/*.dll; do
  if objdump -p "$file" | awk '/DLL Name:/{print $3}' | grep -viE "^($ALLOWED)"; then
    echo "ERROR: $file imports unexpected DLLs (above)"; exit 1
  fi
done

cp "$SRC/LICENSE.md" "$DEST/LICENSE.libtiff.md"
cp "$ZLIB_SRC/LICENSE" "$DEST/LICENSE.zlib"
cp "$JPEG_SRC/LICENSE.md" "$DEST/LICENSE.libjpeg-turbo.md"
{
  echo "libtiff $TIFF_VERSION (windows-x64), built from unmodified source with MSYS2 mingw-w64"
  echo "source: https://download.osgeo.org/libtiff/tiff-$TIFF_VERSION.tar.xz"
  echo "statically linked: zlib $ZLIB_VERSION and libjpeg-turbo $JPEG_VERSION"
  echo "features: JPEG, Deflate, LZW, PackBits, CCITT, LogLuv; tools/C++ disabled"
} > "$DEST/BUILD-INFO.txt"

echo "Staged $(ls "$DEST" | wc -l | tr -d ' ') files into $DEST"
