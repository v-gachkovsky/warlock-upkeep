<p align="center"><img src="docs/logo-curseforge.png" width="128" alt="WarlockUpkeep!"></p>

<h1 align="center">WarlockUpkeep!</h1>

<p align="center">
  Reminders and one-click buttons for Warlocks in <b>World of Warcraft: Forever</b><br>
  armor · Soul Shards · Healthstone · Soulstone · demon
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
  - [Soulstone](#4-soulstone)
  - [Demon](#5-demon)
  - [Grimoires](#6-grimoires)
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
| 2 | **Soul Shards** | Always (counter) | Not clickable |
| 3 | **Healthstone** | No Healthstone in your bags | Creates your strongest Healthstone |
| 4 | **Soulstone** | Stone not applied or missing | Use or create the stone |
| 5 | **Demon** | No pet out | Summons the assigned demon |
| 6 | **Grimoires** | At vendors and in tooltips | — |

### 1. Armor

The icon appears when you have neither Demon Skin, Demon Armor nor Fel Armor. Clicking it casts your
strongest armor: Fel Armor once learned (TBC), otherwise Demon Armor, or Demon Skin before that.
It works the same in combat: the icon shows up as soon as the buff is removed, dispelled or expires,
and disappears when you recast it (see [Client limitations](#client-limitations)).

> **WoW Forever: add Demon Skin and Demon Armor to the Cooldown Manager's Tracked Buffs.** The game hides
> your buffs from addons in combat, and without the Cooldown Manager the addon can't always tell that the
> armor was removed during a fight. Classic Era and TBC don't need this.

### 2. Soul Shards

A counter of the shards in your bags. It lights up when you have fewer than the low threshold (below). With
*Show the threshold next to the count* (off by default) it reads `have/threshold`. It isn't clickable,
since a shard has no action.

**The recommended amount** is made up of:

- **1** for summoning a demon, if Voidwalker, Succubus or Felhunter is learned;
- **1 per** learned stone: Healthstone, Soulstone, Firestone, Spellstone;
- **spare** shards (configurable, 1 by default);
- optionally **Ritual of Summoning**.

The counter appears once you've learned something that spends shards (a demon that costs one or a stone
spell), so low-level characters don't get a "low shards" alert. It exists only on clients with Soul Shard
items (Forever, Classic Era, TBC); in Mists and Retail shards are a resource shown by the game itself.

The highlight threshold equals the recommended amount by default, but you can set it manually.

### 3. Healthstone

The icon appears when there's no Healthstone in your bags. Clicking it creates the strongest Healthstone available.

### 4. Soulstone

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

### 5. Demon

The demon icon appears when you have no pet. Each click variant can be bound to its own demon:

| Click | Demon |
|-------|-------|
| Click | your choice |
| Shift + Click | your choice |
| Ctrl + Click | your choice |
| Alt + Click | your choice |
| Cmd + Click (Mac) | your choice |

Available demons: Imp, Voidwalker, Succubus, Incubus, Felhunter, Felguard.

### 6. Grimoires

On clients with grimoires (WoW Forever, Classic Era, TBC) the addon remembers which spells and ranks each of
your demons knows, and marks the grimoires at vendors for all demons at once, whichever one is out:

- ✅ a check mark and a grey icon: the demon already knows this rank or a higher one;
- ⏳ a question mark: that demon hasn't been checked yet;
- no mark: the demon doesn't know it yet.

The grimoire's tooltip says the same per demon (e.g. *Imp: already knows Firebolt (Rank 7)*), also in your bags.

The game shows a demon's spells only while it's summoned, so **summon each demon once**: from then on the addon
remembers its spells (per character) and updates them whenever that demon is out, e.g. after reading a new
grimoire. The settings list the demons checked so far. Both the vendor marks and the tooltip lines can be
turned off.

## Look and behavior

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
| *Hide all icons while on a flight path* | off | Hides the icons from takeoff to landing |
| *Click-through in combat* | off | In combat all addon elements ignore the mouse, so you can click targets and turn the camera through them. With it off, icons are clickable in combat, also those that show up mid-fight |

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
├── Core.lua             # core: modules, settings, events
├── Widgets.lua          # secure icons, highlight, moving, snapping
├── Minimap.lua          # minimap button
├── Options.lua          # settings panel
├── Media/logo.tga       # addon icon
└── Modules/
    ├── Armor.lua
    ├── Shards.lua
    ├── Healthstone.lua
    ├── Soulstone.lua
    ├── Pet.lua
    └── Grimoires.lua
```

## Releasing

Releases are built by [`.github/workflows/release.yml`](.github/workflows/release.yml) from a version tag.
The tag is the only place the version is set: it goes into the TOC (`## Version: @project-version@`),
the zip name, the GitHub Release and the CurseForge file, so they always match.

1. Add a `## [x.y.z] - YYYY-MM-DD` section to [CHANGELOG.md](CHANGELOG.md). It becomes the release notes.
2. Tag and push:

   ```sh
   git tag v1.0.0
   git push origin v1.0.0
   ```

Tags with a suffix (`v1.1.0-beta1`) become pre-releases (*beta* on CurseForge, *alpha* if the suffix contains `alpha`).

For CurseForge uploads, set in the repository settings:

| Name | Kind | Value |
|------|------|-------|
| `CF_API_KEY` | Secret | CurseForge [API token](https://legacy.curseforge.com/account/api-tokens) |
| `CURSEFORGE_PROJECT_ID` | Variable | CurseForge project ID |

Without them only the GitHub Release is created. CurseForge game versions are taken from `## Interface`;
versions CurseForge doesn't know are skipped.

## License

[MIT](LICENSE) © Volodymyr Hachkovsky
