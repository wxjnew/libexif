# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

libexif is a C library (LGPL-2.0-or-later) for parsing, editing, and saving EXIF data embedded in JPEG files. It supports EXIF standard 2.1/2.2 tags and manufacturer-specific MakerNote data for Canon, Fuji, Olympus, Pentax, Apple, and others.

## Build Commands

```sh
# First time from git checkout
autoreconf -i
./configure
make

# Run all tests
make check

# Install
sudo make install

# Configure options
./configure --disable-docs          # Skip documentation generation
./configure --enable-internal-docs  # Build internal API docs (requires Doxygen)

# Size-optimization build flags (for embedded/specialized use)
CPPFLAGS="-DNO_VERBOSE_TAG_STRINGS" ./configure   # Remove tag names/descriptions
CPPFLAGS="-DNO_VERBOSE_TAG_DATA" ./configure      # Remove enumerated tag data names
```

## Running Tests

```sh
# Run all tests
make check

# Run a specific test binary directly (after building)
./test/test-parse
./test/test-fuzzer

# Run a specific shell test script
cd test && sh parse-regression.sh
```

## Architecture

### Core Data Hierarchy

EXIF data is organized in a tree:
- **`ExifLoader`** (`exif-loader.h`) — State machine for reading EXIF from files or memory buffers
- **`ExifData`** (`exif-data.h`) — Root container; holds one `ExifContent` per IFD (Image File Directory)
- **`ExifContent`** (`exif-content.h`) — Represents a single IFD; contains an array of `ExifEntry`
- **`ExifEntry`** (`exif-entry.h`) — A single EXIF tag with its data
- **`ExifMnoteData`** (`exif-mnote-data.h`) — Abstract interface for manufacturer MakerNote data

### Memory Management

libexif uses reference counting: `foo_new()` to allocate, `foo_ref()` to increment, `foo_unref()` to decrement (and free when count reaches zero). Custom allocators are supported via `ExifMem` (`exif-mem.h`).

### MakerNote Subdirectories

Manufacturer-specific MakerNote implementations live in `libexif/<vendor>/`:
- `libexif/canon/` — Canon MakerNote
- `libexif/fuji/` — Fuji MakerNote
- `libexif/olympus/` — Olympus MakerNote
- `libexif/pentax/` — Pentax MakerNote
- `libexif/apple/` — Apple MakerNote

Each vendor directory contains: `exif-mnote-data-<vendor>.{c,h}`, `mnote-<vendor>-entry.{c,h}`, `mnote-<vendor>-tag.{c,h}`.

### Key Supporting Modules

- `exif-byte-order.{c,h}` — Big/little endian handling
- `exif-format.{c,h}` — EXIF data type formats (BYTE, ASCII, SHORT, LONG, etc.)
- `exif-ifd.{c,h}` — IFD index enumeration (IFD0, IFD1, Exif, GPS, Interoperability)
- `exif-tag.{c,h}` — Tag definitions and lookup
- `exif-log.{c,h}` — Logging interface with pluggable callback
- `exif-utils.{c,h}` — Low-level get/set for typed values in byte buffers

### Build System

Autotools-based: `configure.ac` + `Makefile.am` files throughout. The library version is managed via libtool versioning in `configure.ac`. Translations are in `po/`.

## Security Considerations

All data parsed by the library must be treated as untrusted/potentially malicious. The primary threat model is processing attacker-controlled JPEG files (e.g., via web upload). Memory corruption, infinite loops, and unintentional aborts are all in-scope security bugs. See `SECURITY.md` for reporting guidance.
