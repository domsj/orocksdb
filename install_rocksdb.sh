#!/usr/bin/env bash
set -x
echo $(gcc --version)

VERSION=3.12
shared_lib_file="/usr/local/lib/librocksdb.so.${VERSION}"
if [ -e $shared_lib_file ]; then
    echo "$shared_lib_file exists"
else
    echo "cloning, building, installing rocksdb"
    git clone https://github.com/facebook/rocksdb/
    cd rocksdb
    git checkout tags/rocksdb-${VERSION}
    PORTABLE=1 make shared_lib
    sudo make uninstall
    sudo make install-shared
    sudo ldconfig
fi
