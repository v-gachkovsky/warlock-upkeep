<p align="center"><img src="docs/logo-curseforge.png" width="128" alt="WarlockUpkeep!"></p>

<h1 align="center">WarlockUpkeep!</h1>

<p align="center">
  Reminders and one-click buttons for Warlocks in <b>World of Warcraft: Forever</b><br>
  armor · Soul Shards · Healthstone · Firestone / Spellstone · Soulstone · demon
</p>

<p align="center">
  <b>English</b> · <a href="README_UA.md">Українська</a>
</p>

---

## Contents

- [Overview](#overview)
- [Supported clients](#supported-clients)
- [Installation](#installation)
- [Features](#features)
  - [Armor](#1-armor)
  - [Soul Shards](#2-soul-shards)
  - [Healthstone](#3-healthstone)
  - [Firestone / Spellstone](#4-firestone--spellstone)
  - [Soulstone](#5-soulstone)
  - [Demon](#6-demon)
  - [Grimoires](#7-grimoires)
  - [Summon queue](#8-summon-queue)
- [Look and behavior](#look-and-behavior)
  - [Highlight](#highlight)
  - [Opacity and combat](#opacity-and-combat)
  - [Snapping](#snapping)
  - [Background](#background)
  - [Sounds](#sounds)
- [Controls](#controls)
  - [Commands](#commands)
  - [Minimap button](#minimap-button)
  - [Moving elements](#moving-elements)
- [Client limitations](#client-limitations)
- [Project structure](#project-structure)
- [Releasing](#releasing)
- [Support](#support)
- [License](#license)
- [Changelog](CHANGELOG.md)

## Overview

| | |
|---|---|
| **Clients** | WoW Forever, Classic Era, TBC Anniversary, Mists of Pandaria Classic, Retail ([details](#supported-clients)) |
| **Class** | Warlock only. On any other class the addon creates nothing and stays fully disabled |
| **Version** | 1.0.0 |

The addon shows an icon only when something is missing: armor, shards, stones or your demon.
Clicking the icon fixes it right away.

Every feature can be turned on or off individually. Every icon can be:

- resized, moved and locked in place;
- given a highlight (color; enabled by default);
- given a sound.

## Supported clients

One addon folder works on every client: the TOC lists all interface versions
(`## Interface: 120105, 50504, 20506, 11509, 16001`). The addon adapts to what the client has:

| Client | Interface | Differences |
|--------|-----------|-------------|
| WoW Forever | 16001 | Everything as described below |
| Classic Era | 11509 | Everything as described below |
| TBC Anniversary | 20506 | Fel Armor is cast instead of Demon Armor once learned; Master stones; Felguard |
| Mists of Pandaria Classic | 50504 | No armor icon. No grimoires (demons learn their spells themselves). No shard counter: Soul Shards are a resource with the game's own UI. Soulstone is cast directly on the target. Grimoire of Supremacy demons replace the regular ones |
| Retail (Midnight) | 120105 | No armor icon. No grimoires. No shard counter: Soul Shards are a resource with the game's own UI. Soulstone is cast directly on the target (15 min). Succubus becomes Sayaad. No demon reminder under Grimoire of Sacrifice |

## Installation

Copy or symlink the `WarlockUpkeep` folder into `Interface/AddOns/` of the client you play:

| Client | Folder |
|--------|--------|
| WoW Forever (beta) | `_classic_beta_` |
| WoW Forever (release) | `_forever_` |
| Classic Era | `_classic_era_` |
| TBC Anniversary | `_anniversary_` |
| Mists of Pandaria Classic | `_classic_` |
| Retail | `_retail_` |

For development, a symlink from the repository root is handy:

```sh
# beta
ln -s "$PWD/WarlockUpkeep" "/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/WarlockUpkeep"

# release
ln -s "$PWD/WarlockUpkeep" "/Applications/World of Warcraft/_forever_/Interface/AddOns/WarlockUpkeep"
```

## Features

| # | Feature | Shown when | Click |
|---|---------|------------|-------|
| 1 | **Armor** | No Demon Skin / Demon Armor | Casts your strongest armor |
| 2 | **Soul Shards** | Always (counter) | Shift + click deletes shards above the maximum |
| 3 | **Healthstone** | No Healthstone in your bags, or low health | Creates or uses your strongest Healthstone |
| 4 | **Firestone / Spellstone** | Stone not equipped (applied on Forever) or missing | Equip, apply or create the stone |
| 5 | **Soulstone** | Stone not applied or missing | Use or create the stone |
| 6 | **Demon** | No pet out | Summons the assigned demon |
| 7 | **Grimoires** | At vendors and in tooltips | — |
| 8 | **Summon queue** | Someone in the group asks for a summon | Targets them and casts Ritual of Summoning |

### 1. Armor

The icon appears when you have neither Demon Skin, Demon Armor nor Fel Armor. Clicking it casts your
strongest armor: Fel Armor once learned (TBC), otherwise Demon Armor, or Demon Skin before that.
It works the same in combat: the icon shows up as soon as the buff is removed, dispelled or expires,
and disappears when you recast it (see [Client limitations](#client-limitations)).

> **WoW Forever: add Demon Skin and Demon Armor to the Cooldown Manager's Tracked Buffs.** The game hides
> your buffs from addons in combat, and without the Cooldown Manager the addon can't always tell that the
> armor was removed during a fight. Classic Era and TBC don't need this.

### 2. Soul Shards

A counter of the shards in your bags. It turns red and lights up when you have fewer than the low threshold
(below), and turns yellow and lights up when the count equals it (one more shard used and it's low). With
*Show the threshold next to the count* (off by default) it reads `have/threshold`. With *Keep showing on a mount or flight path* (on by default) it stays on screen
when the General options hide everything else there.

**The recommended amount** is made up of:

- **1** for summoning a demon, if Voidwalker, Succubus or Felhunter is learned;
- **1 per** learned stone: Healthstone, Soulstone (except on Hardcore realms), Firestone, Spellstone;
- **spare** shards (configurable, 1 by default);
- optionally **Ritual of Summoning**.

The counter appears once you've learned something that spends shards (a demon that costs one or a stone
spell), so low-level characters don't get a "low shards" alert. It exists only on clients with Soul Shard
items (Forever, Classic Era, TBC); in Mists and Retail shards are a resource shown by the game itself.

The highlight threshold equals the recommended amount by default, but you can set it manually.

**Extra shards.** Set *Maximum shards* (0 by default, no limit) and the count turns light blue above it.
**Shift + click** on the counter then deletes the extra shards: from ordinary bags first, so a Soul Pouch
keeps its own. Not in combat.

**Full bags.** When a new shard has no free slot in your bags (Drain Soul would lose it), the counter lights up
orange (on by default; color and sound in the settings).
**Reagents** (Forever, Classic Era, TBC). Once you know Inferno or Ritual of Doom, the counter's tooltip also
shows your Infernal Stones and Demonic Figurines, and at a vendor that sells them the addon buys them up to the
amount to keep (1 Infernal Stone and no Figurines by default; 0 means never). It buys only what you can pay for
and prints what it bought. Turn it off under *Reagents* in the settings.

### 3. Healthstone

The icon appears when there's no Healthstone in your bags. Clicking it creates the strongest Healthstone available.

**Low health.** With a Healthstone in your bags, the icon shows with a green highlight when your health drops below
20% (the percentage, color and sound are in the settings), also in combat. Clicking it uses the strongest
Healthstone you have. There's no reminder while the Healthstone is on cooldown.

### 4. Firestone / Spellstone

Forever, Classic Era and TBC only (Mists and Retail have no such stones). Only one of the two works at a time, so
there's one icon for the stone picked in the settings (Firestone by default). It shows once you can create that
stone (outside preview). Like the Soulstone, it has two states with their own highlight and sound:

- **the stone is in your bags but not on**: click to put it on;
- **no stone in your bags**: click to create the strongest one you know.

In **Classic Era and TBC** the stone works while held in the off-hand, so "on" means equipped, and the click
equips it in place of your off-hand item. On **WoW Forever** the stone imbues your main-hand weapon instead, so
"on" means the weapon has its enchant, and the click uses the stone. If the weapon has another temporary
enchant, such as a wizard oil, the addon doesn't remind you by default; *Remind while another temporary
enchant is on the weapon* changes that. The addon tells the stone's enchant from an oil's once you use the
stone (from the icon, your bags or a macro). Without a main-hand weapon there's no reminder.

With the icon on, the recommended Soul Shards count only the chosen stone of the two.

### 5. Soulstone

| Highlight | Meaning | Click |
|-----------|---------|-------|
| 🟡 Yellow | Stone is in your bags but not applied | Use it on a friendly target (or yourself) |
| 🔴 Red | No stone in your bags | Create a stone |

**Soulstone on another player.** A movable label appears under the icon:

- the player's name in their class color;
- a timer under the name, with a small Soulstone icon to its left.

If the Soulstone is on the caster, only the timer with the icon is shown, without a name (this can be turned off).
The same timer shows when another warlock's Soulstone is on you. The *Hide while another warlock's Soulstone
is on you* option (off by default) also hides the Soulstone icon then.

The label's font, size, outline, icon and background opacity are all configurable. In preview mode the
label shows your current target's name in class color (or only the timer without a target) with a fast
running timer, so you can see and place it.

**Timer zones.** The timer changes color as the Soulstone runs low:

| Zone | Default | Configurable |
|------|---------|--------------|
| Normal | white | color |
| Warning | yellow from 5:00 left | on/off, start time, color, sound when it starts |
| Critical | red from 1:00 left | on/off, start time, color, sound when it starts |
| Ran out | — | sound when the timer reaches zero |

The critical zone wins where the zones overlap. Sounds are off by default. In preview mode the timer runs faster (300x by default, adjustable from 1x to 600x)
and the sounds play on every cycle, so you can hear them.

**Hardcore realms.** Nobody can be brought back to life there, so the addon has no Soulstone icon or label on
them and replaces the Soulstone settings with a note, although trainers still teach the spell.

**Messages** (all off by default, texts editable): when you apply a Soulstone the addon can tell the group who
has it ("Soulstone on {name}."), whisper that player ("You have my Soulstone. It lasts {time}.") and, a set
time before it runs out (60 seconds by default), tell the group ("My Soulstone on {name} runs out in {time}.").
The messages go to the instance, raid or party chat, whichever you're in.

### 6. Demon

The demon icon appears when you have no pet. Each click variant can be bound to its own demon:

| Click | Demon |
|-------|-------|
| Click | your choice |
| Shift + Click | your choice |
| Ctrl + Click | your choice |
| Alt + Click | your choice |
| Cmd + Click (Mac) | your choice |

Available demons: Imp, Voidwalker, Succubus, Incubus, Felhunter, Felguard.

While you ride, fly or take a flight path, the game may dismiss the demon for a while. If it was out when you
set off, the icon stays hidden until a few seconds after you land or dismount, so the demon has time to come back.

**Talents** (Forever, Classic Era, TBC). With **Demonic Sacrifice** active, the icon doesn't ask for a demon, just
like with Grimoire of Sacrifice. Optionally (off by default) it reminds you to sacrifice the demon you've
summoned, and the click casts Demonic Sacrifice. With **Soul Link** learned, it reminds you when your demon is
out but Soul Link isn't on (on by default), and the click casts it. Both reminders have their own highlight
(purple) and sound, and show out of combat only.

**Enslave Demon timer** (Subjugate Demon in Classic Era). While a demon is enslaved, a small movable label shows
how long it stays under control (up to 5 minutes) and turns red in the last 30 seconds, with an optional sound.
It can break free earlier.

### 7. Grimoires

On clients with grimoires (WoW Forever, Classic Era, TBC) the addon remembers which spells and ranks each of
your demons knows, and marks the grimoires at vendors for all demons at once, whichever one is out:

- ✅ a check mark and a grey icon: the demon already knows this rank or a higher one;
- ⏳ a question mark: that demon hasn't been checked yet;
- ❌ a red cross and a dark grey icon: you can't summon that demon yet;
- no mark: the demon doesn't know it yet;
- 🎒 a bag in the other corner: you already have this grimoire in your bags.

The grimoire's tooltip says the same per demon (e.g. *Imp: already knows Firebolt (Rank 7)*), also in your bags.

The game shows a demon's spells only while it's summoned, so **summon each demon once**: from then on the addon
remembers its spells (per character) and updates them whenever that demon is out, e.g. after reading a new
grimoire. The settings list the demons checked so far. Both the vendor marks and the tooltip lines can be
turned off.

### 8. Summon queue

Group members who ask for a summon in party, raid or instance chat or in a whisper ("123", "summ", "summon",
"sum pls"... the list is editable) join a small queue window, in the order they asked. A row shows the player in
their class color, their zone (in a raid) and how long they've been waiting; the header shows your Soul Shards
and how many group members stand next to you to click the portal (2 are needed).

- **Click** a player: targets them and casts Ritual of Summoning.
- **Right click**: removes them from the queue.

A player leaves the queue once they're next to you, leave the group, or after the timeout (10 minutes by
default). Someone just summoned shows *summoning* for up to 2 minutes and goes back to waiting if they don't
arrive. The window shows only while someone is waiting (and in preview), and the queue can't change in
combat. Keywords match whole words only: *summ* matches "summ pls!" but not "summary".

**Announcements** (off by default): when Ritual of Summoning starts, from the queue or cast by hand, the addon
can post a line to the group chat ("Summoning {name}, please click the portal!") and whisper the player
("Summoning you now, please accept the summon."). Both texts are editable; `{name}` is the player.

**Selling summons.** Turn it on with `/wu sell` (or in the settings) and a second window lists players outside
your group who look for a summon in a public channel, `/say`, `/yell` or a whisper ("wtb sum", "lf lock", "lfw",
"need a summon"... editable). Their message is in the tooltip, together with the offer you'd send.

- **Click** a buyer: whispers them the offer.
- **Shift + click**: invites them too. Once they join the group, they move on to the summon queue.
- **Right click**: removes them from the list. Quiet buyers drop off after 5 minutes.
- **Ad**: posts your ad to the Trade channel (another channel can be set), at most once per 30 seconds.

The offer depends on the price in the settings: with a price (in gold) it names it, with 0 it asks how much the
buyer would pay. All texts are editable: `{name}` is the buyer, `{zone}` your zone, `{price}` the price and
`{clickers}` a sentence saying how many more people you need next to you to click the portal (left out once
two stand by). Nothing is sent without your click.
### New ranks at the trainer

Forever, Classic Era and TBC. The game lists what a trainer teaches only while its window is open, so the
addon remembers that list (per character) whenever you visit your class trainer, together with the level each
rank needs. After a level up it prints what you can learn now and what it costs, e.g. *new at your trainer
(35s): Shadow Bolt (Rank 5), Immolate (Rank 4).* `/wu trainer` prints the same at any time. Visit the trainer
once for it to start; the message and an optional sound can be turned off in the settings.

## Look and behavior

### Language

The addon speaks English or Ukrainian: pick it with **Language** at the top of General. The texts switch right away
(settings, tooltips, chat messages). English is the default: there is no Ukrainian game client, so the language
doesn't follow the client's. Spell, item and demon summon names come from the game in the client's language.

### Highlight

The **style** is set under General:

| Style | Description |
|-------|-------------|
| *Proc (Cooldown Manager)* | An animation running around the edge, like in the Cooldown Manager. **Default.** Gold keeps its native look, other colors are tinted |
| *Running lines* | Thin lines running along the border |
| *Pulsing border* | A pulsing border |

> [!NOTE]
> If the client lacks the proc animation atlas, the addon falls back to *Running lines* automatically.

**Highlight type**:

| Type | Description |
|------|-------------|
| *Outline* | An outline in the chosen style. **Default** |
| *Fill icon* | Tints the icon itself semi-transparently in the same color. Fill opacity is configurable |
| *Outline + fill* | Both at once |

The *Highlight in combat* checkbox turns highlighting off during combat. By default it stays on in combat.

### Opacity and combat

These General settings apply to the icons, the shard counter and the Soulstone label.

| Option | Default | Description |
|--------|---------|-------------|
| Out-of-combat opacity | 100% | Fully opaque |
| In-combat opacity | 100% | Can't go below 20%, so nearly invisible icons don't steal clicks |
| *Hide icons in combat* | off | Hides the icons for the whole fight. Turned on mid-fight, it applies at once |
| *Hide all icons while on a flight path* | off | Hides everything from takeoff to landing |
| *Hide all icons while mounted* | off | Hides everything while you're on a mount (a flight path follows the option above) |
| *Click-through in combat* | off | In combat all addon elements ignore the mouse, so you can click targets and turn the camera through them. With it off, icons are clickable in combat, also those that show up mid-fight |

The flight path and mount options hide the icons, the Soulstone label and the shard counter. The counter can
stay: with its *Keep showing on a mount or flight path* option (on by default) it's then the only thing on screen.
Mists and Retail have no shard counter, so there these options hide the icons and the Soulstone label.

> [!TIP]
> If you change *Click-through in combat* mid-fight, the shard counter and the Soulstone label follow at once,
> the icons from the next fight (the game locks their mouse input in combat).

### Snapping

When you drop an icon, the counter or the label next to another addon element, it:

- aligns with it by the top edge, bottom edge or center;
- docks right up against its side, top or bottom;
- aligns by the left or right edge or the horizontal center.

This makes it easy to arrange elements into rows and columns.

| General option | Default |
|----------------|---------|
| Snapping | on |
| Snap distance | 10 |
| Gap between elements | 2 |

### Sounds

Every alert can play a sound. The list has 14 game sounds, sounds from
[LibSharedMedia](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) if another addon provides it,
and your own files:

1. Put `.ogg` or `.mp3` files into `World of Warcraft/<client>/Interface/WarlockUpkeepSounds/`.
   The folder is outside the addon, so updates don't delete your files.
2. Fully restart the game: `/reload` doesn't see new files.
3. In **Custom sounds**, enter the file name (`alarm.ogg`) or a full path starting with `Interface\`
   and press **Add**. The file appears in every Sound list.

**Test** next to each list plays the sound and tells you if a file can't be played.

### Background

The shard counter and the Soulstone label have a background opacity setting from 0 to 100%.

### Masque and data brokers

With **Masque** installed, the icons take its skins: pick one for the *WarlockUpkeep!* group in Masque's
settings. Display addons that use **LibDataBroker** (Titan Panel, ElvUI, Bazooka, ChocolateBar...) get a
*WarlockUpkeep* feed: your Soul Shards as text (red when low), the shards and the Soulstone target in its
tooltip, and the same clicks as the minimap button.

## Controls

### Commands

| Command | Action |
|---------|--------|
| `/wu` | Opens the settings (also available under *Options → AddOns*) |
| `/wu lock` | Locks all elements |
| `/wu unlock` | Unlocks all elements |
| `/wu preview` | Shows all icons so you can position them, including spells not learned yet |
| `/wu combat` | Toggles combat simulation |
| `/wu reset` | Resets the settings |
| `/wu auras` | Prints diagnostics of your buffs and recent aura events (useful for bug reports) |
| `/wu grimoires` | Prints what each demon is remembered to know and the summoned demon's spellbook (for bug reports) |
| `/wu trainer` | Prints the ranks waiting at your class trainer and their cost |

**Combat simulation** lets you see out of combat exactly how everything behaves in a fight: opacity,
highlight, hidden icons and click-through. Icons that aren't needed stay in place invisible, as in combat.
With click-through on, icons can't be moved or clicked until the simulation is turned off.
The minimap button stays clickable.

### Minimap button

| Action | Result |
|--------|--------|
| Left click | Opens the settings |
| Right click | Toggles preview |
| Shift + right click | Toggles combat simulation |

The button can be dragged around the minimap, locked, or hidden in the settings.

### Moving elements

- **Icons.** The **Move icons with** option sets how: right-button drag (default)
  or Shift / Ctrl / Alt / Cmd + left button.
- **The counter and the label** are moved by dragging with the left button.

> [!IMPORTANT]
> While an icon is unlocked, a click with the move modifier does nothing.
> For example, Shift+click on the demon icon won't summon a Voidwalker.

## Client limitations

**Secure buttons in combat.** In combat, secure buttons can't be shown, hidden, moved or changed,
and their mouse input can't be switched. The addon works around it with opacity:

- icons appear and disappear in combat just like out of combat (only *Hide icons in combat* hides them all);
- icons are clickable in combat, also those that appear mid-fight; *Click-through in combat* makes all of
  them let clicks through instead. Since mouse input is fixed for the whole fight, a faded-out icon still
  takes clicks at its spot unless click-through is on;
- icon size, position, lock and click-through changed in combat apply after combat; opacity, highlight
  and hiding apply at once.

**Hidden auras (secret values).** WoW Forever closes the aura API to addons in combat. The addon then reads
your buffs from the game's own frames, which keep working:

- **Cooldown Manager** (recommended): add Demon Skin / Demon Armor / Fel Armor to its tracked buffs and
  their state is read by spell, exact in every case;
- **buff frame** (always): a buff cast in combat hides the icon from the cast, and a removed buff shows the
  icon at once while your buffs stay readable. But on any buff change in combat the game hides all buff
  entries from addons; from then on the buff frame can't tell which buff is gone, and without the
  Cooldown Manager the icon appears only after the fight or when the buff's time runs out.
  It never shows the icon while the buff is on: food buffs and buffs from other players are never taken
  for yours.

This covers armor and Grimoire of Sacrifice. Bag items (Healthstone, Soulstone, Soul Shards) and the demon
are always readable.

**Soulstone in combat.** On WoW Forever and Retail a Soulstone removed in combat (from yourself or another
player) is noticed only after the fight; the label and icon update then. A Soulstone can't be dispelled,
so this matters little: check it before the pull. Out of combat a used or removed Soulstone is noticed when the player is visible.

**Spell and item IDs** come from Classic Era and later clients (`Data.lua`). If they differ in Forever, the addon tries to find
the spell by name. New stones or ranks can be added to `Data.lua`.

## Project structure

```
WarlockUpkeep/
├── WarlockUpkeep.toc   # addon manifest
├── Data.lua             # spell and item IDs
├── Locale.lua           # translation lookup and language list
├── Locales/ukUA.lua     # Ukrainian texts
├── Core.lua             # core: modules, settings, events
├── Widgets.lua          # secure icons, highlight, moving, snapping
├── Minimap.lua          # minimap button
├── Options.lua          # settings panel
├── Media/logo.tga       # addon icon
└── Modules/
    ├── Armor.lua
    ├── Shards.lua
    ├── Healthstone.lua
    ├── WeaponStone.lua
    ├── Soulstone.lua
    ├── Pet.lua
    ├── Summon.lua
    ├── SummonSell.lua
    └── Grimoires.lua
```

## Releasing

Releases are built by [`.github/workflows/release.yml`](.github/workflows/release.yml) from a version tag.
The version is written in the TOC (`## Version: x.y.z`), so the addon list shows it even when the addon runs
straight from the repository. The tag must match it: if they differ, the workflow stops before publishing anything.
The version goes into the zip name, the GitHub Release and the CurseForge file, so they always match.

1. Set the version in [`WarlockUpkeep.toc`](WarlockUpkeep/WarlockUpkeep.toc) and add a `## [x.y.z] - YYYY-MM-DD`
   section to [CHANGELOG.md](CHANGELOG.md). The section becomes the release notes.
2. Tag and push:

   ```sh
   git tag v1.0.0
   git push origin v1.0.0
   ```

Tags with a suffix (`v1.1.0-beta1`, with the same version in the TOC) become pre-releases (*beta* on CurseForge, *alpha* if the suffix contains `alpha`).

For CurseForge uploads, set in the repository settings:

| Name | Kind | Value |
|------|------|-------|
| `CF_API_KEY` | Secret | CurseForge [API token](https://legacy.curseforge.com/account/api-tokens) |
| `CURSEFORGE_PROJECT_ID` | Variable | CurseForge project ID |

Without them only the GitHub Release is created. CurseForge game versions are taken from `## Interface`;
versions CurseForge doesn't know are skipped.

## Support

WarlockUpkeep! is free. If it helps you, you can support its development:

- [Ko-fi](https://ko-fi.com/mortivux)
- [monobank jar](https://send.monobank.ua/jar/2GZjyGouqJ)

## License

[MIT](LICENSE) © Volodymyr Hachkovsky
