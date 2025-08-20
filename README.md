# DamiaUI

A minimalist, dark-themed UI addon for World of Warcraft, featuring a clean aesthetic with modern functionality.

![WoW Version](https://img.shields.io/badge/WoW-11.2-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Active-success)

## Features

### 🎨 Dark Minimalist Design
- Clean, dark interface throughout
- Flat textures and subtle borders
- Consistent color scheme
- Reduced visual clutter
- Focus on functionality

### ⚔️ Action Bars
- 5 main action bars + pet/stance bars
- LibActionButton-1.0 integration
- 28px buttons with visual spacing
- Smart keybind abbreviations (SHIFT→s, ALT→a, CTRL→c)
- Class-specific paging and stances
- Vehicle and override bar support

### 💚 Unit Frames
- Powered by oUF framework
- Player, Target, Focus frames
- Party and Raid frames with range checking
- Arena frames for PvP
- Castbars with interrupt coloring
- Buff/Debuff tracking with filters

### 🗺️ Minimap
- Square minimap design
- Coordinate display
- Calendar integration
- Clean button arrangement

### 💬 Chat
- Improved chat tabs
- URL detection and copying
- Sticky channels
- Custom timestamps
- Dark background styling

### 📊 Data Texts
- System performance monitor
- Gold tracker
- Durability display
- Server/Local time

### ✨ Additional Features
- Nameplate styling
- Tooltip improvements
- DBM skin support
- Blizzard frame reskinning
- Error handling system

## Installation

1. Download the latest release from [Releases](https://github.com/yourusername/DamiaUI/releases)
2. Extract the `DamiaUI` folder to your WoW addons directory:
   - Retail: `World of Warcraft\_retail_\Interface\AddOns\`
   - Classic: `World of Warcraft\_classic_\Interface\AddOns\`
3. Restart World of Warcraft or reload UI with `/reload`

## Configuration

DamiaUI uses an in-game configuration system. Access settings with:
```
/damia
/damiaui
```

### Profile Management
- Multiple profile support
- Import/Export functionality
- Character-specific settings

## Slash Commands

| Command | Description |
|---------|-------------|
| `/damia` | Open configuration |
| `/damiaui` | Open configuration |
| `/damia reset` | Reset to defaults |
| `/damia profile [name]` | Switch profile |

## Compatibility

### Required WoW Version
- **11.2** (The War Within)

### Addon Compatibility
- **DBM**: Automatic skin detection and styling
- **BigWigs**: Compatible
- **WeakAuras**: Compatible
- **Details**: Compatible

## Known Issues

- Profile switching requires out of combat
- Some Blizzard frames may not appear until specific events trigger
- Minimap tracking menu requires modern Menu API

## Performance

- **Memory Usage**: ~2.8 MB
- **CPU Impact**: Minimal
- **Load Time**: < 0.5 seconds

## Development

### Libraries Used
- oUF (Unit Frames)
- rLib (Utilities)
- LibActionButton-1.0-ElvUI
- LibButtonGlow-1.0
- LibStub

### File Structure
```
DamiaUI/
├── DamiaUI.toc          # Addon manifest
├── Core/                # Core systems
├── Libraries/           # External libraries
├── Media/              # Textures and fonts
└── Modules/            # Feature modules
    ├── ActionBars/
    ├── Chat/
    ├── DataTexts/
    ├── Minimap/
    ├── Nameplates/
    ├── Skins/
    └── UnitFrames/
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/DamiaUI/issues)
- **Discord**: [Join our Discord](https://discord.gg/yourdiscord)
- **Donations**: [Support Development](https://www.paypal.com/yourpaypal)

## Credits

- oUF framework by Haste
- LibActionButton by Nevcairiel
- Community testers and contributors

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

### Version 2.0.0 (2024-08-20)
- Complete rebuild for WoW 11.2
- Full API compatibility update
- LibActionButton integration
- Modern library implementation
- Performance optimizations

### Previous Versions
See [CHANGELOG.md](https://github.com/yourusername/DamiaUI/blob/main/CHANGELOG.md) for full history.

---

**DamiaUI** - Minimalist perfection for World of Warcraft