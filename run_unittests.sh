#!/bin/bash

LINE="========================================"

USAGE="Usage: $(basename $0) <VERBOSITY[01]> [<EXPRESSION(S)>]

One or more regular expressions can be passed to select certain tests.
Grep (standard syntax) is used to match the test include string."

main()
{
    # Eval inargs
    if [[ $# -lt 1 ]]
    then
        echo "${USAGE}"
        exit 1
    fi
    case ${1} in
      ( 0 ) VB1=false ;;
      ( 1 ) VB1=true ;;
      ( * ) echo "${USAGE}"; exit 1;;
    esac
    shift
    EXPR_LIST=($@)

    # Add lib and test dirs to Python PATH
    export PYTHONPATH=$PWD/lib:$PWD/test:$PYTHONPATH

    # Collect tests; make list global
    local test_dir="."
    [ -d "./test" ] && test_dir="./test"
    TEST_LIST=($(collect_tests "${test_dir}"))
    ${VB1} && print_tests

    run_tests
    print_results
}

collect_tests()
{
    local test_dirs="$@"
    local test_list=($(find_all_tests "${test_dirs}"))

    # Find and return all tests matching any expression
    if [[ "${#EXPR_LIST[@]}" -gt 0 ]]
    then
        match_list=()
        for expr in "${EXPR_LIST[@]}"
        do
            for test in "${test_list[@]}"
            do
                \echo "${test}" | \grep -q "${expr}"
                [[ $? -eq 0 ]] && match_list+=("${test}")
            done
        done
        test_list=("${match_list[@]}")
    fi

    # Sort test list and remove duplicates
    test_list=($(echo "${test_list[@]}" | tr ' ' '\n' | sort -u))

    # Order tests: move those containing ".unit." to the beginning
    local test_list_unit=()
    local test_list_rest=()
    for test in "${test_list[@]}"
    do
        \echo "${test}" | \grep -q "\.unit\."
        if [[ $? -eq 0 ]]
        then
            test_list_unit+=("${test}")
        else
            test_list_rest+=("${test}")
        fi
    done
    echo "${test_list_unit[@]}" "${test_list_rest[@]}"
}

find_all_tests()
{
    local test_dirs="$@"
    \find "${test_dirs}" -name 'test_*.py' | \
            \sed -e "s@${test_dir}/\(.*\).py@\1@" -e "s@/@.@g"
}

print_tests()
{
    echo "${LINE}"
    echo "TESTS:"
    for test in "${TEST_LIST[@]}"
    do
        echo " ${test##*.}"
    done
    echo "${LINE}"
}

run_tests()
{
    ${VB1} && echo "${LINE}"
    local result_list=() timing_list=()
    local i=0 time_file="time.tmp"
    local time_start="$(\date +%s%2N)"
    local stat
    for test in ${TEST_LIST[@]}
    do
        ${VB1} && echo "RUNNING TEST '${test}'"
        ${VB1} && echo "${LINE}"
        \time -f %E -o "${time_file}" \
                exec_silent $(toggle ${VB1}) python3 -m "${test}"
        result_list[i]=$?
        timing_list[i]=$(\tail -n1 "${time_file}")
        # For minimal output, show the result immediately
        # For verbose output, show the results all in the end
        if ! ${VB1}
        then
            [[ ${result_list[i]} -eq 0 ]] && stat="OK" || stat="FAIL"
            print_test_result "${stat}" "${timing_list[i]}" "${test}"
        fi
        i=$((i+1))
        ${VB1} && echo "${LINE}"
    done
    \rm -f "${time_file}"
    local time_end="$(\date +%s%2N)"
    RESULT_LIST=(${result_list[@]})
    TIMING_LIST=(${timing_list[@]})
    unset result timing
    TIMING_TOT=$((time_end-time_start))
}

print_results()
{
    local n=$(echo "${#TEST_LIST[@]}-1" | \bc -l)
    ${VB1} && echo "RESULTS"
    ${VB1} && echo "${LINE}"
    local stat_tot="OK"
    for i in $(seq 0 ${n})
    do
        local res="${RESULT_LIST[i]}" test="${TEST_LIST[i]}"
        local time="${TIMING_LIST[i]}" stat="OK"
        if [[ ${res} -ne 0 ]]
        then
            stat="FAIL"
            stat_tot="${stat}"
        fi
        # For verbose output, show the results all in the end
        ${VB1} && print_test_result "${stat}" "${time}" "${test}"
    done
    local time_min="$(printf %01i $(( TIMING_TOT / 6000 )))"
    local time_sec="$(printf %02i $(( TIMING_TOT /  100 )))"
    local time_mic="$(printf %02i $(( TIMING_TOT %  100 )))"
    local time_tot="${time_min}:${time_sec}.${time_mic}"
    print_test_result "${stat_tot}" "${time_tot}" "TOTAL"
    ${VB1} && echo "${LINE}"
}

print_test_result()
{
    local stat="$1" time="$2" test="$3"
    case ${#stat} in
      ( 2 ) stat="   ${stat}  " ;;
      ( 3 ) stat="  ${stat}  " ;;
      ( 4 ) stat="  ${stat} " ;;
      ( 5 ) stat=" ${stat} " ;;
    esac
    echo "[${stat}] (${time}) ${test}"
}
main "$@"
