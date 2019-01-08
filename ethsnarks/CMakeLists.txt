cmake_minimum_required(VERSION 3.9)

project(ethsnarks)


include(CTest)
enable_testing()


set(
  CURVE
  "ALT_BN128"
  CACHE
  STRING
  "Default curve: one of ALT_BN128, BN128, EDWARDS, MNT4, MNT6"
)

set(
  DEPENDS_DIR
  "${CMAKE_CURRENT_SOURCE_DIR}/depends"
  CACHE
  STRING
  "Optionally specify the dependency installation directory relative to the source directory (default: inside dependency folder)"
)

set(
  DEPENDS_DIR_LIBSNARK
  "${CMAKE_CURRENT_SOURCE_DIR}/depends/libsnark/"
  CACHE
  STRING
  "Optionally specify the dependency installation directory relative to the source directory (default: inside dependency folder)"
)

set(
  DEPENDS_DIR_LIBFF
  "${DEPENDS_DIR_LIBSNARK}/depends/libff/"
  CACHE
  STRING
  "Optionally specify the dependency installation directory relative to the source directory (default: inside dependency folder)"
)

set(
  DEPENDS_DIR_LIBFQFFT
  "${DEPENDS_DIR_LIBSNARK}/depends/libfqfft/"
  CACHE
  STRING
  "Optionally specify the dependency installation directory relative to the source directory (default: inside dependency folder)"
)

set(
  OPT_FLAGS
  ""
  CACHE
  STRING
  "Override C++ compiler optimization flags"
)

option(
  MULTICORE
  "Enable parallelized execution, using OpenMP"
  OFF
)

option(
  USE_MIXED_ADDITION
  "Convert each element of the key pair to affine coordinates"
  OFF
)

option(
  BINARY_OUTPUT
  "Use binary output for serialisation"
  ON
)

option(
  MONTGOMERY_OUTPUT
  "Serialize Fp elements as their Montgomery representations (faster but not human-readable)"
  ON
)

option(
  USE_ASM
  "Use architecture-specific optimized assembly code"
  OFF
)


option(
  PERFORMANCE
  "Enable link-time and aggressive optimizations"
  OFF
)

option(
  WITH_PROCPS
  "Use procps for memory profiling"
  OFF
)

option(
  DEBUG
  "Enable debugging mode"
  OFF
)

option(
  CPPDEBUG
  "Enable debugging of C++ STL (does not imply DEBUG)"
  OFF
)


add_definitions(-DCURVE_${CURVE})

if(${CURVE} STREQUAL "BN128")
  add_definitions(-DBN_SUPPORT_SNARK=1)
endif()

if("${MULTICORE}")
  find_package(OpenMP REQUIRED)
  add_definitions(-DMULTICORE=1)
endif()

if("${USE_ASM}")
  add_definitions(-DUSE_ASM)
endif()

if("${BINARY_OUTPUT}")
  add_definitions(-DBINARY_OUTPUT)
endif()

if("${MONTGOMERY_OUTPUT}")
  add_definitions(-DMONTGOMERY_OUTPUT)
endif()

if(NOT "${USE_PT_COMPRESSION}")
  add_definitions(-DNO_PT_COMPRESSION=1)
endif()

if("${PERFORMANCE}")
  include(CheckIPOSupported)
  check_ipo_supported()
  set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

if("${USE_MIXED_ADDITION}")
  add_definitions(-DUSE_MIXED_ADDITION=1)
endif()

if("${CPPDEBUG}")
  add_definitions(-D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC)
endif()

include(FindPkgConfig)
if("${WITH_PROCPS}")
  pkg_check_modules(
    PROCPS
    REQUIRED

    libprocps
  )
else()
  add_definitions(
    -DNO_PROCPS
  )
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
  # Common compilation flags and warning configuration
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wfatal-errors -Wno-unused-variable")
    # Default optimizations flags (to override, use -DOPT_FLAGS=...)
endif()


# Locate the gmp library and its includes
find_path(GMP_INCLUDE_DIR NAMES gmp.h)
find_library(GMP_LIBRARY gmp)
if(GMP_LIBRARY MATCHES ${CMAKE_SHARED_LIBRARY_SUFFIX})
  set(gmp_library_type SHARED)
else()
  set(gmp_library_type STATIC)
endif()
message(STATUS "GMP: ${GMP_LIBRARY}, ${GMP_INCLUDE_DIR}")
add_library(GMP::gmp ${gmp_library_type} IMPORTED)
set_target_properties(
  GMP::gmp PROPERTIES
  IMPORTED_LOCATION ${GMP_LIBRARY}
  INTERFACE_INCLUDE_DIRECTORIES ${GMP_INCLUDE_DIR}
)


# Locate the gmpxx library and its includes
find_path(GMPXX_INCLUDE_DIR gmpxx.h)
find_library(GMPXX_LIBRARY gmpxx)
if(GMPXX_LIBRARY MATCHES ${CMAKE_SHARED_LIBRARY_SUFFIX})
  set(gmpxx_library_type SHARED)
else()
  set(gmpxx_library_type STATIC)
endif()
add_library(GMP::gmpxx ${gmpxx_library_type} IMPORTED)
message(STATUS "GMPxx: ${GMPXX_LIBRARY}, ${GMPXX_INCLUDE_DIR}")
set_target_properties(
  GMP::gmpxx PROPERTIES
  IMPORTED_LOCATION ${GMPXX_LIBRARY}
  INTERFACE_INCLUDE_DIRECTORIES ${GMPXX_INCLUDE_DIR}
)


add_compile_options(-fPIC)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OPT_FLAGS}")

include(FindPkgConfig)
if("${WITH_PROCPS}")
  pkg_check_modules(PROCPS REQUIRED libprocps)
else()
  add_definitions(-DNO_PROCPS)
endif()

set(OPENSSL_ROOT_DIR /usr/local/opt/openssl/)
find_package(OpenSSL REQUIRED)


add_library(
  ff
  STATIC

  ${DEPENDS_DIR_LIBFF}/libff/algebra/curves/alt_bn128/alt_bn128_g1.cpp
  ${DEPENDS_DIR_LIBFF}/libff/algebra/curves/alt_bn128/alt_bn128_g2.cpp
  ${DEPENDS_DIR_LIBFF}/libff/algebra/curves/alt_bn128/alt_bn128_init.cpp
  ${DEPENDS_DIR_LIBFF}/libff/algebra/curves/alt_bn128/alt_bn128_pairing.cpp
  ${DEPENDS_DIR_LIBFF}/libff/algebra/curves/alt_bn128/alt_bn128_pp.cpp
  ${DEPENDS_DIR_LIBFF}/libff/common/double.cpp
  ${DEPENDS_DIR_LIBFF}/libff/common/profiling.cpp
  ${DEPENDS_DIR_LIBFF}/libff/common/utils.cpp
)

target_include_directories(ff PUBLIC
  ${DEPENDS_DIR_LIBSNARK} ${DEPENDS_DIR_LIBFF} ${DEPENDS_DIR_LIBFQFFT})
target_compile_features(ff PUBLIC cxx_std_11)


if("${DEBUG}" OR "${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  add_definitions(-DDEBUG=1)
  target_compile_definitions(ff PUBLIC DEBUG=1)
endif()

target_include_directories(ff INTERFACE
  ${DEPENDS_DIR_LIBSNARK} ${DEPENDS_DIR_LIBFF} ${DEPENDS_DIR_LIBFQFFT})
target_compile_features(ff INTERFACE cxx_std_11)

target_link_libraries(ff GMP::gmp ${PROCPS_LIBRARIES})

if(OpenMP_CXX_FOUND)
    target_link_libraries(ff OpenMP::OpenMP_CXX)
endif()

add_subdirectory(src)
