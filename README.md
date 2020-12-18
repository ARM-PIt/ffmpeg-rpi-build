# ffmpeg-rpi-build

Dockerized builder for ffmpeg to be used with Raspberry Pi 4 on aarch64 architecture in Debian or Raspberry Pi OS 64-bit.  

## Usage

The build process is broken up into two parts: One image to build the necessary static libraries ```ffmpeg-static-libraries```, and one to compile FFmpeg and build a .deb package using the static libraries image.  

### compile and build image with static libraries

```
docker build -t armpit/ffmpeg-static-libraries:latest ffmpeg-static-libraries
```

### compile and build ffmpeg and .deb package

```
docker build -t armpit/ffmpeg-rpi-build:latest .
```

### run and copy deb to ./artifact

```
docker run \
  -v "$(pwd)"/artifact:/artifact \
  -it armpit/ffmpeg-rpi-build:latest \
  /bin/bash -c "/bin/cp /*.deb /artifact/"
```

## Build Options

Features which can be toggled for the build

### OpenGL support

* uncomment RUN step for installing `libgles2-mesa-dev`
* switch the `--disable-opengl` to `--enable-opengl` under ffmpeg configure flags
* the target OS will also need `libgles2-mesa-dev`

### ffplay support

* uncomment RUN step for installing `libsdl2-dev`
* switch the `--disable-ffplay` to `--enable-ffplay` under ffmpeg configure flags
* uncomment the line `cp -a "${PREFIX}"/bin/ffplay /ffmpeg_"${FFMPEG_DEB_VERSION}"/usr/local/bin/ && \` in the final RUN step for building the deb package
* the target OS will also need `libsdl2-dev`

### Raspberry Pi OS 64 + GL/MMAL support

GL support has yet to make its way into Raspberry Pi OS 64 as it is in beta. Since firmware lacks brcmEGL and brcmGLESv2 resources, support for this has been removed from ffmpeg compile options. When these are added the following can be reintroduced:  

* ```./configure...--extra-libs=...-lbrcmGLESv2 -lbrcmEGL...```

MMAL support existed at one point in the userland repository, but was removed. This build is set to use the last commit in userland that contained mmal support. As this was removed from userland for being problematic, YMMV. To use latest userland and disable mmal, remove the following line from ffmpeg-static-libraries/Dockerfile:  

* ```git checkout "${USERLAND_GIT_COMMIT}"```

And remove the mmal flag from the ffmpeg-rpi-build/Dockerfile:

* ```./configure...--enable-mmal...```
