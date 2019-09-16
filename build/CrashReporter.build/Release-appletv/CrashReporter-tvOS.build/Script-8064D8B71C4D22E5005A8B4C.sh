#!/bin/sh
FRAMEWORK="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework"

lipo \
	"${BUILD_DIR}/${CONFIGURATION}-appletvos/libCrashReporter-AppleTVOS.a" \
	"${BUILD_DIR}/${CONFIGURATION}-appletvsimulator/libCrashReporter-AppleTVSimulator.a" \
	-create -output "${FRAMEWORK}/Versions/Current/${PRODUCT_NAME}"

# Strip debugging symbols
#strip -S "${FRAMEWORK}/Versions/Current/${PRODUCT_NAME}"

cd "${FRAMEWORK}" && ln -sf "Versions/Current/${PRODUCT_NAME}" ./
