#!/bin/bash
set -e

LIBEXIF_DIR="$(cd "$(dirname "$0")" && pwd)"
MIN_IOS="15.0"
MIN_MACOS="12.0"

IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
SIM_SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
MAC_SDK=$(xcrun --sdk macosx --show-sdk-path)

CLANG=$(xcrun --find clang)

echo "Xcode clang : $CLANG"
echo "iOS SDK     : $IOS_SDK"
echo "Sim SDK     : $SIM_SDK"
echo "Mac SDK     : $MAC_SDK"

COMMON_CONFIGURE="
  --disable-shared
  --enable-static
  --disable-nls
  --disable-dependency-tracking
"

cd "$LIBEXIF_DIR"
autoreconf -fiv

# ── iOS Device (arm64) ──────────────────────────────────────
echo ""
echo ">>> Building iOS device (arm64)..."
make distclean 2>/dev/null || true

./configure \
  --host=arm-apple-darwin \
  --prefix="$LIBEXIF_DIR/build/iphoneos" \
  CC="$CLANG" \
  CFLAGS="-target arm64-apple-ios$MIN_IOS -isysroot $IOS_SDK -O2" \
  LDFLAGS="-target arm64-apple-ios$MIN_IOS -isysroot $IOS_SDK" \
  PKG_CONFIG_PATH="" \
  $COMMON_CONFIGURE

make -j$(sysctl -n hw.logicalcpu)
make install

# ── iOS Simulator arm64 ─────────────────────────────────────
echo ""
echo ">>> Building iOS Simulator (arm64)..."
make distclean 2>/dev/null || true

./configure \
  --host=arm-apple-darwin \
  --prefix="$LIBEXIF_DIR/build/iphonesimulator-arm64" \
  CC="$CLANG" \
  CFLAGS="-target arm64-apple-ios$MIN_IOS-simulator -isysroot $SIM_SDK -O2" \
  LDFLAGS="-target arm64-apple-ios$MIN_IOS-simulator -isysroot $SIM_SDK" \
  PKG_CONFIG_PATH="" \
  $COMMON_CONFIGURE

make -j$(sysctl -n hw.logicalcpu)
make install

# ── iOS Simulator x86_64 ────────────────────────────────────
echo ""
echo ">>> Building iOS Simulator (x86_64)..."
make distclean 2>/dev/null || true

./configure \
  --host=x86_64-apple-darwin \
  --prefix="$LIBEXIF_DIR/build/iphonesimulator-x86_64" \
  CC="$CLANG" \
  CFLAGS="-target x86_64-apple-ios$MIN_IOS-simulator -isysroot $SIM_SDK -O2" \
  LDFLAGS="-target x86_64-apple-ios$MIN_IOS-simulator -isysroot $SIM_SDK" \
  PKG_CONFIG_PATH="" \
  $COMMON_CONFIGURE

make -j$(sysctl -n hw.logicalcpu)
make install

# ── macOS arm64 ─────────────────────────────────────────────
echo ""
echo ">>> Building macOS (arm64)..."
make distclean 2>/dev/null || true

./configure \
  --host=arm-apple-darwin \
  --prefix="$LIBEXIF_DIR/build/macos-arm64" \
  CC="$CLANG" \
  CFLAGS="-target arm64-apple-macos$MIN_MACOS -isysroot $MAC_SDK -O2" \
  LDFLAGS="-target arm64-apple-macos$MIN_MACOS -isysroot $MAC_SDK" \
  PKG_CONFIG_PATH="" \
  $COMMON_CONFIGURE

make -j$(sysctl -n hw.logicalcpu)
make install

# ── macOS x86_64 ────────────────────────────────────────────
echo ""
echo ">>> Building macOS (x86_64)..."
make distclean 2>/dev/null || true

./configure \
  --host=x86_64-apple-darwin \
  --prefix="$LIBEXIF_DIR/build/macos-x86_64" \
  CC="$CLANG" \
  CFLAGS="-target x86_64-apple-macos$MIN_MACOS -isysroot $MAC_SDK -O2" \
  LDFLAGS="-target x86_64-apple-macos$MIN_MACOS -isysroot $MAC_SDK" \
  PKG_CONFIG_PATH="" \
  $COMMON_CONFIGURE

make -j$(sysctl -n hw.logicalcpu)
make install

# ── 合并 macOS universal ────────────────────────────────────
echo ""
echo ">>> Merging macOS universal binary..."
mkdir -p build/macos-universal/lib
cp -r build/macos-arm64/include build/macos-universal/
lipo -create \
  build/macos-arm64/lib/libexif.a \
  build/macos-x86_64/lib/libexif.a \
  -output build/macos-universal/lib/libexif.a

# ── 合并 Simulator fat binary ───────────────────────────────
echo ""
echo ">>> Merging simulator fat binary..."
mkdir -p build/iphonesimulator/lib
cp -r build/iphonesimulator-arm64/include build/iphonesimulator/
lipo -create \
  build/iphonesimulator-arm64/lib/libexif.a \
  build/iphonesimulator-x86_64/lib/libexif.a \
  -output build/iphonesimulator/lib/libexif.a

# ── 打包 XCFramework ────────────────────────────────────────
echo ""
echo ">>> Creating LibExif.xcframework..."
rm -rf "$LIBEXIF_DIR/LibExif.xcframework"

xcodebuild -create-xcframework \
  -library build/iphoneos/lib/libexif.a \
  -headers build/iphoneos/include \
  -library build/iphonesimulator/lib/libexif.a \
  -headers build/iphonesimulator/include \
  -library build/macos-universal/lib/libexif.a \
  -headers build/macos-universal/include \
  -output "$LIBEXIF_DIR/LibExif.xcframework"

echo ""
echo "✅ Done: LibExif.xcframework"
echo ""
lipo -info "$LIBEXIF_DIR/LibExif.xcframework/ios-arm64/libexif.a" 2>/dev/null || \
lipo -info "$(find "$LIBEXIF_DIR/LibExif.xcframework" -name "*.a" | head -3)"
