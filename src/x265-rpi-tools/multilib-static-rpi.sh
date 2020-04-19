#!/bin/sh

mkdir -p 8bit 10bit 12bit

cd 12bit
PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig \
cmake ../../../source -DENABLE_SHARED:bool=off -DCMAKE_TOOLCHAIN_FILE=../arm.toolchain.cmake -DMAIN12=ON -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_CLI=OFF -DNUMA_ROOT_DIR=${PREFIX} -DNUMA_INCLUDE_DIR=${PREFIX}/include -DNUMA_LIBRARY=${PREFIX}/lib
make ${MAKEFLAGS}

cd ../10bit
PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
cmake ../../../source -DENABLE_SHARED:bool=off -DCMAKE_TOOLCHAIN_FILE=../arm.toolchain.cmake -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_CLI=OFF -DNUMA_ROOT_DIR=${PREFIX} -DNUMA_INCLUDE_DIR=${PREFIX}/include -DNUMA_LIBRARY=${PREFIX}/lib
make ${MAKEFLAGS}

cd ../8bit
ln -sf ../10bit/libx265.a libx265_main10.a
ln -sf ../12bit/libx265.a libx265_main12.a
PKG_CONFIG_PATH="${PREFIX}"/lib/pkgconfig \
cmake ../../../source -DENABLE_SHARED:bool=off -DCMAKE_TOOLCHAIN_FILE=../arm.toolchain.cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_PREFIX_PATH=${PREFIX} -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DENABLE_CLI=OFF -DNUMA_ROOT_DIR=${PREFIX} -DNUMA_INCLUDE_DIR=${PREFIX}/include -DNUMA_LIBRARY=${PREFIX}/lib
make ${MAKEFLAGS}

# rename the 8bit library, then combine all three into libx265.a
mv libx265.a libx265_main.a

uname=`uname`
if [ "$uname" = "Linux" ]
then

# On Linux, we use GNU ar to combine the static libraries together
ar -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF

else

# Mac/BSD libtool
libtool -static -o libx265.a libx265_main.a libx265_main10.a libx265_main12.a 2>/dev/null

fi
