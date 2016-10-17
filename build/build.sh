#!/bin/sh

set -e

export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

if [ ! -e "/usr/bin/fakeroot" ]; then
	apt-get install fakeroot
fi

MODULENAME="se3-domain"
SCRIPTDIR="${0%/*}"
BUILDDIR=$(cd "$SCRIPTDIR"; pwd) # Same as SCRIPTDIR but with a full path.
PKGDIR="${BUILDDIR}/$MODULENAME"


# Cleaning of $BUILDDIR.
rm -f "${BUILDDIR}/"*.deb
rm -rf "$PKGDIR" && mkdir -p "$PKGDIR"

# Copy the source in the "$PKGDIR" directory. Copy all
# directories in the root of this repository except the
# "build/" directory itself.
for dir in "${BUILDDIR}/../"*
do
    # Convert to the full path.
    dir=$(readlink -f "$dir")

    [ ! -d "$dir" ]            && continue
    [ "$dir" = "${BUILDDIR}" ] && continue

    cp -ra "$dir" "$PKGDIR"
done

VERSION=$(grep -i '^version:' "${PKGDIR}/DEBIAN/control" | cut -d' ' -f2)

while true
do
    [ ! -e "${PKGDIR}/var/cache/se3_install/maj/maj${UPDATENB}.sh" ] && break
    UPDATENB=$((UPDATENB + 1))
done


chmod -R 755 "${PKGDIR}/DEBIAN"

chmod +x  ${PKGDIR}/usr/share/se3/sbin/*
chmod +x ${PKGDIR}/usr/share/se3/scripts/*
# chmod +x ${PKGDIR}/usr/share/se3/shares/shares.avail/*


# Now, it's possible to build the package.
cd "$BUILDDIR" || {
    echo "Error, impossible to change directory to \"${BUILDDIR}\"." >&2
    echo "End of the script."                                        >&2
    exit 1
}
find "$PKGDIR" -name ".empty" -delete

# dpkg --build "$PKGDIR"
# mv $PKGDIR.deb se3_$version.deb

fakeroot dpkg-deb -b "$PKGDIR" "${MODULENAME}${VERSION}.deb"


echo "OK, building succesfully..."


