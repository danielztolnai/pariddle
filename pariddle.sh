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

function get_newest() {
    RIDDLE_JSON=$(curl 'https://qpa.sch.bme.hu/api/Riddle/GetVisible' \
        -H "Authorization: Bearer ${TOKEN}" \
        --compressed \
        -s \
        | jq '.[] | max_by(.id)' 2>/dev/null)
    RIDDLE_TITLE=$(jq '.title' -r <<< ${RIDDLE_JSON})
    RIDDLE_ID=$(jq '.id' -r <<< ${RIDDLE_JSON})
    RIDDLE_IMG=$(jq '.imageId' -r <<< ${RIDDLE_JSON})
    (>&2 echo -e "Riddle: ${RIDDLE_ID} - ${RIDDLE_TITLE}\n")
    if [ ! -f "${RIDDLE_ID}.jpg" ]; then
        curl "https://qpa.sch.bme.hu/api/Image/${RIDDLE_IMG}" \
            -H "Authorization: Bearer ${TOKEN}" \
            --compressed \
            -s > "${RIDDLE_ID}.jpg"
    fi
    echo "${RIDDLE_ID}"
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

if [[ -z "${RIDDLE}" ]]; then
    RIDDLE=$(get_newest)
fi

printf "%-40s %s\n" "Solution" "Response"
echo "-------------------------------------------------"
parallel --no-notice print_result ${RIDDLE} ::: ${SOLUTIONS}

exit 0
