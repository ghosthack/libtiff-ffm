# Third-party notices

## libtiff

The `libtiff-ffm-natives` classifier jars contain a shared library built from
unmodified libtiff source. libtiff uses the permissive Sam Leffler / Silicon
Graphics license. Its complete `LICENSE.md` is included in every classifier
jar. The exact version, enabled features, and source URL are recorded in
`BUILD-INFO.txt`.

## zlib

libtiff statically links zlib 1.3.1 for Deflate and PixarLog support. zlib is
covered by the zlib license; its `LICENSE` file is included in each classifier
jar.

## libjpeg-turbo

libtiff statically links the classic libjpeg API from libjpeg-turbo 3.2.0 for
JPEG and old-JPEG support. libjpeg-turbo combines the IJG, Modified BSD, and
zlib licenses; its `LICENSE.md` is included in each classifier jar.

The native is dynamically loaded and user-replaceable. Set
`LIBTIFF_FFM_LIBDIR` or `-Dlibtiffffm.libdir` to use a compatible host build.
The Java binding code contains no upstream source and is MIT licensed.
