#!/bin/bash

# Reads Claude Code status line JSON from stdin and prints three lines:
#   1. full pwd (with git branch, if inside a repo)
#   2. context usage bar + model + effort level
#   3. 5h / 7d rate limit usage with local reset times

input=$(cat)

# Colors
CYAN='\033[36m'
MAGENTA='\033[95m'
YELLOW='\033[33m'
WHITE='\033[37m'
GREEN='\033[92m'
DIM='\033[90m'
RESET='\033[0m'

# Format a unix epoch as local time. Handles both BSD date (-r) and GNU
# coreutils date (-d @epoch), since Homebrew coreutils may shadow /bin/date.
fmt_epoch() {
    date -r "$1" +"$2" 2>/dev/null || date -d "@$1" +"$2" 2>/dev/null
}

# --- Line 1: full pwd + git branch ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
# Abbreviate $HOME as ~. Done with case rather than ${cwd/#$HOME/~} because
# bash 5 tilde-expands the replacement while bash 3.2 keeps the escaping
# backslash -- neither gives a plain "~".
case "$cwd" in
"$HOME") display_dir="~" ;;
"$HOME"/*) display_dir="~${cwd#"$HOME"}" ;;
*) display_dir="$cwd" ;;
esac

branch=""
track=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
        branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    fi

    # Ahead/behind vs the upstream tracking ref. This is purely local -- it
    # reflects the last fetch, not the live remote (no network in a status line).
    if counts=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count 'HEAD...@{upstream}' 2>/dev/null); then
        ahead=${counts%%[[:space:]]*}
        behind=${counts##*[[:space:]]}
        [ "$ahead" -gt 0 ] 2>/dev/null && track="${track} ${GREEN}↑${ahead}${RESET}"
        [ "$behind" -gt 0 ] 2>/dev/null && track="${track} ${YELLOW}↓${behind}${RESET}"
    else
        # No upstream configured for this branch.
        track=" ${WHITE}(no upstream)${RESET}"
    fi
fi

if [ -n "$branch" ]; then
    line1=$(printf "${CYAN}%s${RESET} ${MAGENTA}%s${RESET}%b" "$display_dir" "$branch" "$track")
else
    line1=$(printf "${CYAN}%s${RESET}" "$display_dir")
fi

# --- Line 2: context bar + model + effort level ---
model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level')
used=$(echo "$input" | jq -r '.context_window.used_percentage')
session_id=$(echo "$input" | jq -r '.session_id // empty')

bar_width=10
filled=$(awk -v u="$used" -v w="$bar_width" 'BEGIN{v=int((u/100)*w+0.5); if(v<0)v=0; if(v>w)v=w; print v}')
empty=$((bar_width - filled))

bar=""
for ((i = 0; i < filled; i++)); do bar="${bar}#"; done
for ((i = 0; i < empty; i++)); do bar="${bar}-"; done

used_rounded=$(awk -v u="$used" 'BEGIN{printf "%.0f", u}')

line2=$(printf "${WHITE}[%s] %s%%${RESET} ${YELLOW}%s${RESET} ${GREEN}(%s)${RESET}" \
    "$bar" "$used_rounded" "$model" "$effort")
if [ -n "$session_id" ]; then
    line2="${line2}$(printf " ${DIM}%s${RESET}" "$session_id")"
fi

# --- Line 3: 5h / 7d rate limits ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

rate_parts=()
if [ -n "$five_pct" ] && [ -n "$five_reset" ]; then
    five_pct_r=$(awk -v p="$five_pct" 'BEGIN{printf "%.0f", p}')
    five_time=$(fmt_epoch "$five_reset" %H:%M)
    rate_parts+=("5h ${five_pct_r}% (resets ${five_time})")
fi
if [ -n "$week_pct" ] && [ -n "$week_reset" ]; then
    week_pct_r=$(awk -v p="$week_pct" 'BEGIN{printf "%.0f", p}')
    week_time=$(fmt_epoch "$week_reset" "%m/%d %H:%M")
    rate_parts+=("7d ${week_pct_r}% (resets ${week_time})")
fi

line3=""
if [ "${#rate_parts[@]}" -eq 2 ]; then
    line3=$(printf "${WHITE}%s / %s${RESET}" "${rate_parts[0]}" "${rate_parts[1]}")
elif [ "${#rate_parts[@]}" -eq 1 ]; then
    line3=$(printf "${WHITE}%s${RESET}" "${rate_parts[0]}")
fi

echo -e "$line1"
echo -e "$line2"
if [ -n "$line3" ]; then
    echo -e "$line3"
fi
