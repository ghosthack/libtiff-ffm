# libtiff-ffm

Panama FFM (jextract) bindings for **libtiff 4.7.2** with bundled,
from-source natives. One Maven coordinate, no JNI and no user-installed
libtiff.

| Artifact | Contents | License |
|---|---|---|
| `io.github.ghosthack:libtiff-ffm` | generated FFM stubs + runtime loader (JDK 22+) | MIT |
| `io.github.ghosthack:libtiff-ffm-natives` | one native classifier jar per platform | libtiff/zlib/libjpeg-turbo licenses |

The native is a single shared library. zlib 1.3.1 and libjpeg-turbo 3.2.0
are statically linked, so JPEG and Deflate work without extra shared-library
dependencies. LZW, PackBits, CCITT, ThunderScan, NeXT, and LogLuv support are
built into libtiff itself.

## Use

```xml
<dependency>
  <groupId>io.github.ghosthack</groupId>
  <artifactId>libtiff-ffm</artifactId>
  <version>4.7.2-0.1.0</version>
</dependency>
<dependency>
  <groupId>io.github.ghosthack</groupId>
  <artifactId>libtiff-ffm-natives</artifactId>
  <version>4.7.2-0.1.0</version>
  <classifier>macos-arm64</classifier> <!-- windows-x64 / linux-x64 -->
  <scope>runtime</scope>
</dependency>
```

When using the module path, declare `requires libtiff.ffm;` and run with
`--enable-native-access=libtiff.ffm`. On the class path, use
`--enable-native-access=ALL-UNNAMED`.

```java
import io.github.ghosthack.libtiffffm.libtiff.LibTiff;

try (Arena arena = Arena.ofConfined()) {
    MemorySegment tif = LibTiff.TIFFOpen(
            arena.allocateFrom("image.tif"), arena.allocateFrom("r"));
    if (tif == MemorySegment.NULL) throw new IOException("TIFFOpen failed");
    try {
        MemorySegment width = arena.allocate(ValueLayout.JAVA_INT);
        var getPointer = LibTiff.TIFFGetField.makeInvoker(LibTiff.C_POINTER);
        if (getPointer.apply(tif, LibTiff.TIFFTAG_IMAGEWIDTH(), width) != 1) {
            throw new IOException("missing image width");
        }
        System.out.println(width.get(ValueLayout.JAVA_INT, 0));
    } finally {
        LibTiff.TIFFClose(tif);
    }
}
```

`TIFFGetField` and `TIFFSetField` are C variadic functions. jextract exposes
each as an invoker factory specialized with the layouts of the arguments after
the tag. Output values use `LibTiff.C_POINTER`; integer values passed to
`TIFFSetField` use `LibTiff.C_INT` because C promotes smaller integers in a
variadic call; float values use `LibTiff.C_DOUBLE`. See
`LibTiffSmokeTest.java` for a complete Deflate write/read example.

The curated low-level surface includes:

- file and callback-based client I/O;
- tag get/set and field metadata;
- scanline, strip, tile, and RGBA reading/writing;
- multi-directory TIFF and BigTIFF navigation;
- codec discovery and open-time memory/error options;
- byte-swapping and libtiff allocation helpers.

## Native resolution

`LibTiffLibs.lookup()` resolves in this order:

1. `-Dlibtiffffm.libdir=<dir>` or `LIBTIFF_FFM_LIBDIR`;
2. the matching natives jar, extracted once under
   `~/.cache/libtiff-ffm/<version>-<platform>/`;
3. libraries already loaded by the application and platform-default symbols.

Supported classifiers are `macos-arm64`, `windows-x64`, and `linux-x64`.

## Build

```sh
mkdir -p build
curl -sfL https://download.osgeo.org/libtiff/tiff-4.7.2.tar.xz | tar xJ -C build
build-natives/macos-arm64.sh
jextract/gen-bindings.sh
mvn clean install
```

The native scripts fetch zlib and libjpeg-turbo themselves. Run the Windows
script in an MSYS2 MINGW64 shell. Stub generation is done once on macOS using
jextract 22; set `JEXTRACT` to override the default sibling
`../ffmpeg-ffm/tools/jextract-22/bin/jextract` path.

Binding code is MIT. Native classifier jars carry the upstream license texts;
see [THIRD-PARTY.md](THIRD-PARTY.md).
