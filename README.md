<div align="center">

```
 █████╗ ██╗    ██╗
██╔══██╗██║    ██║   AW Downloader
███████║██║ █╗ ██║   Multi-Site · Termux · Android
██╔══██║██║███╗██║   v3.0
██║  ██║╚███╔███╔╝
╚═╝  ╚═╝ ╚══╝╚══╝
```

![Version](https://img.shields.io/badge/version-3.0-blue?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Termux%20%7C%20Android-green?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-orange?style=flat-square)
![yt-dlp](https://img.shields.io/badge/powered%20by-yt--dlp-red?style=flat-square)
![Author](https://img.shields.io/badge/by-Ahmed%20Awad-cyan?style=flat-square)

**Download from YouTube, Facebook, Instagram, TikTok, and 1000+ sites — inside Termux on Android**

[Installation](#-quick-installation) · [Usage](#-usage) · [Modes](#-download-modes) · [Structure](#-folder-structure) · [Troubleshooting](#-troubleshooting) · [License](#-license)

---

### 🌐 اختر لغتك / Choose Your Language

[![العربية](https://img.shields.io/badge/🇸🇦-العربية-green?style=for-the-badge)](#-النسخة-العربية)
&nbsp;&nbsp;
[![English](https://img.shields.io/badge/🇬🇧-English-blue?style=for-the-badge)](#-english-version)

</div>

---

# 🇸🇦 النسخة العربية

<div align="center">

**حمّل من يوتيوب، فيسبوك، إنستاغرام، تيكتوك وأكثر من 1000 موقع — من داخل Termux على أندرويد**

</div>

---

## ✨ المميزات

| الميزة | التفاصيل |
|--------|----------|
| 🌍 دعم أكثر من 1000 موقع | YouTube · Facebook · Instagram · TikTok · Twitter/X · Vimeo وغيرها |
| 📂 تحميل الملفات | Google Drive · Dropbox · Mega · MediaFire · 4Shared · OneDrive · GoFile وغيرها |
| 🔍 معاينة تلقائية | يعرض اسم الملف وحجمه قبل التنزيل · معاينة نصوص وـ PDF في الـ terminal |
| 🛡 تخطي الإعلانات | يكتشف روابط الإعلانات والـ trackers ويتخطاها تلقائياً |
| 📥 تحميل كامل للقناة | Playlists + Uploads + مقاطع غير مصنفة — بدون تكرار |
| 🔗 Playlists غير مدرجة | دعم روابط Unlisted و Private Playlists |
| ♻️ بدون تكرار عبر Playlists | الفيديو المشترك بين Playlists يُحمَّل مرة واحدة فقط |
| ⏱ آخر تشغيل فقط | تحميل المقاطع الجديدة فقط منذ آخر تشغيل — لكل قناة مستقلة |
| 🎬 جودات متعددة | Best / 4K / 1080p / 720p / 480p / 360p |
| 🎵 صوت فقط | MP3 و M4A بجودة عالية |
| 📁 تنظيم تلقائي | مجلد لكل قناة · مجلد فرعي لكل Playlist |
| 🖥 واجهة TUI بمفاتيح الأسهم | تنقل بـ ↑↓ واختيار بـ Enter |
| 🔄 استئناف تلقائي | يكمل من حيث وقف عند الانقطاع |
| ⚙️ إعدادات من داخل البرنامج | تغيير مجلد التحميل بدون تعديل الكود |
| 📝 سجلات كاملة | ملف log لكل جلسة تحميل |

---

## 📋 المتطلبات

- **Android** 7.0 أو أحدث
- **Termux** من [F-Droid](https://f-droid.org/en/packages/com.termux/) *(لا تستخدم إصدار Google Play — قديم ومكسور)*
- اتصال بالإنترنت أثناء التثبيت
- مساحة كافية على التخزين

> ⚠️ **مهم جداً:** ثبّت Termux من **F-Droid** فقط، إصدار Google Play لا يدعم التثبيت بشكل صحيح.

---

## 🚀 التثبيت السريع

### الطريقة 1: عبر Git (موصى بها)

```bash
pkg install git -y
git clone https://github.com/ahmed-awad26/aw-downloader.git
cd aw-downloader
bash install.sh
```

### الطريقة 2: بدون Git

```bash
pkg install curl unzip -y
curl -L https://github.com/ahmed-awad26/aw-downloader/archive/main.zip -o aw-dl.zip
unzip aw-dl.zip
cd aw-downloader-main
bash install.sh
```

---

## 📦 الحزم التي يثبتها `install.sh` تلقائياً

### حزم Termux (pkg)

| الحزمة | الغرض |
|--------|--------|
| `python` | تشغيل yt-dlp |
| `ffmpeg` | دمج الفيديو والصوت وتحويل الصيغ |
| `curl` | تحميل الملفات |
| `wget` | تحميل بديل |
| `git` | تحديث البرنامج من GitHub |
| `libxml2` | مكتبة XML |
| `libxslt` | مكتبة XSLT |
| `openssl` | اتصالات مشفرة |
| `ca-certificates` | شهادات SSL |
| `termux-tools` | أدوات Termux الأساسية |
| `jq` | معالجة JSON |
| `unzip` | فك ضغط الملفات |
| `megatools` *(اختياري)* | تحميل ملفات Mega.nz |

### حزم Python (pip)

| الحزمة | الغرض |
|--------|--------|
| `yt-dlp` | محرك التحميل الرئيسي (1000+ موقع) |
| `requests` | طلبات HTTP |
| `tqdm` | شريط التقدم |
| `rich` | تنسيق ألوان الـ terminal |
| `colorama` | ألوان ANSI |

---

## 🎮 الاستخدام

```bash
# من مجلد المشروع
bash ytdl.sh

# أو من أي مكان بعد التثبيت
awdl
```

### خطوات التحميل

```
1. من القائمة الرئيسية اختر "Start new download"
2. أدخل أي رابط:
   • https://www.youtube.com/@ChannelName       (قناة يوتيوب)
   • https://www.youtube.com/playlist?list=PL…  (قائمة تشغيل)
   • https://www.facebook.com/video/…           (فيسبوك)
   • https://www.instagram.com/reel/…           (إنستاغرام)
   • أي رابط فيه فيديو — yt-dlp يكتشفه تلقائياً
3. اختر الجودة (1080p موصى به)
4. لقنوات يوتيوب: اختر وضع التحميل
5. أكد البدء — التحميل يبدأ فوراً
```

---

## 📥 أوضاع التحميل

*(لقنوات يوتيوب فقط — باقي المواقع تُحمَّل مباشرة)*

| الوضع | الوصف |
|-------|-------|
| Playlists only | كل Playlists القناة في مجلدات منفصلة |
| Uploads only | كل ما رُفع على القناة |
| Playlists + Uploads | الاثنان — بدون تكرار للفيديوهات المشتركة |
| All + Uncategorized | الاثنان + مقاطع خارج أي Playlist |
| Latest since last run | المقاطع الجديدة فقط منذ آخر تشغيل |
| Custom playlist URL | رابط Playlist مباشر (Unlisted / Private) |

---

## 📁 هيكل المجلدات

```
/sdcard/Download/AW-DL/
│
├── 📁 ChannelName/
│   ├── 📁 Playlists/
│   │   ├── 📁 Playlist_Title_1/
│   │   │   ├── Video 1 [id].mp4
│   │   │   └── Video 2 [id].mp4
│   │   └── 📁 Playlist_Title_2/
│   │       └── ...
│   ├── 📁 Uploads/
│   ├── 📁 Uncategorized/
│   ├── 📁 Latest/
│   ├── .last_run              ← تاريخ آخر تشغيل (لكل قناة)
│   ├── latest_report.txt      ← تقرير آخر تحديث
│   └── download_YYYYMMDD.log  ← سجل جلسة التحميل
│
├── 📁 facebook.com/
│   └── video [id].mp4
│
└── 📁 Playlist_PLxxxxxxxx/
    └── ...
```

---

## 🔧 استكشاف الأخطاء

### ❌ إذن التخزين مرفوض

```bash
termux-setup-storage
# ثم أعد تشغيل Termux
# أندرويد 11+: الإعدادات ← التطبيقات ← Termux ← الأذونات ← التخزين ← السماح بالكل
```

### ❌ yt-dlp غير موجود

```bash
pip install yt-dlp
# أو
pip3 install yt-dlp
```

### ❌ ffmpeg غير موجود أو معطوب

```bash
pkg install ffmpeg --fix-broken -y
```

### ❌ التحميل بطيء أو يتوقف

```bash
pip install --upgrade yt-dlp
```

### ❌ خطأ SSL

```bash
pkg install openssl ca-certificates -y
pip install --upgrade certifi
```

### ❌ لا مساحة كافية

```bash
df -h /sdcard
find "$HOME/storage/shared/Download" -name "*.part" -delete
```

### ❌ pkg update يفشل

```bash
termux-change-repo
pkg update -y
```

---

## 🔄 التحديث

```bash
cd aw-downloader
bash update.sh
# أو من داخل البرنامج: القائمة الرئيسية ← Update
```

---

## ⚙️ الإعداد

```bash
# تغيير مجلد التحميل من داخل البرنامج:
# القائمة الرئيسية ← Settings ← Change folder

# أو يدوياً:
echo 'DOWNLOAD_ROOT=/sdcard/MyVideos' >> .config
```

---

<div align="center">

صُنع بـ ❤️ بواسطة **Ahmed Awad**  
[github.com/ahmed-awad26](https://github.com/ahmed-awad26)  
⭐ إذا أعجبك المشروع، أضفه للمفضلة!

[⬆ اختر اللغة](#-اختر-لغتك--choose-your-language)

</div>

---
---

# 🇬🇧 English Version

<div align="center">

**Download from YouTube, Facebook, Instagram, TikTok, and 1000+ sites — inside Termux on Android**

</div>

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 🌍 1000+ video sites | YouTube · Facebook · Instagram · TikTok · Twitter/X · Vimeo and more |
| 📂 File hosting | Google Drive · Dropbox · Mega · MediaFire · 4Shared · OneDrive · GoFile + more |
| 🔍 Pre-download info | Shows filename and size before downloading · auto-previews text/PDF files |
| 🛡 Ad redirect filter | Detects and skips tracker/ad redirects embedded in download pages |
| 📥 Full channel download | Playlists + Uploads + Uncategorized — no duplicates |
| 🔗 Unlisted playlist support | Download private or unlisted playlists by direct URL |
| ♻️ Cross-playlist dedup | Videos shared across playlists are downloaded exactly once |
| ⏱ Latest-only mode | Download only new videos since last run — tracked per channel |
| 🎬 Multiple qualities | Best / 4K / 1080p / 720p / 480p / 360p |
| 🎵 Audio only | High-quality MP3 and M4A extraction |
| 📁 Smart folder structure | One folder per channel, subfolders per playlist |
| 🖥 Arrow-key TUI | Navigate with ↑↓, select with Enter |
| 🔄 Auto-resume | Continues from where it stopped after interruption |
| ⚙️ In-app settings | Change download folder without editing code |
| 📝 Full logging | Log file per download session |

---

## 📋 Requirements

- **Android** 7.0 or later
- **Termux** from [F-Droid](https://f-droid.org/en/packages/com.termux/) *(do NOT use Google Play — it's outdated)*
- Internet connection during installation
- Sufficient storage space

> ⚠️ **Important:** Use the F-Droid version of Termux only. The Google Play version does not support proper package installation.

---

## 🚀 Quick Installation

### Method 1: Via Git (Recommended)

```bash
pkg install git -y
git clone https://github.com/ahmed-awad26/aw-downloader.git
cd aw-downloader
bash install.sh
```

### Method 2: Without Git

```bash
pkg install curl unzip -y
curl -L https://github.com/ahmed-awad26/aw-downloader/archive/main.zip -o aw-dl.zip
unzip aw-dl.zip
cd aw-downloader-main
bash install.sh
```

---

## 📦 Packages Installed by `install.sh`

### Termux packages (pkg)

| Package | Purpose |
|---------|---------|
| `python` | Runs yt-dlp |
| `ffmpeg` | Merges video/audio, converts formats |
| `curl` | File downloading |
| `wget` | Fallback downloader |
| `git` | Updates from GitHub |
| `libxml2` | XML parsing |
| `libxslt` | XSLT processing |
| `openssl` | Secure connections |
| `ca-certificates` | SSL certificate bundle |
| `termux-tools` | Core Termux utilities |
| `jq` | JSON processing |
| `unzip` | ZIP archive extraction |
| `megatools` *(optional)* | Mega.nz downloads |

### Python packages (pip)

| Package | Purpose |
|---------|---------|
| `yt-dlp` | Main download engine (1000+ sites) |
| `requests` | HTTP request library |
| `tqdm` | Progress bar utilities |
| `rich` | Colored terminal formatting |
| `colorama` | Cross-platform ANSI colors |

---

## 🎮 Usage

```bash
# From the project folder
bash ytdl.sh

# From anywhere after installation
awdl
```

### Steps

```
1. Select "Start new download" from the main menu
2. Paste any URL:
   • https://www.youtube.com/@ChannelName         (YouTube channel)
   • https://www.youtube.com/playlist?list=PL…    (playlist)
   • https://www.facebook.com/video/…             (Facebook)
   • https://www.instagram.com/reel/…             (Instagram)
   • Any URL with a playable video — yt-dlp auto-detects it
3. Choose quality (1080p recommended)
4. For YouTube channels: choose a download mode
5. Confirm — download starts immediately
```

---

## 📥 Download Modes

*(YouTube channels only — all other sites download directly)*

| Mode | Description |
|------|-------------|
| Playlists only | All channel playlists in separate subfolders |
| Uploads only | Every video ever uploaded to the channel |
| Playlists + Uploads | Both — shared videos downloaded only once |
| All + Uncategorized | Everything + videos not in any playlist |
| Latest since last run | Only new videos since the last session |
| Custom playlist URL | Any direct playlist link (unlisted / private) |

---

## 📁 Folder Structure

```
/sdcard/Download/AW-DL/
│
├── 📁 ChannelName/
│   ├── 📁 Playlists/
│   │   ├── 📁 Playlist_Title_1/
│   │   │   ├── Video 1 [id].mp4
│   │   │   └── Video 2 [id].mp4
│   │   └── 📁 Playlist_Title_2/
│   ├── 📁 Uploads/
│   ├── 📁 Uncategorized/
│   ├── 📁 Latest/
│   ├── .last_run              ← date of last run (per channel)
│   ├── latest_report.txt      ← latest-mode download report
│   └── download_YYYYMMDD.log
│
├── 📁 facebook.com/
│   └── video [id].mp4
│
└── 📁 Playlist_PLxxxxxxxx/
    └── ...
```

---

## 🔧 Troubleshooting

### ❌ Storage permission denied

```bash
termux-setup-storage
# Android 11+: Settings → Apps → Termux → Permissions → Storage → Allow all files
```

### ❌ yt-dlp not found

```bash
pip install yt-dlp
```

### ❌ ffmpeg broken or not found

```bash
pkg install ffmpeg --fix-broken -y
```

### ❌ Download stalls or is slow

```bash
pip install --upgrade yt-dlp
```

### ❌ SSL / certificate error

```bash
pkg install openssl ca-certificates -y
pip install --upgrade certifi
```

### ❌ No storage space

```bash
df -h /sdcard
find "$HOME/storage/shared/Download" -name "*.part" -delete
```

### ❌ pkg update fails

```bash
termux-change-repo
pkg update -y
```

---

## 🔄 Updating

```bash
cd aw-downloader
bash update.sh
# or from inside the app: Main Menu → Update
```

---

## 📄 License

```
MIT License

Copyright (c) 2025 Ahmed Awad (github.com/ahmed-awad26)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

> **Notice:** This tool relies on [yt-dlp](https://github.com/yt-dlp/yt-dlp) for downloading.  
> Please respect the intellectual property rights of content creators and the terms of service of each platform.

---

<div align="center">

Made with ❤️ by **Ahmed Awad**  
[github.com/ahmed-awad26](https://github.com/ahmed-awad26)

⭐ If you find this useful, give it a star!

[⬆ Back to language selection](#-اختر-لغتك--choose-your-language)

</div>
