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

0.2.75 adds **General Settings > Buff tracking > Target-only buff tracking**.
It is off by default. When enabled, selected buffs update only while that raid
member is targeted; selected debuffs keep their normal raid tracking.
Changing mode clears previously collected buff history. This mode can still
show buffs cast by other healers: targeting does not identify their caster.
Save settings to keep the choice.

The tutorial now uses your selected frame design and colours for Ctrl-drag
practice. The opening tutorial card no longer has an arrow.

Hover targeting changes your actual selected target; it does not cast spells.
Health, mana and effect tracking depend on the game's available information,
with limited coverage outside render distance. The experimental raid-effect
reader admits up to 64 selected spell IDs. Last-seen timers are estimates.

Profile imports support manual paste. Existing profile codes remain compatible.
Live one-part and multi-part whisper delivery still needs confirmation.
The optional previous-raid-target return remains experimental during rapid
switching. An intermittent cog input issue is under investigation.

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
