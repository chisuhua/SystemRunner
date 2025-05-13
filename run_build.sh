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
TGT=(all icsc scc sc_example noxim)

[ -z "${BUILD_TYPE}" ] && BUILD_TYPE=Debug

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
      elif [ $arg == rel ]; then
        BUILD_TYPE=RelWithDebInfo
      fi
    fi
  elif echo "${TGT[@]}" | grep -wq "$arg"; then
    if [ $arg != all ]; then
      CMD="${CMD}_$arg"
    fi
  else
    echo "Usage: run_build.sh with argument of ${OPT[@]} or ${TGT[@]}, the all and dbgrel argument is default"
    exit
  fi
done

echo "CMD is $CMD"
CMAKE_COMMON="-DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${BUILD_DIR} -DCMAKE_CXX_STANDARD=${CXX_STD} -DCMAKE_INSTALL_LIBDIR=lib"

##### scc
SCC_CMAKE_SETTING="${CMAKE_COMMON} -DBUILD_SHARED_LIBS=OFF"
SCC_SRC=sc_libs/scc
SCC_BUILD=${BUILD_DIR}/scc
function build_scc {
    cmake -S ${SCC_SRC} -B ${SCC_BUILD} -Wno-dev ${SCC_CMAKE_SETTING} -DENABLE_CONAN=OFF \
        -DBoost_NO_WARN_NEW_VERSIONS=ON -DSCC_LIB_ONLY=OFF
    cmake --build ${SCC_BUILD} --target install -j 2
}
function clean_scc {
  rm -rf ${SCC_BUILD}
}

##### noxim
NOXIM_SRC=sc_libs/noxim
NOXIM_BUILD=${BUILD_DIR}/noxim
function build_noxim {
  cmake -S ${NOXIM_SRC} -B ${NOXIM_BUILD} ${CMAKE_COMMON}
  cmake --build ${NOXIM_BUILD} -j 2
}
function clean_noxim {
  rm -rf ${NOXIM_BUILD}
}


##### sc_example
SC_EXAMPLE_SRC=${ICSC_HOME}
SC_EXAMPLE_BUILD=${BUILD_DIR}/sc_example
function build_sc_example {
    cmake -S ${SC_EXAMPLE_SRC} -B ${SCC_EXAMPLE_BUILD} -Wno-dev ${CMAKE_COMMON}
    cmake --build ${SC_EXAMPLE_BUILD} --target install -j 2
}
function clean_scc {
  rm -rf ${SC_EXAMPLE_BUILD}
}

##### icsc
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
