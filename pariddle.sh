#!/bin/bash

TOKEN=""
COOKIE=""
export TOKEN COOKIE

RIDDLE=${1}
shift
SOLUTIONS="$@"

function solve_riddle() {
    RIDDLE="${1}"
    SOLUTION="${2}"
    curl "https://qpa.sch.bme.hu/riddles/${RIDDLE}/solve" \
        -H "${COOKIE}" \
        -H 'Origin: https://qpa.sch.bme.hu' \
        -H 'Accept-Encoding: gzip, deflate, br' \
        -H 'Accept-Language: en-GB,en;q=0.8,en-US;q=0.6,hu;q=0.4' \
        -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
        -H 'Accept: application/json, text/javascript, */*; q=0.01' \
        -H "Referer: https://qpa.sch.bme.hu/riddles/${RIDDLE}" \
        -H 'X-Requested-With: XMLHttpRequest' \
        -H 'Connection: keep-alive' \
        --data "_token=${TOKEN}&solution=${SOLUTION}" \
        --compressed \
        -s \
        | jq '.success' -r
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

if [[ -z "${TOKEN}" ]] || [[ -z "${COOKIE}" ]]; then
    echo "Token and/or cookie is missing. Please set variables TOKEN and COOKIE. You can copy the data from your browser."
    exit 1
fi

printf "%-40s %s\n" "Solution" "Response"
echo "-------------------------------------------------"
parallel print_result ${RIDDLE} ::: ${SOLUTIONS}

exit 0
