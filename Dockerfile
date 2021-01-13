FROM armpits/ffmpeg-static-libraries:aarch64

ARG PREFIX=/usr/local
ARG TMPDIR=/ffmpeg-libraries
ARG FFMPEG_DEB_VERSION=012021-1
ARG FFMPEG_GIT_BRANCH=master
ARG FFMPEG_GIT_TAG=n4.2.1
ARG FFMPEG_GIT_COMMIT=a619787a9ca87e0c4566cf124d52d23974a440d9
RUN git clone https://github.com/FFmpeg/FFmpeg.git "${TMPDIR}"/FFmpeg
    #cd "${TMPDIR}"/FFmpeg && \
    #git checkout -b "${FFMPEG_GIT_BRANCH}" && \
    #git checkout "${FFMPEG_GIT_COMMIT}" && \
    #git checkout tags/"${FFMPEG_GIT_TAG}" && \

COPY patches/configure-opengl-rpi.patch "${TMPDIR}"/FFmpeg/
COPY patches/ffmpeg-v4l2_m2m.patch "${TMPDIR}"/FFmpeg/libavcodec/
RUN cd "${TMPDIR}"/FFmpeg && patch -f < configure-opengl-rpi.patch
RUN cd "${TMPDIR}"/FFmpeg/libavcodec && patch -f < ffmpeg-v4l2_m2m.patch

## Use --enable-ffplay, but will require libsdl2-dev on target for working ffmpeg
#RUN apt-get update && apt-get install -y libsdl2-dev

## Use --enable-opengl, but will require libgles2-mesa-dev on target for working ffmpeg
#RUN apt-get update && apt-get install -y libgles2-mesa-dev

RUN cp -a /usr/lib/gcc/aarch64-linux-gnu/8/libgomp.a "${PREFIX}"/lib/ && \
    ldconfig

RUN cd "${TMPDIR}"/FFmpeg && \
    export PREFIX="${PREFIX}" && \
    PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig:/opt/vc/lib/pkgconfig \
    ./configure \
    --prefix="${PREFIX}" \
    --pkg-config-flags="--static" \
    --enable-static \
    --arch=aarch64 \
    --target-os=linux \
    --extra-cflags="-mcpu=cortex-a72 -I"${PREFIX}"/include -I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux" \
    --extra-ldflags="-L"${PREFIX}"/lib -L/opt/vc/lib" \
    --extra-libs='-lstdc++ -lpthread -lm -ldl -lz -lrt -lbcm_host -lvcos -lvchiq_arm -lgomp' \
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
    --enable-libv4l2 \
    --enable-v4l2-m2m \
    --enable-nonfree \
    --enable-mmal \
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
