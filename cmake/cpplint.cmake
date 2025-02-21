find_file(CPPLINT NAMES cpplint cpplint.exe)
if(CPPLINT)
    # Create the all_lint meta target if it does not exist
    if(NOT TARGET all_lint)
        add_custom_target(all_lint)
        set_target_properties(all_lint PROPERTIES EXCLUDE_FROM_ALL TRUE)
    endif()
    # Define a cmake function for adding a new lint target.
    function(new_linter_target NAME SRC)
        cmake_parse_arguments(
            NEW_LINTER_TARGET
            ""
            ""
            "EXCLUDE_FILTERS"
            ${ARGN})
        # Don't lint external files
        list(FILTER SRC EXCLUDE REGEX "^${FLAMEGPU_ROOT}/externals/.*")
        # Don't lint user provided list of regular expressions.
        foreach(EXCLUDE_FILTER ${NEW_LINTER_TARGET_EXCLUDE_FILTERS})
            list(FILTER SRC EXCLUDE REGEX "${EXCLUDE_FILTER}")
        endforeach()

        # Only lint accepted file type extensions h++, hxx, cuh, cu, c, c++, cxx, cc, hpp, h, cpp, hh
        list(FILTER SRC INCLUDE REGEX ".*\\.(h\\+\\+|hxx|cuh|cu|c|c\\+\\+|cxx|cc|hpp|h|cpp|hh)$")

        # Build a list of arguments to pass to CPPLINT
        LIST(APPEND CPPLINT_ARGS "")

        # Specify output format for msvc highlighting
        if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
            LIST(APPEND CPPLINT_ARGS "--output" "vs7")
        endif()
        # Set the --repository argument if included as a sub project.
        if(NOT CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
            # Use find the repository root via git, to pass to cpplint.
            execute_process(COMMAND git rev-parse --show-toplevel
            WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
            RESULT_VARIABLE git_repo_found
            OUTPUT_VARIABLE abs_repo_root
            OUTPUT_STRIP_TRAILING_WHITESPACE)
            if(git_repo_found EQUAL 0)
                LIST(APPEND CPPLINT_ARGS "--repository=${abs_repo_root}")
            endif()
        endif()
        # Add the lint_ target
        add_custom_target(
            "lint_${PROJECT_NAME}"
            COMMAND ${CPPLINT} ${CPPLINT_ARGS}
            ${SRC}
        )

        # Don't trigger this target on ALL_BUILD or Visual Studio 'Rebuild Solution'
        set_target_properties("lint_${NAME}" PROPERTIES EXCLUDE_FROM_ALL TRUE)
        # Add the custom target as a dependency of the global lint target
        if(TARGET all_lint)
            add_dependencies(all_lint lint_${NAME})
        endif()
        # Put within Lint filter
        if (CMAKE_USE_FOLDERS)
            set_property(GLOBAL PROPERTY USE_FOLDERS ON)
            set_property(TARGET "lint_${PROJECT_NAME}" PROPERTY FOLDER "Lint")
        endif ()
    endfunction()
else()
    # Don't create this message multiple times
    if(NOT COMMAND add_flamegpu_executable)
        message( 
            " cpplint: NOT FOUND!\n"
            " Lint projects will not be generated.\n"
            " Please install cpplint as described on https://pypi.python.org/pypi/cpplint.\n"
            " In most cases command 'pip install --user cpplint' should be sufficient.")
        function(new_linter_target NAME SRC)
        endfunction()
    endif()
endif()