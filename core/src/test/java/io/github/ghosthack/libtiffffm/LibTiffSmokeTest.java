package io.github.ghosthack.libtiffffm;

import io.github.ghosthack.libtiffffm.libtiff.LibTiff;
import org.junit.jupiter.api.Test;

import java.lang.foreign.Arena;
import java.lang.foreign.MemorySegment;
import java.lang.foreign.ValueLayout;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** End-to-end proof that the bundled library can write and read Deflate TIFF. */
class LibTiffSmokeTest {
    private static final int WIDTH = 16;
    private static final int HEIGHT = 12;

    @Test
    void reportsExpectedVersionAndCodecs() {
        String version = LibTiff.TIFFGetVersion().getString(0);
        assertTrue(version.contains("Version 4.7.2"), version);
        assertNotEquals(0, LibTiff.TIFFIsCODECConfigured((short) LibTiff.COMPRESSION_LZW()));
        assertNotEquals(0, LibTiff.TIFFIsCODECConfigured((short) LibTiff.COMPRESSION_ADOBE_DEFLATE()));
        assertNotEquals(0, LibTiff.TIFFIsCODECConfigured((short) LibTiff.COMPRESSION_JPEG()));
    }

    @Test
    void writesAndReadsDeflateRgbImage() throws Exception {
        Path file = Files.createTempFile("libtiff-ffm-", ".tif");
        try (Arena arena = Arena.ofConfined()) {
            MemorySegment path = arena.allocateFrom(file.toString());
            MemorySegment writeMode = arena.allocateFrom("w");
            MemorySegment tif = LibTiff.TIFFOpen(path, writeMode);
            assertNotEquals(MemorySegment.NULL, tif, "TIFFOpen for writing");

            var setInt = LibTiff.TIFFSetField.makeInvoker(LibTiff.C_INT);
            try {
                set(setInt, tif, LibTiff.TIFFTAG_IMAGEWIDTH(), WIDTH);
                set(setInt, tif, LibTiff.TIFFTAG_IMAGELENGTH(), HEIGHT);
                set(setInt, tif, LibTiff.TIFFTAG_SAMPLESPERPIXEL(), 3);
                set(setInt, tif, LibTiff.TIFFTAG_BITSPERSAMPLE(), 8);
                set(setInt, tif, LibTiff.TIFFTAG_ORIENTATION(), LibTiff.ORIENTATION_TOPLEFT());
                set(setInt, tif, LibTiff.TIFFTAG_PLANARCONFIG(), LibTiff.PLANARCONFIG_CONTIG());
                set(setInt, tif, LibTiff.TIFFTAG_PHOTOMETRIC(), LibTiff.PHOTOMETRIC_RGB());
                set(setInt, tif, LibTiff.TIFFTAG_COMPRESSION(), LibTiff.COMPRESSION_ADOBE_DEFLATE());
                set(setInt, tif, LibTiff.TIFFTAG_ROWSPERSTRIP(), HEIGHT);

                MemorySegment row = arena.allocate(WIDTH * 3L);
                for (int y = 0; y < HEIGHT; y++) {
                    for (int x = 0; x < WIDTH; x++) {
                        long offset = x * 3L;
                        row.set(ValueLayout.JAVA_BYTE, offset, (byte) (x * 11));
                        row.set(ValueLayout.JAVA_BYTE, offset + 1, (byte) (y * 13));
                        row.set(ValueLayout.JAVA_BYTE, offset + 2, (byte) 0x5a);
                    }
                    assertEquals(1, LibTiff.TIFFWriteScanline(tif, row, y, (short) 0), "row " + y);
                }
            } finally {
                LibTiff.TIFFClose(tif);
            }

            MemorySegment readMode = arena.allocateFrom("r");
            tif = LibTiff.TIFFOpen(path, readMode);
            assertNotEquals(MemorySegment.NULL, tif, "TIFFOpen for reading");
            try {
                var getPointer = LibTiff.TIFFGetField.makeInvoker(LibTiff.C_POINTER);
                MemorySegment width = arena.allocate(ValueLayout.JAVA_INT);
                MemorySegment height = arena.allocate(ValueLayout.JAVA_INT);
                assertEquals(1, getPointer.apply(tif, LibTiff.TIFFTAG_IMAGEWIDTH(), width));
                assertEquals(1, getPointer.apply(tif, LibTiff.TIFFTAG_IMAGELENGTH(), height));
                assertEquals(WIDTH, width.get(ValueLayout.JAVA_INT, 0));
                assertEquals(HEIGHT, height.get(ValueLayout.JAVA_INT, 0));

                MemorySegment raster = arena.allocate((long) WIDTH * HEIGHT * Integer.BYTES);
                assertEquals(1, LibTiff.TIFFReadRGBAImageOriented(tif, WIDTH, HEIGHT, raster,
                        LibTiff.ORIENTATION_TOPLEFT(), 1));

                int x = 7;
                int y = 5;
                int abgr = raster.getAtIndex(ValueLayout.JAVA_INT, y * WIDTH + x);
                assertEquals(x * 11, abgr & 0xff, "red");
                assertEquals(y * 13, abgr >>> 8 & 0xff, "green");
                assertEquals(0x5a, abgr >>> 16 & 0xff, "blue");
                assertEquals(0xff, abgr >>> 24, "alpha");
            } finally {
                LibTiff.TIFFClose(tif);
            }
        } finally {
            Files.deleteIfExists(file);
        }
    }

    private static void set(LibTiff.TIFFSetField invoker, MemorySegment tif, int tag, int value) {
        assertEquals(1, invoker.apply(tif, tag, value), "TIFFSetField tag " + tag);
    }
}
