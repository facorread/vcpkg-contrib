vcpkg_minimum_required(VERSION 2022-10-12)
set(DISTFILE_SHA512_HASH 4e92195fa058c707146f2690f3a38b46c33add948c852f67659ca005a6aa980bbf97be96528b0f8391690facb880ac2126cd60198c6c175e7f3f06cca7e29f9d)

vcpkg_download_distfile(
    DISTFILE
    FILENAME "glpk.tar.gz"
    URLS "https://ftpmirror.gnu.org/gnu/glpk/glpk-${VERSION}.tar.gz" "https://ftp.gnu.org/gnu/glpk/glpk-${VERSION}.tar.gz"
    SHA512 ${DISTFILE_SHA512_HASH}
)

# 2022-12-15 Note: Patching the configure script does not work because the script is replaced when
# vcpkg_configure_make() runs AUTOCONFIG. Instead, try patching configure.ac
vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${DISTFILE}"
    PATCHES
        configure.ac.patch
)

# set(LIBS "")
vcpkg_list(SET CONFIGURE_OPTIONS)
if("dl" IN_LIST FEATURES)
    vcpkg_list(APPEND CONFIGURE_OPTIONS --enable-dl=dlfcn "LIBS=-ldl \$LIBS")
    # 2022-12-15 Note: The following line is misinterpreted by cl.exe as looking for dl.obj or so
    # set(LIBS "dl")
    # 2022-12-15 Note: The following line is misinterpreted by cl.exe as /ldl
    # set(VCPKG_LINKER_FLAGS "${VCPKG_LINKER_FLAGS} -ldl")
else()
    vcpkg_list(APPEND CONFIGURE_OPTIONS --disable-dl)
endif()

if("gmp" IN_LIST FEATURES)
    vcpkg_list(APPEND CONFIGURE_OPTIONS --with-gmp)
else()
    vcpkg_list(APPEND CONFIGURE_OPTIONS --without-gmp)
endif()

if("mysql" IN_LIST FEATURES)
    vcpkg_list(APPEND CONFIGURE_OPTIONS --enable-mysql)
else()
    vcpkg_list(APPEND CONFIGURE_OPTIONS --disable-mysql)
endif()

if("odbc" IN_LIST FEATURES)
    vcpkg_list(APPEND CONFIGURE_OPTIONS --enable-odbc)
else()
    vcpkg_list(APPEND CONFIGURE_OPTIONS --disable-odbc)
endif()

vcpkg_list(APPEND CONFIGURE_OPTIONS
    "CPPFLAGS=-I${CURRENT_INSTALLED_DIR}/include/mysql \$CPPFLAGS"
)

# 2022-12-15 Notes about including w64/config_VC into config.h
# glpk's approach for building on Windows steers away from the functionality provided by Autotools.
# Instead of invoking macros that define __WOE__ depending on the compiler, the documentation
# at w64/readme.txt suggests that the system maintainer should run batch files to build glpk.
# Unfortunately, the provided batch files at w64/ are incompatible with vcpkg.

# With this in mind, we determined that the only viable course of action was
# to add the definitions of __WOE__, TLS, and ODBC_DLNAME to CFLAGS manually as done above.
# Here is some discarded, unmaintained code that did not accomplish this objective:

# file(COPY_FILE "${SOURCE_PATH}/w64/config_VC" "${SOURCE_PATH}/w64/config_VC.h.in")
# set(CONFIG_HEADERS "w64/config_VC.h")

# 2022-12-15 Note: This discarded code was trying to activate definitions from w64/config_VC
# if(DEFINED VCPKG_TARGET_IS_WINDOWS OR DEFINED VCPKG_TARGET_IS_UWP OR DEFINED VCPKG_TARGET_IS_MINGW)
#     set(VCPKG_C_FLAGS "${VCPKG_C_FLAGS} -D__WOE__=1 -DTLS=__declspec\\\\\\(thread\\\\\\)")
#     set(VCPKG_CXX_FLAGS "${VCPKG_CXX_FLAGS} -D__WOE__=1 -DTLS=__declspec\\\\\\(thread\\\\\\)")
#     if("odbc" IN_LIST FEATURES)
#         set(VCPKG_C_FLAGS "${VCPKG_C_FLAGS} -DODBC_DLNAME=odbc32.dll")
#         set(VCPKG_CXX_FLAGS "${VCPKG_CXX_FLAGS} -DODBC_DLNAME=odbc32.dll")
#     endif()
#     if("mysql" IN_LIST FEATURES)
#         set(VCPKG_C_FLAGS "${VCPKG_C_FLAGS} -DMYSQL_DLNAME=libmysql.dll")
#         set(VCPKG_CXX_FLAGS "${VCPKG_CXX_FLAGS} -DMYSQL_DLNAME=libmysql.dll")
#     endif()
# else()
#     set(VCPKG_CXX_FLAGS "${VCPKG_CXX_FLAGS}")
#     set(VCPKG_CXX_FLAGS "${VCPKG_CXX_FLAGS}")
# endif()

vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    AUTOCONFIG
    NO_ADDITIONAL_PATHS
    DETERMINE_BUILD_TRIPLET
    # CONFIGURE_ENVIRONMENT_VARIABLES
        # LIBS
    OPTIONS
        ${CONFIGURE_OPTIONS}
)

vcpkg_install_make()
vcpkg_fixup_pkgconfig()
vcpkg_copy_pdbs()
vcpkg_copy_tools(TOOL_NAMES glpsol AUTO_CLEAN)
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(INSTALL "${SOURCE_PATH}/COPYING" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
