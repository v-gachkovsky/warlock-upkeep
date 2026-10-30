# WarlockUpkeep!

**Never forget your armor, stones, shards or demon again.**

WarlockUpkeep! is a lightweight helper for Warlocks in **World of Warcraft: Forever**. It shows an icon only when
something is missing, and a single click fixes it: cast your armor, create a Healthstone, apply a Soulstone or
summon your demon.

On any other class the addon does nothing and stays fully disabled.

**Works on every client:** WoW Forever, Classic Era, TBC Anniversary, Mists of Pandaria Classic and Retail.
The addon adapts to each one: Fel Armor and Master stones in TBC, no extra shard counter (the game shows them) and direct-cast
Soulstone in Mists and Retail, Sayaad and Grimoire of Sacrifice in Retail.

---

## Features

| Icon | Shown when | Click |
|------|------------|-------|
| **Armor** | Demon Skin / Demon Armor is missing | Casts your strongest armor |
| **Soul Shards** | Always (counter) | — |
| **Healthstone** | No Healthstone in your bags | Creates your strongest Healthstone |
| **Firestone / Spellstone** | Stone not equipped (applied on Forever) or missing | Equips, applies or creates the stone |
| **Soulstone** | Stone unused or missing | Applies or creates the stone |
| **Demon** | No pet out | Summons the demon you assigned |
| **Grimoires** | At vendors and in tooltips | — |

### Armor

Reminds you when neither Demon Skin nor Demon Armor is up. Click to cast Demon Armor, or Demon Skin if you
haven't learned Demon Armor yet.

> **WoW Forever: add Demon Skin and Demon Armor to the Cooldown Manager's Tracked Buffs.** The game hides
> your buffs from addons in combat, and the Cooldown Manager is what lets the addon notice the armor being
> removed or recast during a fight.

### Soul Shard counter

Shows your shards (optionally as **have / threshold**), turns yellow at the threshold and red when you fall
below it, with a highlight in the same color. The threshold equals the recommended amount by default. The recommended amount is calculated from what you actually know:

- 1 shard for summoning a demon (once Voidwalker, Succubus or Felhunter is learned)
- 1 shard for each learned stone: Healthstone, Soulstone (except on Hardcore realms), Firestone, Spellstone
- spare shards (1 by default, configurable)
- optionally, Ritual of Summoning

You can also set the warning threshold manually.

### Healthstone

Appears when there's no Healthstone in your bags. Click to create the strongest one you know.

### Firestone / Spellstone

Forever, Classic Era and TBC. Pick your stone in the settings (Firestone by default); the icon shows once you
can create it. Yellow when the stone is in your
bags but not on, red when there's none. In Classic Era and TBC the click equips the stone in your off-hand; on
WoW Forever it imbues your main-hand weapon (by default no reminder while another temporary enchant, such as
an oil, is on it).

### Soulstone

- **Yellow highlight**: the stone is in your bags but not applied. Click to use it on your friendly target (or yourself).
- **Red highlight**: no stone in your bags. Click to create one.

When your Soulstone is on another player, a movable label shows **their name in class color and the remaining
time**. When it's on yourself, or another warlock's Soulstone is on you, only the timer is shown (optional).
Another warlock's Soulstone on you can also hide the icon (an option, off by default). Font, size, outline, icon and background
opacity are all configurable.

On Hardcore realms nobody can be brought back to life, so there's no Soulstone icon or label there, although
trainers still teach the spell.

### Demon

Appears when you have no pet. Bind a different demon to **Click, Shift, Ctrl, Alt and Cmd (Mac)**: Imp,
Voidwalker, Succubus, Incubus, Felhunter or Felguard. It stays hidden while you ride, fly or take a flight path
if your demon was out when you set off, since the game dismisses it for a while.

### Grimoires

At a grimoire vendor, see **which books your demons already know, for all of them at once**, without summoning
each one: learned grimoires get a check mark and turn grey (books for demons you can't summon yet are dark grey with a red cross), books already in your bags get a bag icon, and the tooltip tells per demon what it knows
(also in your bags). Summon each demon once so the addon can read its spells; after that it remembers them and
keeps them up to date. WoW Forever, Classic Era and TBC.

---

## Make it yours

- **Language**: English or Ukrainian, switched in the settings.
- **Every feature** can be turned on or off individually.
- **Every icon** can be resized, moved, locked, and given its own highlight color and alert sound.
- **Highlight styles**: *Proc* (the Cooldown Manager animation, default), *Running lines* or *Pulsing border*.
- **Highlight types**: *Outline*, *Fill icon* or both. Highlighting in combat can be turned off.
- **Snapping**: drop an element next to another one and it lines up neatly, so building rows and columns is easy.
  Snap distance and spacing are adjustable.
- **Background opacity** for the shard counter and the Soulstone label.
- **Sounds**: 14 game sounds, LibSharedMedia sounds, or **your own .ogg / .mp3 files** for every alert.
- **Masque** skins for the icons and a **LibDataBroker** feed (Titan Panel, ElvUI, Bazooka...) with your shards.

## Built for combat

- Separate **in-combat and out-of-combat opacity**.
- **Hide icons in combat** if you only want reminders between fights.
- **Hide everything while on a flight path** or **while mounted**, optionally keeping just the shard counter (on clients that have one).
- **Click-through in combat**: in combat the icons ignore the mouse, so you can click targets and turn the
  camera right through them.
- **Combat simulation**: preview out of combat how everything will look and behave once a fight starts.
- Icons appear and disappear in combat just like out of combat, even while WoW hides auras: the addon
  follows your buffs through the fight. Icons stay clickable in combat unless you turn on click-through.

---

## Commands

| Command | Action |
|---------|--------|
| `/wu` | Open settings (also in *Options → AddOns*) |
| `/wu lock` / `/wu unlock` | Lock or unlock all elements |
| `/wu preview` | Show all icons to position them |
| `/wu combat` | Toggle combat simulation |
| `/wu reset` | Reset settings |

## Minimap button

- **Left click**: open settings
- **Right click**: toggle preview
- **Shift + right click**: toggle combat simulation

The button can be dragged around the minimap, locked or hidden.

## Moving icons

By default, drag icons with the **right mouse button**. You can switch to Shift / Ctrl / Alt / Cmd + left
button in the settings. The shard counter and the Soulstone label are dragged with the left button.

---

## Good to know

- WoW doesn't allow secure buttons to be shown, hidden or moved in combat, so icons fade in and out instead;
  a faded-out icon still takes clicks at its spot unless click-through is on. Settings changed in combat
  apply after combat.
- WoW Forever hides auras in combat. The addon remembers your buffs before the fight and notices in combat
  when they are removed or run out. For the armor, add Demon Skin and Demon Armor to the Cooldown Manager's
  Tracked Buffs so changes during a fight are caught too.
- A Soulstone removed in combat (WoW Forever, Retail) is noticed only after the fight. It can't be
  dispelled, so check it before the pull.
- Spell and item IDs come from Classic Era. If anything differs in Forever, the addon looks the spell up by name.

## Support

WarlockUpkeep! is free. If it helps you, you can support its development:

- [Ko-fi](https://ko-fi.com/mortivux)
- [monobank jar](https://send.monobank.ua/jar/2GZjyGouqJ)

Found a bug or have an idea? Tell me any way you like:

- comments on this page
- [GitHub Issues](https://github.com/v-gachkovsky/warlock-upkeep/issues)
- email: [volodymyr.hachkovsky@icloud.com](mailto:volodymyr.hachkovsky@icloud.com)

Say what you did, what you expected and what happened (a screenshot helps), and add what `/wu auras` prints
(for grimoires, `/wu grimoires`).

---

With ❤️ from 🇺🇦
