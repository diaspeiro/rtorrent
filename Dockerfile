ARG BASE_IMAGE=cgr.dev/chainguard/wolfi-base:latest
FROM ${BASE_IMAGE} AS build_rtorrent
LABEL stage=build

#=============#
# Build Stage #
#=============#
ARG SOURCE_DATE_EPOCH=0
ENV CFLAGS="-O2 -I/opt/include -pipe -fno-plt -mshstk -Wformat -Wformat-security -Werror=format-security -Werror=implicit-function-declaration" \
        CXXFLAGS="-O2 -I/opt/include -pipe -fno-plt -mshstk -Wformat -Wformat-security -Werror=format-security -Werror=implicit-function-declaration" \
        LDFLAGS="-L/opt/lib -Wl,-O1 -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,-rpath,/opt/lib" \
        PKG_CONFIG_PATH="/opt/lib/pkgconfig/"

WORKDIR /build

RUN --mount=type=cache,target=/var/cache,sharing=locked <<ENDRUN
apk add autoconf automake ca-certificates cmake curl gcc git jq libtool make patch perl pkgconf pkgconf-dev posix-libc-utils python-3.13 py3.13-pip py3.13-wheel
ENDRUN

SHELL ["/bin/bash", "-c"]

# Build zlib
RUN --mount=type=bind,source=.github/dependency-versions.json,target=/build/dv.json \
    --mount=type=bind,source=scripts/fetch-dep.sh,target=/usr/local/bin/fetch-dep <<ENDRUN
set -uex
umask 0022
fetch-dep zlib
cd zlib
CFLAGS="${CFLAGS} -Wno-deprecated-non-prototype" cmake -DCMAKE_INSTALL_PREFIX=/opt -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_RPATH=/opt/lib -DZLIB_BUILD_TESTING=off -DZLIB_BUILD_STATIC=off .
make -j$(getconf _NPROCESSORS_ONLN)
make install
ENDRUN

# Build openssl
RUN --mount=type=bind,source=.github/dependency-versions.json,target=/build/dv.json \
    --mount=type=bind,source=scripts/fetch-dep.sh,target=/usr/local/bin/fetch-dep <<ENDRUN
set -uex
umask 0022
fetch-dep openssl
cd openssl
./config CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" LDFLAGS="${LDFLAGS}" --prefix=/opt --libdir=lib --openssldir=/etc/opt/ssl --api=3.0 --with-rand-seed=getrandom enable-pie no-apps no-argon2 no-aria no-bf no-blake2 no-cached-fetch no-camellia no-cast no-cmac no-cmp no-cms no-comp no-ct no-des no-docs no-dsa no-dso no-dtls no-dtls1-method no-dtls1_2-method no-ec2m no-egd no-filenames no-gost no-hmac-drbg-kdf no-http no-idea no-integrity-only-ciphers no-kbkdf no-krb5kdf no-md4 no-mdc2 no-mdc2 no-ml-dsa no-module no-ocb no-psk no-pvkkdf no-rc2 no-rmd160 no-scrypt no-sctp no-seed no-siphash no-slh-dsa no-sm2 no-sm2-precomp no-sm3 no-sm4 no-snmpkdf no-srtp no-srtpkdf no-sshkdf no-sskdf no-ssl-trace no-tests no-tls1 no-tls1-method no-tls1_1 no-tls1_1-method no-tls-deprecated-ec no-ts no-unstable-qlog no-whirlpool no-x942kdf no-x963kdf
make -j$(getconf _NPROCESSORS_ONLN)
make install_sw
ENDRUN

# Build nghttp2
RUN --mount=type=bind,source=.github/dependency-versions.json,target=/build/dv.json \
    --mount=type=bind,source=scripts/fetch-dep.sh,target=/usr/local/bin/fetch-dep <<ENDRUN
set -uex
umask 0022
fetch-dep nghttp2
cd nghttp2
cmake -DCMAKE_INSTALL_PREFIX=/opt -DCMAKE_INCLUDE_PATH=/opt/include -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_RPATH=/opt/lib -DENABLE_LIB_ONLY=on -DENABLE_DOC=off -DENABLE_FAILMALLOC=off .
make -j$(getconf _NPROCESSORS_ONLN)
make install
ENDRUN

# Build c-ares
RUN --mount=type=bind,source=.github/dependency-versions.json,target=/build/dv.json \
    --mount=type=bind,source=scripts/fetch-dep.sh,target=/usr/local/bin/fetch-dep <<ENDRUN
set -uex
umask 0022
fetch-dep cares c-ares
cd c-ares
cmake -DCMAKE_INSTALL_PREFIX=/opt -DCMAKE_INCLUDE_PATH=/opt/include -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_RPATH=/opt/lib -DCARES_BUILD_TOOLS=off -DCARES_SYMBOL_HIDING=on .
make -j$(getconf _NPROCESSORS_ONLN)
make install
ENDRUN

# Build curl
RUN --mount=type=bind,source=.github/dependency-versions.json,target=/build/dv.json \
    --mount=type=bind,source=scripts/fetch-dep.sh,target=/usr/local/bin/fetch-dep <<ENDRUN
set -uex
umask 0022
fetch-dep curl
cd curl
cmake -DCMAKE_INSTALL_PREFIX=/opt -DCMAKE_INCLUDE_PATH=/opt/include -DCMAKE_LIBRARY_PATH=/opt/lib -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_RPATH=/opt/lib -DBUILD_EXAMPLES=off -DBUILD_TESTING=off -DBUILD_LIBCURL_DOCS=off -DBUILD_MISC_DOCS=off -DENABLE_CURL_MANUAL=off -DHTTP_ONLY=on -DENABLE_ARES=on -DCURL_USE_OPENSSL=on -DCURL_USE_LIBPSL=off -DENABLE_UNIX_SOCKETS=off -DCURL_USE_LIBSSH2=off -DUSE_LIBIDN2=off -DCURL_DISABLE_PROXY=on -DCURL_DISABLE_HSTS=on .
make -j$(getconf _NPROCESSORS_ONLN)
make install
ENDRUN

# Build libtorrent
RUN --mount=type=bind,source=.github/dependency-versions.json,target=/build/dv.json \
    --mount=type=bind,source=scripts/fetch-dep.sh,target=/usr/local/bin/fetch-dep \
    --mount=type=bind,source=patches,target=/patches <<ENDRUN
set -uex
umask 0022
fetch-dep libtorrent
cd libtorrent
autoreconf -fiv
CFLAGS="${CFLAGS// -Werror=implicit-function-declaration/}" CXXFLAGS="${CXXFLAGS// -Werror=implicit-function-declaration/}" ./configure --prefix=/opt --disable-debug
make -j$(getconf _NPROCESSORS_ONLN)
make install
ENDRUN

# Build rtorrent
RUN --mount=type=bind,source=.github/dependency-versions.json,target=/build/dv.json \
    --mount=type=bind,source=scripts/fetch-dep.sh,target=/usr/local/bin/fetch-dep \
    --mount=type=bind,source=patches,target=/patches <<ENDRUN
set -uex
umask 0022
fetch-dep rtorrent
cd rtorrent
autoreconf -fiv
CFLAGS="${CFLAGS// -Werror=implicit-function-declaration/}" CXXFLAGS="${CXXFLAGS// -Werror=implicit-function-declaration/}" ./configure --prefix=/opt --disable-debug --with-xmlrpc-tinyxml2 --without-ncurses
make -j$(getconf _NPROCESSORS_ONLN)
make install
ENDRUN

# Build python wheels
RUN <<ENDRUN
set -uex
umask 0022
pip wheel --wheel-dir=/build/wheels \
    git+https://github.com/kannibalox/pyrosimple@d24655a708059d322633e361e2e204983e51f491 \
    git+https://github.com/cinemagoer/cinemagoer@aca62692b6f0ca7ed9c70871bafd8b558c6ba6ec \
    git+https://github.com/guessit-io/guessit@c7b39db259b9c988046eb5200862b87d26d54696
ENDRUN

# Cleanup
RUN <<ENDRUN
set -uex
umask 0022
rm -rf /opt/{share,include}
rm -rf /opt/bin/{c_rehash,curl-config,mk-ca-bundle.pl,wcurl}
rm -rf /opt/lib/{cmake,pkgconfig,*.a,*.la}
strip --strip-unneeded /opt/lib/*.so /opt/bin/*
ENDRUN

#===============#
# Runtime Stage #
#===============#
FROM ${BASE_IMAGE} AS rtorrent

ARG SOURCE_DATE_EPOCH=0

RUN --mount=type=cache,target=/var/cache,sharing=locked \
    --mount=type=bind,from=build_rtorrent,source=/opt,target=/mnt/opt \
    --mount=type=bind,from=build_rtorrent,source=/build/wheels,target=/mnt/wheels \
    --mount=type=bind,source=files,target=/mnt/files <<ENDRUN
set -uex
umask 0022
apk add --no-interactive bash ca-certificates curl jq libstdc++ python-3.13 py3.13-pip py3.13-wheel rsync tzdata
cp -a /mnt/opt/. /opt
python3 -m venv /opt/venv
/opt/venv/bin/pip install --no-index --find-links=/mnt/wheels pyrosimple cinemagoer guessit
cp -a /mnt/files/. /
find /docker-entrypoint.d -type f -regex '.*\.\(sh\|envsh\)$' -print0 | xargs -r0 chmod +x
chmod +x /docker-entrypoint.sh /docker-entrypoint.d/*.sh /opt/bin/rtmove
find / -xdev -exec touch -hd "@${SOURCE_DATE_EPOCH}" {} + || true
ENDRUN

SHELL [ "/bin/bash", "-c" ]

ENV PATH="/opt/venv/bin:/opt/bin:/rtorrent/bin:$PATH" \
    PYRO_RTORRENT_RC="/rtorrent/rtorrent.rc" \
    PYRO_CONF="/rtorrent/config.toml"
VOLUME [ "/rtorrent/data", "/ipc/rtorrent", "/downloads" ]
USER nonroot
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "rtorrent", "-n", "-o", "import=/rtorrent/rtorrent.rc" ]
