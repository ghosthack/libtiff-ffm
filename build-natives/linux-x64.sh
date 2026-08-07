#!/bin/sh
# Build libtiff with static zlib and libjpeg-turbo support, then stage one
# self-contained Linux x86-64 shared library.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TIFF_VERSION=4.7.2
ZLIB_VERSION=1.3.1
JPEG_VERSION=3.2.0
SRC="${1:-$ROOT/build/tiff-$TIFF_VERSION}"
PREFIX="$ROOT/build/prefix-linux-x64"
ZLIB_SRC="$ROOT/build/zlib-$ZLIB_VERSION"
JPEG_SRC="$ROOT/build/libjpeg-turbo-$JPEG_VERSION"
ZLIB_PREFIX="$ROOT/build/prefix-zlib-linux-x64"
JPEG_PREFIX="$ROOT/build/prefix-jpeg-linux-x64"
DEST="$ROOT/natives/src/main/resources/libtiff-natives/linux-x64"

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

cmake -S "$ZLIB_SRC" -B "$ZLIB_SRC/build-linux-x64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$ZLIB_PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=OFF -DZLIB_BUILD_EXAMPLES=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON
ninja -C "$ZLIB_SRC/build-linux-x64" install
cmake -S "$JPEG_SRC" -B "$JPEG_SRC/build-linux-x64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$JPEG_PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib -DENABLE_SHARED=0 -DENABLE_STATIC=1 \
  -DWITH_TURBOJPEG=0 -DWITH_TOOLS=0 -DWITH_TESTS=0 -DCMAKE_POSITION_INDEPENDENT_CODE=ON
ninja -C "$JPEG_SRC/build-linux-x64" install
cmake -S "$SRC" -B "$SRC/build-linux-x64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_PREFIX_PATH="$ZLIB_PREFIX;$JPEG_PREFIX" \
  -DZLIB_ROOT="$ZLIB_PREFIX" -DZLIB_LIBRARY="$ZLIB_PREFIX/lib/libz.a" \
  -DZLIB_LIBRARY_RELEASE="$ZLIB_PREFIX/lib/libz.a" \
  -DZLIB_INCLUDE_DIR="$ZLIB_PREFIX/include" -DJPEG_ROOT="$JPEG_PREFIX" \
  -Dtiff-tools=OFF -Dtiff-tests=OFF -Dtiff-contrib=OFF -Dtiff-docs=OFF -Dtiff-cxx=OFF \
  -Dzlib=ON -Djpeg=ON -Dlzma=OFF -Dzstd=OFF -Dwebp=OFF -Djbig=OFF -Dlerc=OFF -Dlibdeflate=OFF -Dopengl=OFF
ninja -C "$SRC/build-linux-x64" install

rm -rf "$DEST"
mkdir -p "$DEST"
so="$(readlink -f "$PREFIX/lib/libtiff.so")"
base="$(patchelf --print-soname "$so")"
cp "$so" "$DEST/$base"
chmod 644 "$DEST/$base"
patchelf --set-rpath '$ORIGIN' "$DEST/$base"
printf '%s\n' "$base" > "$DEST/manifest.txt"

if readelf -d "$DEST/$base" | awk '/NEEDED/ {print $NF}' | tr -d '[]' \
    | grep -vE '^(libc|libm|libpthread|libdl|librt)\.so|^ld-linux'; then
  echo "ERROR: $base links non-glibc libraries (above)"; exit 1
fi

cp "$SRC/LICENSE.md" "$DEST/LICENSE.libtiff.md"
cp "$ZLIB_SRC/LICENSE" "$DEST/LICENSE.zlib"
cp "$JPEG_SRC/LICENSE.md" "$DEST/LICENSE.libjpeg-turbo.md"
{
  echo "libtiff $TIFF_VERSION (linux-x64), built from unmodified source"
  echo "source: https://download.osgeo.org/libtiff/tiff-$TIFF_VERSION.tar.xz"
  echo "statically linked: zlib $ZLIB_VERSION and libjpeg-turbo $JPEG_VERSION"
  echo "features: JPEG, Deflate, LZW, PackBits, CCITT, LogLuv; tools/C++ disabled"
} > "$DEST/BUILD-INFO.txt"

echo "Staged $(ls "$DEST" | wc -l | tr -d ' ') files into $DEST"
