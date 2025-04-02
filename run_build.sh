#!/bin/bash
##

test -z $ICSC_HOME && { echo "ICSC_HOME is not configured"; exit 1; }
echo "Using ICSC_HOME = $ICSC_HOME"
script_dir=$(cd $(dirname "${BASH_SOURCE[0]}") >/dev/null && pwd)

export CC=$(type -p gcc)
export CXX_STD=17
export CXX=$(type -p g++)
# export SC_VERSION=2.3.4
export SYSTEMC_HOME=${ICSC_HOME}
export SYSTEMCAMS_HOME=${ICSC_HOME}

DISTRO=$(lsb_release -i -s)

BUILD_DIR=build

OPT=(dbg rel dbgrel clean)
TGT=(all icsc scc sc_example)

[ -z "${BUILD_TYPE}" ] && BUILD_TYPE=RelWithDebInfo

CMD="build"

for arg in "$@"; do
  if echo "${OPT[@]}" | grep -wq "$arg"; then
    if [ $arg == clean ]; then
      CMD=clean
    else
      if [ $arg == dbg ]; then
        BUILD_TYPE=Debug
      elif [ $arg == rel ]; then
        BUILD_TYPE=Release
      fi
    fi
  elif echo "${TGT[@]}" | grep -wq "$arg"; then
    if [ $arg != all ]; then
      CMD="${CMD}_$arg"
    fi
  else
    echo "Usage: run_build_scc.sh with argument of ${OPT[@]}"
    exit
  fi
done

echo "CMD is $CMD"

CMAKE_COMMON_SETTINGS="-DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DBUILD_SHARED_LIBS=OFF -DCMAKE_CXX_STANDARD=${CXX_STD} -DCMAKE_INSTALL_LIBDIR=lib"
SCC_SRC=${ICSC_HOME}/scc
SCC_BUILD=${BUILD_DIR}/scc

function build_scc {
    #-DBoost_NO_SYSTEM_PATHS=TRUE -DBOOST_ROOT=${SCC_INSTALL} -DBoost_NO_WARN_NEW_VERSIONS=ON -DSCC_LIB_ONLY=ON || exit 1
    echo "cmake -S ${SCC_SRC} -B build/scc -Wno-dev ${CMAKE_COMMON_SETTINGS} -DENABLE_CONAN=OFF "
    echo "    -DBoost_NO_WARN_NEW_VERSIONS=ON -DSCC_LIB_ONLY=OFF"
    cmake -S ${SCC_SRC} -B ${SCC_BUILD} -Wno-dev ${CMAKE_COMMON_SETTINGS} -DENABLE_CONAN=OFF \
        -DBoost_NO_WARN_NEW_VERSIONS=ON -DSCC_LIB_ONLY=OFF
    cmake --build ${SCC_BUILD} --target install -j 2
}
function clean_scc {
  rm -rf ${SCC_BUILD}
}

CMAKE_COMMON_SETTINGS="-DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_CXX_STANDARD=${CXX_STD} -DCMAKE_INSTALL_LIBDIR=lib"
SC_EXAMPLE_SRC=${ICSC_HOME}
SC_EXAMPLE_BUILD=${BUILD_DIR}/sc_example
function build_sc_example {
    cmake -S ${SC_EXAMPLE_SRC} -B ${SCC_EXAMPLE_BUILD} -Wno-dev ${CMAKE_COMMON_SETTINGS}
    cmake --build ${SC_EXAMPLE_BUILD} --target install -j 2
}
function clean_scc {
  rm -rf ${SC_EXAMPLE_BUILD}
}

function build_icsc {
  echo "running build_icsc"
  ${ICSC_HOME}/icsc/install_icsc.sh
}

function build {
  build_sc_example
  build_scc
}

function clean {
  clean_scc
  clean_sc_example
}

$CMD
