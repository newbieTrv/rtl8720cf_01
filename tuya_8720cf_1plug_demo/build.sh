#!/bin/sh

APP_BIN_NAME=$1
USER_SW_VER=$2
TARGET_PLATFORM=$3
echo APP_BIN_NAME=$APP_BIN_NAME
echo USER_SW_VER=$USER_SW_VER
echo TARGET_PLATFORM=$TARGET_PLATFORM


[ -z $APP_BIN_NAME ] && echo "no app name!" && exit 99
[ -z $USER_SW_VER ] && echo "no version!" && exit 99
[ -z $TARGET_PLATFORM ] && echo "no platform!" && exit 99

set -e

cd `dirname $0`

export APP_DIR=`pwd`
#export APP_INC_DIRS=`shell find ../../sdk -type d`
#export TY_IOT_LIB_LDFLAGS=

#判断是否有CI的输出目录，如果没有，把应用的输出目录作为CI输出目录，作为编译文件的输出位置，供应用开发用
if [ ! -n "$CI_PACKAGE_PATH" ] ;then
    export CI_PACKAGE_PATH="$(pwd)/output/$1_$2"
#创建编译文件输出目录
if [ ! -z output/$1_$2 ]; then
    mkdir -p output/$1_$2
	echo "Create output files"
fi
    echo "not CI build app path=$CI_PACKAGE_PATH"
else
    echo "is CI build the CI packet path is $CI_PACKAGE_PATH"
fi

#******默认每次编译的时候clean应用和开发环境，时间比较长******
#清除开发环境的编译文件
cd ./../../platforms/$TARGET_PLATFORM/project/realtek_amebaz2_v0_example/GCC-RELEASE
make clean
cd ${APP_DIR}
#清除应用的编译文件。!!!注意!!!这里会删除所有应用的“.o”文件。
find ./../../platforms/$TARGET_PLATFORM/tuya_common/ ./$1 -name "*.o" -or -name "*.d" -or -name "*.su"  | xargs rm -f
#******默认clean*end******

echo "***************************************COMPILE START*******************************************"

cd ../../platforms/$TARGET_PLATFORM/project/realtek_amebaz2_v0_example/

#编译应用的话需要去掉“application.is.mk”文件中的“include ../../../../../build/build_param”
sed -i "s/TUYA_BUILD_TYPE=sdk/TUYA_BUILD_TYPE=app/g" ./GCC-RELEASE/application.is.mk
sed -i "s/TUYA_SHELL_APP 1/TUYA_SHELL_APP 0/g" ./inc/platform_opts.h
sed -i "s/TUYA_SHELL_TEST 1/TUYA_SHELL_TEST 0/g" ./../../tuya_common/src/tuya_main.c

sh -x ./build_app.sh $APP_BIN_NAME $USER_SW_VER package
cd -

exit 0

if [ -z $CI_PACKAGE_PATH ]; then
    PACKAGE_PATH=../../output/dist/${APP_BIN_NAME}/${USER_SW_VER}
else
    PACKAGE_PATH=$CI_PACKAGE_PATH
fi

BIN_QIO=${PACKAGE_PATH}/${APP_BIN_NAME}_QIO_$USER_SW_VER.bin
BIN_DOUT=${PACKAGE_PATH}//${APP_BIN_NAME}_DOUT_$USER_SW_VER.bin
BIN2=../../output/${APP_BIN_NAME}_${USER_SW_VER}/boot_all.bin
BIN4=../../output/${APP_BIN_NAME}_${USER_SW_VER}/mp_${APP_BIN_NAME}_\(1\)_$USER_SW_VER.bin
BIN5=../../output/${APP_BIN_NAME}_${USER_SW_VER}/${APP_BIN_NAME}_\(2\)_$USER_SW_VER.bin

mkdir -p ${PACKAGE_PATH}

cp ../../output/${APP_BIN_NAME}_${USER_SW_VER}/${APP_BIN_NAME}_\(1\)_$USER_SW_VER.bin ${PACKAGE_PATH}
cp ../../output/${APP_BIN_NAME}_${USER_SW_VER}/${APP_BIN_NAME}_\(2\)_$USER_SW_VER.bin ${PACKAGE_PATH}

./build/package_2M $BIN_QIO $BIN2 ./build/system_qio_2M.bin $BIN4 $BIN5
echo "package_2M QIO file success"

./build/package_2M $BIN_DOUT $BIN2 ./build/system_dout_2M.bin $BIN4 $BIN5
echo "package DOUT file success"

ls -lh ${PACKAGE_PATH}

echo "***************************************COMPILE SUCCESS!*******************************************"
