OCAML_LIBDIR?=`ocamlfind printconf destdir`
OCAML_FIND ?= ocamlfind

all:
	$(MAKE) build
	$(MAKE)	test

build:
	ocamlbuild -use-ocamlfind -lflags -cclib,-l:librocksdb.so rocks.inferred.mli rocks.cma rocks.cmxa rocks.cmxs rocks_options.inferred.mli

test:
	ocamlbuild -use-ocamlfind -lflags -cclib,-l:librocksdb.so rocks_test.native rocks.inferred.mli rocks.cma rocks.cmxa rocks.cmxs

clean:
	ocamlbuild -clean

install:
	mkdir -p $(OCAML_LIBDIR)
	$(OCAML_FIND) install rocks -destdir $(OCAML_LIBDIR) _build/META \
	 _build/rocks.a \
	 _build/rocks.cma \
	 _build/rocks.cmi \
	 _build/rocks.cmx \
	 _build/rocks.cmxa \
	 _build/rocks.cmxs

uninstall:
	$(OCAML_FIND) remove rocks -destdir $(OCAML_LIBDIR)
