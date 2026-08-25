#!/usr/bin/env bash

SKILL_ROOT="${PWD}/src/.agents/skills"
SKILL_CONFIG="${PWD}/src/.agents/skill-destinations.sh"

skill_error() {
    echo "ERROR: $*" >&2
    exit 1
}

skill() {
    [[ $# -eq 2 ]] || skill_error "skill expects a name and destination"

    local name="$1" path="$2"
    local source="${SKILL_ROOT}/${name}"
    local destination="${HOME}/${path}/${name}"

    [[ "${name}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] ||
        skill_error "Invalid skill name: ${name}"
    case "${path}" in
    .agents/skills | .claude/skills) ;;
    *) skill_error "Unsupported skill destination: ${path}" ;;
    esac
    [[ -d "${source}" ]] || skill_error "Missing skill: ${name}"
    [[ -f "${source}/SKILL.md" ]] || skill_error "Missing SKILL.md for skill: ${name}"

    if [[ "${SKILL_MODE}" == validate ]]; then
        ((SKILL_COUNT += 1))
        return
    fi

    mkdir -p "${destination%/*}"
    if { [[ -e "${destination}" ]] || [[ -L "${destination}" ]]; } &&
        ! diff -qr "${source}" "${destination}"; then
        read -rp "Overwrite ${destination} ? [y/N]: " yn
        if [[ "${yn}" != [yY] ]]; then
            echo "continue"
            return
        fi
        echo "ok"
    fi

    if [[ -L "${destination}" ]]; then
        unlink "${destination}"
    elif [[ -e "${destination}" ]]; then
        rm -rf "${destination}"
    fi
    ln -s "${source}" "${destination}"
}

skill_is_configured() (
    local wanted="$1"

    skill() {
        [[ "$1" == "${wanted}" ]] && exit 0
    }

    # shellcheck source=src/.agents/skill-destinations.sh
    source "${SKILL_CONFIG}"
    exit 1
)

validate_skill_destinations() {
    [[ -f "${SKILL_CONFIG}" ]] || skill_error "Missing ${SKILL_CONFIG}"

    (
        SKILL_MODE=validate
        SKILL_COUNT=0
        # shellcheck source=src/.agents/skill-destinations.sh
        source "${SKILL_CONFIG}"
        ((SKILL_COUNT)) || skill_error "No skill destinations configured"
    )

    local source
    for source in "${SKILL_ROOT}"/*; do
        [[ ! -d "${source}" ]] || skill_is_configured "${source##*/}" ||
            skill_error "No destination configured for skill: ${source##*/}"
    done
}

install_skills() {
    SKILL_MODE=install
    # shellcheck source=src/.agents/skill-destinations.sh
    source "${SKILL_CONFIG}"
}
