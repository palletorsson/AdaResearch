# Linked seed instruments in the web editor

The frame-timing scope, MOVE/KEEP recording sphere and seed-source console are
generated parts of the seed-replay exhibit. `seed_journey.gd` positions them
relative to the `random_return` placement with the same `route_link`. Counting
map tokens alone therefore omitted three instruments that visitors could see.
The travelling sphere itself is the existing `random_return` artifact.

The randomness registry now describes these parts, their enabling configuration,
their positioning anchor and their local offsets. The web hall editor resolves
that metadata against its working map, shows three numbered markers and a
**Linked instruments** list. Moving or rotating the parent placement updates the
markers, including pending edits. Selecting a part selects that parent for
editing; it does not create an independent copy or change the seed connection.
Missing or ambiguous links are reported without guessing a position.

Registry search recognizes “time frame study”, “seed move sphere”, “hand
movement” and related names. Search results identify the containing exhibit and
list its parts. Normal placements, experiment recipes and runtime scripts were
not changed by this repair.

Current mode: linked parts move with their parent. Independent component movement
was offered as an optional alternative and is not implemented in this change.

Verification: 127 native museum checks pass, including frame capture/replay,
movement sampling and the linked journey. Eleven web tests pass, including a
comparison of the editor's computed marker coordinates against the native
instruments. The changed frontend and API files pass a scoped TypeScript check.
The browser rejected a reload under its URL security policy, so visual browser
verification remains unperformed; no alternate browser path was attempted.
Physical headset verification remains open.

[Verification receipt](verification.json) · [Native checks](museum.json)
· [Probe](museum_probe.gd)

Open [Random Definition](http://localhost:3003/long-museum?hall=Random_Definition)
and refresh the page. The room panel shows 8 artifacts plus 3 linked instruments.
