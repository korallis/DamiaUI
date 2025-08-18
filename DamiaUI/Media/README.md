# DamiaUI Media Assets

This directory contains media assets for the DamiaUI addon, including fonts, sounds, textures, and the addon icon.

## Icon Creation Guide

### DamiaUI_Icon.blp Specifications

The addon icon should be created with the following specifications to maintain brand consistency:

#### Technical Requirements
- **Resolution**: 64x64 pixels
- **Format**: BLP (Blizzard Picture format) for WoW compatibility
- **Source Format**: TGA (Targa) for creation/editing
- **Color Depth**: 24-bit or 32-bit with alpha channel
- **Color Profile**: sRGB

#### Color Scheme
The DamiaUI brand uses a dark theme with orange accents:

- **Background**: Dark (RGB: 26, 26, 26) - `r=0.1, g=0.1, b=0.1`
- **Primary Accent**: Orange (RGB: 204, 128, 26) - `r=0.8, g=0.5, b=0.1`
- **Border/Secondary**: Medium gray (RGB: 77, 77, 77) - `r=0.3, g=0.3, b=0.3`
- **Text/Details**: Light gray (RGB: 230, 230, 230) - `r=0.9, g=0.9, b=0.9`

#### Design Elements
The icon should feature:
- **Primary Element**: Stylized "D" or "DUI" text
- **Style**: Bold, modern, professional appearance
- **Layout**: Centered composition with balanced spacing
- **Effects**: Subtle depth (bevel, shadow, or glow) without overwhelming the design
- **Border**: Optional thin border in medium gray for definition

#### Creation Steps

1. **Create Base Canvas**
   - New document: 64x64 pixels, transparent background
   - Add dark background rectangle with 2-3px rounded corners

2. **Add Typography**
   - Choose bold, sans-serif font (e.g., Arial Bold, Helvetica Bold)
   - Size: Approximately 36-42px for single "D", 24-28px for "DUI"
   - Color: Orange accent (#CC801A)
   - Position: Centered horizontally and vertically

3. **Apply Effects**
   - Subtle drop shadow: 1-2px offset, 15-20% opacity black
   - Optional inner bevel: 1px, soft highlight/shadow
   - Ensure effects don't reduce legibility

4. **Add Border (Optional)**
   - 1-2px stroke in medium gray (#4D4D4D)
   - Inside or center stroke to maintain 64x64 dimensions

5. **Export Process**
   - Save as 24-bit TGA first (DamiaUI_Icon.tga)
   - Convert to BLP using WoW addon tools:
     - BLPConverter
     - Warcraft III Viewer
     - World Editor
     - Online BLP converters

#### File Naming Convention
- **Working File**: `DamiaUI_Icon.tga` (source file for editing)
- **Final File**: `DamiaUI_Icon.blp` (WoW-compatible format)

#### Quality Checklist
- [ ] Icon is clearly readable at 64x64 pixels
- [ ] Colors match DamiaUI brand specifications
- [ ] Icon maintains professional appearance
- [ ] No pixelation or artifacts
- [ ] File size is reasonable (typically < 10KB for BLP)
- [ ] Icon works well on both light and dark backgrounds

#### BLP Conversion Tools
- **BLPConverter**: Free Windows tool for BLP creation
- **Online Converters**: Various web-based BLP converters
- **GIMP Plugin**: BLP import/export plugin available
- **Photoshop Plugin**: Third-party BLP support plugins

#### Testing
Test the icon in-game by:
1. Loading the addon
2. Opening the AddOns menu in character select
3. Verifying icon appears correctly and is easily identifiable
4. Checking icon clarity in addon management interfaces

## Directory Structure
```
Media/
├── DamiaUI_Icon.blp     # Addon icon (BLP format)
├── DamiaUI_Icon.tga     # Icon source file (TGA format)
├── Fonts/               # Custom fonts
├── Sounds/              # Audio files
└── Textures/            # UI textures and backgrounds
```

## File Formats
- **Icons**: BLP (converted from TGA)
- **Fonts**: TTF, OTF
- **Sounds**: OGG, WAV
- **Textures**: BLP, TGA

## Brand Guidelines
Maintain consistency with DamiaUI's dark theme and orange accent colors throughout all media assets. The professional, modern aesthetic should be reflected in all visual elements.