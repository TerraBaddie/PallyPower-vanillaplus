# PallyPower - VanillaPlus

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
- Existing VanillaPlus fork features are retained, including regular/greater blessing selection, solo buff frame, pet support, max blessing rank display, and blessing talent-rank display.

## Judgement assignment scope

This feature is currently for **coordination/assignment only**. It does not automatically cast a Seal or Judgement, track the target debuff, or announce assignments in Raid/Party chat. Other Paladins need this updated build to see the Judgement assignment column.

## Installation

Extract the addon so the path is:

```text
World of Warcraft\Interface\AddOns\PallyPower\PallyPower.toc
```

The addon folder must be named **PallyPower**.

## Compatibility

Designed for the **WoW 1.12.1 client / VanillaPlus** environment using legacy Vanilla-era Lua/XML APIs.

See `README.txt` for the detailed change log and usage notes.
