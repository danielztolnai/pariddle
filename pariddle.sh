#!/bin/bash

TOKEN=""
QPA_USER=""
QPA_PASS=""
export QPA_USER QPA_PASS TOKEN

IMG_EXT="pic"
TOOL_DEPS="parallel jq curl"
COLSEP="_"

RIDDLE=${1}
shift

SOLUTIONS=""
for i in "$@"; do
    NEXT_SOLUTION=${i// /${COLSEP}}
    SOLUTIONS="${SOLUTIONS}${NEXT_SOLUTION} "
done

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
        | jq '.[] | select(length > 0) | max_by(.id)' 2>/dev/null)
    RIDDLE_TITLE=$(jq '.title' -r <<< ${RIDDLE_JSON})
    RIDDLE_ID=$(jq '.id' -r <<< ${RIDDLE_JSON})
    RIDDLE_IMG=$(jq '.imageId' -r <<< ${RIDDLE_JSON})
    (>&2 echo -e "Riddle: ${RIDDLE_ID} - ${RIDDLE_TITLE}")
    if [ ! -f "${RIDDLE_ID}.${IMG_EXT}" ]; then
        curl "https://qpa.sch.bme.hu/api/Image/${RIDDLE_IMG}" \
            -H "Authorization: Bearer ${TOKEN}" \
            --compressed \
            -s > "${RIDDLE_ID}.${IMG_EXT}"
    fi
    echo "${RIDDLE_ID}"
}

function solve_riddle() {
    RIDDLE="${1}"
    shift
    SOLUTION="$@"
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
    shift
    SOLUTION="$@"
    printf "%-40s %s\n"  "${SOLUTION}" "$(solve_riddle ${RIDDLE} ${SOLUTION})"
}
export -f print_result

function open_image() {
    IMAGE_FILE="${1}"
    OPEN_CMD="xdg-open"
    if hash "${OPEN_CMD}" &>/dev/null; then
        "${OPEN_CMD}" "${IMAGE_FILE}"
    fi
}

if ! hash ${TOOL_DEPS} &>/dev/null; then
    echo "Missing dependency. Please make sure the following tools are available on your system: ${TOOL_DEPS}"
    exit 1
fi

if [[ -z "${TOKEN}" ]]; then
    TOKEN=$(authenticate)
    if [[ $? -ne 0 ]]; then
        (>&2 echo "Authentication error, check credentials (QPA_USER+QPA_PASS or TOKEN)");
        exit 1
    fi
fi

if [[ "$#" -lt "1" ]]; then
    echo "Usage: $0 [RIDDLE ID] [SOLUTION]..."
    echo "Downloading fresh fun..."
    RIDDLE=$(get_newest)
    open_image "${RIDDLE}.${IMG_EXT}"
    exit 0
fi

if [[ -z "${RIDDLE}" ]]; then
    RIDDLE=$(get_newest)
fi

printf "%-40s %s\n" "Solution" "Response"
echo "-------------------------------------------------"
parallel --colsep "${COLSEP}" print_result ${RIDDLE} ::: ${SOLUTIONS} 2>/dev/null

exit 0
