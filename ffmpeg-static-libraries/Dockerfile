FROM debian:10-slim

ARG DEBIAN_FRONTEND="noninteractive"

RUN mkdir -p /usr/share/man/man1 && \
    apt-get update && \
    apt-get full-upgrade -y && \
    apt-get install -y \
    vim \
    autoconf \
    automake \
    cmake \
    curl \
    bzip2 \
    g++ \
    gcc \
    git \
    gperf \
    libtool \
    make \
    nasm \
    perl \
    pkg-config \
    python \
    ragel \
    yasm \
    meson \
    autopoint \
    gettext \
    libffi-dev \
    libudev-dev

ARG PREFIX=/usr/local
ARG TMPDIR=/ffmpeg-libraries
RUN mkdir "${TMPDIR}" /opt/vc /lib/modules

ARG OPENCORE_AMR_VERSION=0.1.5
ARG XVID_VERSION=1.3.4
ARG FREETYPE_VERSION=2.5.5
ARG FONTCONFIG_VERSION=2.12.4
ARG ZLIB_VERSION=1.2.11
ARG GMP_VERSION=6.2.0
ARG NETTLE_VERSION=3.5.1
ARG GNUTLS_VERSION=3.6.13
ARG X264_GIT_BRANCH=stable
ARG USERLAND_GIT_COMMIT=7d3c6b9

RUN git clone https://github.com/raspberrypi/userland "${TMPDIR}"/userland && \
    cd "${TMPDIR}"/userland && \
    git checkout "${USERLAND_GIT_COMMIT}" && \
    cp -a "${TMPDIR}"/userland/interface/* "${PREFIX}"/include/ && \
    sed -i -e 's/sudo//g' ${TMPDIR}/userland/buildme && \
    bash buildme --aarch64 && \
    echo "/opt/vc/lib" > /etc/ld.so.conf.d/00-vmcs.conf && \
    ln -sf /opt/vc/bin/vcgencmd /usr/bin/vcgencmd && \
    ldconfig

RUN mkdir "${TMPDIR}"/zlib && cd "${TMPDIR}"/zlib && \
    curl -sLO https://www.zlib.net/zlib-"${ZLIB_VERSION}".tar.gz && \
    tar -zx -f zlib-"${ZLIB_VERSION}".tar.gz && cd zlib-"${ZLIB_VERSION}" && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" && \
    make && \
    make install && \
    ldconfig

RUN git clone --depth 1 https://github.com/mstorsjo/fdk-aac.git "${TMPDIR}"/fdk-aac && \
    cd "${TMPDIR}"/fdk-aac && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    autoreconf -fiv && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone --depth 1 https://code.videolan.org/videolan/dav1d.git "${TMPDIR}"/dav1d && \
    mkdir "${TMPDIR}"/dav1d/build && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    cd "${TMPDIR}"/dav1d/build && \
    meson --buildtype release --default-library static --prefix="${PREFIX}" --libdir lib .. && \
    ninja -j$(nproc) && \
    ninja install && \
    ldconfig

RUN git clone --depth 1 https://github.com/ultravideo/kvazaar.git "${TMPDIR}"/kvazaar && \
    cd "${TMPDIR}"/kvazaar && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    ./autogen.sh && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone --depth 1 https://chromium.googlesource.com/webm/libvpx "${TMPDIR}"/libvpx && \
    cd "${TMPDIR}"/libvpx && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared --disable-examples --disable-tools --disable-unit_tests --disable-docs && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone --depth 1 https://aomedia.googlesource.com/aom "${TMPDIR}"/aom && \
    mkdir "${TMPDIR}"/aom/aom_build && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    cd "${TMPDIR}"/aom/aom_build && \
    cmake -G "Unix Makefiles" AOM_SRC -DENABLE_NASM=on -DPYTHON_EXECUTABLE="$(which python3)" -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DBUILD_SHARED_LIBS=0 .. && \
    #sed -i 's/ENABLE_NEON:BOOL=ON/ENABLE_NEON:BOOL=OFF/' CMakeCache.txt && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone https://github.com/sekrit-twc/zimg.git "${TMPDIR}"/zimg && \
    cd "${TMPDIR}"/zimg && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    sh autogen.sh && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN mkdir "${TMPDIR}"/opencore-amr && cd "${TMPDIR}"/opencore-amr && \
    curl -sL https://versaweb.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-"${OPENCORE_AMR_VERSION}".tar.gz | \
    tar -zx --strip-components=1 && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone https://github.com/xiph/ogg.git "${TMPDIR}"/ogg && \
    cd "${TMPDIR}"/ogg && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    sh autogen.sh && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone https://github.com/xiph/vorbis.git "${TMPDIR}"/vorbis && \
    cd "${TMPDIR}"/vorbis && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    sh autogen.sh && \
    OGG_CFLAGS=-I"${PREFIX}"/include \
    OGG_LIBS="-L"${PREFIX}"/lib -logg" \
    VORBIS_CFLAGS=-I"${TMPDIR}"/vorbis/include \
    VORBIS_LIBS="-L"${TMPDIR}"/vorbis/lib -lvorbis -lvorbisenc" \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone https://github.com/xiph/theora.git "${TMPDIR}"/theora && \
    cd "${TMPDIR}"/theora && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    sh autogen.sh && \
    OGG_CFLAGS=-I"${PREFIX}"/include \
    OGG_LIBS="-L"${PREFIX}"/lib -logg" \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone https://github.com/xiph/opus.git "${TMPDIR}"/opus && \
    cd "${TMPDIR}"/opus && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    sh autogen.sh && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone https://code.videolan.org/videolan/x264.git "${TMPDIR}"/x264 && \
    cd "${TMPDIR}"/x264 && \
    git checkout -b "${X264_GIT_BRANCH}" && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --enable-pic --disable-cli && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone https://github.com/zlargon/lame.git "${TMPDIR}"/lame && \
    cd "${TMPDIR}"/lame && \
    cp -a /usr/share/misc/config.guess ./ && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone https://github.com/uclouvain/openjpeg.git "${TMPDIR}"/openjpeg && \
    cd "${TMPDIR}"/openjpeg && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DBUILD_SHARED_LIBS=0 . && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN mkdir "${TMPDIR}"/freetype && cd "${TMPDIR}"/freetype && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    curl -sLO https://download.savannah.gnu.org/releases/freetype/freetype-"${FREETYPE_VERSION}".tar.gz && \
    tar -zx --strip-components=1 -f freetype-"${FREETYPE_VERSION}".tar.gz && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone https://github.com/fribidi/fribidi.git "${TMPDIR}"/fribidi && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    cd "${TMPDIR}"/fribidi && \
    sh autogen.sh && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make && \
    make install && \
    ldconfig

RUN git clone https://github.com/libexpat/libexpat.git "${TMPDIR}"/libexpat && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    cd "${TMPDIR}"/libexpat/expat && \
    sh buildconf.sh && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN mkdir "${TMPDIR}"/fontconfig && cd "${TMPDIR}"/fontconfig && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    curl -sLO https://www.freedesktop.org/software/fontconfig/release/fontconfig-"${FONTCONFIG_VERSION}".tar.bz2 && \
    tar -jx --strip-components=1 -f fontconfig-"${FONTCONFIG_VERSION}".tar.bz2 && \
    FREETYPE_CFLAGS=-I"${PREFIX}"/include/freetype2 \
    FREETYPE_LIBS="-L"${PREFIX}"/lib -lfreetype" \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone --depth 1 https://github.com/harfbuzz/harfbuzz.git "${TMPDIR}"/harfbuzz && \
    cd "${TMPDIR}"/harfbuzz && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    sh autogen.sh && \
    FREETYPE_CFLAGS=-I"${PREFIX}"/include/freetype2 \
    FREETYPE_LIBS="-L"${PREFIX}"/lib -lfreetype" \
    FRIBIDI_CFLAGS=-I"${PREFIX}"/include/fribidi \
    FRIBIDI_LIBS="-L"${PREFIX}"/lib -lfribidi" \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j2 && \
    make install && \
    ldconfig

RUN git clone https://github.com/libass/libass.git "${TMPDIR}"/libass && \
    cd "${TMPDIR}"/libass && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    sh autogen.sh && \
    FREETYPE_CFLAGS=-I"${PREFIX}"/include/freetype2 \
    FREETYPE_LIBS="-L"${PREFIX}"/lib -lfreetype" \
    FRIBIDI_CFLAGS=-I"${PREFIX}"/include/fribidi \
    FRIBIDI_LIBS="-L"${PREFIX}"/lib -lfribidi" \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone https://github.com/georgmartius/vid.stab.git "${TMPDIR}"/vid.stab && \
    cd "${TMPDIR}"/vid.stab && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DBUILD_SHARED_LIBS=0 . && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN mkdir "${TMPDIR}"/gmp && cd "${TMPDIR}"/gmp && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    curl -sLO https://gmplib.org/download/gmp/gmp-"${GMP_VERSION}".tar.bz2 && \
    tar -jx --strip-components=1 -f gmp-"${GMP_VERSION}".tar.bz2 && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN mkdir "${TMPDIR}"/nettle && cd "${TMPDIR}"/nettle && \
    curl -sLO https://ftp.gnu.org/gnu/nettle/nettle-"${NETTLE_VERSION}".tar.gz && \
    tar -zx -f nettle-"${NETTLE_VERSION}".tar.gz && cd nettle-"${NETTLE_VERSION}" && \
    sed -i -e 's/-fpic/-fPIC/g' ${TMPDIR}/nettle/nettle-"${NETTLE_VERSION}"/configure && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig:${PKG_CONFIG_PATH} \
    ./configure --prefix="${PREFIX}" --enable-pic --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN mkdir "${TMPDIR}"/gnutls && cd "${TMPDIR}"/gnutls && \
    curl -sLO https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-"${GNUTLS_VERSION}".tar.xz && \
    tar -xf gnutls-"${GNUTLS_VERSION}".tar.xz && cd gnutls-"${GNUTLS_VERSION}" && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig:${PKG_CONFIG_PATH} \
    CPPFLAGS="-I"${PREFIX}"/include" \
    LDFLAGS="-L"${PREFIX}"/lib" \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared --without-p11-kit --with-included-libtasn1 --with-included-unistring && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone git://linuxtv.org/v4l-utils.git "${TMPDIR}"/v4l-utils && \
    cd "${TMPDIR}"/v4l-utils && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    ./bootstrap.sh && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone --depth 1 https://github.com/alsa-project/alsa-lib.git "${TMPDIR}"/alsa-lib && \
    cd "${TMPDIR}"/alsa-lib && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    autoreconf -fiv && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN git clone https://github.com/numactl/numactl.git "${TMPDIR}"/numactl && \
    cd "${TMPDIR}"/numactl && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    sh autogen.sh && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-pic --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

COPY patches/xvid-Makefile-static-lib.patch "${TMPDIR}"/xvid-Makefile-static-lib.patch
RUN mkdir "${TMPDIR}"/xvid && cd "${TMPDIR}"/xvid && \
    curl -sLO http://downloads.xvid.org/downloads/xvidcore-"${XVID_VERSION}".tar.gz && \
    tar -zx -f xvidcore-"${XVID_VERSION}".tar.gz && \
    cd xvidcore/build/generic && \
    cp "${TMPDIR}"/xvid-Makefile-static-lib.patch ./ && \
    patch -f < xvid-Makefile-static-lib.patch && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

COPY src/x265-rpi-tools "${TMPDIR}"/x265-rpi-tools
RUN git clone https://github.com/videolan/x265.git "${TMPDIR}"/x265 && \
    export PREFIX="${PREFIX}" && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    cd "${TMPDIR}"/x265/build/linux && \
    mv "${TMPDIR}"/x265-rpi-tools/* ./ && \
    ./multilib-static-rpi.sh && \
    make -C 8bit install && \
    ldconfig

COPY patches/omx-Makefile-am-static-lib.patch "${TMPDIR}"/omx-Makefile-am-static-lib.patch
RUN git clone https://github.com/felipec/libomxil-bellagio.git "${TMPDIR}"/libomxil-bellagio && \
    cd "${TMPDIR}"/libomxil-bellagio && \
    sed -i 's/\-Werror//g' configure.ac && \
    cp "${TMPDIR}"/omx-Makefile-am-static-lib.patch ./ && \
    patch -f -p0 < omx-Makefile-am-static-lib.patch && \
    export PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig && \
    autoreconf -ivf && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    ldconfig

CMD ["bin/bash"]
