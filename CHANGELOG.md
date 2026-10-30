# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Summon queue**: group members who ask for a summon in party, raid or instance chat or in a whisper ("123",
  "summ", "summon"...; the keywords are editable, whole words only) join a queue window in the order they
  asked, with their class color, zone (in a raid) and wait time. The header shows your Soul Shards and how many
  group members stand next to you to click the portal. Click a player to target them and cast Ritual of
  Summoning, right click to remove them. Players leave the queue once they're next to you, leave the group or
  wait longer than the timeout (10 minutes by default). Optional sound when someone joins.
- **Selling summons** (`/wu sell` or the settings; off by default): a second window lists players outside the
  group who look for a summon in public channels, /say, /yell or whispers ("wtb sum", "lf lock", "lfw"...;
  editable). Click whispers them the offer, Shift + click also invites them, right click removes them; once in
  the group they move on to the summon queue. The offer names your price, or asks how much the buyer would pay
  when the price is 0. The price takes a plain number of gold ("5") or gold, silver and copper ("1g50s", "75s",
  "2g5c"). The *Ad* button posts a "WTS summon" ad to Trade (or another channel), at most once per
  30 seconds. All texts are editable ({name}, {zone}, {price}, {clickers}); nothing is sent without a click.
  The window's *Place* field sets what {zone} says ("BRD meeting stone"); empty, it's the zone you're in, and it
  clears when you go to another zone.
- Both summon windows can be resized by their bottom-right corner while unlocked, and scroll with the mouse
  wheel when more players are listed than fit; the queue scrolls out of combat only. Preview fills them with
  enough sample players to try the scrolling.
- **Not enough people at the portal**: when you start a summon from the queue and fewer than two group members
  stand next to you, the addon asks for help ("Need 1 more next to me to click the summoning portal!"). For your
  group it goes to the group chat; for a summon you sold it also goes to /say, /yell and the ad channel (Trade),
  asking players around to whisper you for an invite. On by default, each channel and both texts adjustable,
  at most once per 15 seconds.
- **Summon announcements** (off by default): when Ritual of Summoning starts, a line to the group chat ("Summoning
  {name}, please click the portal!") and a whisper to the player ("Summoning you now, please accept the summon.").
  Both texts are editable.
- **Soulstone messages** (off by default, texts editable): when you apply a Soulstone, tell the group who has it
  and whisper that player; a set time before it runs out (60 seconds by default), tell the group. `{name}` is
  the player and `{time}` the time left.

## [1.9.0] - 2026-10-30

### Added
- **Firestone / Spellstone icon** (WoW Forever, Classic Era, TBC). Pick the stone in the settings (Firestone by
  default); the icon shows once you can create that stone.
  Like the Soulstone, it has two states with their own highlight and sound: the stone is in your bags but not on
  (click to put it on), or there's none (click to create the strongest one). In Classic Era and TBC "on" means
  held in the off-hand, and the click equips it. On WoW Forever the stone imbues the main-hand weapon, and the
  click uses it; by default there's no reminder while another temporary enchant (an oil) is on the weapon, and
  a new option reminds you anyway.

### Changed
- The recommended Soul Shards count only the Firestone or Spellstone chosen for the icon, not both (both again
  when the icon is turned off).
- The CurseForge page's Support section also lists the ways to report a bug or share an idea (comments, GitHub
  Issues, email) and what to include.

## [1.8.1] - 2026-10-29

### Added
- Links to support the project on Ko-fi and through a monobank jar: in the README, on the CurseForge page and
  behind GitHub's *Sponsor* button.

### Fixed
- **Hardcore realms**: the addon no longer reminds you to create and apply a Soulstone, which can't bring anyone
  back there (trainers still teach it), and doesn't count it in the recommended shards. The Soulstone settings
  are replaced by a note.
- The addon list showed `@project-version@` instead of the version when the addon ran straight from the
  repository (the released zip always had the right one). The TOC now holds the version number itself.

## [1.8.0] - 2026-10-28

### Added
- **Hide all icons while mounted** (General, off by default). A flight path follows its own option even where
  the game counts it as being mounted.
- **Soul Shard counter**: *Keep showing on a mount or flight path* (on by default). When the mount or flight
  path option hides everything, the counter stays, so it's the only thing on screen.

### Changed
- *Hide all icons while on a flight path* (and the new mount option) also hide the Soulstone label, and the
  shard counter unless it's kept on screen.
- The Ukrainian name of the flight path option now says it's about flight paths (*під час польоту на таксі*).
- **Grimoires**: at vendors, grimoires for demons you can't summon yet get a red cross and turn dark grey instead
  of plain grey, so they no longer look like learned ones (or like the game's red for books you can't use yet).
- **Grimoires**: the mark on grimoires already in your bags is the vendor's sack icon instead of the square
  backpack button.

## [1.7.1] - 2026-10-27

### Fixed
- **Soulstone in combat on Retail**: the Soulstone icon showed up mid-fight although your Soulstone (or the one
  on another player) was still on. The game hides auras from addons in combat, and the addon took the hidden
  Soulstone for a used one. A Soulstone now stays tracked through the fight until it runs out, and the addon
  checks it again right after combat, as the README describes. The same check could also bring back the demon
  icon in combat under Grimoire of Sacrifice.
- **Demon icon on flying mounts**: it lit up when you took off, since the game dismisses the demon in the air.
  Now, as on flight paths, the demon counts as there while you're mounted or flying if it was out when you set
  off, and after you land or dismount it gets a few seconds to come back before the icon shows (also after
  a flight path).

## [1.7.0] - 2026-10-26

### Added
- **Soul Shard counter**: when the count equals the low threshold (one more shard used and it's low), the text
  and the icon highlight turn yellow by default (new *Text color at the threshold* and *Highlight color at the
  threshold* options). Below the threshold they stay red, and the sound plays only then.

### Changed
- **Dropdown lists** in the settings instead of buttons that cycled through the values (language, sounds,
  fonts, highlight, move mode, demons per click). Long lists, like sounds, scroll.
- **Grimoires**: the settings list the learned demons that aren't checked yet, and the help text and grimoire
  tooltips explain how to check one (summon it once, anywhere).

### Fixed
- The Cooldown Manager note in the armor settings showed on Classic Era and TBC, which have no Cooldown Manager
  and read buffs in combat; it now shows only on WoW Forever.
- Help notes in the settings no longer touch the row below them.
- Clearer Ukrainian texts for click-through and hiding icons in combat.

## [1.6.0] - 2026-10-26

### Added
- **Ukrainian translation**: the new *Language* option at the top of the settings switches the addon's texts
  (settings, tooltips, chat messages) between English and Ukrainian right away, without a reload.
  English stays the default, since there is no Ukrainian game client to follow.

## [1.5.0] - 2026-10-25

### Added
- **Grimoires** (WoW Forever, Classic Era, TBC): the addon remembers which spells and ranks each demon knows
  (read while it's summoned, so summon each one once) and marks grimoires at vendors for all demons at once:
  a check mark and grey icon for learned ones, a question mark for demons not checked yet, a grey icon for
  demons you can't summon yet, and a bag icon on grimoires already in your bags. Grimoire tooltips
  say what each demon knows. New *Grimoires* section in the options and a `/wu grimoires` diagnostic command.

## [1.4.0] - 2026-10-23

### Added
- **Another warlock's Soulstone on you**: the Soulstone label shows its timer (without a name), and the new
  option *Hide while another warlock's Soulstone is on you* (off by default) hides the Soulstone icon.

### Fixed
- The close button (X) of the options window now always closes it; before, it sometimes didn't and the
  window had to be closed from the minimap button.
- A Soulstone used on yourself no longer shows the label with your own name (in white) until the next aura
  check: casts on yourself are recognized when the game reports your name with the realm.

## [1.3.0] - 2026-10-23

### Changed
- The Soul Shard counter now shows just the shards you have. The old *Show recommended amount* option is
  replaced by *Show the threshold next to the count* (off by default): `have/threshold`, where the threshold
  is the one that turns the counter red (the recommended amount unless set manually).
- Section titles in the options now have matching icons.

### Fixed
- Icons no longer show while you're dead or a ghost (there's nothing to fix until you're back), and dying
  doesn't play alert sounds. Preview mode still shows them for positioning.

## [1.2.0] - 2026-10-22

### Added
- **Hide all icons while on a flight path**: new option under General (off by default).

## [1.1.1] - 2026-10-22

### Fixed
- The demon icon no longer shows up when you take a flight path with your demon out (the game dismisses it
  until landing). Without a demon the icon stays during the flight.

## [1.1.0] - 2026-10-22

### Changed
- **Renamed to WarlockUpkeep!** (was Warlock Toolkit): the addon folder is now `WarlockUpkeep`, slash
  commands are `/wu` and `/warlockupkeep`, and custom sounds go into `Interface/WarlockUpkeepSounds/`.
  Settings saved under the old name aren't carried over.
- The armor options (on WoW Forever), README and CurseForge page now say to add Demon Skin and Demon Armor
  to the Cooldown Manager's Tracked Buffs, which in-combat armor tracking relies on.

### Fixed
- Classic Era / TBC / Mists: removing a buff in combat didn't bring its icon back until the fight ended,
  as if auras were hidden in combat there too. They're read as usual now; only Forever and Retail hide them.
- Soulstone: a stone removed or used during a fight (WoW Forever, Retail) is picked up right after combat.
- Classic clients without the newer aura API fall back to the plain buff list for the armor, Grimoire of
  Sacrifice and Soulstone tracking.

## [1.0.2] - 2026-10-22

### Added
- **Preview shows every icon, learned or not** (also with simulated combat), so a low-level character can
  place and set up all icons in advance. Icons for spells you don't know yet do nothing on click.
- `/wlt auras`: diagnostics of what the client returns for your buffs, for bug reports.

### Changed
- Outside preview the Soul Shard counter appears once Drain Soul is learned, and the Soulstone label once
  you can create Soulstones.

### Fixed
- **Icons in combat now work like out of combat** (WoW Forever hides auras from addons in combat):
  - the armor icon no longer shows in combat while Demon Skin / Demon Armor is on;
  - it appears as soon as the buff is removed, dispelled or expires, and disappears when you recast it,
    also several times in one fight. Buffs are read from the Cooldown Manager if the buff is tracked there
    (recommended: exact in every case), otherwise from the game's own buff frame, which can't tell after
    other buffs change in combat. Food buffs and buffs from other players are never taken for yours;
  - the same goes for Grimoire of Sacrifice and a Soulstone on yourself; a used or removed Soulstone on
    another player is noticed when they're visible;
  - icons appear and disappear during the fight instead of staying until it ends, and are clickable
    unless "Click-through in combat" is on, also when they show up mid-fight;
  - "Hide icons in combat" turned on during a fight applies at once; invisible icons show no tooltip.
- Aura changes reached the addon late or not at all, which delayed the icons and Soulstone tracking.
- Combat simulation now behaves exactly like a real fight.

## [1.0.1] - 2026-10-21

### Added
- Soulstone timer zones: the timer turns yellow at 5 minutes left and red at 1 minute. In the options
  each zone can be turned off and has its own start time (seconds left), color and sound when it starts;
  a sound can also play when the timer runs out. Sounds are off by default.
- More game sounds to choose from (14 instead of 6), LibSharedMedia sounds when available, and
  custom sound files: put .ogg / .mp3 files into `Interface/WarlockToolkitSounds/` and add them in
  the new "Custom sounds" section; they show up in every sound list. Test reports files that can't play.

### Changed
- Preview mode shows the Soulstone label as if cast now: your current target's name in class color,
  or only the timer (as on yourself) without a target. The timer runs faster (300x by default,
  a second per 5 minutes; adjustable from 1x to 600x in the options) and restarts from the full duration,
  playing the timer sounds on every cycle.

### Fixed
- Low-level Warlocks no longer see the Soul Shard counter with a "low shards" alert before learning
  anything that spends shards (a demon that costs one or a stone spell).
- Mists / Retail: the options no longer show the Demon Armor section (the armor spells don't exist there)
  or the Soulstone settings that only apply to Soulstone items.
- Soulstone label showed only the timer, without the target's name, when the client didn't report
  the cast target: the target is now taken from the friendly unit you have targeted. Out of combat
  the Soulstone is also looked up on your target and focus, not only on group members.
- Player names in Chinese or Korean (and Cyrillic with fonts that lack it) showed as squares on the
  Soulstone label: names now fall back to the game's own fonts for those alphabets.

## [1.0.0] - 2026-10-21

First release. Supports WoW Forever (`16001`), Classic Era (`11509`), TBC Anniversary (`20506`),
Mists of Pandaria Classic (`50504`) and Retail (`120105`) from a single TOC.

### Added
- **Armor reminder**: icon when Demon Skin / Demon Armor / Fel Armor is missing; click casts the strongest armor
  (Fel Armor once learned in TBC).
- **Soul Shard counter** in `have/recommended` format, with a configurable spare count,
  optional Ritual of Summoning and a manual highlight threshold. Only on clients with Soul Shard items
  (Forever, Classic Era, TBC); Mists and Retail show shards in the game's own UI.
- **Healthstone reminder**: icon when no Healthstone is in the bags; click creates the strongest one.
  Master stones in TBC; Demonic Healthstone counts in Retail.
- **Soulstone tracker**: yellow highlight for an unused stone, red for a missing one;
  movable label with the target's name in class color and a timer. The target is tracked by GUID.
  In Mists and Retail the Soulstone is cast directly on the target.
- **Demon summon icon** with Click / Shift / Ctrl / Alt / Cmd bindings for Imp, Voidwalker,
  Succubus, Incubus, Felhunter and Felguard. Grimoire of Supremacy demons (Mists) and Sayaad (Retail)
  replace the regular ones; no reminder while Grimoire of Sacrifice is active.
- Shared widgets: secure action icons, resizing, moving, locking and snapping into rows and columns.
- Highlight styles (*Proc*, *Running lines*, *Pulsing border*) and types (*Outline*, *Fill icon*, *Outline + fill*).
- *Highlight in combat* option.
- Separate in-combat and out-of-combat opacity (in-combat opacity is limited to at least 20%).
- *Hide icons in combat* and *Click-through in combat* options.
- Combat simulation (`/wlt combat`, Shift + right click on the minimap button), including click-through.
- Minimap button: settings, preview, combat simulation; draggable, lockable and hideable.
- Options window and `/wlt` commands: `lock`, `unlock`, `preview`, `combat`, `reset`.
- *Move icons with* option: right-button drag or a modifier + left button; the move modifier never triggers the icon's action.
- Combat handling for secure buttons: icons visible at the start of combat stay clickable until it ends,
  icons hidden at the start of combat don't take clicks.
- Addon logo.
- English and Ukrainian READMEs, CurseForge description, this changelog.
- MIT license.
- Automated releases to GitHub Releases and CurseForge from a version tag.
