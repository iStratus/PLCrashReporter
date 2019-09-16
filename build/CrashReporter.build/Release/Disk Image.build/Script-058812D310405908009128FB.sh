#!/bin/sh
# Attempt to verify that the code we're building matches the source archive we're generating
# We only check for local modifications; in theory, we could assert the existence of a (local, not yet pushed)
# release tag.
if [ "${PL_ALLOW_LOCAL_MODS}" != 1 ] && [ "${CONFIGURATION}" = "Release" ]; then
    if [ "$(git status --porcelain | grep -v '??' | wc -l | awk '{print $1}')" != "0" ]; then
        echo "" >/dev/stderr
        echo "=== RELEASE BUILD ERROR ===" >/dev/stderr
        echo "Local modifications are not permitted when generating a Release build." >/dev/stderr
        echo "Modifications:" >/dev/stderr
        git status --porcelain | grep -v '??' >/dev/stderr

        echo "" >/dev/stderr
        echo "Set the PL_ALLOW_LOCAL_MODS=1 to bypass this check, or use a non-release build configuration:" >/dev/stderr
        echo "  env PL_ALLOW_LOCAL_MODS=1 xcodebuild ..." >/dev/stderr
        echo "=== RELEASE BUILD ERROR ===" >/dev/stderr
        echo "" >/dev/stderr

        exit 1
    fi
fi

# Set up the destroot
OUTPUT_DEST="${BUILT_PRODUCTS_DIR}"
PRODUCT_DIR="${PRODUCT_NAME}-${CURRENT_PROJECT_VERSION}"
DESTROOT="${OUTPUT_DEST}/${PRODUCT_DIR}"

mkdir -p "${DESTROOT}"

# Per-target installation destinations
IPHONE_DEST="${DESTROOT}/iOS Framework"
APPLETV_DEST="${DESTROOT}/tvOS Framework"
MAC_DEST="${DESTROOT}/Mac OS X Framework"
TOOL_DEST="${DESTROOT}/Tools"
SRC_DEST="${DESTROOT}/Source"
LICENSE_DEST="${DESTROOT}/LICENSE.txt"

DOC_SUBDIR="Documentation"
DOC_DEST="${DESTROOT}/${DOC_SUBDIR}"

# Per-platform framework sources
MAC_SRC="${BUILD_DIR}/${CONFIGURATION}-MacOSX"
IPHONE_SRC="${BUILD_DIR}/${CONFIGURATION}-iphone"
APPLETV_SRC="${BUILD_DIR}/${CONFIGURATION}-appletv"

# Populate the destroot
mkdir -p "${IPHONE_DEST}" || exit 1
rsync -av "${IPHONE_SRC}/CrashReporter.framework" "${IPHONE_DEST}" || exit 1

mkdir -p "${APPLETV_DEST}" || exit 1
rsync -av "${APPLETV_SRC}/CrashReporter.framework" "${APPLETV_DEST}" || exit 1

mkdir -p "${MAC_DEST}" || exit 1
rsync -av "${MAC_SRC}/CrashReporter.framework" "${MAC_SRC}/CrashReporter.framework.dSYM" "${MAC_DEST}" || exit 1

mkdir -p "${TOOL_DEST}" || exit 1
install -m 755 "${BUILD_DIR}/${CONFIGURATION}-MacOSX/plcrashutil" "${TOOL_DEST}" || exit 1

mkdir -p "${SRC_DEST}" || exit 1
git archive --format=tar --prefix="plcrashreporter-${CURRENT_PROJECT_VERSION}/" HEAD | tar -C "${SRC_DEST}" -xf - || exit 1

rsync -av "${SRCROOT}/LICENSE" "${LICENSE_DEST}"

# Doxygen could be in /usr/local/bin (Homebrew) or /opt/local/bin (MacPorts)
# and those don't seem to be in PATH
export PATH=$PATH:/usr/local/bin:/opt/local/bin

if [ ! -z `which doxygen` ]; then
    # Generate the documentation
	pushd "${SRCROOT}" >/dev/null || exit 1
    doxygen
    if [ $? != 0 ]; then
        echo "ERROR: Documentation generation failed" >/dev/stderr
        exit 1
    fi
	popd >/dev/null

    # Populate the Documentation directory
	rm -rf "${DOC_DEST}"
    mv Documentation/API "${DOC_DEST}"

    # Add a top-level Documentation symlink
    pushd "${DESTROOT}" >/dev/null
    ln -sf "${DOC_SUBDIR}/index.html" "API Documentation.html"
    popd >/dev/null
else
    echo "WARNING: Doxygen not available, skipping documentation generation" >/dev/stderr
fi

# Create the disk image
rm -f "${DESTROOT}.dmg"
hdiutil create -srcfolder "${DESTROOT}" "${DESTROOT}.dmg" || exit 1

# Create the ZIP archive
rm -f "${DESTROOT}.zip"
pushd "${OUTPUT_DEST}" >/dev/null
zip --symlinks -r "${PRODUCT_DIR}.zip" "${PRODUCT_DIR}" || exit 1
popd >/dev/null

