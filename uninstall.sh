#!/usr/bin/env sh

if [ -z  "$1" ]; then
    export PREFIX=/usr
    # Make sure only root can run our script
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
else
    export PREFIX=$1
fi

echo "Uninstalling from prefix ${PREFIX}"

rm ${PREFIX}/bin/ttyx
rm ${PREFIX}/share/glib-2.0/schemas/io.github.gwelr.ttyx.gschema.xml
glib-compile-schemas ${PREFIX}/share/glib-2.0/schemas/
rm -rf ${PREFIX}/share/ttyx

find ${PREFIX}/share/locale -type f -name "ttyx.mo" -delete
find ${PREFIX}/share/icons/hicolor -type f -name "io.github.gwelr.ttyx.png" -delete
find ${PREFIX}/share/icons/hicolor -type f -name "io.github.gwelr.ttyx*.svg" -delete
rm ${PREFIX}/share/nautilus-python/extensions/open-ttyx.py
rm ${PREFIX}/share/dbus-1/services/io.github.gwelr.ttyx.service
rm ${PREFIX}/share/applications/io.github.gwelr.ttyx.desktop
rm ${PREFIX}/share/metainfo/io.github.gwelr.ttyx.appdata.xml
rm ${PREFIX}/share/man/man1/ttyx.1.gz
rm ${PREFIX}/share/man/*/man1/ttyx.1.gz
