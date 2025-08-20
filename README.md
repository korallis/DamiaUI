# DamiaUI - World of Warcraft UI Replacement

## Clean Rebuild Project

This is a complete rebuild of DamiaUI, starting from proven working code.

## Project Structure

```
Damia/                     # Project root
├── README.md             # This file
├── LICENSE               # MIT License
├── .gitignore           # Git configuration
├── DamiaUI-Plan/        # Development documentation
│   ├── MASTER_REBUILD_PLAN.md      # Start here!
│   ├── WORKING_EXAMPLE.lua         # 350 lines of working code
│   ├── MISTAKES_ANALYSIS.md        # Learning from failures
│   ├── PREVENTION_ROADMAP.md       # Avoiding past mistakes
│   ├── IMPLEMENTATION_GUIDE.md     # Working code patterns
│   └── VALIDATION_CHECKLIST.md     # Testing procedures
└── DamiaUI/             # The actual addon folder
    ├── DamiaUI.toc      # Addon manifest
    ├── DamiaUI.lua      # Main addon file
    ├── Libraries/       # Standard libraries (NO RENAMING!)
    ├── Locales/        # Localization files
    └── Media/          # Icons and assets
```

## Installation

1. Copy the `DamiaUI` folder to:
   - **Windows**: `C:\Program Files\World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac**: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`

2. Launch World of Warcraft
3. Verify addon is listed in the AddOns menu
4. Type `/damiaui` in-game to test

## Development Approach

### Current Status: Clean Start
- Removed 131 files of non-functional code
- Starting with WORKING_EXAMPLE.lua (350 lines that actually work)
- Following proven patterns from successful addons

### Development Phases

**Phase 1: Foundation** (Current)
- Implement working player/target frames
- Add functional action bars
- Test everything works in-game

**Phase 2: Modularization**
- Split into logical files (6-7 max)
- Maintain all functionality
- Test after each change

**Phase 3: Configuration**
- Add slash commands
- Implement saved variables
- Keep it simple

## Core Development Rules

1. **NEVER rename libraries** - Use standard LibStub names
2. **Test in-game frequently** - Within 1 hour of coding
3. **Working code first** - No abstractions without functionality
4. **One feature at a time** - Complete before starting next
5. **Visible changes only** - If users can't see it, don't build it

## Documentation

All development documentation is in the `DamiaUI-Plan/` folder:

- **Start with**: `MASTER_REBUILD_PLAN.md`
- **Learn from**: `MISTAKES_ANALYSIS.md`
- **Reference**: `IMPLEMENTATION_GUIDE.md`
- **Test with**: `VALIDATION_CHECKLIST.md`

## Key Lesson Learned

> **131 files with zero functionality < 350 lines that actually work**

The previous version had excessive complexity with no actual functionality. This rebuild focuses on simple, working code that users can actually see and use.

## Testing

```lua
/damiaui         -- Main command
/reload          -- Reload UI
/framestack      -- Check frame visibility
```

## License

MIT License - See LICENSE file for details

## Contributing

This is currently in active rebuild. The focus is on getting core functionality working before accepting contributions.

---

**Remember**: Simple and working beats complex and broken every time.