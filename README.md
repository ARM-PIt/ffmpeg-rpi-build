# ffmpeg-rpi-build

Dockerized builder for ffmpeg to be used with Raspberry Pi 4 on armhf architecture in Debian 10 or Raspbian Buster. As is, the resulting deb package from 'docker build ...' provides a static ffmpeg binary under /usr/local/bin.

## Usage

Docker build and run commands to create debian package and copy to local artifact directory.

### compile and build .deb package

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

### Raspberry Pi OS 64 + GL support

GL support has yet to make its way into Raspberry Pi OS 64 as it is in beta. Since firmware lacks brcmEGL and brcmGLESv2 resources, support for this has been removed from ffmpeg compile options. When these are added the following can be reintroduced:  

* ```./configure...--extra-libs=...-lbrcmGLESv2 -lbrcmEGL...```
* ```./configure...--enable-mmal...```
