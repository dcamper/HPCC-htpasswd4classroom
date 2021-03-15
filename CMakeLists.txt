################################################################################
#    HPCC SYSTEMS software Copyright (C) 2020 HPCC Systems®.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
################################################################################

cmake_minimum_required(VERSION 3.13.0)

project(htpasswd4ClassroomSecurity)

#############################################
# Begin common compiler settings extracted from platform's cmake_modules/commonSetup.cmake
#############################################

if ("${CMAKE_BUILD_TYPE}" STREQUAL "")
  set ( CMAKE_BUILD_TYPE "Release" )
elseif (NOT "${CMAKE_BUILD_TYPE}" MATCHES "^Debug$|^Release$|^RelWithDebInfo$")
  message (FATAL_ERROR "Unknown build type ${CMAKE_BUILD_TYPE}")
endif ()

if (CMAKE_SIZEOF_VOID_P EQUAL 8)
  set ( ARCH64BIT 1 )
else ()
  set ( ARCH64BIT 0 )
endif ()

set (CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -D_DEBUG -DDEBUG")

IF (USE_INLINE_TSC)
  add_definitions (-DINLINE_GET_CYCLES_NOW)
ENDIF()

if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
 set (CMAKE_COMPILER_IS_CLANGXX 1)
endif()
if ("${CMAKE_C_COMPILER_ID}" MATCHES "Clang")
 set (CMAKE_COMPILER_IS_CLANG 1)
endif()
if ((CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_CLANG) AND (NOT ${CMAKE_C_COMPILER_VERSION} MATCHES "[0-9]+\\.[0-9]+\\.[0-9]+"))
    execute_process(COMMAND ${CMAKE_C_COMPILER} -dumpversion OUTPUT_VARIABLE CMAKE_C_COMPILER_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
endif ()
if ((CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANGXX) AND (NOT ${CMAKE_CXX_COMPILER_VERSION} MATCHES "[0-9]+\\.[0-9]+\\.[0-9]+"))
    execute_process(COMMAND ${CMAKE_CXX_COMPILER} -dumpversion OUTPUT_VARIABLE CMAKE_CXX_COMPILER_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()
if (CMAKE_COMPILER_IS_GNUCC AND NOT CMAKE_BUILD_TYPE STREQUAL "Debug" AND NOT CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
  add_definitions (-fvisibility=hidden)
endif ()
if (CMAKE_COMPILER_IS_CLANGXX)
  execute_process( COMMAND ${CMAKE_CXX_COMPILER} --version OUTPUT_VARIABLE clang_full_version_string )
  if (${clang_full_version_string} MATCHES "Apple LLVM version ([0-9]+\\.[0-9]+\\.[0-9]+).*")
    string (REGEX REPLACE "Apple LLVM version ([0-9]+\\.[0-9]+\\.[0-9]+).*" "\\1" APPLE_CLANG_VERSION ${clang_full_version_string})
  endif()
  if (${clang_full_version_string} MATCHES ".*based on LLVM ([0-9]+\\.[0-9]+).*")
    string (REGEX REPLACE ".*based on LLVM ([0-9]+\\.[0-9]+).*" "\\1" CLANG_VERSION ${clang_full_version_string})
  else()
    if (${clang_full_version_string} MATCHES ".*clang version ([0-9]+\\.[0-9]+).*")
      string (REGEX REPLACE ".*clang version ([0-9]+\\.[0-9]+).*" "\\1" CLANG_VERSION ${clang_full_version_string})
    endif()
  endif()
endif ()

if (WIN32)
  message (FATAL_ERROR "Windows builds are not supported")
else ()
  if (CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANGXX)
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -frtti -fPIC -fmessage-length=0 -Werror=format -Wformat-security -Wformat-nonliteral -Wuninitialized")
    SET (CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -rdynamic")
    SET (CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -g -fno-inline-functions")
    if (CMAKE_COMPILER_IS_GNUCXX)
      SET (CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -g -fno-default-inline")
      if (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.2.4 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 4.2.4)
        SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=return-type -Werror=format-nonliteral")
      endif ()
      if (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.4.0 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 4.4.0)
        SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-psabi")
      endif ()
      if (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 2.95.3 OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 2.95.3)
        SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wparentheses")
      endif ()
    endif ()
    SET (CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELEASE}")
    SET (CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELEASE}")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    # Handle forced default char type
    if (USE_SIGNED_CHAR AND USE_UNSIGNED_CHAR )
      message (FATAL_ERROR "Can't use USE_SIGNED_CHAR and USE_UNSIGNED_CHAR together!")
    else()
      if (USE_SIGNED_CHAR)
          SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsigned-char")
      endif ()
      if (USE_UNSIGNED_CHAR )
          SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -funsigned-char")
      endif ()
    endif ()
  endif ()
  if (CMAKE_COMPILER_IS_CLANGXX)
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=logical-op-parentheses -Werror=bool-conversions -Werror=return-type -Werror=comment")
    if (APPLE)
      SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
      SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations")
    endif ()
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}  -Werror=bitwise-op-parentheses -Werror=tautological-compare")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}  -Wno-switch-enum -Wno-format-zero-length -Wno-switch")
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}  -Qunused-arguments")  # Silence messages about pthread not being used when linking...
    SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}  -Wno-inconsistent-missing-override -Wno-unknown-warning-option")  # Until we fix them all, whcih would be a huge task...
    if (CLANG_VERSION VERSION_GREATER 3.6 OR CLANG_VERSION VERSION_EQUAL 3.6 OR APPLE_CLANG_VERSION VERSION_GREATER 6.0)
      SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-pointer-bool-conversion")
    endif()
  endif()
  # All of these are defined in platform.h too, but need to be defined before any system header is included
  ADD_DEFINITIONS (-D_LARGEFILE_SOURCE=1 -D_LARGEFILE64_SOURCE=1 -D_FILE_OFFSET_BITS=64 -D__USE_LARGEFILE64=1 -D__USE_FILE_OFFSET64=1)
  if ("${GIT_COMMAND}" STREQUAL "")
      set ( GIT_COMMAND "git" )
  endif ()
endif ()

#############################################
# End common compiler settings extracted from platform's cmake_modules/commonSetup.cmake
#############################################

if(APPLE)
  set(CMAKE_MACOSX_RPATH ON)
endif()

# Define the root directory of installed HPCC Systems code
set(HPCC_RUNTIME_DIR "/opt/HPCCSystems"
    CACHE PATH "Home directory of the installed HPCC Systems code")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${HPCC_RUNTIME_DIR})

# Important HPCC Systems subdirectories
set(HPCC_LIB_DIR "${HPCC_RUNTIME_DIR}/lib")
set(HPCC_EXEC_DIR "${HPCC_RUNTIME_DIR}/bin")

add_subdirectory(configxml)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${HPCC_SOURCE_DIR}/cmake_modules")
find_package(APR REQUIRED)

set(SRCS
    "${HPCC_SOURCE_DIR}/system/security/shared/authmap.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/htpasswd4ClassroomSecurity.cpp")

include_directories ("${HPCC_SOURCE_DIR}/system/include"
                     "${HPCC_SOURCE_DIR}/system/security/shared"
                     "${HPCC_SOURCE_DIR}/system/jlib"
                     "${HPCC_SOURCE_DIR}/esp/platform"
                     "${HPCC_SOURCE_DIR}/dali/base"
                     "${APR_INCLUDE_DIR}"
                     "${APRUTIL_INCLUDE_DIR}")

ADD_DEFINITIONS(-DHTPASSWD4CLASSROOMSECURITY_EXPORTS -D_USRDLL)

# Add HPCC Systems installed local library directory to search path
set(CMAKE_INSTALL_RPATH "${HPCC_LIB_DIR}")
link_directories(htpasswd4ClassroomSecurity "${HPCC_LIB_DIR}")

add_library(htpasswd4ClassroomSecurity SHARED ${SRCS})

install(TARGETS htpasswd4ClassroomSecurity
        RUNTIME DESTINATION "${HPCC_EXEC_DIR}"
        LIBRARY DESTINATION "${HPCC_LIB_DIR}"
        ARCHIVE DESTINATION "${HPCC_LIB_DIR}")

target_link_libraries(htpasswd4ClassroomSecurity
                      PRIVATE jlib
                      PRIVATE ${APR_LIBRARIES}
                      PRIVATE ${APRUTIL_LIBRARIES})

################################################################################
# cpack
################################################################################

set(majorver "1")
set(minorver "0")
set(pointver "0")
set(vendorname "HPCC Systems")

set(CPACK_PACKAGE_VENDOR "${vendorname}®")
set(CPACK_PACKAGE_VENDOR_WITHOUT_TRADEMARK "${vendorname}")

set(CPACK_PACKAGE_NAME "htpasswd4ClassroomSecurity")
set(CPACK_PACKAGE_VERSION_MAJOR "${majorver}")
set(CPACK_PACKAGE_VERSION_MINOR "${minorver}")
set(CPACK_PACKAGE_VERSION_PATCH "${pointver}")
set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
set(CPACK_SOURCE_GENERATOR TGZ)
set(CPACK_PACKAGE_CONTACT "Dan S. Camper <dan.camper@lexisnexisrisk.com>")

set(CPACK_PACKAGING_INSTALL_PREFIX "${HPCC_RUNTIME_DIR}")

if("${CPACK_RPM_PACKAGE_ARCHITECTURE}" STREQUAL "i686")
    set(CPACK_RPM_PACKAGE_ARCHITECTURE "i386")
endif()

set(CPACK_SYSTEM_NAME "${CMAKE_SYSTEM_NAME}-${CPACK_RPM_PACKAGE_ARCHITECTURE}")
if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
    set(CPACK_STRIP_FILES TRUE)
endif()

get_filename_component(ABS_HPCC_SOURCE_DIR "${HPCC_SOURCE_DIR}" ABSOLUTE)

execute_process(
    COMMAND "${ABS_HPCC_SOURCE_DIR}/cmake_modules/distrocheck.sh"
    OUTPUT_VARIABLE packageManagement
    ERROR_VARIABLE  packageManagement)
execute_process(
    COMMAND "${ABS_HPCC_SOURCE_DIR}/cmake_modules/getpackagerevisionarch.sh"
    OUTPUT_VARIABLE packageRevisionArch
    ERROR_VARIABLE  packageRevisionArch)

message("-- Auto Detecting Packaging type")
message("-- distro uses ${packageManagement}, revision is ${packageRevisionArch}")

set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}_${packageRevisionArch}")

if("${packageManagement}" STREQUAL "DEB")
    set(CPACK_GENERATOR "${packageManagement}")
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${vendorname}")
    # Standard sections values:
    # https://www.debian.org/doc/debian-policy/ch-archive.html/#s-subsections
    set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
elseif("${packageManagement}" STREQUAL "RPM")
    set(CPACK_GENERATOR "${packageManagement}")
    set(CPACK_RPM_PACKAGE_AUTOREQ "0")
    set(CPACK_RPM_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION}")
    set(CPACK_RPM_PACKAGE_RELEASE "1")
    set(CPACK_RPM_PACKAGE_VENDOR "${vendorname}®")
    set(CPACK_RPM_PACKAGE_ARCHITECTURE ${CMAKE_SYSTEM_PROCESSOR})
    # Standard group names: http://fedoraroject.org/wiki/RPMGroups
    set(CPACK_RPM_PACKAGE_GROUP "development/system")
    set(CPACK_RPM_PACKAGE_SUMMARY "${CPACK_PACKAGE_NAME}")
    set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION /opt)
else()
    message("WARNING: Unsupported package ${packageManagement}.")
endif ()

include(CPack)
