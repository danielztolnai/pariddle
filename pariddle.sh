#!/bin/bash

TOKEN=""
export TOKEN

RIDDLE=${1}
shift
SOLUTIONS="$@"

function solve_riddle() {
    RIDDLE="${1}"
    SOLUTION="${2}"
    curl 'https://qpa.sch.bme.hu/api/Riddle/Guess' \
        -H "Authorization: Bearer ${TOKEN}" \
        -H 'Content-Type: application/json' \
        --data-binary "{\"guess\":\"${SOLUTION}\",\"riddleId\":\"${RIDDLE}\"}" \
        --compressed \
        -s \
        | jq '.wasCorrect' -r
}
export -f solve_riddle

function print_result() {
    RIDDLE="${1}"
    SOLUTION="${2}"
    printf "%-40s %s\n"  "${SOLUTION}" "$(solve_riddle ${RIDDLE} ${SOLUTION})"
}
export -f print_result

if [[ "$#" -lt "1" ]]; then
    echo "Usage: $0 [RIDDLE ID] [SOLUTION]..."
    exit 0
fi

if [[ -z "${TOKEN}" ]]; then
    echo "Token is missing. Please set the variable TOKEN. You can copy the data from your browser."
    exit 1
fi

printf "%-40s %s\n" "Solution" "Response"
echo "-------------------------------------------------"
parallel --no-notice print_result ${RIDDLE} ::: ${SOLUTIONS}

exit 0
