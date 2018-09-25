#!/bin/bash

TOKEN=""
QPA_USER=""
QPA_PASS=""
export QPA_USER QPA_PASS TOKEN

RIDDLE=${1}
shift
SOLUTIONS="$@"

function authenticate() {
    curl 'https://qpa.sch.bme.hu/api/Auth/Login' \
        -H 'Content-Type: application/json-patch+json' \
        --data-binary "{\"email\":\"${QPA_USER}\",\"password\":\"${QPA_PASS}\"}" \
        --compressed \
        -s \
        | jq '.jwt.authToken' -r 2>/dev/null
}

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
    TOKEN=$(authenticate)
    if [[ $? -ne 0 ]]; then
        (>&2 echo "Authentication error, check credentials (QPA_USER+QPA_PASS or TOKEN)");
        exit 1
    fi
fi

printf "%-40s %s\n" "Solution" "Response"
echo "-------------------------------------------------"
parallel --no-notice print_result ${RIDDLE} ::: ${SOLUTIONS}

exit 0
