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
    yasm \
    meson \
    autopoint \
    gettext \
    libffi-dev

ARG PREFIX=/usr/local
ARG TMPDIR=/ffmpeg-libraries
RUN mkdir "${TMPDIR}"

ARG OPENCORE_AMR_VERSION=0.1.5
ARG XVID_VERSION=1.3.4
ARG FREETYPE_VERSION=2.5.5
ARG FONTCONFIG_VERSION=2.12.4
ARG ZLIB_VERSION=1.2.11
ARG GMP_VERSION=6.2.0
ARG NETTLE_VERSION=3.5.1
ARG GNUTLS_VERSION=3.6.13
ARG X264_GIT_BRANCH=stable
ARG RPI_FIRMWARE_GIT_BRANCH=4.19.97-v7l

RUN git clone -b "${RPI_FIRMWARE_GIT_BRANCH}" https://github.com/ARM-PIt/rpi-firmware-essentials.git "${TMPDIR}"/rpi-firmware-essentials && \ 
    git clone --depth=1 https://github.com/raspberrypi/userland "${TMPDIR}"/userland && \
    mkdir /opt/vc && \
    mkdir /lib/modules && \
    cp -a "${TMPDIR}"/rpi-firmware-essentials/hardfp/opt/* /opt/ && \
    cp -a "${TMPDIR}"/rpi-firmware-essentials/modules/* /lib/modules/ && \ 
    cp -a "${TMPDIR}"/userland/interface/* "${PREFIX}"/include/ && \
    echo "/opt/vc/lib" > /etc/ld.so.conf.d/00-vmcs.conf && \
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
    cmake -G "Unix Makefiles" AOM_SRC -DENABLE_NASM=on -DPYTHON_EXECUTABLE="$(which python3)" -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DBUILD_SHARED_LIBS=0 -DCMAKE_C_FLAGS="-mfpu=neon -mfloat-abi=hard" .. && \
    sed -i 's/ENABLE_NEON:BOOL=ON/ENABLE_NEON:BOOL=OFF/' CMakeCache.txt && \
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
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig:${PKG_CONFIG_PATH} \
    ./configure --prefix="${PREFIX}" --enable-static --disable-shared && \
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

ARG FFMPEG_DEB_VERSION=052020-1
ARG FFMPEG_GIT_BRANCH=master
ARG FFMPEG_GIT_TAG=n4.2.1
ARG FFMPEG_GIT_COMMIT=a619787a9ca87e0c4566cf124d52d23974a440d9
ARG FFMPEG_CACHE_KILL=1
RUN git clone https://github.com/FFmpeg/FFmpeg.git "${TMPDIR}"/FFmpeg && \
    #cd "${TMPDIR}"/FFmpeg && \
    #git checkout -b "${FFMPEG_GIT_BRANCH}" && \
    #git checkout "${FFMPEG_GIT_COMMIT}" && \
    #git checkout tags/"${FFMPEG_GIT_TAG}" && \
    echo "${FFMPEG_CACHE_KILL}"

COPY patches/configure-opengl-rpi.patch "${TMPDIR}"/FFmpeg/
RUN cd "${TMPDIR}"/FFmpeg && patch -f < configure-opengl-rpi.patch

## Use --enable-ffplay, but will require libsdl2-dev on target for working ffmpeg
#RUN apt-get update && apt-get install -y libsdl2-dev

## Use --enable-opengl, but will require libgles2-mesa-dev on target for working ffmpeg
#RUN apt-get update && apt-get install -y libgles2-mesa-dev

RUN cp -a /usr/lib/gcc/arm-linux-gnueabihf/8/libgomp.a "${PREFIX}"/lib/ && \
    ldconfig

RUN cd "${TMPDIR}"/FFmpeg && \
    export PREFIX="${PREFIX}" && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig:/opt/vc/lib/pkgconfig \
    ./configure \ 
    --prefix="${PREFIX}" \
    --pkg-config-flags="--static" \
    --enable-static \
    --arch=armhf \
    --target-os=linux \
    --extra-cflags="-I"${PREFIX}"/include -I"${PREFIX}"/include/bellagio -I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux" \    
    --extra-ldflags="-L"${PREFIX}"/lib -L"${PREFIX}"/lib/bellagio -L/opt/vc/lib" \
    --extra-libs='-lstdc++ -lpthread -lm -ldl -lz -lrt -lbrcmGLESv2 -lEGL -lbcm_host -lvcos -lvchiq_arm -lgomp' \
    --enable-debug \
    --disable-stripping \
    --enable-runtime-cpudetect \
    --disable-doc \
    --disable-shared \
    --disable-libxcb \
    --disable-opengl \
    --disable-ffplay \
    --enable-gmp \
    --enable-gpl \
    --enable-libaom \
    --enable-libass \
    --enable-libdav1d \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-fontconfig \
    --enable-libkvazaar \
    --enable-libmp3lame \
    --enable-libopencore-amrnb \
    --enable-libopencore-amrwb \
    --enable-libopus \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libzimg \
    --enable-zlib \
    --enable-libx264 \
    --enable-libx265 \
    --enable-neon \
    --enable-mmal \
    --enable-libv4l2 \
    --enable-v4l2-m2m \
    --enable-nonfree \
    --enable-omx \
    --enable-omx-rpi \
    --enable-version3 \
    --enable-pthreads \
    --enable-avresample \
    --enable-gnutls \
    --enable-libvidstab \
    --enable-libopenjpeg \
    --enable-libtheora \
    --enable-libxvid \
    --enable-postproc \
    --enable-rpath && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN mkdir -p /ffmpeg_"${FFMPEG_DEB_VERSION}"/usr/local/bin && \
    mkdir -p /ffmpeg_"${FFMPEG_DEB_VERSION}"/usr/local/lib/pkgconfig && \
    mkdir /ffmpeg_"${FFMPEG_DEB_VERSION}"/DEBIAN && \
    mkdir /artifact

COPY src/control.template /ffmpeg_"${FFMPEG_DEB_VERSION}"/DEBIAN/control.template

RUN envsubst < /ffmpeg_"${FFMPEG_DEB_VERSION}"/DEBIAN/control.template > /ffmpeg_"${FFMPEG_DEB_VERSION}"/DEBIAN/control && \
    rm /ffmpeg_"${FFMPEG_DEB_VERSION}"/DEBIAN/control.template

RUN cp -a "${PREFIX}"/bin/ffmpeg /ffmpeg_"${FFMPEG_DEB_VERSION}"/usr/local/bin/ && \
    cp -a "${PREFIX}"/bin/ffprobe /ffmpeg_"${FFMPEG_DEB_VERSION}"/usr/local/bin/ && \
    #cp -a "${PREFIX}"/bin/ffplay /ffmpeg_"${FFMPEG_DEB_VERSION}"/usr/local/bin/ && \
    dpkg-deb --build ffmpeg_"${FFMPEG_DEB_VERSION}" && \
    rm -rf ffmpeg_"${FFMPEG_DEB_VERSION}"

CMD ["/bin/bash"]
