Mazrim Raid Frames 0.2.75

General Settings now has Target-only buff tracking (off by default).
When enabled, buffs update only from the current target; known selected
debuffs continue through the raid tracker. Changing mode clears prior buff
history. Targeting still shows buffs from any caster, not only your own.
Save settings to keep the choice. Existing profiles and codes are preserved.

Previous update: 0.2.74

The tutorial's Ctrl-drag practice now uses the actual raid-frame renderer,
including your selected Original/Ellesmere design, colours, health text and
mana strip. Its three sample frames are reused and cleaned up with the guide.
The first tutorial message no longer shows an arrow. Your settings and raid
placements are preserved. Replay from cog > Quick tour to try it.

Previous update: 0.2.73

Receiving shared profiles now uses the native incoming-whisper channel and
supports both positional chat callbacks and the native event argument table.
Only whispers from the named sender are accepted. Profile codes, previews,
Save as new profile, limits and existing saved settings remain unchanged.
Manual paste remains available. Live whisper acceptance is still required.

Previous update: 0.2.72

Effects with the same full name and type now share one entry. Its icon,
priority, frame appearance, colour and screen-alert settings apply to all
known versions together. Existing per-ID settings show as mixed until edited.
Spell variant maps admit up to 256 IDs per independent choice. The native
experimental raid reader still admits 64 selected IDs at a time; its partial
coverage remains visible in tracking status.

Previous update: 0.2.71

Each frame-effect texture card now owns its preview. Opening Appearance
first no longer lets the earlier samples hide behind the texture cards.

Previous update: 0.2.70

The Quick tour starts automatically on first use. A separate tutorial.txt
record remembers that it was shown, including when skipped or closed.
Use Quick tour in settings to replay it any time. Existing users see it
once after this update if they do not already have that record.

Previous update: 0.2.69

Browse includes 13,001 descriptive effect records from a locally installed
client-scan list. Live observations take precedence. These records do not
prove an effect is currently present on a member. Names with different IDs
remain separate versions. New names can take a minute or longer to resolve.

Screen alerts require an identified debuff. Choosing a buff or an effect
whose type is unknown shows an explanation and leaves its alert off.

Previous update: 0.2.68

The settings header now reads Raid Frames. Browse can find Inspired (ID 127)
by name before it has been observed. Enable Show icon to display it on your
raid frames when the addon observes it on a member.

Previous update: 0.2.67

Loading a profile asks before replacing your current setup. Save copy & load
keeps a separate named profile. Load without saving skips the copy, and
Cancel keeps the current setup open.

Previous update: 0.2.66

Profiles > Share profile creates a Layout only or Full profile code.
Copy the code into a whisper. For numbered parts, send one part per whisper.
On the other client, choose Profiles > Receive from chat, enter the sender's
character name, and click Listen for whisper. You can also paste a full code.
Preview the setup and choose Save as new profile. Click its card when you
want to load it. Sharing leaves out named raid placements and session state.

Whisper parts are at most 120 ASCII characters. The installed English chat
input uses a 160-character cap. Exact live whisper delivery still needs a
two-player comparison. Use the full code if the game truncates a whisper.

Previous update: 0.2.65

Open the cog and choose Known issues below Quick tour to see the current
game and addon API limitations.

Previous update: 0.2.64

Ctrl-drag validates the dragged member and the destination. Health updates
and unrelated players entering or leaving render range no longer cancel a
valid drop. If the session placement list fills, the addon can reclaim
departed members' temporary placements once the current roster is named.

Previous update: 0.2.63

Health numbers take priority over automatically placed distance text on
narrow frames. The number can use a smaller font to keep its digits, and
very large values can use scientific notation. No ellipsis is used for HP.

Previous update: 0.2.62

Open the cog and choose Quick tour. Drag its header to move the card.
Practise Ctrl-dragging a sample member into Priority, and see a large
screen alert example after the Buffs & Debuffs step.
Appearance highlights the draggable names, HP, distance and icons.

Experimental raid tracking starts on for fresh setups. A saved off
choice is kept. Screen alerts still need to be enabled separately.

Previous update: 0.2.61

Shield > Reset member positions returns everyone to their original raid slot.
It clears manual moves and Priority, and turns off sorting. The saved slot
preset and frame settings are kept.

Previous update: 0.2.60

Local raid symbols sit higher above player nameplates.

Previous update: 0.2.59

Open the cog and choose Quick tour for a short, optional walkthrough.
Buffs & Debuffs > Icon layout shares the draggable Appearance editor.
Move the name, HP, distance and icons on the sample, then Save settings.
Layout Preset labels the role you chose even when its sample slot is unfilled.

Previous update: 0.2.58

Open Buffs & Debuffs, then Effects. Browse searches the built-in catalogue,
effects observed in the raid, and your saved choices. My effects collects
everything you have configured. Search by name or exact spell ID. If a name
is missing, select a raid member with that effect and check again after an
observation. Available reads may miss effects. A manual ID is a choice, not
an observation.

Select a result to choose its icon and timer, frame colour or texture, and
screen alert in one place. The switches are independent. Each effect's
example previews your choices. Save settings keeps the configuration.

Icon layout holds the draggable example and icon display options. Screen
alerts holds the global pause switch and movable preview. Alerts use the
experimental raid debuff tracker in General Settings. Advanced > Tracking
holds Reset alert history.

Previous update: 0.2.57

Each raid member can have their own local symbol. A full raid of 50 is
supported. Right-click a member to assign, change or clear their symbol.
Symbols use the existing screen projection. Updates are shared across
frames when many members are marked. Symbols are visible only to you.

Appearance > Colours now shares the draggable example with Frame design.
Drag name, health and distance text or selected effect icons. Both sections
edit the same positions, with sample paging and Reset text.

Appearance > Frame design > Health numbers offers Percentage, Current HP,
Missing HP and Off. On small windows use Next to reach this control.

Previous update: 0.2.56 - Fireworks intro removed

The first-open fireworks animation and Replay intro control are removed.
No welcome animation widgets, driver work or textures are loaded. The old
intro.txt record is left untouched, along with settings, profiles and traces.
All existing frame and targeting features remain.

Previous update: 0.2.55 - Dead member presentation

Observed zero-health members show an empty frame with only their name.
Low-health/mana warnings, mana, HP/distance text, crown/role icons, effects
and selection outlines are hidden in this state. Click and hover targeting
remain available. Normal presentation returns on the next accepted positive
HP reading. Unknown or offline readings are not treated as death.
Settings and profiles are unchanged.

Previous update: 0.2.54

Refresh Addons, then check the version in the cog. Use the shield to turn
hover targeting on once and choose Hide original raid frames once. These
choices are now saved separately from profiles and restored on addon load.
New installations start with hover OFF and leave native visibility unchanged.
Closing settings or moving frames suspends hover dispatch without forgetting
your choice. No target is selected simply by restoring that choice.

Hide / Return now requests the game's saved raid-frame preference through
the native raid-options callback, rather than replaying a window hotkey.
The native portal handler uses this preference. A completed request does not
prove the client accepted the visibility change: verify a portal in game.
Unavailable native controls leave manual raid management accessible, and
never trigger automatic toggle hotkeys. Restore attempts are bounded.
Control-only saves preserve other saved settings and do not save unrelated
unsaved edits. Unknown/malformed settings block writes instead of being lost.

Indicators: each low-health style has its own colour picker. Deficit hatch
supports Stripes, Solid, or Stripes + solid, with separate stripe/fill colours
and opacity. The example updates as choices change. The selected target and
hover outline retain their own colour controls. No flashing is added.

Appearance > Frame design: Show distance sits below Thin mana strip and is
OFF by default. It uses only distance already accepted by the shared reader.
Known distance shows rounded metres; unavailable/offline distance shows ?.
It does not increase member scans or infer distance from missing resources.
Distance text can be positioned in the Appearance example with other items.

Shift-drag moves frames; Ctrl-drag changes local member placement. Layout
Preset and Priority affect your display only. Original uses native role
colours; Ellesmere uses your custom palette. Save settings keeps visual
changes; profiles store frame setups separately from hover/native choices.

Drag names, health text and selected icons in the Appearance example.
Buffs & Debuffs > Icon layout controls grouped/individual icon positions.
Countdown font and anchor stay fixed; whole units round down. Estimated
history keeps ~, and unknown expiry is never invented. Frame materials are
static original textures, with a colour fallback if image loading fails.
Setting tips appear only on the left labels.

Native target-name correction starts automatically, with a guarded name-only
update after selection. Return previous raid target remains OFF by default,
supports prior raid members only, and is separate from hover activation.

One shared frontend is retained for standalone/Public. Approved Native
reader, aura retrieval, target route and sampling budgets are unchanged.
Offline checks use restricted Lua 5.1; they are not in-game proof.
This package does not contain or overwrite settings, intro state or traces.
