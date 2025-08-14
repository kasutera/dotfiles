#!/usr/bin/env bash

if [[ "$0" != ./set_home_bin.sh ]]; then
    echo "ERROR: Please run this with ./set_home_bin.sh" >&2
    exit 1
fi

if [[ "${PWD}" != "${HOME}/dotfiles" ]]; then
    echo "ERROR: Please clone this in your \${HOME} directory" >&2
    exit 1
fi

# diff-highlight: find and create wrapper
SEARCH_PATHS=(
    "$(brew --prefix 2>/dev/null)/share/git-core/contrib/diff-highlight/diff-highlight"
    "/usr/local/share/git-core/contrib/diff-highlight/diff-highlight"
)

DIFF_HIGHLIGHT_PATH=""
for path in "${SEARCH_PATHS[@]}"; do
    if [[ -f "${path}" && -x "${path}" ]]; then
        DIFF_HIGHLIGHT_PATH="${path}"
        break
    fi
done

if [[ -z "${DIFF_HIGHLIGHT_PATH}" ]]; then
    echo "ERROR: diff-highlight not found in any standard location" >&2
    exit 1
fi

echo "Found diff-highlight at: ${DIFF_HIGHLIGHT_PATH}"

# Create wrapper script with found path
cat > ~/bin/diff-highlight << EOF
#!/usr/bin/env bash
exec "${DIFF_HIGHLIGHT_PATH}" "\$@"
EOF

chmod +x ~/bin/diff-highlight
