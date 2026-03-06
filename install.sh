#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
#   AW Downloader  ·  v3.0  ·  Termux Installer
#   Author  : Ahmed Awad  (github.com/ahmed-awad26)
#   License : MIT
# ═══════════════════════════════════════════════════════════════

set -e

C='\033[0;36m'; W='\033[1;37m'; G='\033[0;32m'
R='\033[0;31m'; Y='\033[1;33m'; D='\033[2m'; RST='\033[0m'

# ── Banner ───────────────────────────────────────────────────
show_banner() {
  clear
  printf "${C}\n"
  printf "  ╔══════════════════════════════════════════════════════╗\n"
  printf "  ║                                                      ║\n"
  printf "  ║   ${W} █████╗ ██╗    ██╗${C}                               ║\n"
  printf "  ║   ${W}██╔══██╗██║    ██║${C}                               ║\n"
  printf "  ║   ${W}███████║██║ █╗ ██║${C}  ${D}Downloader  v3.0${RST}${C}             ║\n"
  printf "  ║   ${W}██╔══██║██║███╗██║${C}  ${D}by Ahmed Awad${RST}${C}                ║\n"
  printf "  ║   ${W}██║  ██║╚███╔███╔╝${C}  ${D}github.com/ahmed-awad26${RST}${C}      ║\n"
  printf "  ║   ${W}╚═╝  ╚═╝ ╚══╝╚══╝${C}                               ║\n"
  printf "  ║                                                      ║\n"
  printf "  ╚══════════════════════════════════════════════════════╝${RST}\n\n"
}

# ── Helpers ──────────────────────────────────────────────────
step() { printf "\n  ${C}┌─${RST} ${W}%s${RST}\n" "$1"; }
ok()   { printf "  ${G}✔${RST}  %s\n" "$1"; }
warn() { printf "  ${Y}⚠${RST}  %s\n" "$1"; }
err()  { printf "  ${R}✘${RST}  %s\n" "$1"; }
info() { printf "  ${D}·  %s${RST}\n" "$1"; }

# ── Progress bar (single line, updates in place) ─────────────
progress_bar() {
  local msg="$1" n="$2" total="$3"
  local pct=$(( n * 100 / total ))
  local filled=$(( pct * 30 / 100 ))
  local bar="" i
  for (( i=0; i<filled;  i++ )); do bar+="█"; done
  for (( i=filled; i<30; i++ )); do bar+="░"; done
  printf "\r\033[K  ${C}[${G}%s${C}]${RST} ${W}%3d%%${RST}  ${D}%s${RST}" "$bar" "$pct" "$msg"
}

# ─────────────────────────────────────────────────────────────
show_banner
printf "  ${W}Starting installation...${RST}\n"

# ── 1. Storage permission ────────────────────────────────────
step "Requesting storage permission"
printf "\n  ${Y}⚠${RST}  Storage access is needed to save downloads.\n"
printf "  ${D}A dialog will appear — tap ${G}ALLOW${D} to continue.${RST}\n\n"
printf "  ${C}Press ENTER to request storage permission...${RST} "
read -r

termux-setup-storage

info "Waiting for permission..."
sleep 3

STORAGE_OK=false
for _d in "$HOME/storage/shared" "/sdcard" "/storage/emulated/0"; do
  [ -d "$_d" ] && [ -w "$_d" ] && { STORAGE_OK=true; SDCARD="$_d"; break; }
done

if [ "$STORAGE_OK" = false ]; then
  err "Storage permission not granted."
  printf "\n  ${Y}Fixes:${RST}\n"
  printf "  ${D}1. Settings → Apps → Termux → Permissions → Storage → Allow${RST}\n"
  printf "  ${D}2. Restart Termux and run install.sh again${RST}\n"
  printf "  ${D}3. Android 11+: grant 'All files access'${RST}\n\n"
  printf "  ${C}Continue with Termux internal storage only? [y/n]:${RST} "
  read -r fb
  if [[ "$fb" =~ ^[Yy]$ ]]; then
    SDCARD="$HOME/downloads"; mkdir -p "$SDCARD"
    warn "Downloads will save to: $SDCARD"
  else
    err "Installation cancelled."; exit 1
  fi
fi
ok "Storage granted → $SDCARD"

# ── 2. Upgrade all packages ──────────────────────────────────
step "Upgrading Termux packages"
warn "This may take a few minutes..."
DEBIAN_FRONTEND=noninteractive pkg upgrade -y 2>&1 \
  | grep -E "upgraded|newly installed|error" | tail -5
ok "Packages upgraded"

# ── 3. Install pkg packages ──────────────────────────────────
step "Installing required packages"
echo ""

PKG_LIST=(
  "python"         "Python 3 runtime (yt-dlp engine)"
  "ffmpeg"         "Video/audio merge & format conversion"
  "curl"           "File downloader"
  "wget"           "Fallback file downloader"
  "git"            "Version control & updates"
  "libxml2"        "XML parsing library"
  "libxslt"        "XSLT processing library"
  "openssl"        "SSL / secure connections"
  "ca-certificates" "SSL certificate bundle"
  "termux-tools"   "Core Termux utilities"
  "jq"             "JSON processor"
  "unzip"          "ZIP archive tool"
)

TOTAL_PKG=$(( ${#PKG_LIST[@]} / 2 ))
i=0; count=0
while [ $i -lt ${#PKG_LIST[@]} ]; do
  name="${PKG_LIST[$i]}"
  desc="${PKG_LIST[$((i+1))]}"
  (( count++ ))
  progress_bar "pkg: $name" "$count" "$TOTAL_PKG"
  DEBIAN_FRONTEND=noninteractive pkg install -y "$name" 2>/dev/null \
    || { echo ""; warn "Skipped: $name"; }
  i=$(( i + 2 ))
done
echo ""
ok "All pkg packages installed"

# ── 3b. Verify ffmpeg ────────────────────────────────────────
step "Verifying ffmpeg"
if ! ffmpeg -version &>/dev/null; then
  warn "ffmpeg has a linking issue — attempting fix..."
  DEBIAN_FRONTEND=noninteractive pkg install -y --fix-broken ffmpeg 2>/dev/null || true
  ffmpeg -version &>/dev/null && ok "ffmpeg fixed" || warn "ffmpeg still broken — try: pkg install ffmpeg --fix-broken"
else
  ok "ffmpeg OK → $(ffmpeg -version 2>/dev/null | head -1 | cut -d' ' -f3)"
fi

# ── 4. pip packages ──────────────────────────────────────────
step "Installing Python libraries"
echo ""

PIP_LIST=(
  "yt-dlp"     "Main download engine (YouTube + 1000+ sites)"
  "requests"   "HTTP request library"
  "tqdm"       "Progress bar utilities"
  "rich"       "Colored terminal output"
  "colorama"   "Cross-platform ANSI colors"
)

TOTAL_PY=$(( ${#PIP_LIST[@]} / 2 ))
j=0; pcount=0
while [ $j -lt ${#PIP_LIST[@]} ]; do
  pkg="${PIP_LIST[$j]}"
  pdesc="${PIP_LIST[$((j+1))]}"
  (( pcount++ ))
  progress_bar "pip: $pkg" "$pcount" "$TOTAL_PY"
  pip install --quiet --upgrade "$pkg" 2>/dev/null \
    || pip3 install --quiet --upgrade "$pkg" 2>/dev/null \
    || { echo ""; warn "Skipped pip: $pkg"; }
  j=$(( j + 2 ))
done
echo ""
ok "Python libraries installed"

# ── 5. Verify critical tools ─────────────────────────────────
step "Verifying tools"
ALL_OK=true
for tool in python3 ffmpeg yt-dlp curl git; do
  if command -v "$tool" &>/dev/null; then
    ver=$("$tool" --version 2>/dev/null | head -1 || echo "OK")
    ok "$tool  ${D}$ver${RST}"
  else
    err "$tool  NOT FOUND"; ALL_OK=false
  fi
done
[ "$ALL_OK" = false ] && warn "Some tools missing — check internet and re-run."

# ── 6. Make scripts executable ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$SCRIPT_DIR/ytdl.sh"  2>/dev/null || true
chmod +x "$SCRIPT_DIR/ytdl_helper.py" 2>/dev/null || true

# ── 7. Create global shortcut ─────────────────────────────────
step "Creating global shortcut"
SHORTCUT="$PREFIX/bin/awdl"
cat > "$SHORTCUT" << SHORTCUT_EOF
#!/data/data/com.termux/files/usr/bin/bash
cd "$SCRIPT_DIR"
bash ytdl.sh "\$@"
SHORTCUT_EOF
chmod +x "$SHORTCUT"
ok "Shortcut created — type 'awdl' from anywhere to launch"

# ── 8. Save config ───────────────────────────────────────────
cat > "$SCRIPT_DIR/.config" << CONF_EOF
SDCARD=$SDCARD
DOWNLOAD_ROOT=$SDCARD/Download/AW-DL
CONF_EOF
ok "Config saved → $SDCARD/Download/AW-DL"

# ── 9. Git init ──────────────────────────────────────────────
step "Initializing Git repo"
cd "$SCRIPT_DIR"
[ ! -d ".git" ] && git init -q && ok "Git initialized" || ok "Git already initialized"
git config user.email 2>/dev/null | grep -q @ \
  || { git config user.email "aw-downloader@local"; git config user.name "Ahmed Awad"; }
git add -A
git diff --cached --quiet \
  && ok "No new changes" \
  || { git commit -q -m "AW Downloader v3.0 — Multi-site TUI" && ok "Git commit created"; }

printf "\n  ${D}To push to GitHub:${RST}\n"
printf "  ${D}  git remote add origin https://github.com/ahmed-awad26/aw-downloader.git${RST}\n"
printf "  ${D}  git push -u origin main${RST}\n"

# ── Done ─────────────────────────────────────────────────────
printf "\n"
printf "  ${G}╔══════════════════════════════════════════════════════╗${RST}\n"
printf "  ${G}║   ✔  Installation complete!                         ║${RST}\n"
printf "  ${G}╠══════════════════════════════════════════════════════╣${RST}\n"
printf "  ${G}║${RST}   ${D}Run from folder :${RST}  ${W}bash ytdl.sh${RST}                  ${G}║${RST}\n"
printf "  ${G}║${RST}   ${D}Run from anywhere:${RST}  ${W}awdl${RST}                         ${G}║${RST}\n"
printf "  ${G}╚══════════════════════════════════════════════════════╝${RST}\n\n"
printf "  ${C}Press ENTER to launch now...${RST} "
read -r
bash "$SCRIPT_DIR/ytdl.sh"
