# DamiaUI Integration System

The DamiaUI Integration System provides seamless configuration and positioning for popular World of Warcraft addons, ensuring they work perfectly with DamiaUI's centered layout philosophy.

## Features

- **Auto-Configuration**: Automatically detects and configures popular addons when they're loaded
- **Pre-configured Templates**: Ready-to-use import strings and configurations for WeakAuras, Details!, DBM, and more
- **Non-invasive**: Only applies templates when no existing user configuration is detected
- **Instant Integration**: When users install supported addons alongside DamiaUI, they get positioned and styled correctly automatically
- **Import/Export**: Share DamiaUI-compatible configurations with other users
- **Centered Layout Optimization**: All templates follow DamiaUI's centered UI philosophy

## Supported Addons

### WeakAuras
- **Class Resources**: Essential class-specific resource tracking (combo points, holy power, etc.)
- **Personal Cooldowns**: Important personal ability cooldowns displayed vertically
- **Target Debuffs**: Target debuff and DoT tracking
- **Raid Cooldowns**: Important raid utility and cooldown tracking
- **Proc Alerts**: Visual alerts for important procs and buffs
- **Boss Abilities**: Encounter-specific mechanic tracking

### Details! (DPS Meter)
- **Window Configurations**: Optimized positioning for different group types
- **Aurora Theme Integration**: Matches DamiaUI's Aurora-based styling
- **Dynamic Positioning**: Automatically adjusts based on solo/party/raid context
- **Custom Skin**: DamiaUI-specific Details! skin with matching colors

### DBM (Deadly Boss Mods)
- **Timer Bar Positioning**: Centered timer bars that don't interfere with UI elements
- **Warning Text Positioning**: Optimally placed warning messages
- **Color Scheme**: DBM colors that complement DamiaUI's theme
- **Dynamic Layout Adjustment**: Positions adjust based on UI layout preset

## How It Works

### Auto-Configuration Process

1. **Addon Detection**: The system monitors for addon loading events
2. **Configuration Check**: Verifies if the addon already has user configuration
3. **Template Application**: If no existing config, applies DamiaUI-optimized templates
4. **Positioning**: Uses DamiaUI's centered positioning system
5. **Styling**: Applies Aurora theme integration and DamiaUI colors

### Non-Invasive Principle

The integration system respects user choice:
- Never overwrites existing user configurations
- Only applies templates to "fresh" addon installations
- Provides manual options to apply templates if desired
- Easy reset to defaults functionality

## File Structure

```
Modules/Integration/
├── Integration.lua              # Main integration system
├── AutoConfig.lua              # Auto-configuration engine
├── Templates/
│   ├── WeakAurasTemplates.lua  # WeakAuras import strings and configs
│   ├── DetailsTemplates.lua    # Details! window configurations
│   └── DBMTemplates.lua        # DBM positioning and styling
└── README.md                   # This documentation
```

## Configuration

Integration settings are available in the DamiaUI configuration panel under "Integration":

### Auto-Configuration Options
- **Enable Auto-Configuration**: Toggle automatic addon configuration
- **Verbose Logging**: Enable detailed integration logging
- **Template Module Status**: View which template modules are active

### Per-Addon Settings
- **WeakAuras**: Auto-install recommended templates for player class
- **Details!**: Auto-configure window positioning based on group type
- **DBM**: Apply DamiaUI color scheme and positioning

## Usage

### For Users

The integration system works automatically:

1. **Install DamiaUI** and enable it
2. **Install supported addons** (WeakAuras, Details!, DBM, etc.)
3. **Login to game** - templates are applied automatically
4. **Enjoy perfectly positioned addons** that complement DamiaUI

### Manual Configuration

If you want to manually apply templates:

1. Open DamiaUI Configuration (`/damiaui config`)
2. Navigate to "Integration" section
3. Choose specific addon templates to apply
4. Use "Import Configuration" to share setups

### Sharing Configurations

To share your DamiaUI addon setup:

1. Go to Integration > Auto Configuration panel
2. Click "Export Configuration"
3. Share the generated string with others
4. Others can use "Import Configuration" to apply your setup

## Template Details

### WeakAuras Templates

All WeakAuras templates are positioned using DamiaUI's centered coordinate system:

- **Player Resources**: `x: -200, y: -140` (below player frame)
- **Target Resources**: `x: 200, y: -140` (below target frame)
- **Personal Cooldowns**: `x: -400, y: -50` (left side, vertical)
- **Target Debuffs**: `x: 400, y: -50` (right side, vertical)
- **Proc Alerts**: `x: 0, y: 50` (center, above player)

### Details! Templates

Details! windows are positioned based on group context:

- **Solo**: Compact positioning on the right side
- **Party**: Medium-sized windows with group-appropriate metrics
- **Raid**: Larger windows with comprehensive raid metrics

### DBM Templates

DBM elements are positioned to avoid UI conflicts:

- **Timer Bars**: `x: 0, y: 300` (top center)
- **Warning Text**: `x: 0, y: 0` (center screen)
- **Raid Warnings**: `x: 0, y: 150` (upper center)

## Development

### Adding New Templates

To add support for a new addon:

1. Create a new template module in `Templates/`
2. Implement the required interface methods:
   - `Initialize()`
   - `IsAddonAvailable()`
   - `ApplyTemplate(templateName)`
   - `GetAvailableTemplates()`

3. Register the module in `Integration.lua`
4. Add configuration options to `Defaults.lua`

### Template Module Interface

```lua
local NewAddonTemplates = {}

function NewAddonTemplates:Initialize()
    -- Initialize the template module
    return success
end

function NewAddonTemplates:IsAddonAvailable()
    -- Check if the target addon is loaded
    return boolean
end

function NewAddonTemplates:ApplyTemplate(templateName, options)
    -- Apply the specified template
    return success, message
end

function NewAddonTemplates:GetAvailableTemplates()
    -- Return list of available templates
    return templateTable
end
```

## Troubleshooting

### Templates Not Applied
- Check if addon is loaded after DamiaUI
- Verify auto-configuration is enabled
- Look for existing user configuration that prevents auto-apply

### Wrong Positioning
- Check UI scale settings
- Verify resolution detection is working correctly
- Try refreshing templates from Integration panel

### Import/Export Issues
- Ensure import string is complete and not truncated
- Check that source and destination have compatible addon versions
- Verify both users have the same supported addons installed

## Future Enhancements

Planned additions to the integration system:

- **Plater Nameplate Templates**: Positioning and styling for Plater
- **ElvUI Compatibility Mode**: Safe integration for ElvUI users
- **OmniCC Integration**: Cooldown styling integration
- **Masque Support**: Action bar button styling compatibility
- **Custom Template Builder**: In-game tool for creating custom templates

## Support

For issues with the integration system:

1. Check DamiaUI logs for integration errors
2. Verify addon versions are supported
3. Try resetting templates to defaults
4. Report issues on the DamiaUI GitHub repository

The integration system is designed to provide a seamless experience while respecting user choice and addon compatibility.