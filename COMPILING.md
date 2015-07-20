You need some opam packages
```
opam install ctypes.0.4.0 ctypes-foreign
```

You'll also need to install rocksdb
```
git clone https://github.com/facebook/rocksdb/
cd rocksdb
git checkout tags/rocksdb-3.9.1
make shared_lib
sudo cp librocksdb.so /usr/local/lib/
```

There's a primitive script that does this:
```
./install_rocksdb.sh
```


Afterwards run `make` in the root dir of this repository.
The package can be installed with `make install`.
