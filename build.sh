#!/bin/bash
# -*- coding: utf-8 -*-

test -z $ICSC_HOME && { echo "ICSC_HOME is not configured"; exit 1; }
echo "Using ICSC_HOME = $ICSC_HOME"

#export CXX=g++-11
#export CXX_STD=17
export CC=$(type -p gcc)
export CXX_STD=17
export CXX=$(type -p g++)

export SYSTEMC_HOME=${ICSC_HOME}
export SYSTEMCAMS_HOME=${ICSC_HOME}

SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") >/dev/null && pwd)
BUILD_DIR=$SCRIPT_DIR/build

THREADS=$(nproc)

BUILD_OPT=(dbg rel dbgrel)
RUN=(build clean run gdb)
OPT=(n)
TGT=(all icsc scc sc_example sc_nose noxim)

# default option
[ -z "${BUILD_TYPE}" ] && BUILD_TYPE=Debug
[ -z "${BUILD_CMD}" ] && CMD=build

function Usage {
    echo "Usage: run_build.sh with one below argument"
    echo "       the argument ${RUN[@]}: build is the default"
    echo "       the argument ${BUILD_OPT[@]}: build option, dbgrel is the default"
    echo "       the argument ${TGT[@]}: the target will be built, all is default"
    echo "       the argument n: will print the run command but not executed"
    exit
}

BUILD_ARG=
NORUN=n

function is_in_list() {
  local target="$1"
  shift
  local list=("$@")

  for item in "${list[@]}"; do
    if [[ "$item" == "$target" ]]; then
      return 0
    fi
  done

  return 1
}

if [ -z "$1" ]; then
  echo "using default action: build"
else
  if is_in_list "$1" "${RUN[@]}"; then
    CMD=$1
    echo "will running $CMD $BUILD_ARG"
    shift
  fi
fi

for arg in "$@"; do
  if [ ${arg:0:1} == "-" ]; then
    Usage
  elif [ "$arg" == "n" ]; then
    NORUN=y
  elif echo "${BUILD_OPT[@]}" | grep -wq "$arg"; then
    if [ $arg == dbg ]; then
      BUILD_TYPE=Debug
    elif [ $arg == rel ]; then
      BUILD_TYPE=Release
    elif [ $arg == reldbg ]; then
      BUILD_TYPE=RelWithDebInfo
    fi
  elif echo "${TGT[@]}" | grep -wq "$arg"; then
    if [ $arg != all ]; then
      CMD="${CMD}_$arg"
    fi
  elif echo "${OPT[@]}" | grep -wq "$arg"; then
    BUILD_ARG+="$arg "
  else
    Usage
  fi
done

echo "will running $CMD $BUILD_ARG"

function run_cmd {
   echo $1;
   if [ "$NORUN" != "y" ]; then
     eval $1 || { echo "Failed to run $1"; exit 1;}
   fi
}

##### scc
CMAKE_COMMON="-DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${BUILD_DIR} -DCMAKE_CXX_STANDARD=${CXX_STD} -DCMAKE_INSTALL_LIBDIR=lib"
SCC_CMAKE_SETTING="${CMAKE_COMMON} -DBUILD_SHARED_LIBS=OFF"

SCC_SRC=sc_libs/scc
SCC_BUILD=${BUILD_DIR}/scc
function build_scc {
    run_cmd "cmake -S ${SCC_SRC} -B ${SCC_BUILD} -Wno-dev ${SCC_CMAKE_SETTING} -DENABLE_CONAN=OFF \
        -DBoost_NO_WARN_NEW_VERSIONS=ON -DSCC_LIB_ONLY=OFF"
    run_cmd "cmake --build ${SCC_BUILD} --target install -j 2"
}

function clean_scc {
    rm -rf ${SCC_BUILD}
}


##### noxim
NOXIM_SRC=sc_libs/noxim
NOXIM_BUILD=${BUILD_DIR}/noxim
function build_noxim {
    run_cmd "cmake -S ${NOXIM_SRC} -B ${NOXIM_BUILD} ${CMAKE_COMMON}"
    run_cmd "cmake --build ${NOXIM_BUILD} -j 2"
}
function clean_noxim {
    run_cmd "rm -rf ${NOXIM_BUILD}"
}


##### sc_example
SC_EXAMPLE_SRC=${ICSC_HOME}
SC_EXAMPLE_BUILD=${BUILD_DIR}/sc_example
function build_sc_example {
    run_cmd "cmake -S ${SC_EXAMPLE_SRC} -B ${SCC_EXAMPLE_BUILD} -Wno-dev ${CMAKE_COMMON}"
    run_cmd "cmake --build ${SC_EXAMPLE_BUILD} --target install -j 2"
}
function clean_scc {
    run_cmd "rm -rf ${SC_EXAMPLE_BUILD}"
}

##### icsc
function build_icsc {
    echo "running build_icsc"
    ${ICSC_HOME}/icsc/install_icsc.sh
}

##### sc_nose
CMAKE_COMMON="-DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
NOSE_SRC=external/nose
SCNOSE_SRC=sc_libs/sc_nose
NOSE_BUILD=${BUILD_DIR}/sc_nose
function build_sc_nose {
	  run_cmd "cmake -S ${NOSE_SRC} -B ${NOSE_BUILD} ${CMAKE_COMMON}"
	  run_cmd "cmake --build ${NOSE_BUILD} -j 2"
}

function clean_sc_nose {
    rm -rf $NOSE_BUILD
}

########################################
function build {
    build_scc $@
    build_noxim $@
    build_scnose $@
    build_sc_example $@
}

function clean {
    clean_scc
    clean_noxim
    clean_scnose
}

echo "running $CMD $@"
$CMD $@
