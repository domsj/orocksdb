FROM ubuntu:bionic-20190307

ENV release_name=bionic
ENV rocksdb_version=5.11.3
ENV ocaml_version=4.07.1

# force our apt to use look at mirrors (by prepending a mirrors line)
# RUN sed 's@archive.ubuntu.com@ubuntu.mirror.atratoip.net@' -i /etc/apt/sources.list
RUN sed -i "1s;^;deb mirror://mirrors.ubuntu.com/mirrors.txt ${release_name}-updates main restricted universe multiverse\n;" /etc/apt/sources.list
RUN sed -i "1s;^;deb mirror://mirrors.ubuntu.com/mirrors.txt ${release_name}         main restricted universe multiverse\n;" /etc/apt/sources.list

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential m4 apt-utils \
	lcov \
        libffi-dev libssl-dev \
        libbz2-dev \
        libgmp3-dev \
        libev-dev \
        libsnappy-dev \
        libxen-dev \
        help2man \
        pkg-config \
        time \
        aspcud \
        wget \
        rsync \
        darcs \
        git \
        unzip \
        yasm \
        automake \
        debhelper \
        psmisc \
        strace \
        curl \
        g++ \
        libgflags-dev \
        sudo \
        libtool \
        fuse \
        sysstat \
        ncurses-dev \
        liburiparser1 \
        tzdata \
        binutils-dev \
        libpcre3-dev \
        patchelf \
        socat \
        libcurl4-openssl-dev \
        equivs \
        libgtest-dev \
        help2man \
        zlib1g-dev \
        cmake

RUN cd /usr/src/gtest \
        && cmake . \
        && make \
        && mv libg* /usr/lib/

ARG HOST_UID
RUN useradd jenkins -u $HOST_UID -g root --create-home
#RUN echo "jenkins ALL=NOPASSWD: ALL" >/etc/sudoers.d/jenkins

# Install rocksdb:
RUN wget -q \
    https://github.com/facebook/rocksdb/archive/v${rocksdb_version}.tar.gz -O - \
    | tar zxf - \
    && PORTABLE=1 make -j$(nproc 2>/dev/null || echo 1) -C rocksdb-${rocksdb_version} shared_lib \
    && sudo make -C rocksdb-${rocksdb_version} install-shared \
    && rm -rf rocksdb-${rocksdb_version}

RUN wget https://github.com/ocaml/opam/releases/download/2.0.3/opam-2.0.3-x86_64-linux \
    && mv opam-2.0.3-x86_64-linux /usr/bin/opam \
    && chmod a+x /usr/bin/opam

ENV OPAMROOT=/home/jenkins/OPAM

env opam_env="opam config env --root=${OPAMROOT}"

RUN opam init --root ${OPAMROOT} --compiler=${ocaml_version} --disable-sandboxing
ADD opam.switch opam.switch
RUN eval `${opam_env}` && export OPAMROOT=${OPAMROOT} && \
    opam switch import opam.switch -y --strict

RUN eval ${opam_env} && export OPAMROOT=${OPAMROOT} && \
    opam list && \
    opam switch export opam.switch.out && \
    cat opam.switch.out

RUN diff -u opam.switch opam.switch.out

RUN su - -c "echo 'eval `${opam_env}`' >> /home/jenkins/.profile"
RUN su - -c "echo 'LD_LIBRARY_PATH=/usr/local/lib; export LD_LIBRARY_PATH;' >> /home/jenkins/.profile"
RUN echo "jenkins ALL=NOPASSWD: ALL" >/etc/sudoers.d/jenkins

ENTRYPOINT ["/home/jenkins/orocksdb/docker/docker-entrypoint.sh"]
