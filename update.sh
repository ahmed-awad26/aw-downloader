#!/data/data/com.termux/files/usr/bin/bash
# update.sh — Self-updater for AW Downloader

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; RESET='\033[0m'; BOLD='\033[1m'

echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════╗"
echo "  ║   🔄 AW Downloader Updater    ║"
echo "  ╚═══════════════════════════════╝"
echo -e "${RESET}"

# Update pkg packages
echo -e "  ${WHITE}تحديث الحزم...${RESET}"
pkg update -y 2>/dev/null
pkg upgrade -y 2>/dev/null
echo -e "  ${GREEN}✔ تم تحديث الحزم${RESET}"

# Update yt-dlp
echo -e "  ${WHITE}تحديث yt-dlp...${RESET}"
pip install --upgrade yt-dlp 2>&1 | tail -2
echo -e "  ${GREEN}✔ تم تحديث yt-dlp: $(yt-dlp --version)${RESET}"

# Update from git if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/.git" ]; then
  echo -e "  ${WHITE}تحديث من GitHub...${RESET}"
  cd "$SCRIPT_DIR"
  git pull origin main 2>&1 | tail -3
  echo -e "  ${GREEN}✔ تم تحديث الكود${RESET}"
fi

echo ""
echo -e "  ${GREEN}${BOLD}✅ تم التحديث بنجاح!${RESET}"
echo -e "  ${CYAN}الإصدار الحالي لـ yt-dlp: $(yt-dlp --version)${RESET}"
