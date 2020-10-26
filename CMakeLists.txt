# Cmake 3.4 brought the OpenSSL::SSL and OpenSSL::Crypto targets
cmake_minimum_required (VERSION 3.4)

project ("dma" LANGUAGES C)

include(CheckLibraryExists)

set(BINOWNER "root")
set(DMA_MAIL_USER "mail")
set(BINGROUP "mail")

#######################################################################################################
#	Check if usernames and groups exist
#	The "mail" group should actually exist everywhere, but on e.g. FreeBSD there's just a "mailnull" user
#######################################################################################################
if(NOT DEFINED ENV{MAIL_GROUP})
	message(CHECK_START "Checking for group ${BINGROUP}")
	execute_process(COMMAND "getent" "group" "${BINGROUP}" RESULT_VARIABLE NO_MAIL_GROUP OUTPUT_QUIET ERROR_QUIET)
	if(NO_MAIL_GROUP)
		#Try mailnull
		message(CHECK_FAIL "not found")
		list(APPEND CMAKE_MESSAGE_INDENT "  ")
		message(CHECK_START "Checking for substitute group mailnull")
		execute_process(COMMAND "getent" "group" "mailnull" RESULT_VARIABLE NO_MAILNULL_GROUP OUTPUT_QUIET ERROR_QUIET)
		if(NO_MAILNULL_GROUP)
			message(CHECK_FAIL "not found")
			message(FATAL_ERROR "Neither \"${BINGROUP}\" nor \"mailnull\" exists. Aborting.\n"
					"Consider creating a new group and supplying it by running:\n"
					"shell$$ MAIL_GROUP=newgroup cmake ..")
		endif()
		message(CHECK_PASS "found")
		list(POP_BACK CMAKE_MESSAGE_INDENT)
		set(BINGROUP "mailnull")
	else()
		message(CHECK_PASS "found")
	endif()
else()
	message(CHECK_START "Checking for group $ENV{MAIL_GROUP}")
	execute_process(COMMAND "getent" "group" "$ENV{MAIL_GROUP}" RESULT_VARIABLE NO_MAIL_GROUP OUTPUT_QUIET ERROR_QUIET)
	if(NO_MAIL_GROUP)
		message(CHECK_FAIL "not found")
		message(FATAL_ERROR "Supplied group $ENV{MAIL_GROUP} doesn't exist'")
	else()
		message(CHECK_PASS "found")
		set(BINGROUP $ENV{MAIL_GROUP})
	endif()
endif()

if(NOT DEFINED ENV{MAIL_USER})
	message(CHECK_START "Checking for user ${DMA_MAIL_USER}")
	execute_process(COMMAND "getent" "passwd" "${DMA_MAIL_USER}" RESULT_VARIABLE NO_MAIL_USER OUTPUT_QUIET ERROR_QUIET)
	if(NO_MAIL_USER)
		#Try mailnull
		message(CHECK_FAIL "not found")
		list(APPEND CMAKE_MESSAGE_INDENT "  ")
		message(CHECK_START "Checking for substitute user mailnull")
		execute_process(COMMAND "getent" "passwd" "mailnull" RESULT_VARIABLE NO_MAILNULL_USER OUTPUT_QUIET ERROR_QUIET)
		if(NO_MAILNULL_USER)
			message(CHECK_FAIL "not found")
			message(FATAL_ERROR "Neither \"${DMA_MAIL_USER}\" nor \"mailnull\" exists. Aborting.\n"
					"Consider creating a username and supplying it by running:\n"
					"shell$$ MAIL_USER=newusername cmake ..")
		endif()
		message(CHECK_PASS "found")
		list(POP_BACK CMAKE_MESSAGE_INDENT)
		set(DMA_MAIL_USER "mailnull")
	else()
		message(CHECK_PASS "found")
	endif()
else()
	message(CHECK_START "Checking for user $ENV{MAIL_USER}")
	execute_process(COMMAND "getent" "passwd" "$ENV{MAIL_USER}" RESULT_VARIABLE NO_MAIL_USER OUTPUT_QUIET ERROR_QUIET)
	if(NO_MAIL_USER)
		message(CHECK_FAIL "not found")
		message(FATAL_ERROR "Supplied user $ENV{MAIL_USER} doesn't exist'")
	else()
		message(CHECK_PASS "found")
		set(DMA_MAIL_USER $ENV{MAIL_USER})
	endif()
endif()

#######################################################################################################
#	Get version
#######################################################################################################
message(CHECK_START "Retrieving version")
execute_process(COMMAND "sh" "get-version.sh" WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} OUTPUT_VARIABLE DMA_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
message(CHECK_PASS "${DMA_VERSION}")

#######################################################################################################
#	YACC and FLEX targets
#######################################################################################################
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR})
find_package(YACC REQUIRED)
find_package(FLEX REQUIRED)

BISON_TARGET(aliases_parser aliases_parse.y ${CMAKE_CURRENT_BINARY_DIR}/aliases_parse.c COMPILE_FLAGS "-b aliases_")
FLEX_TARGET(aliases_scan aliases_scan.l ${CMAKE_CURRENT_BINARY_DIR}/aliases_scan.c)
ADD_FLEX_BISON_DEPENDENCY(aliases_scan aliases_parser)

BISON_TARGET(auth_parser auth_parse.y ${CMAKE_CURRENT_BINARY_DIR}/auth_parse.c COMPILE_FLAGS "-p auth_ -b auth_")
FLEX_TARGET(auth_scan auth_scan.l ${CMAKE_CURRENT_BINARY_DIR}/auth_scan.c)
ADD_FLEX_BISON_DEPENDENCY(auth_scan auth_parser)

BISON_TARGET(conf_parser conf_parse.y ${CMAKE_CURRENT_BINARY_DIR}/conf_parse.c COMPILE_FLAGS "-p conf_ -b conf_")
FLEX_TARGET(conf_scan conf_scan.l ${CMAKE_CURRENT_BINARY_DIR}/conf_scan.c)
ADD_FLEX_BISON_DEPENDENCY(conf_scan conf_parser)

#######################################################################################################
#	Targets and corresponding settings
#######################################################################################################
add_executable (dma
	"dma.c"
	"base64.c"
	"conf.c"
	"crypto.c"
	"dns.c"
	"local.c"
	"mail.c"
	"net.c"
	"spool.c"
	"util.c"
	${BISON_aliases_parser_OUTPUTS}
    ${FLEX_aliases_scan_OUTPUTS}
	${BISON_conf_parser_OUTPUTS}
    ${FLEX_conf_scan_OUTPUTS}
	${BISON_auth_parser_OUTPUTS}
    ${FLEX_auth_scan_OUTPUTS}
	)

add_executable(dma-mbox-create "dma-mbox-create.c")

target_include_directories(dma PRIVATE ${CMAKE_CURRENT_BINARY_DIR} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

set_target_properties(dma dma-mbox-create PROPERTIES C_STANDARD 11 C_STANDARD_REQUIRED ON)

if(UNIX)
#######################################################################################################
#	Some UNIX-defaults
#######################################################################################################
	set(BINMODE_DMA "2755")
	set(BINMODE_DMA_MBOX_CREATE "4754")
	if(NOT DEFINED ENV{BINPATH})
		set(BINPATH "sbin")
	else()
		set(BINPATH $ENV{BINPATH})
	endif()
	if(NOT DEFINED ENV{CONF_PATH})
		set(CONF_PATH "/etc/dma")
	else()
		set(CONF_PATH $ENV{CONF_PATH})
	endif()
	if(NOT DEFINED ENV{LIBEXEC})
		set(LIBEXEC "${CMAKE_INSTALL_PREFIX}/lib")
	else()
		set(LIBEXEC $ENV{LIBEXEC})
	endif()
	if(NOT DEFINED ENV{MAN})
		set(MAN "${CMAKE_INSTALL_PREFIX}/share/man")
	else()
		set(MAN $ENV{MAN})
	endif()
	if(DEFINED ENV{FORCE_DFCOMPAT})
		#Mainly for debugging dfcompat
		message(STATUS "FORCE_DFCOMPAT set, using dfcompat")
		target_sources(dma PRIVATE dfcompat.c)
		target_compile_definitions(dma PRIVATE USE_COMPAT_BSDFUNCTIONS)
		set(FORCE_DFCOMPAT TRUE)
	endif()
	if(NOT DEFINED ENV{SPOOLDIR})
		set(SPOOLDIR "/var/spool/dma")
	else()
		set(SPOOLDIR $ENV{SPOOLDIR})
	endif()
	if(NOT DEFINED ENV{VARMAIL})
		set(VARMAIL "/var/mail")
	else()
		set(VARMAIL $ENV{VARMAIL})
	endif()

	#Generate spooldirs
	add_custom_target(install-spool-dirs
			COMMAND ${CMAKE_COMMAND} -DSPOOLDIR=${SPOOLDIR} -DVARMAIL=${VARMAIL} -DBINGROUP=${BINGROUP} -P "${CMAKE_CURRENT_SOURCE_DIR}/install-spool-dirs.cmake"
			COMMENT "Creating spooldirs ${SPOOLDIR} and ${VARMAIL}"
		)
	
	#######################################################################################################
	#	Linux-specific settings
	#######################################################################################################
	if(CMAKE_SYSTEM_NAME MATCHES "Linux")
		message(STATUS "Linux system detected (${CMAKE_SYSTEM_NAME})")
		#Check for libbsd only if FORCE_DFCOMPAT has not been set
		if(NOT FORCE_DFCOMPAT)
			message(CHECK_START "Checking for libbsd")
			find_library(LIBBSD bsd)
			find_path(LIBBSD_INCLUDE_DIR bsd.h PATH_SUFFIXES bsd)
			get_filename_component(LIBBSD_LIBDIR ${LIBBSD} DIRECTORY)
			if(LIBBSD AND LIBBSD_INCLUDE_DIR)
				CHECK_LIBRARY_EXISTS("${LIBBSD}" "reallocf" ${LIBBSD_LIBDIR} HAVE_LIBBSD_REALLOCF)
				CHECK_LIBRARY_EXISTS("${LIBBSD}" "strlcpy" ${LIBBSD_LIBDIR} HAVE_LIBBSD_STRLCPY)
				CHECK_LIBRARY_EXISTS("${LIBBSD}" "getprogname" ${LIBBSD_LIBDIR} HAVE_LIBBSD_GETPROGNAME)
			endif()
			if(NOT (HAVE_LIBBSD_REALLOCF AND HAVE_LIBBSD_STRLCPY AND HAVE_LIBBSD_GETPROGNAME)
					OR NOT LIBBSD_INCLUDE_DIR)
				message(CHECK_FAIL "not found")
				message(STATUS "Using dfcompat")
				target_sources(dma PRIVATE dfcompat.c)
				target_compile_definitions(dma PRIVATE USE_COMPAT_BSDFUNCTIONS)
			else()
				message(CHECK_PASS "found")
				message(STATUS "Using libbsd found at ${LIBBSD} with includes in ${LIBBSD_INCLUDE_DIR}")
				target_link_libraries(dma PRIVATE ${LIBBSD})
				target_include_directories(dma SYSTEM PRIVATE ${LIBBSD_INCLUDE_DIR})
				target_compile_definitions(dma PRIVATE LIBBSD_OVERLAY)
			endif()			
		endif()

		message(CHECK_START "Checking for libresolv")
		find_library(LIBRESOLV resolv REQUIRED)
		message(CHECK_PASS "found")
		target_link_libraries(dma PRIVATE ${LIBRESOLV})

		#Certain Linux-specific targets. On *BSD /etc/mail/mailer.conf should take care of these links
		
		add_custom_target(sendmail-link
			COMMAND ${CMAKE_COMMAND} -E create_symlink "${CMAKE_INSTALL_PREFIX}/${BINPATH}/dma" "${CMAKE_INSTALL_PREFIX}/${BINPATH}/sendmail"
			COMMENT "Creating link from ${CMAKE_INSTALL_PREFIX}/${BINPATH}/sendmail to ${CMAKE_INSTALL_PREFIX}/${BINPATH}/dma"
		)
		add_custom_target(mailq-link
			COMMAND ${CMAKE_COMMAND} -E create_symlink "${CMAKE_INSTALL_PREFIX}/${BINPATH}/dma" "${CMAKE_INSTALL_PREFIX}/${BINPATH}/mailq"
			COMMENT "Creating link from ${CMAKE_INSTALL_PREFIX}/${BINPATH}/mailq to ${CMAKE_INSTALL_PREFIX}/${BINPATH}/dma"
		)
	elseif(CMAKE_SYSTEM_NAME MATCHES "BSD" OR CMAKE_SYSTEM_NAME MATCHES "DragonFly")
	#######################################################################################################
	#	*BSD overrides from the default
	#######################################################################################################
		message(STATUS "BSD system detected (${CMAKE_SYSTEM_NAME})")
		#Just checking whether the env-vars are not set. If set, though, they have already been defined above
		if(NOT DEFINED ENV{CONF_PATH})
			set(CONF_PATH "${CMAKE_INSTALL_PREFIX}/etc/dma")		#Defaults to /usr/local/etc/dma
		endif()
		if(NOT DEFINED ENV{LIBEXEC})
			set(LIBEXEC "${CMAKE_INSTALL_PREFIX}/libexec")
		endif()
		if(NOT DEFINED ENV{BINPATH})
			set(BINPATH "libexec")
		endif()

		set(BINMODE_DMA "2555")
		set(BINMODE_DMA_MBOX_CREATE "4554")
	elseif(CMAKE_SYSTEM_NAME MATCHES "SunOS")
	#######################################################################################################
	#	SunOS based (OpenSolaris, ...)
	#######################################################################################################
		message(STATUS "SunOS system detected (${CMAKE_SYSTEM_NAME})")
		find_library(LIBSOCKET socket REQUIRED)
		find_library(LIBNSL nsl REQUIRED)
		find_library(LIBRESOLV resolv REQUIRED)

		target_compile_definitions(dma PRIVATE NEED_ROUNDUP_COMPAT)
		target_link_libraries(dma PRIVATE ${LIBSOCKET} PRIVATE ${LIBNSL} PRIVATE ${LIBRESOLV})
	else()
	#######################################################################################################
	#	Maybe add some specific rules for other operating systems here
	#######################################################################################################
		message(WARNING "Unknown system detected (${CMAKE_SYSTEM_NAME}). Trying UNIX-defaults.")
	endif()

	#######################################################################################################
	#	Generic Installation Rules
	#######################################################################################################
	install(TARGETS dma RUNTIME DESTINATION ${BINPATH})
	install(FILES "dma.8" DESTINATION ${MAN}/man8)

	#Check if config files already exist
	#We'll not overwrite them in this case
	#CMAKE's built-in if(EXISTS filename) reports a file as non-existent even though it is only not readable
	#So we need to rely on the POSIX test utility.

	execute_process(COMMAND "test" "-f" "${CONF_PATH}/dma.conf" RESULT_VARIABLE DMA_CONF_NONEXISTENT OUTPUT_QUIET ERROR_QUIET)
	if(DMA_CONF_NONEXISTENT)
		install(FILES "dma.conf" DESTINATION ${CONF_PATH})
	else()
		install(CODE "message(\"Keeping existing dma.conf in ${CONF_PATH}.\")")
	endif()

	execute_process(COMMAND "test" "-f" "${CONF_PATH}/auth.conf" RESULT_VARIABLE AUTH_CONF_NONEXISTENT OUTPUT_QUIET ERROR_QUIET)
	if(AUTH_CONF_NONEXISTENT)
		install(FILES "auth.conf" DESTINATION ${CONF_PATH} PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ)
		install(CODE "execute_process(COMMAND \"chgrp\" \"${BINGROUP}\" \"${CONF_PATH}/auth.conf\")")
	else()
		install(CODE "message(\"Keeping existing auth.conf in ${CONF_PATH}.\")")
	endif()

	install(TARGETS dma-mbox-create RUNTIME DESTINATION ${LIBEXEC})
	install(CODE "execute_process(COMMAND \"chgrp\" \"${BINGROUP}\" \"${CMAKE_INSTALL_PREFIX}/${BINPATH}/dma\")")
	install(CODE "execute_process(COMMAND \"chown\" \"${BINOWNER}\" \"${CMAKE_INSTALL_PREFIX}/${BINPATH}/dma\")")
	install(CODE "execute_process(COMMAND \"chmod\" \"${BINMODE_DMA}\" \"${CMAKE_INSTALL_PREFIX}/${BINPATH}/dma\")")
	install(CODE "execute_process(COMMAND \"chgrp\" \"${BINGROUP}\" \"${LIBEXEC}/dma-mbox-create\")")
	install(CODE "execute_process(COMMAND \"chown\" \"${BINOWNER}\" \"${LIBEXEC}/dma-mbox-create\")")
	install(CODE "execute_process(COMMAND \"chmod\" \"${BINMODE_DMA_MBOX_CREATE}\" \"${LIBEXEC}/dma-mbox-create\")")


else()
	#######################################################################################################
	#	NO UNIX --> just abort
	#######################################################################################################
	message(FATAL_ERROR "No UNIX system detected. Aborting.")
endif()

#######################################################################################################
#	OpenSSL, compiler settings and defines
#######################################################################################################

find_package(OpenSSL REQUIRED)
target_link_libraries(dma PRIVATE OpenSSL::SSL PRIVATE OpenSSL::Crypto)
target_include_directories(dma PRIVATE ${OPENSSL_INCLUDE_DIR})
target_include_directories(dma-mbox-create PRIVATE ${OPENSSL_INCLUDE_DIR})

include(CheckCCompilerFlag)
CHECK_C_COMPILER_FLAG("-Wno-format-truncation" SUPPORTS_NO_FORMAT_TRUNCATION)
if(SUPPORTS_NO_FORMAT_TRUNCATION)
	message(STATUS "Disabling -Wformat-truncation")
	target_compile_options(dma PRIVATE "-Wno-format-truncation")
endif()

target_compile_options(dma PRIVATE -Wall -Wextra)
target_compile_options(dma-mbox-create PRIVATE -Wall -Wextra)
target_compile_definitions(dma PRIVATE CONF_PATH="${CONF_PATH}" LIBEXEC_PATH="${LIBEXEC}" DMA_VERSION="${DMA_VERSION}" DMA_GROUP="${BINGROUP}" DMA_ROOT_USER="${DMA_MAIL_USER}")
target_compile_definitions(dma-mbox-create PRIVATE CONF_PATH="${CONF_PATH}" LIBEXEC_PATH="${LIBEXEC}" DMA_VERSION="${DMA_VERSION}" DMA_GROUP="${BINGROUP}" DMA_ROOT_USER="${DMA_MAIL_USER}")
