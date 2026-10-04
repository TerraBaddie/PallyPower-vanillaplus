# PallyPower - VanillaPlus

<img width="1306" height="701" alt="image" src="https://github.com/user-attachments/assets/0676a65f-987b-428d-ac49-0d6c801ba923" />


A **World of Warcraft 1.12.1 / VanillaPlus** PallyPower fork with updated blessing behavior, safer assignment parsing, and a new synchronized Judgement assignment column.

## Current changes

- **20-minute regular blessings by default** — Improved Blessing talent ranks are no longer required to reach 20 minutes. Rebuff/timer logic uses a flat `20 * 60` seconds.
- **Blessing of Might allowed on Hunters** with Smart Buffs enabled. Priest, Mage, and Warlock remain filtered by the existing Smart Buff logic.
- **Fixed the global `class` crash** by keeping player class data local, parsing assignment IDs numerically with `tonumber()`, validating ranges, and removing unsafe global `class` use from grid controls.
- **Judgement assignments per Paladin** for **Judgement of the Crusader**, **Judgement of Wisdom**, **Judgement of Light**, or **None**.
- **Judgement controls:** left-click cycles forward, mouse wheel cycles forward/backward, right-click clears, and hover shows the current assignment.
- **Judgement assignments sync between updated PallyPower clients** using reserved assignment column `10`. Older clients are tolerated; an older `SELF` sync will not erase an existing Judgement assignment.
- **Class labels added above the assignment icons:** Warrior, Rogue, Priest, Druid, Paladin, Hunter, Mage, Warlock, Shaman, and Pets.
- **Polished Judgement header** with the label `Judgement` above a normal **32x32** icon, matching the class-header layout.
- **Correct Judgement header icon:** `Interface\Icons\Spell_Holy_RighteousFury`.
- **Assignment chat announcer** beside the close button: left-click cycles **S / Y / P / R / RW**, and right-click opens a spam-warning confirmation before sending.
- **RW is permission-aware** and only appears while in a raid as raid leader/assistant.
- **Roster-aware announcement wording** uses simple `whole raid`, `Non-Mana User (melee)`, and `Mana User (caster)` summaries, plus the Paladin's Judgement assignment.
- **Clickable whisper helper:** the Paladin name in the alternate-blessing line is a standard player hyperlink; clicking it opens `/w NAME`.
- **Throttled chat output** sends roughly one line every 0.8 seconds instead of dumping the whole batch in one frame.
- Existing VanillaPlus fork features are retained, including regular/greater blessing selection, solo buff frame, pet support, max blessing rank display, and blessing talent-rank display.

## Judgement assignment scope

This feature is currently for **coordination/assignment only**. It does not automatically cast a Seal or Judgement or track the target debuff. The optional chat announcer can include each Paladin's Judgement assignment. Other Paladins need this updated build to see the Judgement assignment column.

## Installation

Extract the addon so the path is:

```text
World of Warcraft\Interface\AddOns\PallyPower\PallyPower.toc
```

The addon folder must be named **PallyPower**.

## Compatibility

Designed for the **WoW 1.12.1 client / VanillaPlus** environment using legacy Vanilla-era Lua/XML APIs.

See `README.txt` for the detailed change log and usage notes.


## Assignment chat announcer

The small button beside the close button selects where assignments are announced:

- `S` = Say
- `Y` = Yell
- `P` = Party
- `R` = Raid
- `RW` = Raid Warning (raid leader/assistant only)

**Left-click** cycles destinations. **Right-click** opens a confirmation before sending. Multi-line output is paced to reduce chat-flood risk. For a two-blessing split, the announcer uses **Non-Mana User (melee)** and **Mana User (caster)** wording and includes a clickable Paladin name so players can open a whisper for an alternate blessing. Judgement assignments are announced as `NAME is assigned to Judgement of ...`.

Current feature build: **1.7-JA2**.


### JA3 announcer fix

The blessing announcer now summarizes from the configured PallyPower class assignment columns rather than only classes currently present in the live roster. This fixes solo testing and cases where Warrior/Rogue/Pets were assigned Might while the player's own Paladin column used Wisdom. The simple role buckets are:

- **Non-Mana User (melee):** Warrior, Rogue, Pets
- **Mana User (caster):** Priest, Druid, Paladin, Hunter, Mage, Warlock, Shaman

Current feature build: **1.7-JA3**.
