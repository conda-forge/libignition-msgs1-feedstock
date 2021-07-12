#!/bin/sh

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 ]]; then
  (
    mkdir -p build-host
    pushd build-host

    export CC=$CC_FOR_BUILD
    export CXX=$CXX_FOR_BUILD
    export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}

    # Unset them as we're ok with builds that are either slow or non-portable
    unset CFLAGS
    unset CXXFLAGS

    cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=$BUILD_PREFIX -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True \
      -DINSTALL_IGN_MSGS_GEN_EXECUTABLE:BOOL=ON

    cmake --build . --parallel ${CPU_COUNT} --config Release
    cmake --build . --parallel ${CPU_COUNT} --config Release --target install
  )
fi

mkdir build
cd build

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" == "1" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc -DIGN_MSGS_GEN_EXECUTABLE:BOOL=$BUILD_PREFIX/bin/ign_msgs_gen"
fi

cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=$PREFIX -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True

cmake --build . --config Release
cmake --build . --config Release --target install
export CTEST_OUTPUT_ON_FAILURE=1
if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
  ctest -C Release -E "INTEGRATION|PERFORMANCE|REGRESSION"
fi
