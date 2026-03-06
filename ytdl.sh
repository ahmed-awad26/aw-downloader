#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
#   AW Downloader  ·  v3.0  ·  Termux Multi-Site TUI
#   github.com/ahmed-awad26
# ═══════════════════════════════════════════════════════════════

# ── Colors ────────────────────────────────────────────────────
C='\033[0;36m'     # Cyan
W='\033[1;37m'     # Bold White
G='\033[0;32m'     # Green
R='\033[0;31m'     # Red
Y='\033[1;33m'     # Yellow
M='\033[0;35m'     # Magenta
D='\033[2m'        # Dim
BLD='\033[1m'      # Bold
RST='\033[0m'      # Reset

# ── Config ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/.config"

if [ -f "$CONFIG" ]; then
  source "$CONFIG"
else
  for _d in "$HOME/storage/shared" "/sdcard" "/storage/emulated/0"; do
    [ -d "$_d" ] && [ -w "$_d" ] && { SDCARD="$_d"; break; }
  done
  SDCARD="${SDCARD:-$HOME/downloads}"
  DOWNLOAD_ROOT="$SDCARD/Download/AW-DL"
fi
mkdir -p "$DOWNLOAD_ROOT"
PIDFILE="$HOME/.ytdl_running.pid"
STATE_FILE="$HOME/.ytdl_state"

# ─────────────────────────────────────────────────────────────
# UI PRIMITIVES
# ─────────────────────────────────────────────────────────────
cls() { printf '\033[2J\033[H'; }

banner() {
  printf "${C}  ╔══════════════════════════════════════════════════════╗${RST}\n"
  printf "${C}  ║                                                      ║${RST}\n"
  printf "${C}  ║   ${W} █████╗ ██╗    ██╗${C}                               ║${RST}\n"
  printf "${C}  ║   ${W}██╔══██╗██║    ██║${C}  ${W}AW Downloader${RST}${C}               ║${RST}\n"
  printf "${C}  ║   ${W}███████║██║ █╗ ██║${C}  ${D}v3.0  ·  Termux${RST}${C}              ║${RST}\n"
  printf "${C}  ║   ${W}██╔══██║██║███╗██║${C}                               ║${RST}\n"
  printf "${C}  ║   ${W}██║  ██║╚███╔███╔╝${C}  ${D}$(date '+%Y-%m-%d  %H:%M')${RST}${C}              ║${RST}\n"
  printf "${C}  ║                                                      ║${RST}\n"
  printf "${C}  ╚══════════════════════════════════════════════════════╝${RST}\n"
  printf "\n  ${D}Save to:${RST} ${C}%s${RST}\n\n" "$DOWNLOAD_ROOT"
}

box() {
  local t="$1" w=54
  local lp=$(( (w - ${#t} - 2) / 2 ))
  local rp=$(( w - ${#t} - 2 - lp ))
  [ $lp -lt 0 ] && lp=0; [ $rp -lt 0 ] && rp=0
  printf "  ${C}┌"; printf '─%.0s' $(seq 1 $w); printf "┐${RST}\n"
  printf "  ${C}│"; printf ' %.0s' $(seq 1 $lp)
  printf " ${W}%s${C} " "$t"
  printf ' %.0s' $(seq 1 $rp); printf "│${RST}\n"
  printf "  ${C}└"; printf '─%.0s' $(seq 1 $w); printf "┘${RST}\n\n"
}

div()   { printf "  ${D}${C}──────────────────────────────────────────────────────${RST}\n"; }
ok()    { printf "  ${G}✔${RST} ${W}%s${RST}\n" "$1"; sleep 1; }
err()   { printf "  ${R}✘${RST} ${R}%s${RST}\n" "$1"; }
warn()  { printf "  ${Y}⚠${RST} ${Y}%s${RST}\n" "$1"; sleep 1; }
info()  { printf "  ${C}·${RST} ${D}%s${RST}\n" "$1"; }

# ─────────────────────────────────────────────────────────────
# ARROW-KEY TUI MENU  —  Sets: TUI_RESULT = chosen index
# ─────────────────────────────────────────────────────────────
_tui_render() {
  local -n __arr="$1"
  local sel="$2" n=${#__arr[@]}
  for (( i=0; i<n; i++ )); do
    IFS='|' read -r ic lbl desc <<< "${__arr[$i]}"
    if (( i == sel )); then
      printf "  \033[48;5;234m${C}${BLD}  %-3s %-28s${RST}\033[48;5;234m  ${D}%-20s${RST}\n" \
        "$ic" "$lbl" "$desc"
    else
      printf "   ${D}%-3s${RST} ${W}%-28s${RST}  ${D}%-20s${RST}\n" "$ic" "$lbl" "$desc"
    fi
  done
}

tui_menu() {
  local title="$1"
  local -n _iref="$2"
  local n=${#_iref[@]} cur=0 key b1 b2
  printf '\033[?25l'; stty -echo 2>/dev/null
  while true; do
    cls; banner
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
      printf "  ${G}● Running${RST}  ${D}PID: $(cat "$PIDFILE")${RST}\n\n"
    else
      printf "  ${D}○ Idle${RST}\n\n"
    fi
    box "$title"
    _tui_render _iref "$cur"
    printf "\n"; div
    printf "  ${D}↑↓ navigate  ·  Enter select${RST}\n"
    IFS= read -rsn1 key
    if [[ "$key" == $'\x1b' ]]; then
      IFS= read -rsn1 -t 0.05 b1; IFS= read -rsn1 -t 0.05 b2
      case "${b1}${b2}" in
        '[A') (( cur > 0   )) && (( cur-- )) ;;
        '[B') (( cur < n-1 )) && (( cur++ )) ;;
      esac
    elif [[ "$key" == '' || "$key" == $'\r' || "$key" == $'\n' ]]; then
      break
    fi
  done
  stty echo 2>/dev/null; printf '\033[?25h'
  TUI_RESULT=$cur
}

# ─────────────────────────────────────────────────────────────
# PROGRESS BAR
# ─────────────────────────────────────────────────────────────
draw_bar() {
  local pct="${1:-0}" speed="${2:---}" size="${3:---}"
  local bar_width=30
  local filled=$(( pct * bar_width / 100 ))
  local empty=$(( bar_width - filled ))
  local bar="" i
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty;  i++ )); do bar+="░"; done
  printf "\r\033[K  ${C}[${G}%s${C}]${RST} ${W}%3d%%${RST}  ${D}%-12s  %-8s${RST}" \
    "$bar" "$pct" "$speed" "$size"
}

# ─────────────────────────────────────────────────────────────
# yt-dlp OUTPUT PARSER
# ─────────────────────────────────────────────────────────────
stream() {
  local log="$1" report="${2:-}" last_title="" cur_path=""
  local ndone=0 nskip=0
  while IFS= read -r line; do
    echo "$line" >> "$log"
    if echo "$line" | grep -qE '^\[download\] Destination:'; then
      cur_path=$(echo "$line" | sed 's/.*Destination: //')
      local title
      title=$(basename "$cur_path" | sed 's/ \[.*$//' \
        | sed 's/\.f[0-9]*\.[a-z0-9]*$//' | sed 's/\.[a-z0-9]\{2,5\}$//')
      if [[ -n "$title" && "$title" != "$last_title" ]]; then
        last_title="$title"
        local short="${title:0:52}"
        (( ${#title} > 52 )) && short="${title:0:49}..."
        printf "\n  ${M}▸${RST} ${W}%s${RST}\n" "$short"
      fi
      draw_bar 0
    elif echo "$line" | grep -qE '^\[download\].*has already been downloaded'; then
      (( nskip++ ))
      local s; s=$(echo "$line" | sed 's/\[download\] //' | sed 's/ has already.*//' | sed 's|.*/||')
      printf "\n  ${D}↷  %.50s${RST}\n" "$s"
    elif echo "$line" | grep -qE '^\[download\]\s+[0-9]+\.[0-9]+%'; then
      local pct speed size
      pct=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+%' | head -1 | tr -d '%' | cut -d. -f1)
      speed=$(echo "$line" | grep -oE 'at\s+[0-9.]+[KMG]iB/s' | sed 's/at //' | head -1)
      size=$(echo "$line" | grep -oE 'of\s+[~]?[0-9.]+[KMG]iB' | sed 's/of //' | head -1)
      draw_bar "${pct:-0}" "${speed:---}" "${size:---}"
    elif echo "$line" | grep -qE '^\[download\] 100(\.0)?% of .* in [0-9]'; then
      draw_bar 100; (( ndone++ ))
      printf "\n  ${G}✔ Done${RST}  ${D}[ dl: %d  skip: %d ]${RST}\n" "$ndone" "$nskip"
      [[ -n "$report" && -n "$cur_path" ]] && echo "$cur_path" >> "${report}.tmp"
    elif echo "$line" | grep -qE '^\[download\] 100%'; then
      draw_bar 100
    elif echo "$line" | grep -qE '^\[ffmpeg\]|^\[Merger\]'; then
      printf "\r  ${Y}⚙ Merging...${RST}\033[K                        "
    elif echo "$line" | grep -qE '^ERROR'; then
      echo "$line" | grep -qE 'ffmpeg|Postprocess' \
        || printf "\n  ${R}✘${RST} %s\n" "$line"
    elif echo "$line" | grep -qE '^WARNING'; then
      echo "$line" | grep -qE 'No supported JavaScript|merging of multiple|unavailable' \
        || printf "  ${Y}⚠${RST} %s\n" "$line"
    fi
  done
  printf "\n\n  ${D}Total: ${G}%d${D} downloaded  ·  ${Y}%d${D} skipped${RST}\n" "$ndone" "$nskip"
}

# ─────────────────────────────────────────────────────────────
# SMART ARCHIVE INTEGRITY CHECK
# ─────────────────────────────────────────────────────────────
check_missing() {
  local arc="$1" dir="$2"
  [ -f "$arc" ] || return
  local miss=()
  while IFS= read -r line; do
    local vid_id; vid_id=$(echo "$line" | awk '{print $2}')
    [[ -z "$vid_id" ]] && continue
    find "$dir" -maxdepth 1 -name "*${vid_id}*" 2>/dev/null | grep -q . || miss+=("$vid_id")
  done < "$arc"
  [ ${#miss[@]} -eq 0 ] && return
  printf "\n  ${Y}⚠ %d file(s) archived but missing on disk:${RST}\n" "${#miss[@]}"
  for id in "${miss[@]}"; do printf "    ${D}· %s${RST}\n" "$id"; done
  printf "\n  ${C}[1]${RST} Re-download missing  ${C}[2]${RST} Skip\n  Choose: "
  read -r ch
  if [[ "$ch" == "1" ]]; then
    for id in "${miss[@]}"; do sed -i "/youtube $id/d" "$arc" 2>/dev/null; done
    ok "Removed from archive — will re-download"
  fi
}

_cleanup_junk() {
  find "$1" -maxdepth 1 -type f \
    \( -name "*.webp" -o -name "*.jpg" -o -name "*.jpeg" \
    -o -name "*.png"  -o -name "*.json" -o -name "*.description" \
    -o -name "*.part" \) -delete 2>/dev/null
}

# ─────────────────────────────────────────────────────────────
# CORE yt-dlp RUNNER
# Env:  GLOBAL_ARCHIVE  (set for cross-playlist dedup)
#       REPORT_FILE     (set for latest-mode reports)
# ─────────────────────────────────────────────────────────────
run_ytdlp() {
  local log="$1" url="$2"; shift 2
  local out_tmpl
  if [ "$AUDIO_ONLY" = true ]; then
    out_tmpl="${CURRENT_OUT_DIR}/%(title)s.%(ext)s"
  else
    out_tmpl="${CURRENT_OUT_DIR}/%(title)s [%(id)s].%(ext)s"
  fi

  local arc="${CURRENT_OUT_DIR}/.ytdl_archive"
  if [ -n "$GLOBAL_ARCHIVE" ]; then
    arc="$GLOBAL_ARCHIVE"
    # Skip per-dir missing check when using global archive —
    # files may live in other playlist dirs and would appear "missing"
  else
    check_missing "$arc" "$CURRENT_OUT_DIR"
  fi

  local args=(
    "--ignore-errors" "--no-abort-on-error" "--continue"
    "--download-archive" "$arc"
    "--retries" "10" "--fragment-retries" "20" "--retry-sleep" "5"
    "--concurrent-fragments" "4"
    "--merge-output-format" "mp4"
    "--add-metadata" "--newline"
    "-o" "$out_tmpl"
  )
  if [ "$AUDIO_ONLY" = true ]; then
    args+=("-x" "--audio-format" "$EXT" "--audio-quality" "0")
  else
    args+=("-f" "$FORMAT")
  fi
  for flag in "$@"; do args+=("$flag"); done
  args+=("$url")

  yt-dlp "${args[@]}" 2>&1 | stream "$log" "${REPORT_FILE:-}"
  _cleanup_junk "$CURRENT_OUT_DIR"
}

# ═══════════════════════════════════════════════════════════════
# URL DETECTION & INPUT
# ═══════════════════════════════════════════════════════════════
detect_url_type() {
  local url="$1"
  # YouTube
  if echo "$url" | grep -qE 'youtube\.com/(@[^/?]+|channel/|c/|user/)'; then
    echo "channel"; return
  fi
  if echo "$url" | grep -qE 'youtube\.com/playlist\?list=|list=PL[A-Za-z0-9_-]+'; then
    echo "playlist"; return
  fi
  if echo "$url" | grep -qE 'youtube\.com/watch\?|youtube\.com/shorts/|youtu\.be/'; then
    echo "video"; return
  fi
  # File hosting
  if echo "$url" | grep -qE 'drive\.google\.com|docs\.google\.com.*export'; then
    echo "gdrive"; return
  fi
  if echo "$url" | grep -qE 'dropbox\.com/(s|sh|scl)/'; then
    echo "dropbox"; return
  fi
  if echo "$url" | grep -qE 'mega\.nz|mega\.co\.nz'; then
    echo "mega"; return
  fi
  if echo "$url" | grep -qE 'mediafire\.com/(file|download)/'; then
    echo "mediafire"; return
  fi
  if echo "$url" | grep -qE '4shared\.com/(file|download|zip)/'; then
    echo "fourshared"; return
  fi
  if echo "$url" | grep -qE '1drv\.ms|onedrive\.live\.com'; then
    echo "onedrive"; return
  fi
  if echo "$url" | grep -qE 'gofile\.io|pixeldrain\.com|sendspace\.com|wetransfer\.com|filetransfer\.io'; then
    echo "fileshare"; return
  fi
  # Direct file by extension
  if echo "$url" | grep -qiE '\.(zip|rar|7z|gz|bz2|pdf|mp3|wav|flac|aac|ogg|apk|exe|dmg|iso|docx?|xlsx?|pptx?|epub|mobi)([?#]|$)'; then
    echo "directfile"; return
  fi
  # Social video / everything else
  echo "other"
}

normalize_yt_url() {
  local url="$1"
  url=$(echo "$url" | tr -d '[:space:]')
  [[ "$url" != http* ]] && url="https://$url"
  url=$(echo "$url" \
    | sed -e 's|https://youtube\.com|https://www.youtube.com|g' \
          -e 's|https://m\.youtube\.com|https://www.youtube.com|g' \
          -e 's|https://music\.youtube\.com|https://www.youtube.com|g')
  if echo "$url" | grep -qE '/@[^/?]|/channel/|/c/|/user/'; then
    url=$(echo "$url" | sed 's/?.*//; s|/$||')
    if   echo "$url" | grep -qE '/@[^/]+'; then
      echo "https://www.youtube.com$(echo "$url" | grep -oE '/@[^/]+')"; return
    elif echo "$url" | grep -qE '/channel/UC[A-Za-z0-9_-]+'; then
      echo "https://www.youtube.com$(echo "$url" | grep -oE '/channel/UC[A-Za-z0-9_-]+')"; return
    elif echo "$url" | grep -qE '/c/[^/]+'; then
      echo "https://www.youtube.com$(echo "$url" | grep -oE '/c/[^/]+')"; return
    elif echo "$url" | grep -qE '/user/[^/]+'; then
      echo "https://www.youtube.com$(echo "$url" | grep -oE '/user/[^/]+')"; return
    fi
  fi
  echo "$url"
}

get_url_input() {
  cls; printf "\n"
  box "Paste URL — Any Site"
  printf "  ${C}┌──────────────────────────────────────────────────────┐${RST}\n"
  printf "  ${C}│${RST}  ${W}Video sites${RST}  YouTube · Facebook · Instagram · TikTok ${C}│${RST}\n"
  printf "  ${C}│${RST}               Twitter/X · Vimeo · Dailymotion + more  ${C}│${RST}\n"
  printf "  ${C}├──────────────────────────────────────────────────────┤${RST}\n"
  printf "  ${C}│${RST}  ${W}File hosts${RST}   Google Drive · Dropbox · Mega           ${C}│${RST}\n"
  printf "  ${C}│${RST}               MediaFire · 4Shared · OneDrive            ${C}│${RST}\n"
  printf "  ${C}│${RST}               GoFile · PixelDrain · WeTransfer + more   ${C}│${RST}\n"
  printf "  ${C}├──────────────────────────────────────────────────────┤${RST}\n"
  printf "  ${C}│${RST}  ${W}Direct links${RST} .zip .rar .pdf .apk .mp3 .exe …        ${C}│${RST}\n"
  printf "  ${C}└──────────────────────────────────────────────────────┘${RST}\n\n"
  div
  printf "  ${C}URL:${RST} "
  read -r RAW_URL

  if [[ -z "$RAW_URL" ]]; then
    err "URL is empty."; sleep 1; get_url_input; return
  fi

  INPUT_URL="$RAW_URL"
  URL_TYPE=$(detect_url_type "$RAW_URL")
  if [[ "$URL_TYPE" == "channel" || "$URL_TYPE" == "playlist" || "$URL_TYPE" == "video" ]]; then
    INPUT_URL=$(normalize_yt_url "$RAW_URL")
  fi

  INPUT_NAME=""
  case "$URL_TYPE" in
    channel)
      if echo "$INPUT_URL" | grep -qE '/@'; then
        INPUT_NAME=$(echo "$INPUT_URL" | grep -oE '@[^/]+' | tr -d '@')
      elif echo "$INPUT_URL" | grep -qE '/channel/'; then
        INPUT_NAME=$(echo "$INPUT_URL" | grep -oE 'UC[A-Za-z0-9_-]+' | head -1)
      else
        INPUT_NAME=$(echo "$INPUT_URL" | sed 's|.*/||')
      fi ;;
    playlist)
      local pl_id; pl_id=$(echo "$INPUT_URL" | grep -oE 'list=[^&]+' | sed 's/list=//' | head -c 16)
      INPUT_NAME="Playlist_${pl_id}" ;;
    video)
      local vid_id; vid_id=$(echo "$INPUT_URL" | grep -oE '[?&]v=[^&]+' | sed 's/.*v=//' | head -c 12)
      INPUT_NAME="Video_${vid_id:-$(date +%s)}" ;;
    gdrive|dropbox|mega|mediafire|fourshared|onedrive|fileshare|directfile|other)
      INPUT_NAME=$(echo "$RAW_URL" | grep -oE 'https?://[^/]+' \
        | sed 's|https\?://||; s/^www\.//' | head -c 32)
      INPUT_NAME="${INPUT_NAME:-Download_$(date +%s)}" ;;
  esac

  [[ -z "$INPUT_NAME" ]] && INPUT_NAME="Download_$(date +%s)"
  INPUT_SAFE=$(echo "$INPUT_NAME" | tr -dc 'a-zA-Z0-9_\-' | head -c 60)
  [[ -z "$INPUT_SAFE" ]] && INPUT_SAFE="Download_$(date +%s)"

  printf "\n  ${D}Detected: ${C}%s${RST}  →  %s\n" "$URL_TYPE" "${INPUT_URL:0:55}"
  ok "Accepted: $INPUT_NAME"
}

# ═══════════════════════════════════════════════════════════════
# QUALITY SELECTOR
# ═══════════════════════════════════════════════════════════════
select_quality() {
  cls; printf "\n"
  box "Video Quality"
  printf "  ${C}┌──────────────────────────────────────────────────┐${RST}\n"
  printf "  ${C}│${RST}  ${W}[1]${RST}  ◈  Best auto         ${D}picks best available${RST}  ${C}│${RST}\n"
  printf "  ${C}│${RST}  ${W}[2]${RST}  4K 2160p             ${D}ultra HD · large files${RST} ${C}│${RST}\n"
  printf "  ${C}│${RST}  ${W}[3]${RST}  HD 1080p             ${D}excellent · recommended${RST} ${C}│${RST}\n"
  printf "  ${C}│${RST}  ${W}[4]${RST}  HD 720p              ${D}high quality${RST}          ${C}│${RST}\n"
  printf "  ${C}│${RST}  ${W}[5]${RST}  SD 480p              ${D}medium · mobile${RST}       ${C}│${RST}\n"
  printf "  ${C}│${RST}  ${W}[6]${RST}  LQ 360p              ${D}low · smallest${RST}        ${C}│${RST}\n"
  printf "  ${C}├──────────────────────────────────────────────────┤${RST}\n"
  printf "  ${C}│${RST}  ${W}[7]${RST}  ♫  MP3 audio only    ${D}high quality MP3${RST}      ${C}│${RST}\n"
  printf "  ${C}│${RST}  ${W}[8]${RST}  ♫  M4A audio only    ${D}AAC / M4A format${RST}      ${C}│${RST}\n"
  printf "  ${C}└──────────────────────────────────────────────────┘${RST}\n\n"
  div
  printf "  ${C}Choose [1-8]:${RST} "
  read -r qc
  AUDIO_ONLY=false
  case "$qc" in
    1) FORMAT="bestvideo+bestaudio/best";                               EXT="mp4"; QUALITY_NAME="Best (auto)" ;;
    2) FORMAT="bestvideo[height<=2160]+bestaudio/best[height<=2160]";  EXT="mp4"; QUALITY_NAME="4K 2160p" ;;
    3) FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]";  EXT="mp4"; QUALITY_NAME="1080p HD" ;;
    4) FORMAT="bestvideo[height<=720]+bestaudio/best[height<=720]";    EXT="mp4"; QUALITY_NAME="720p HD" ;;
    5) FORMAT="bestvideo[height<=480]+bestaudio/best[height<=480]";    EXT="mp4"; QUALITY_NAME="480p SD" ;;
    6) FORMAT="bestvideo[height<=360]+bestaudio/best[height<=360]";    EXT="mp4"; QUALITY_NAME="360p LQ" ;;
    7) FORMAT="bestaudio/best"; EXT="mp3"; QUALITY_NAME="MP3 Audio"; AUDIO_ONLY=true ;;
    8) FORMAT="bestaudio/best"; EXT="m4a"; QUALITY_NAME="M4A Audio"; AUDIO_ONLY=true ;;
    *) FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]";  EXT="mp4"; QUALITY_NAME="1080p HD" ;;
  esac
  ok "Quality: $QUALITY_NAME"
}

# ═══════════════════════════════════════════════════════════════
# CHANNEL MODE SELECTOR
# ═══════════════════════════════════════════════════════════════
select_mode() {
  cls; printf "\n"
  box "Download Mode"
  printf "  ${C}┌────────────────────────────────────────────────────────┐${RST}\n"
  printf "  ${C}│${RST}  ${W}[1]${RST}  📋  Playlists only          ${D}named playlists${RST}      ${C}│${RST}\n"
  printf "  ${C}│${RST}  ${W}[2]${RST}  📺  Uploads only            ${D}all channel videos${RST}   ${C}│${RST}\n"
  printf "  ${C}│${RST}  ${W}[3]${RST}  🔀  Playlists + Uploads     ${D}both, dedup enabled${RST}* ${C}│${RST}\n"
  printf "  ${C}│${RST}  ${W}[4]${RST}  ✦   All + Uncategorized     ${D}not in any playlist${RST}  ${C}│${RST}\n"
  printf "  ${C}│${RST}  ${W}[5]${RST}  🕐  Latest since last run   ${D}only new videos${RST}      ${C}│${RST}\n"
  printf "  ${C}│${RST}  ${W}[6]${RST}  🔗  Custom playlist URL     ${D}unlisted / private${RST}   ${C}│${RST}\n"
  printf "  ${C}└────────────────────────────────────────────────────────┘${RST}\n"
  printf "  ${D}  * Videos shared across playlists downloaded only once${RST}\n\n"
  div
  printf "  ${C}Choose [1-6]:${RST} "
  read -r mc
  CUSTOM_PL_URL=""
  case "$mc" in
    1) DL_MODE="playlists";         MODE_NAME="Playlists only" ;;
    2) DL_MODE="uploads";           MODE_NAME="Uploads only" ;;
    3) DL_MODE="all";               MODE_NAME="Playlists + Uploads" ;;
    4) DL_MODE="all_uncategorized"; MODE_NAME="All + Uncategorized" ;;
    5) DL_MODE="latest";            MODE_NAME="Latest since last run" ;;
    6) DL_MODE="custom_playlist";   MODE_NAME="Custom Playlist URL"
       printf "\n  ${C}Playlist URL:${RST} "; read -r CUSTOM_PL_URL
       [[ -z "$CUSTOM_PL_URL" ]] && { err "Empty URL — defaulting"; DL_MODE="playlists"; MODE_NAME="Playlists only"; } ;;
    *) DL_MODE="all";               MODE_NAME="Playlists + Uploads" ;;
  esac
  ok "Mode: $MODE_NAME"
}

# ═══════════════════════════════════════════════════════════════
# CONFIRM + SAVE SESSION STATE
# ═══════════════════════════════════════════════════════════════
confirm_download() {
  cls; printf "\n"
  box "Confirm Download"
  printf "  ${C}┌──────────────────────────────────────────────────────────┐${RST}\n"
  printf "  ${C}│${RST}  ${D}Target ${RST}  ${W}%-48s${RST} ${C}│${RST}\n" "${INPUT_NAME:0:48}"
  printf "  ${C}│${RST}  ${D}URL    ${RST}  ${D}%-48s${RST} ${C}│${RST}\n" "${INPUT_URL:0:48}"
  [[ -n "$QUALITY_NAME" && "$QUALITY_NAME" != "Original file" ]] && \
  printf "  ${C}│${RST}  ${D}Quality${RST}  ${G}%-48s${RST} ${C}│${RST}\n" "$QUALITY_NAME"
  [ -n "$MODE_NAME" ] && \
  printf "  ${C}│${RST}  ${D}Mode   ${RST}  ${Y}%-48s${RST} ${C}│${RST}\n" "$MODE_NAME"
  printf "  ${C}│${RST}  ${D}Save to${RST}  ${M}%-48s${RST} ${C}│${RST}\n" "${INPUT_DIR:0:48}"
  printf "  ${C}└──────────────────────────────────────────────────────────┘${RST}\n\n"
  div
  printf "  ${G}[Y]${RST} Start   ${R}[N]${RST} Cancel\n\n  Choose: "
  read -r cf
  if [[ ! "$cf" =~ ^[Yy]$ ]]; then warn "Cancelled."; main_menu; return; fi

  cat > "$STATE_FILE" << EOF
INPUT_URL="$INPUT_URL"
INPUT_NAME="$INPUT_NAME"
INPUT_SAFE="$INPUT_SAFE"
INPUT_DIR="$INPUT_DIR"
URL_TYPE="$URL_TYPE"
DL_MODE="${DL_MODE:-single}"
MODE_NAME="${MODE_NAME:-}"
FORMAT="$FORMAT"
QUALITY_NAME="$QUALITY_NAME"
AUDIO_ONLY="${AUDIO_ONLY:-false}"
EXT="${EXT:-mp4}"
CUSTOM_PL_URL="${CUSTOM_PL_URL:-}"
EOF
}

# ═══════════════════════════════════════════════════════════════
# PLAYLIST DOWNLOADER  —  uses GLOBAL_ARCHIVE to prevent
# the same video from being downloaded into multiple playlists
# ═══════════════════════════════════════════════════════════════
_dl_playlists() {
  local log="$1"
  info "Fetching playlist list..."

  local PL_IDS PL_TITLES PLAYLISTS
  PL_IDS=$(yt-dlp --flat-playlist --no-warnings \
    --print "%(id)s" "$INPUT_URL/playlists" 2>/dev/null | grep "^PL")
  PL_TITLES=$(yt-dlp --flat-playlist --no-warnings \
    --print "%(title)s" "$INPUT_URL/playlists" 2>/dev/null | grep -v "^$")

  if [[ -z "$PL_IDS" ]]; then warn "No playlists found."; return; fi

  PLAYLISTS=$(paste <(echo "$PL_IDS") <(echo "$PL_TITLES") \
    | awk -F$'\t' '!seen[$1]++')

  # Shared archive across all playlists: if video X lives in
  # both Playlist A and Playlist B, it is downloaded once (into A)
  # and skipped when Playlist B is processed.
  GLOBAL_ARCHIVE="$INPUT_DIR/.global_playlist_archive"
  export GLOBAL_ARCHIVE

  local count=0
  while IFS=$'\t' read -r pl_id pl_title; do
    [[ -z "$pl_id" || "$pl_id" != PL* ]] && continue
    (( count++ ))
    local safe_title
    safe_title=$(printf '%s' "$pl_title" \
      | sed 's|[/\\:*?"<>|]|_|g; s/^\.\|[[:space:]]*$//g')
    safe_title="${safe_title:-Playlist_$count}"

    CURRENT_OUT_DIR="$INPUT_DIR/Playlists/$safe_title"
    mkdir -p "$CURRENT_OUT_DIR"

    printf "\n  ${M}╔ Playlist %d${RST}\n  ${M}║${RST} ${W}%s${RST}\n  ${M}╚${RST} ${D}→ %s${RST}\n\n" \
      "$count" "$pl_title" "$CURRENT_OUT_DIR"

    run_ytdlp "$log" "https://www.youtube.com/playlist?list=${pl_id}"
  done <<< "$PLAYLISTS"

  unset GLOBAL_ARCHIVE
  [[ $count -eq 0 ]] && warn "No valid playlists found."
}


# ═══════════════════════════════════════════════════════════════
# FILE HOSTING DOWNLOAD ENGINE
# Supports: GDrive, Dropbox, Mega, MediaFire, 4Shared, OneDrive
#           GoFile, PixelDrain, WeTransfer, direct file links
# Features: pre-download name+size info, auto-preview for
#           text/PDF, skips ad/tracker redirects
# ═══════════════════════════════════════════════════════════════

_fmt_size() {
  local b="${1:-0}"
  if   (( b >= 1073741824 )); then printf "%.1f GB" "$(echo "scale=1; $b/1073741824" | bc)"
  elif (( b >= 1048576    )); then printf "%.1f MB" "$(echo "scale=1; $b/1048576"    | bc)"
  elif (( b >= 1024       )); then printf "%.1f KB" "$(echo "scale=1; $b/1024"       | bc)"
  else printf "%d B" "$b"; fi
}

_curl_bar() {
  local pct="${1:-0}" speed="${2:---}" size="${3:---}"
  local bar_width=30 filled=$(( pct * 30 / 100 )) bar="" i
  local empty=$(( 30 - filled ))
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty;  i++ )); do bar+="░"; done
  printf "\r\033[K  ${C}[${G}%s${C}]${RST} ${W}%3d%%${RST}  ${D}%-12s  %-8s${RST}" \
    "$bar" "$pct" "$speed" "$size"
}

# Resolve Google Drive share URL → direct download
_gdrive_direct() {
  local url="$1" file_id=""
  if echo "$url" | grep -qE '/file/d/[^/]+'; then
    file_id=$(echo "$url" | grep -oE '/file/d/[^/?]+' | sed 's|/file/d/||')
  elif echo "$url" | grep -qE '[?&]id=[A-Za-z0-9_-]+'; then
    file_id=$(echo "$url" | grep -oE '[?&]id=[A-Za-z0-9_-]+' | sed 's/.*id=//' | head -1)
  fi
  if [[ -n "$file_id" ]]; then
    echo "https://drive.google.com/uc?export=download&id=${file_id}&confirm=t"
  else
    echo "$url"
  fi
}

# Dropbox → direct download (dl=1)
_dropbox_direct() {
  local url="$1"
  echo "$url" | grep -qE '[?&]dl=' \
    && echo "$url" | sed 's/dl=0/dl=1/g' \
    || echo "${url}?dl=1"
}

# OneDrive → expand short link + add download param
_onedrive_direct() {
  local url="$1"
  if echo "$url" | grep -qE '1drv\.ms'; then
    local expanded
    expanded=$(curl -sI --max-time 10 -L "$url" \
      | grep -i '^location:' | tail -1 | tr -d '\r' | sed 's/.*ocation: //')
    [[ -n "$expanded" ]] && url="$expanded"
  fi
  echo "$url" | grep -qE 'download=' && echo "$url" || echo "${url}&download=1"
}

# Returns 0 (true) if URL looks like an ad/tracker redirect
_is_ad_redirect() {
  local url="$1"
  echo "$url" | grep -qiE \
    'ads\.|adclick\.|doubleclick\.|googlesyndication\.|adnxs\.com|adform\.net|outbrain\.|taboola\.|propellerads\.|adf\.ly|linkvertise\.|ouo\.io|sh\.st|bc\.vc|sub2unlock\.|shorte\.st|shrinkme\.'
}

# Fetch file metadata (name, size, content-type) via HEAD
_fetch_file_info() {
  local url="$1"
  local headers
  headers=$(curl -sI --max-time 15 -L \
    -H "User-Agent: Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36" \
    "$url" 2>/dev/null)

  FILE_INFO_NAME=$(echo "$headers" | grep -i 'content-disposition' \
    | grep -oE 'filename[^;"\n]*=["\s]*[^";\n]+' \
    | sed 's/filename.*=//i; s/["\r ]//g' | head -1)
  [[ -z "$FILE_INFO_NAME" ]] && \
    FILE_INFO_NAME=$(echo "$url" | sed 's/?.*//' | sed 's|.*/||' | head -c 60)
  [[ -z "$FILE_INFO_NAME" ]] && FILE_INFO_NAME="download_$(date +%s)"

  local raw_size
  raw_size=$(echo "$headers" | grep -i '^content-length:' \
    | tail -1 | tr -d '\r' | awk '{print $2}')
  [[ -n "$raw_size" && "$raw_size" =~ ^[0-9]+$ ]] \
    && FILE_INFO_SIZE=$(_fmt_size "$raw_size") \
    || FILE_INFO_SIZE="unknown size"

  FILE_INFO_TYPE=$(echo "$headers" | grep -i '^content-type:' \
    | tail -1 | tr -d '\r' | sed 's/.*content-type://i; s/;.*//' | tr -d ' ')
}

# Preview text/PDF files in terminal
_try_preview() {
  local path="$1" ctype="${2:-}"
  if echo "$ctype" | grep -qiE 'text/plain|text/html|application/json|text/csv'; then
    printf "\n  ${C}┌─ Preview ──────────────────────────────────────┐${RST}\n"
    head -25 "$path" 2>/dev/null | while IFS= read -r l; do
      printf "  ${D}│ %s${RST}\n" "${l:0:54}"
    done
    printf "  ${C}└────────────────────────────────────────────────┘${RST}\n"
    return 0
  fi
  if echo "$ctype" | grep -qi 'pdf' || echo "$path" | grep -qi '\.pdf$'; then
    if command -v pdftotext &>/dev/null; then
      printf "\n  ${C}┌─ PDF Preview (page 1) ─────────────────────────┐${RST}\n"
      pdftotext -f 1 -l 1 "$path" - 2>/dev/null | head -20 | while IFS= read -r l; do
        printf "  ${D}│ %s${RST}\n" "${l:0:54}"
      done
      printf "  ${C}└────────────────────────────────────────────────┘${RST}\n"
    else
      info "PDF preview: install pdftotext  (pkg install poppler)"
    fi
    return 0
  fi
  return 1
}

# Generic file downloader: info → progress bar → verify → preview
_download_file() {
  local url="$1" out_dir="$2"
  mkdir -p "$out_dir"

  # Resolve platform-specific direct download URLs
  local dl_url="$url"
  case "$URL_TYPE" in
    gdrive)   dl_url=$(_gdrive_direct   "$url") ;;
    dropbox)  dl_url=$(_dropbox_direct  "$url") ;;
    onedrive) dl_url=$(_onedrive_direct "$url") ;;
  esac

  # Skip ad/tracker redirects
  if _is_ad_redirect "$dl_url"; then
    warn "Skipped — looks like an ad or tracker redirect."
    warn "Paste the direct download link from the site."
    return 1
  fi

  # Fetch name + size before downloading
  info "Fetching file info..."
  _fetch_file_info "$dl_url"

  printf "\n  ${C}┌──────────────────────────────────────────────────────┐${RST}\n"
  printf "  ${C}│${RST}  ${D}File   ${RST}  ${W}%-46s${RST} ${C}│${RST}\n" "${FILE_INFO_NAME:0:46}"
  printf "  ${C}│${RST}  ${D}Size   ${RST}  ${G}%-46s${RST} ${C}│${RST}\n" "$FILE_INFO_SIZE"
  printf "  ${C}│${RST}  ${D}Type   ${RST}  ${D}%-46s${RST} ${C}│${RST}\n" "${FILE_INFO_TYPE:0:46}"
  printf "  ${C}│${RST}  ${D}Save to${RST}  ${M}%-46s${RST} ${C}│${RST}\n" "${out_dir:0:46}"
  printf "  ${C}└──────────────────────────────────────────────────────┘${RST}\n\n"

  local out_path="$out_dir/$FILE_INFO_NAME"

  # Download with inline progress bar
  # curl writes progress to stderr; stdbuf flushes it line-by-line
  curl -L --max-time 3600 \
    -H "User-Agent: Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36" \
    --retry 5 --retry-delay 3 \
    -C - \
    -w "\n" \
    -# \
    -o "$out_path" \
    "$dl_url" 2>&1 | \
  while IFS= read -r curlline; do
    local pct spd siz
    pct=$(echo "$curlline" | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f1 2>/dev/null)
    spd=$(echo "$curlline" | awk '{print $NF}' 2>/dev/null)
    siz=$(echo "$curlline" | grep -oE '[0-9.]+[kMGT]' | head -1 2>/dev/null)
    [[ -n "$pct" ]] && _curl_bar "${pct:-0}" "${spd:---}" "${siz:---}"
  done

  printf "\n"

  if [ -f "$out_path" ] && [ -s "$out_path" ]; then
    local actual_size
    actual_size=$(_fmt_size "$(stat -c%s "$out_path" 2>/dev/null || echo 0)")
    printf "  ${G}✔ Saved:${RST}  ${W}%s${RST}  ${D}(%s)${RST}\n\n" "$FILE_INFO_NAME" "$actual_size"
    if _try_preview "$out_path" "$FILE_INFO_TYPE"; then
      printf "\n  ${D}Press ENTER to continue...${RST} "; read -r
    fi
    return 0
  else
    err "Download failed or file is empty."
    err "Try the direct download link from the site."
    return 1
  fi
}

# Mega.nz — needs megatools
_download_mega() {
  local url="$1" out_dir="$2"
  mkdir -p "$out_dir"
  if command -v megadl &>/dev/null; then
    printf "  ${D}Using megatools...${RST}\n\n"
    megadl --path "$out_dir" "$url"
  elif command -v mega-get &>/dev/null; then
    mega-get --path="$out_dir" "$url"
  else
    warn "megatools not installed."
    printf "\n  ${C}Install:${RST}  ${W}pkg install megatools${RST}\n"
    printf "  ${D}Or download manually: %s${RST}\n\n" "$url"
    printf "  ${D}Press ENTER to continue...${RST} "; read -r
  fi
}

# ═══════════════════════════════════════════════════════════════
# DOWNLOAD ROUTER
# ═══════════════════════════════════════════════════════════════
run_download() {
  local LOG="$INPUT_DIR/download_$(date +%Y%m%d_%H%M%S).log"
  AUDIO_ONLY="${AUDIO_ONLY:-false}"

  cls; printf "\n"
  printf "  ${C}╔══════════════════════════════════════════════════════╗${RST}\n"
  printf "  ${C}║   ${W}▶ Downloading...${C}                                  ║${RST}\n"
  printf "  ${C}╠══════════════════════════════════════════════════════╣${RST}\n"
  printf "  ${C}║   ${D}Target ${RST}  ${W}%-44s${C} ║${RST}\n" "${INPUT_NAME:0:44}"
  [ -n "$MODE_NAME" ] && \
  printf "  ${C}║   ${D}Mode   ${RST}  ${Y}%-44s${C} ║${RST}\n" "$MODE_NAME"
  [[ -n "$QUALITY_NAME" && "$QUALITY_NAME" != "Original file" ]] && \
  printf "  ${C}║   ${D}Quality${RST}  ${G}%-44s${C} ║${RST}\n" "$QUALITY_NAME"
  printf "  ${C}╚══════════════════════════════════════════════════════╝${RST}\n\n"

  case "$URL_TYPE" in
    channel)
      case "$DL_MODE" in
        uploads)
          printf "  ${C}◆ Uploads${RST}\n\n"
          CURRENT_OUT_DIR="$INPUT_DIR/Uploads"; mkdir -p "$CURRENT_OUT_DIR"
          run_ytdlp "$LOG" "$INPUT_URL/videos" ;;
        playlists)
          printf "  ${C}◆ Playlists${RST}\n\n"
          _dl_playlists "$LOG" ;;
        all)
          printf "  ${C}◆ Playlists${RST}\n\n"; _dl_playlists "$LOG"
          printf "\n  ${C}◆ Uploads${RST}\n\n"
          CURRENT_OUT_DIR="$INPUT_DIR/Uploads"; mkdir -p "$CURRENT_OUT_DIR"
          run_ytdlp "$LOG" "$INPUT_URL/videos" ;;
        all_uncategorized)
          printf "  ${C}◆ Playlists${RST}\n\n"; _dl_playlists "$LOG"
          printf "\n  ${C}◆ Uploads${RST}\n\n"
          CURRENT_OUT_DIR="$INPUT_DIR/Uploads"; mkdir -p "$CURRENT_OUT_DIR"
          run_ytdlp "$LOG" "$INPUT_URL/videos"
          printf "\n  ${C}◆ Uncategorized (not in any playlist)${RST}\n\n"
          local PL_IDS_UC
          PL_IDS_UC=$(yt-dlp --flat-playlist --no-warnings \
            --print "%(id)s" "$INPUT_URL/playlists" 2>/dev/null | sort -u)
          CURRENT_OUT_DIR="$INPUT_DIR/Uncategorized"; mkdir -p "$CURRENT_OUT_DIR"
          if [[ -n "$PL_IDS_UC" ]]; then
            local SKIP_ARC="$INPUT_DIR/.playlist_skip_archive"
            printf "%s\n" $PL_IDS_UC | sed 's/^/youtube /' > "$SKIP_ARC"
            run_ytdlp "$LOG" "$INPUT_URL/videos" "--download-archive" "$SKIP_ARC"
          else
            run_ytdlp "$LOG" "$INPUT_URL/videos"
          fi ;;
        latest)
          printf "  ${C}◆ Latest videos${RST}\n\n"
          local DATEFILE="$INPUT_DIR/.last_run" DATE_AFTER=""
          if [ -f "$DATEFILE" ]; then
            DATE_AFTER=$(cat "$DATEFILE")
            info "Last run: $DATE_AFTER  →  downloading newer only"
          else
            info "First run — downloading all available uploads"
          fi
          CURRENT_OUT_DIR="$INPUT_DIR/Latest"; mkdir -p "$CURRENT_OUT_DIR"
          REPORT_FILE="$INPUT_DIR/latest_report.txt"
          local RUN_DATE; RUN_DATE=$(date '+%Y-%m-%d %H:%M')
          export REPORT_FILE
          if [ -n "$DATE_AFTER" ]; then
            run_ytdlp "$LOG" "$INPUT_URL/videos" "--dateafter" "$DATE_AFTER"
          else
            run_ytdlp "$LOG" "$INPUT_URL/videos"
          fi
          if [ -f "${REPORT_FILE}.tmp" ]; then
            local nc; nc=$(wc -l < "${REPORT_FILE}.tmp")
            {
              printf "════════════════════════════════════════════════\n"
              printf "  Update : %s  ·  New: %d\n" "$RUN_DATE" "$nc"
              printf "════════════════════════════════════════════════\n"
              while IFS= read -r fp; do
                local fn; fn=$(basename "$fp" | sed 's/\.[^.]*$//' | sed 's/ \[.*$//')
                printf "  ▶ %s\n    %s\n\n" "$fn" "$fp"
              done < "${REPORT_FILE}.tmp"
              printf "\n"; [ -f "$REPORT_FILE" ] && cat "$REPORT_FILE"
            } > "${REPORT_FILE}.new"
            mv "${REPORT_FILE}.new" "$REPORT_FILE"
            rm -f "${REPORT_FILE}.tmp"
            printf "  ${G}✔ Report:${RST} ${D}%s${RST}\n" "$REPORT_FILE"
          else
            info "No new videos this session."
          fi
          date +%Y%m%d > "$DATEFILE"
          unset REPORT_FILE ;;
        custom_playlist)
          printf "  ${C}◆ Custom Playlist${RST}\n\n"
          local pl_slug; pl_slug=$(echo "$CUSTOM_PL_URL" \
            | grep -oE 'list=[^&]+' | sed 's/list=//' | head -c 20)
          CURRENT_OUT_DIR="$INPUT_DIR/Playlists/${pl_slug:-Custom}"
          mkdir -p "$CURRENT_OUT_DIR"
          run_ytdlp "$LOG" "$CUSTOM_PL_URL" ;;
      esac ;;
    playlist)
      printf "  ${C}◆ Playlist${RST}\n\n"
      CURRENT_OUT_DIR="$INPUT_DIR"; mkdir -p "$CURRENT_OUT_DIR"
      run_ytdlp "$LOG" "$INPUT_URL" ;;
    video|other)
      printf "  ${C}◆ Downloading${RST}\n\n"
      CURRENT_OUT_DIR="$INPUT_DIR"; mkdir -p "$CURRENT_OUT_DIR"
      run_ytdlp "$LOG" "$INPUT_URL" ;;

    mega)
      printf "  ${C}◆ Mega.nz${RST}\n\n"
      CURRENT_OUT_DIR="$INPUT_DIR"
      _download_mega "$INPUT_URL" "$CURRENT_OUT_DIR" ;;

    gdrive|dropbox|onedrive|mediafire|fourshared|fileshare|directfile)
      printf "  ${C}◆ File Download${RST}\n\n"
      CURRENT_OUT_DIR="$INPUT_DIR"
      _download_file "$INPUT_URL" "$CURRENT_OUT_DIR" ;;
  esac

  printf "\n"; div; _show_completion "$LOG"
}

_show_completion() {
  local log="$1" errors=0 total=0
  [ -f "$log" ] && errors=$(grep -c "^ERROR" "$log" 2>/dev/null || true)
  [ -f "$log" ] && total=$(grep -c "^\[download\]" "$log" 2>/dev/null || true)
  cls; printf "\n"
  printf "  ${G}╔══════════════════════════════════════════════════════╗${RST}\n"
  printf "  ${G}║   ✔  Download Complete!                              ║${RST}\n"
  printf "  ${G}╠══════════════════════════════════════════════════════╣${RST}\n"
  printf "  ${G}║${RST}   ${D}Target${RST}   ${W}%-44s${G} ║${RST}\n" "${INPUT_NAME:0:44}"
  printf "  ${G}║${RST}   ${D}Saved${RST}    ${M}%-44s${G} ║${RST}\n" "${INPUT_DIR:0:44}"
  printf "  ${G}║${RST}   ${D}Ops${RST}      ${G}%-44s${G} ║${RST}\n" "$total"
  [ "$errors" -gt 0 ] && \
  printf "  ${G}║${RST}   ${D}Errors${RST}   ${R}%-44s${G} ║${RST}\n" "$errors (see log)"
  printf "  ${G}║${RST}   ${D}Log${RST}      ${D}%-44s${G} ║${RST}\n" "${log:0:44}"
  printf "  ${G}╚══════════════════════════════════════════════════════╝${RST}\n\n"
  div
  printf "\n  ${C}[1]${RST} Download another   ${C}[2]${RST} Exit\n\n  Choose: "
  read -r na
  case "$na" in 1) main_menu ;; *) _goodbye ;; esac
}

_goodbye() {
  cls; printf "\n"
  printf "  ${C}╔══════════════════════════════════════════════════════╗${RST}\n"
  printf "  ${C}║   ${W}Thanks for using AW Downloader — Goodbye! ✌${C}       ║${RST}\n"
  printf "  ${C}╚══════════════════════════════════════════════════════╝${RST}\n\n"
  exit 0
}

# ═══════════════════════════════════════════════════════════════
# DOWNLOAD FLOW ENTRY
# ═══════════════════════════════════════════════════════════════
start_download() {
  echo $$ > "$PIDFILE"
  get_url_input
  # Skip quality selection for file-hosting — no transcoding needed
  local _ft="gdrive dropbox mega mediafire fourshared onedrive fileshare directfile"
  if echo "$_ft" | grep -qw "$URL_TYPE"; then
    QUALITY_NAME="Original file"; FORMAT=""; AUDIO_ONLY=false; EXT=""
  else
    select_quality
  fi
  INPUT_DIR="$DOWNLOAD_ROOT/$INPUT_SAFE"
  mkdir -p "$INPUT_DIR"
  if [[ "$URL_TYPE" == "channel" ]]; then
    select_mode
  else
    DL_MODE="single"; MODE_NAME=""
  fi
  confirm_download
  run_download
  rm -f "$PIDFILE"
}

# ═══════════════════════════════════════════════════════════════
# MANAGEMENT ACTIONS
# ═══════════════════════════════════════════════════════════════
pause_download() {
  if [ -f "$PIDFILE" ]; then
    local pid; pid=$(cat "$PIDFILE")
    if kill -0 "$pid" 2>/dev/null; then
      kill -STOP "$pid"
      printf "\n  ${Y}⏸ Paused${RST}  ${D}(PID: %s)${RST}\n  ${D}Press ENTER to resume...${RST}" "$pid"
      read -r; kill -CONT "$pid"
      printf "  ${G}▶ Resumed${RST}\n"
    else printf "  ${D}No active download${RST}\n"; fi
  else printf "  ${D}No active download${RST}\n"; fi
  sleep 2; main_menu
}

stop_download() {
  if [ -f "$PIDFILE" ]; then
    local pid; pid=$(cat "$PIDFILE")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" && rm -f "$PIDFILE"
      printf "  ${G}✔ Stopped${RST}  ${D}(PID: %s)${RST}\n" "$pid"
    else rm -f "$PIDFILE"; printf "  ${D}No active download${RST}\n"; fi
  else printf "  ${D}No active download${RST}\n"; fi
  sleep 2; main_menu
}

resume_download() {
  if [ ! -f "$STATE_FILE" ]; then warn "No previous session found."; sleep 2; main_menu; return; fi
  source "$STATE_FILE"
  printf "\n  ${C}Resuming:${RST} ${W}%s${RST}  ${D}(%s)${RST}\n\n" "$INPUT_NAME" "$MODE_NAME"
  echo $$ > "$PIDFILE"; run_download; rm -f "$PIDFILE" "$STATE_FILE"
}

delete_folder() {
  cls; printf "\n"; box "Delete Download Folder"
  printf "  ${D}Downloaded folders:${RST}\n\n"
  local dirs=()
  while IFS= read -r d; do
    dirs+=("$(basename "$d")")
    printf "  ${C}[%d]${RST}  %s\n" "${#dirs[@]}" "$(basename "$d")"
  done < <(find "$DOWNLOAD_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
  if [ ${#dirs[@]} -eq 0 ]; then info "No downloads yet."; sleep 2; main_menu; return; fi
  printf "\n  ${D}Number to delete (0 = cancel):${RST} "; read -r dc
  [[ "$dc" == "0" ]] && { main_menu; return; }
  local idx=$(( dc - 1 ))
  if [[ $idx -ge 0 && $idx -lt ${#dirs[@]} ]]; then
    local target="$DOWNLOAD_ROOT/${dirs[$idx]}"
    printf "\n  ${R}⚠ Delete:${RST} %s\n  ${R}[y]${RST} confirm  ${D}[n]${RST} cancel: " "$target"
    read -r cf
    [[ "$cf" =~ ^[Yy]$ ]] && rm -rf "$target" && ok "Deleted." || info "Cancelled."
  fi
  sleep 2; main_menu
}

show_system_info() {
  cls; printf "\n"; box "System Info"
  printf "  ${D}yt-dlp  :${RST}  ${W}%s${RST}\n" "$(yt-dlp --version 2>/dev/null || echo 'not found')"
  printf "  ${D}ffmpeg  :${RST}  ${W}%s${RST}\n" "$(ffmpeg -version 2>/dev/null | head -1 | cut -d' ' -f3 || echo 'not found')"
  printf "  ${D}python3 :${RST}  ${W}%s${RST}\n" "$(python3 --version 2>/dev/null || echo 'not found')"
  printf "  ${D}Folder  :${RST}  ${C}%s${RST}\n" "$DOWNLOAD_ROOT"
  local used; used=$(du -sh "$DOWNLOAD_ROOT" 2>/dev/null | cut -f1)
  printf "  ${D}Used    :${RST}  ${W}${used:-0}${RST}\n"
  if find "$DOWNLOAD_ROOT" -name ".last_run" -maxdepth 3 2>/dev/null | grep -q .; then
    printf "\n  ${D}Last runs:${RST}\n"
    find "$DOWNLOAD_ROOT" -name ".last_run" -maxdepth 3 2>/dev/null | while read -r f; do
      printf "  ${C}·${RST} ${D}%-30s${RST} → ${W}%s${RST}\n" \
        "$(basename "$(dirname "$f")")" "$(cat "$f")"
    done
  fi
  printf "\n"; div; printf "  ${D}Press ENTER to go back...${RST}"; read -r; main_menu
}

update_project() {
  cls; printf "\n"; box "Update"
  printf "  ${C}[1/3]${RST} Updating yt-dlp...\n"
  pip install --quiet --upgrade yt-dlp 2>/dev/null \
    && ok "yt-dlp → v$(yt-dlp --version 2>/dev/null)" \
    || warn "Could not update yt-dlp"
  printf "\n  ${C}[2/3]${RST} Updating packages...\n"
  DEBIAN_FRONTEND=noninteractive pkg upgrade -y 2>&1 | grep -E "upgraded|error" | tail -3
  ok "Packages updated"
  printf "\n  ${C}[3/3]${RST} Pulling from GitHub...\n"
  cd "$SCRIPT_DIR" || return
  if git remote get-url origin &>/dev/null; then
    git pull --rebase 2>&1 | tail -3 && ok "Script updated"
  else
    warn "No GitHub remote — only yt-dlp & packages updated"
    info "Add remote: git remote add origin <URL>"
  fi
  printf "\n"; div; printf "  ${D}Press ENTER to go back...${RST}"; read -r; main_menu
}

settings_menu() {
  cls; printf "\n"; box "Settings"
  printf "  ${D}Download folder:${RST}\n  ${C}%s${RST}\n\n" "$DOWNLOAD_ROOT"
  printf "  ${W}[1]${RST}  Change folder\n  ${W}[2]${RST}  Back\n\n  Choose: "
  read -r sc
  if [[ "$sc" == "1" ]]; then
    printf "\n  ${C}New path:${RST} "; read -r NEW_ROOT
    if [[ -n "$NEW_ROOT" ]]; then
      mkdir -p "$NEW_ROOT" 2>/dev/null && {
        DOWNLOAD_ROOT="$NEW_ROOT"
        echo "DOWNLOAD_ROOT=\"$DOWNLOAD_ROOT\"" > "$CONFIG"
        ok "Saved: $DOWNLOAD_ROOT"
      } || err "Cannot create that directory"
    fi
  fi
  sleep 1; main_menu
}

check_deps() {
  local miss=()
  for t in yt-dlp ffmpeg python3; do command -v "$t" &>/dev/null || miss+=("$t"); done
  if [ ${#miss[@]} -gt 0 ]; then
    err "Missing tools: ${miss[*]}"
    printf "  ${Y}Run install.sh first:  bash install.sh${RST}\n\n"
    exit 1
  fi
}

# ═══════════════════════════════════════════════════════════════
# MAIN MENU
# ═══════════════════════════════════════════════════════════════
main_menu() {
  local menu_items=(
    "▶ |Start new download|YouTube · Facebook · any URL"
    "⏸ |Pause / Resume|SIGSTOP / SIGCONT current"
    "⏹ |Stop download|Kill current process"
    "↩ |Resume last session|Continue from where stopped"
    "🗑 |Delete folder|Remove a download folder"
    "↑ |Update|yt-dlp · packages · GitHub"
    "⚙ |Settings|Change download folder"
    "ℹ |System info|Versions · storage · last runs"
    "✕ |Exit|"
  )
  tui_menu "Main Menu" menu_items
  case "$TUI_RESULT" in
    0) start_download   ;;
    1) pause_download   ;;
    2) stop_download    ;;
    3) resume_download  ;;
    4) delete_folder    ;;
    5) update_project   ;;
    6) settings_menu    ;;
    7) show_system_info ;;
    8) _goodbye         ;;
    *) main_menu        ;;
  esac
}

check_deps
main_menu
