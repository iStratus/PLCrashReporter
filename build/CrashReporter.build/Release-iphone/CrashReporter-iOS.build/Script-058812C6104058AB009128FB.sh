#!/bin/sh
FRAMEWORK="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework"

lipo \
"${BUILD_DIR}/${CONFIGURATION}-iphoneos/libCrashReporter-iPhoneOS.a" \
"${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/libCrashReporter-iPhoneSimulator.a" \
-create -output "${FRAMEWORK}/Versions/Current/${PRODUCT_NAME}"

# Strip debugging symbols
#strip -S "${FRAMEWORK}/Versions/Current/${PRODUCT_NAME}"

# Create a Bitcode backward compatible binary with older Xcode versions but still support architectures from newer Xcode versions
if [ -z "$PL_ARM64E_XCODE_PATH" ]; then
echo "Path to Xcode version supporting arm64e not provided; Bitcode compatibility and device architectures are limited to the running Xcode version."
else
LIB_IPHONEOS_TEMP="${BUILD_DIR}/${CONFIGURATION}-iphoneos/libCrashReporter-iPhoneOS.a"
LIB_IPHONEOS_FINAL="${FRAMEWORK}/Versions/Current/${PRODUCT_NAME}"

# Build with the Xcode version supporting arm64e
env DEVELOPER_DIR="$PL_ARM64E_XCODE_PATH" /usr/bin/xcodebuild ARCHS="arm64e" -configuration Release -target 'CrashReporter-iOS-Device'

# Concatenate the architectures built from Xcode versions 
env DEVELOPER_DIR="$PL_ARM64E_XCODE_PATH" /usr/bin/lipo ${LIB_IPHONEOS_FINAL} ${LIB_IPHONEOS_TEMP} -create -output ${LIB_IPHONEOS_FINAL}
fi

cd "${FRAMEWORK}" && ln -sf "Versions/Current/${PRODUCT_NAME}" ./

