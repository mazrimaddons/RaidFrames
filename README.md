# Raid Frames

Keep your raid organised and important information easy to see.

- Original ArcheAge and Ellesmere-inspired frame designs with custom colours and dimensions.
- Click and optional hover targeting.
- Automatic class sorting and manual Ctrl-drag placement.
- A separate movable Priority group.
- Selected buff/debuff icons, timers, frame effects and optional screen alerts.
- Low-health and low-mana warnings and optional distance readings.
- Native raid-management access, saved profiles and profile sharing.
- A short first-use tutorial, with Quick tour available for replay.

## Current version

0.2.72. Hover targeting changes your actual selected target. Health, mana and effect
tracking depend on the information available from the game, with limited coverage
outside render distance. The experimental raid-effect reader admits up to 64
selected spell IDs at a time. See Known issues in the addon for current limitations.

## Installation folder

The runtime uses the folder name `Mazrim_Raid_Frames`. Install the files from
this repository into `Documents/AAClassic/Addon/Mazrim_Raid_Frames/`.
Keep that folder name when configuring the addon manager's installation identity.

For manual installation, add `Mazrim_Raid_Frames` to `Addon/addons.txt` on its own
line. Refresh Addons, or restart the client if it still reports an older version.

Updates should merge into the existing folder. Keep personal `settings.txt` and
`tutorial.txt` files when updating.

## Credits

Created by Mazrim with ChatGPT. See the bundled license files for shared code.
