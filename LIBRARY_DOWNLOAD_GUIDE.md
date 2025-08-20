# DamiaUI Library Download Guide
## Essential Libraries for WoW 11.2 Compatibility

---

## ✅ Already Downloaded
1. **oUF** - Unit Frames Framework
   - Already cloned from: https://github.com/oUF-wow/oUF

---

## 📥 Libraries to Download

### 1. LibStub (REQUIRED)
**Purpose:** Core library loading system
**Download:** 
- Direct file: https://raw.githubusercontent.com/BigWigsMods/packager/master/LibStub/LibStub.lua
- Alternative: https://www.wowace.com/projects/libstub/files
- Place in: `DamiaUI/Libraries/LibStub/LibStub.lua`

### 2. CallbackHandler-1.0 (REQUIRED)
**Purpose:** Event callback management
**Download:**
- GitHub Repo: https://github.com/BigWigsMods/packager/tree/master/CallbackHandler-1.0
- Direct files:
  - https://raw.githubusercontent.com/BigWigsMods/packager/master/CallbackHandler-1.0/CallbackHandler-1.0.lua
  - https://raw.githubusercontent.com/BigWigsMods/packager/master/CallbackHandler-1.0/CallbackHandler-1.0.xml
- Place in: `DamiaUI/Libraries/CallbackHandler-1.0/`

### 3. LibActionButton-1.0 (HIGHLY RECOMMENDED)
**Purpose:** Advanced action button handling for 11.2
**Download:**
- GitHub: https://github.com/nevcairiel/LibActionButton-1.0
- Clone command: `git clone https://github.com/nevcairiel/LibActionButton-1.0.git`
- Place in: `DamiaUI/Libraries/LibActionButton-1.0/`

### 4. LibSharedMedia-3.0 (OPTIONAL but useful)
**Purpose:** Shared media (textures, fonts, sounds)
**Download:**
- CurseForge: https://www.curseforge.com/wow/addons/libsharedmedia-3-0/files
- Place in: `DamiaUI/Libraries/LibSharedMedia-3.0/`

### 5. AceDB-3.0 (OPTIONAL - for advanced settings)
**Purpose:** Database/SavedVariables management
**Download:**
- Part of Ace3: https://www.curseforge.com/wow/addons/ace3/files
- Or standalone from: https://www.wowace.com/projects/ace3/files
- Place in: `DamiaUI/Libraries/AceDB-3.0/`

---

## 📦 Manual Download Instructions

### Option 1: Download Individual Files
1. Visit each GitHub raw link
2. Right-click and "Save As..."
3. Place in the appropriate Libraries subfolder

### Option 2: Use Git (Recommended)
```bash
cd /Users/lee/Library/Mobile Documents/com~apple~CloudDocs/Dev/Damia/DamiaUI/Libraries

# LibActionButton (most important for action bars)
git clone https://github.com/nevcairiel/LibActionButton-1.0.git

# For Ace3 libraries (optional but useful)
git clone https://github.com/AceAddOn/Ace3.git
```

### Option 3: Download from CurseForge
1. Go to each CurseForge link
2. Download the latest version
3. Extract only the library folder (not the entire addon)
4. Place in DamiaUI/Libraries/

---

## 📝 After Downloading

Once libraries are downloaded, update `DamiaUI.toc`:

```toc
# Libraries
Libraries\LibStub\LibStub.lua
Libraries\CallbackHandler-1.0\CallbackHandler-1.0.xml

# oUF (latest from GitHub)
Libraries\oUF\oUF.xml

# LibActionButton (if downloaded)
Libraries\LibActionButton-1.0\LibActionButton-1.0.xml

# Additional libraries as needed...
```

---

## 🔧 Quick Setup Commands

Run these commands to set up the essential libraries:

```bash
# Navigate to Libraries folder
cd "/Users/lee/Library/Mobile Documents/com~apple~CloudDocs/Dev/Damia/DamiaUI/Libraries"

# Create LibStub folder and download
mkdir -p LibStub
curl -L https://raw.githubusercontent.com/BigWigsMods/packager/master/LibStub/LibStub.lua -o LibStub/LibStub.lua

# Create CallbackHandler folder and download
mkdir -p CallbackHandler-1.0
curl -L https://raw.githubusercontent.com/BigWigsMods/packager/master/CallbackHandler-1.0/CallbackHandler-1.0.lua -o CallbackHandler-1.0/CallbackHandler-1.0.lua
curl -L https://raw.githubusercontent.com/BigWigsMods/packager/master/CallbackHandler-1.0/CallbackHandler-1.0.xml -o CallbackHandler-1.0/CallbackHandler-1.0.xml

# Clone LibActionButton (for proper action bars)
git clone https://github.com/nevcairiel/LibActionButton-1.0.git
```

---

## ⚠️ Important Notes

1. **LibActionButton-1.0** is crucial for proper action bar functionality in 11.2
2. **LibStub** and **CallbackHandler** are required by most other libraries
3. Always use the latest versions for 11.2 compatibility
4. Some libraries may require their own dependencies - check their documentation

---

## 🎯 Priority Order

1. **Essential:** LibStub, CallbackHandler-1.0
2. **Critical for Action Bars:** LibActionButton-1.0
3. **Already Have:** oUF (for unit frames)
4. **Nice to Have:** LibSharedMedia-3.0, AceDB-3.0

Download these in order and test after each addition to ensure compatibility.