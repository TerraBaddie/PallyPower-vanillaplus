PallyPower - VanillaPlus
========================

World of Warcraft 1.12.1 / VanillaPlus PallyPower fork
Repository: TerraBaddie/PallyPower-vanillaplus

CURRENT BUILD CHANGES
=====================

1. 20-Minute Paladin Blessings
------------------------------
- Regular Paladin Blessings are treated as 20 minutes by default.
- Improved Blessing talent ranks are no longer required to reach a 20-minute
  duration.
- PallyPower's rebuff/timer logic now uses a flat 20 * 60 second duration.
- Existing talent-rank information is still displayed because those talents may
  affect blessing strength or other server-specific behavior; they simply no
  longer extend the timer.

2. Blessing of Might on Hunters
-------------------------------
- Hunters are no longer blocked from receiving Blessing of Might when Smart
  Buffs is enabled.
- The old Smart Buff filter treated Hunter as one of the classes that should
  never receive Might. Hunter was removed from that exclusion.
- Priest, Mage, and Warlock remain filtered from Might by the existing Smart
  Buff logic.

3. Global 'class' Crash Fix
---------------------------
Fixes the error:

  PallyPower.lua: attempt to perform arithmetic on global 'class'
  (a string value)

Changes include:
- The player's class returned by UnitClass() is kept in a local variable instead
  of leaking into the global 'class' variable.
- ASSIGN addon messages are parsed into local numeric class/assignment IDs.
- tonumber() and range validation are used before performing numeric operations.
- Grid click and mouse-wheel handlers no longer rely on an unsafe global class
  value.

This prevents a string such as "PALADIN" from being used where PallyPower expects
an assignment column number.

4. Judgement Assignment System
------------------------------
Adds a separate per-Paladin Judgement assignment column to PallyPower.

Supported assignments:
- Judgement of the Crusader
- Judgement of Wisdom
- Judgement of Light
- None

The Judgement assignment is deliberately separate from blessing assignments and
uses the reserved assignment slot/column 10.

Controls:
- Left-click: cycle forward through Judgements.
- Mouse wheel up/down: cycle forward or backward.
- Right-click: clear the Judgement assignment.
- Hover: show the Paladin's current Judgement assignment in a tooltip.

Current scope:
- This is an assignment and coordination feature.
- It does NOT automatically cast a Seal or Judgement.
- It does NOT currently track whether the Judgement debuff is active on the
  target.
- Judgement assignments can now be included in the optional chat announcement
  feature described below.

5. Judgement Assignment Synchronization
----------------------------------------
- Updated PallyPower clients exchange the Judgement assignment through the
  existing addon communication system.
- The extra assignment is transmitted as assignment column 10.
- Incoming assignment data is validated so only the supported Judgement values
  are accepted.
- SELF synchronization includes the Judgement slot for updated clients.
- Mixed-version protection preserves an existing Judgement assignment when an
  older PallyPower client sends a SELF message that does not contain the new
  Judgement slot.

Important:
- Other Paladins must use this updated PallyPower build to see Judgement
  assignments in their PallyPower window.
- Older PallyPower clients do not display the new Judgement column.

6. Assignment Grid UI Improvements
----------------------------------
The top of the assignment grid now includes text labels above the existing class
icons for easier reading:

- Warrior
- Rogue
- Priest
- Druid
- Paladin
- Hunter
- Mage
- Warlock
- Shaman
- Pets

The header area was expanded/repositioned so the labels and icons have enough
space and remain aligned with their assignment columns.

7. Judgement Header UI
----------------------
- The old experimental "Judge / Assign" text box was removed.
- The Judgement column now matches the class-header style:
    Judgement
    [32x32 icon]
- The Judgement header icon is the actual classic Judgement spell icon:

  Interface\Icons\Spell_Holy_RighteousFury

- It is the same 32x32 size as the class icons for a cleaner, consistent layout.

8. Existing VanillaPlus Fork Features Retained
----------------------------------------------
The current build keeps the existing VanillaPlus PallyPower features, including:
- Option to switch between Regular Blessings and Greater Blessings.
- Buff frame available while solo.
- Pet support in the assignment/buff table.
- Displays the maximum available blessing rank for each Paladin.
- Displays relevant blessing talent rank information.

INSTALLATION
============

1. Extract the archive.
2. The final addon folder must be named exactly:

   PallyPower

3. Place it in:

   World of Warcraft\Interface\AddOns\

4. The expected path is:

   World of Warcraft\Interface\AddOns\PallyPower\PallyPower.toc

5. Restart the game or reload the UI if appropriate.

COMPATIBILITY
=============

- Intended for the World of Warcraft 1.12.1 client / VanillaPlus environment.
- Uses the legacy Vanilla-era Lua/XML addon API style.
- Judgement assignment display/sync requires this updated build on participating
  Paladin clients.

NOTES
=====

The Judgement system is currently intended for raid coordination rather than
combat automation. Blessing functionality remains separate from Judgement
assignments so the original PallyPower workflow is preserved.


9. Assignment Chat Announcer
----------------------------
Adds a compact chat-destination button beside the main PallyPower close button.

Left-click cycles through:
- S  = Say
- Y  = Yell
- P  = Party
- R  = Raid
- RW = Raid Warning

Raid Warning is only offered while the player is in a raid and has raid
leader/assistant privileges. If Raid Warning was selected and that permission
is lost, PallyPower automatically falls back to Raid.

Hovering the button explains the channel abbreviations and controls.
Right-click prepares the assignment announcement. Before anything is sent,
PallyPower displays an "Are you sure?" confirmation that includes the number of
messages and the selected chat destination.

The announcement batch is paced at approximately one line every 0.8 seconds so
it does not dump every assignment into chat in a single frame.

Announcement wording:
- If one Paladin has the same blessing for every represented class in the current
  group/raid:

    NAME is buffing the whole raid with Kings.

  ("whole party" is used in a party.)

- If two blessings are in use:

    NAME is buffing Non-Mana User (melee) with Might.
    NAME is buffing Mana User (caster) with Wisdom.
    Whisper [NAME] if Mana User (melee) and you would rather have Might over Wisdom.

- The [NAME] in the Whisper line is a normal Vanilla player hyperlink. Clicking
  it opens a /w to that Paladin; it does not automatically send a whisper.

- If the Paladin has a Judgement assignment, it is announced as:

    NAME is assigned to Judgement of Wisdom.

- If more than two distinct blessings are assigned to represented classes, the
  announcer uses a short custom-assignment notice rather than guessing which
  blessing should be called melee/caster.

10. Version
-----------
- Current feature build: 1.7-JA2
