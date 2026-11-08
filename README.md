# Raid Frames

Keep your raid organised and important information easy to see.

- Original ArcheAge and Ellesmere-inspired designs with custom colours and dimensions.
- Click and optional hover targeting.
- Automatic class sorting, manual Ctrl-drag placement and a movable Priority group.
- Selected buff/debuff icons, timers, frame effects and optional screen alerts.
- Low-health and low-mana indicators and optional distance readings.
- Native raid-management access, saved profiles and profile sharing.
- A short first-use tutorial and replayable Quick tour.

## Version 0.2.83

Choose which HoTs use the HoT tracking helper. Those effects update while you
target a member; other buffs and debuffs keep their normal tracking. This helps
follow healing, but does not identify who cast an effect.

Optional Return previous raid target retains the member selected before a
hover sweep and requests them again when the pointer leaves the raid frames.
If their identity and readable health cannot be confirmed, it keeps the last
hovered target. The option is off by default and only supports raid members.

Settings, profiles and tutorial progress are saved in the manager-preserved
`.data` folder. Keep that folder when updating manually.

## Install

Install **Raid Frames** through Classic Addon Manager, or download the FULL ZIP
from [Releases](https://github.com/mazrimaddons/RaidFrames/releases/latest).
Use installation folder `Mazrim_Raid_Frames` and repository branch `main`.

For manual installation, copy the `Mazrim_Raid_Frames` folder into
`Documents/AAClassic/Addon/` and add `Mazrim_Raid_Frames` to `Addon/addons.txt`.
Use the UPDATE ZIP to replace matching files in an existing installation.
Fully restart the game after updating, then confirm 0.2.83 in the settings.

## Known limitations

Hover targeting changes the actual selected target and does not cast spells.
Rapid selections can briefly bounce before settling. Distant members' HP/mana
may be unknown when the game does not expose them. Effect tracking is partial;
last-seen timers are estimates, and buff caster ownership is unknown.
Manual profile-code paste is verified; live whisper delivery needs confirmation.
See **Known issues** in the addon for details.

## Credits

Created by Mazrim with ChatGPT. See the bundled license files for shared code.
