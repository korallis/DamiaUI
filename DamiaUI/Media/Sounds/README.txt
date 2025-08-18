DamiaUI Media - Sounds Directory

This directory contains sound files for the DamiaUI addon.

Sound Categories:
- UI interaction sounds (button clicks, hover effects)
- Notification sounds (alerts, warnings, confirmations)
- Combat sounds (ability ready, low health warnings)
- Special event sounds (level up, achievement unlocks)

File Formats:
- .ogg (Recommended for WoW - best compression/quality)
- .wav (Supported but larger file size)
- .mp3 (Supported in recent WoW versions)

Sound Requirements:
- Keep file sizes small for addon distribution
- Use appropriate sample rates (22kHz-44kHz)
- Consider volume normalization across all sounds
- Test in-game with various sound settings

Naming Convention:
- Use descriptive names: ButtonClick.ogg
- Include purpose in name: WarningAlert.ogg
- Avoid spaces in filenames

Production Note:
In production, this directory would contain actual sound files
such as:
- ButtonHover.ogg
- ButtonClick.ogg
- AlertWarning.ogg
- NotificationSuccess.ogg
- etc.

WoW Default Sounds can be referenced as:
- "Interface\\AddOns\\DamiaUI\\Media\\Sounds\\YourSound.ogg"

Sound Integration Example:
PlaySoundFile("Interface\\AddOns\\DamiaUI\\Media\\Sounds\\ButtonClick.ogg")