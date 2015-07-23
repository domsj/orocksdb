#!/usr/bin/env bash

shared_lib_file="/usr/local/lib/librocksdb.so"
if [ -e $shared_lib_file ]; then
    echo "$shared_lib_file exists"
else
    echo "cloning, building, installing rocksdb"
    git clone https://github.com/facebook/rocksdb/
    cd rocksdb
    git checkout tags/rocksdb-3.12
    make shared_lib
    sudo cp ./librocksdb.so "$shared_lib_file"
fi
