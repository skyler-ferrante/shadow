ARG OS_IMAGE="fedora:latest"

FROM "${OS_IMAGE}" AS build

RUN dnf install -y \
	dnf-plugins-core \
	libcmocka-devel \
	systemd-devel
RUN dnf builddep -y shadow-utils

COPY ./ /usr/local/src/shadow/
WORKDIR /usr/local/src/shadow/

RUN ./autogen.sh \
	--enable-shadowgrp \
	--enable-man \
	--with-audit \
        --with-sha-crypt \
	--with-bcrypt \
	--with-yescrypt \
	--with-selinux \
        --without-libpam \
	--enable-shared \
	--without-libbsd \
        --with-group-name-max-length=32 \
	--enable-lastlog \
	--enable-logind=no
RUN make -kj4 || true
RUN make
RUN bash -c "trap 'cat <tests/unit/test-suite.log >&2' ERR; make check;"
RUN make install

FROM scratch AS export
COPY --from=build /usr/local/src/shadow/config.log \
    /usr/local/src/shadow/config.h ./
