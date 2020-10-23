if(NOT DEFINED SPOOLDIR OR NOT DEFINED VARMAIL OR NOT DEFINED BINGROUP)
	message(FATAL_ERROR "Insufficient parameters to script")
endif()

execute_process(COMMAND "test" "-d" "${SPOOLDIR}" RESULT_VARIABLE SPOOLDIR_NONEXISTENT OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND "test" "-d" "${VARMAIL}" RESULT_VARIABLE VARMAIL_NONEXISTENT OUTPUT_QUIET ERROR_QUIET)

if(SPOOLDIR_NONEXISTENT)
	file(MAKE_DIRECTORY ${SPOOLDIR})
	execute_process(COMMAND "chgrp" "${BINGROUP}" "${SPOOLDIR}"
					COMMAND "chmod" "2775" "${SPOOLDIR}")
else()
	message(STATUS "${SPOOLDIR} already exists. Skipping this directory.")
endif()

if(VARMAIL_NONEXISTENT)
	file(MAKE_DIRECTORY ${VARMAIL})
	execute_process(COMMAND "chgrp" "${BINGROUP}" "${VARMAIL}"
					COMMAND "chmod" "2775" "${VARMAIL}")
else()
	message(STATUS "${VARMAIL} already exists. Skipping this directory.")
endif()