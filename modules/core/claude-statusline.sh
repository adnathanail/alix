#!/bin/bash
# Claude Code statusline
# Single line, truecolor: repo | branch | context tokens | cost | velocity | model

input=$(cat)

RESET=$'\033[0m'
SEP_COLOR=$'\033[2;38;2;90;90;90m'
BOLD_YELLOW=$'\033[1;38;2;230;200;60m'
BOLD_CYAN=$'\033[1;38;2;60;200;220m'
YELLOW=$'\033[38;2;230;200;60m'
GREEN=$'\033[38;2;70;200;90m'
RED=$'\033[38;2;220;70;60m'
MAGENTA=$'\033[38;2;200;90;200m'
LIGHT_GRAY=$'\033[38;2;130;130;130m'

SEP="${SEP_COLOR} | ${RESET}"

# --- repo name ---
repo_name=$(echo "$input" | jq -r '.workspace.repo.name // empty')
if [ -z "$repo_name" ]; then
  project_dir=$(echo "$input" | jq -r '.workspace.project_dir // .cwd')
  repo_name=$(basename "$project_dir")
fi

# --- git branch (skip optional locks) ---
cwd=$(echo "$input" | jq -r '.cwd')
branch=$(git --no-optional-locks -C "$cwd" branch --show-current 2>/dev/null)

# --- context usage in tokens ---
total_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')

# Gradient reaches red at the autocompact window size (not the raw model
# context window), since that's when Claude Code actually compacts.
# Read autoCompactWindow from settings, highest precedence first; fall back to
# the model's real context window if the setting is absent everywhere.
AUTOCOMPACT_WINDOW=""
for settings_file in \
  "$cwd/.claude/settings.local.json" \
  "$cwd/.claude/settings.json" \
  "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"; do
  [ -f "$settings_file" ] || continue
  val=$(jq -r '.autoCompactWindow // empty' "$settings_file" 2>/dev/null)
  if [ -n "$val" ]; then
    AUTOCOMPACT_WINDOW="$val"
    break
  fi
done
if [ -z "$AUTOCOMPACT_WINDOW" ]; then
  AUTOCOMPACT_WINDOW=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
fi
used_pct=$(awk -v t="$total_tokens" -v w="$AUTOCOMPACT_WINDOW" 'BEGIN{printf "%.4f", (w>0? t/w*100 : 0)}')

tokens_fmt=$(awk -v t="$total_tokens" 'BEGIN{printf "%.1fk tokens", t/1000}')

ctx_color=$(awk -v p="$used_pct" 'BEGIN{
  g1r=0;   g1g=200; g1b=80;
  y1r=220; y1g=200; y1b=0;
  r1r=220; r1g=40;  r1b=20;
  if (p < 0) p = 0;
  if (p > 100) p = 100;
  if (p <= 50) {
    f = p/50;
    r = g1r + (y1r-g1r)*f;
    g = g1g + (y1g-g1g)*f;
    b = g1b + (y1b-g1b)*f;
  } else {
    f = (p-50)/50;
    r = y1r + (r1r-y1r)*f;
    g = y1g + (r1g-y1g)*f;
    b = y1b + (r1b-y1b)*f;
  }
  printf "\033[38;2;%d;%d;%dm", r, g, b;
}')

# --- session cost ---
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
cost_fmt=$(awk -v c="$cost" 'BEGIN{printf "$%.2f", c}')

# --- code velocity ---
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# --- model ---
model_name=$(echo "$input" | jq -r '.model.display_name // "unknown"')
effort_level=$(echo "$input" | jq -r '.effort.level // empty')

# --- session quota usage ---
session_quota_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
session_quota_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# --- assemble ---
out="${BOLD_YELLOW}${repo_name}${RESET}"

if [ -n "$branch" ]; then
  out="${out}${SEP}${BOLD_CYAN}(${branch})${RESET}"
fi

out="${out}${SEP}${ctx_color}${tokens_fmt}${RESET}"
out="${out}${SEP}${YELLOW}${cost_fmt}${RESET}"
out="${out}${SEP}${GREEN}+${lines_added}${RESET} ${RED}-${lines_removed}${RESET}"

model_out="${model_name}"
if [ -n "$effort_level" ]; then
  model_out="${model_out} (${effort_level})"
fi
out="${out}${SEP}${MAGENTA}${model_out}${RESET}"

if [ -n "$session_quota_pct" ]; then
  if [ -n "$session_quota_resets_at" ]; then
    quota_fmt=$(awk -v p="$session_quota_pct" -v r="$session_quota_resets_at" -v now="$(date +%s)" \
      'BEGIN{h=(r-now)/3600; if (h<0) h=0; printf "%.0f%% (%.1fh)", p, h}')
  else
    quota_fmt=$(awk -v p="$session_quota_pct" 'BEGIN{printf "%.0f%%", p}')
  fi
  out="${out}${SEP}${LIGHT_GRAY}${quota_fmt}${RESET}"
fi

printf "%b" "$out"
