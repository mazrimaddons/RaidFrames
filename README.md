# Raid Frames

Keep your raid organised and important information easy to see.

- Original ArcheAge and Ellesmere-inspired designs with custom colours and dimensions.
- Click and optional hover targeting.
- Automatic class sorting, manual Ctrl-drag placement and a movable Priority group.
- Selected buff/debuff icons, timers, frame effects and optional screen alerts.
- Low-health and low-mana indicators and optional distance readings.
- Native raid-management access, saved profiles and profile sharing.
- A one-time welcome card for new installations.

## Version 0.2.92

New installations show the welcome card once.

## Version 0.2.91

Raid member names can fall back to the raid slot when the ID-based lookup comes up empty. Distances of 1,000 m or more display in kilometres.

Open an effect to choose a specific spell ID. Recent observations highlight the active version on your selected target, or on you when you have no target. The experimental HoT helper is paused while caster ownership is investigated. Selected buffs and debuffs use ordinary tracking.

Optional Return previous raid target retains the member selected before a
hover sweep and requests them again when the pointer leaves the raid frames.
If their identity and readable health cannot be confirmed, it keeps the last
hovered target. The option is off by default and only supports raid members.

Settings, profiles and the welcome record are saved in the manager-preserved
`.data` folder. Keep that folder when updating manually.

## Install

Install **Raid Frames** through Classic Addon Manager, or download the FULL ZIP
from [Releases](https://github.com/mazrimaddons/RaidFrames/releases/latest).
Use installation folder `Mazrim_Raid_Frames` and repository branch `main`.

For manual installation, copy the `Mazrim_Raid_Frames` folder into
`Documents/AAClassic/Addon/` and add `Mazrim_Raid_Frames` to `Addon/addons.txt`.
Use the UPDATE ZIP to replace matching files in an existing installation.
Fully restart the game after updating, then confirm 0.2.92 in the settings.

## Known limitations

Hover targeting changes the actual selected target and does not cast spells.
Rapid selections can briefly bounce before settling. Distant members' HP/mana
may be unknown when the game does not expose them. Effect tracking is partial;
last-seen timers are estimates, and buff caster ownership is unknown.
Manual profile-code paste is verified; live whisper delivery needs confirmation.
See **Known issues** in the addon for details.

## Credits

Created by Mazrim with ChatGPT. See the bundled license files for shared code.
