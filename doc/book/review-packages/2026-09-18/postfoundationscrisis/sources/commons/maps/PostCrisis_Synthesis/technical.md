# Return with a change — implementation and encounter

The primary artifact is `accountability_ledger`. Its [scene](../../../commons/artifacts/accountability_ledger/accountability_ledger.tscn) and [implementation](../../../commons/artifacts/accountability_ledger/accountability_ledger.gd) supply the behaviour described here.

The defaults are log_interval=1.8 and visible_lines=6. _push_entry() chooses one shared index into the prewritten CHOICES and EXCLUDED arrays, pushes the pair to a bounded buffer and increments _count. The display starts with two entries. _process() advances the timer and animates the lamp and spool. There is no persistent log, visitor input or completion evaluation. The formula and earlier artifacts remain supporting reminders; their presence does not certify the ledger's examples.

## Operation to read after the encounter

```gdscript
_entries.push_front(line)
while _entries.size() > visible_lines:
    _entries.pop_back()
_count += 1
```

A line enters at the front; another leaves when the buffer is full. The counter survives that loss. We met a running count near the point at the beginning of the museum. Here counting and remembering separate in four lines of code. The machine can announce progress while the evidence of an earlier problem has already disappeared.

## What to compare

Read one choice/exclusion pair and keep it in mind after it scrolls away. Choose a room you have walked and name one obstacle, one possible change and one observation that would tell you whether it helped.

The entry count increases while old entries leave the six-line buffer. The examples are prewritten. The display records no visitor decisions and does not save the discussion.

## Limits and next test

Make the ledger accept a real museum observation with hall, affected activity, proposed change and later result. Preserve unresolved entries across visits. Begin with the contributor-counter ambiguity or a control whose reach has actually been tested.

This source audit does not establish headset readability, comfortable reach, collision clearance or frame rate. Those remain runtime observations. Existing supporting artifacts stay in the map; primary status identifies the book's encounter, not the only permitted content.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/PostCrisis_Synthesis/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.
