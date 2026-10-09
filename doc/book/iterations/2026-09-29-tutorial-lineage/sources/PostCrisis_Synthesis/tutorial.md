# Which consequence will you keep in view after the next line arrives?

Every hall made a choice inspectable. Here we turn that practice towards the museum itself.

<!-- @accountability_ledger -->

Read one choice/exclusion pair and keep it in mind after it scrolls away. Choose a room you have walked and name one obstacle, one possible change and one observation that would tell you whether it helped.

The entry count increases while old entries leave the six-line buffer. The examples are prewritten and arrive every six seconds. The display records no visitor decisions and does not save the discussion.

The source makes the operation inspectable:

```gdscript
_entries.push_front(line)
while _entries.size() > visible_lines:
    _entries.pop_back()
_count += 1
```

A line enters at the front; another leaves when the buffer is full. The counter survives that loss. We met a running count near the point at the beginning of the museum. Here counting and remembering separate in four lines of code. The machine can announce progress while the evidence of an earlier problem has already disappeared.

[Implementation](../../../commons/artifacts/accountability_ledger/accountability_ledger.gd). This is an excerpt from the artifact, not a standalone program.

Naming an exclusion does not repair it. Nor should every design limitation be treated as the same kind of harm. Keep the specific body, activity and consequence in view. The next iteration needs a durable record of a change and its outcome, including an outcome we did not expect. Generalisation begins when another hall presents the same relation; it remains a proposal until someone can test that second encounter.

<!-- @ -->

Return to one earlier hall. Remember both an obstacle and a form you wanted to enter. Desire can locate a next experiment as clearly as a fault. The spine has supplied tools for another pass, not a final inventory of possible bodies.

## Next experiment — not yet a visitor control

Make the ledger accept a real museum observation with hall, affected activity, proposed change and later result. Preserve unresolved entries across visits. Begin with the contributor-counter ambiguity or a control whose reach has actually been tested.
