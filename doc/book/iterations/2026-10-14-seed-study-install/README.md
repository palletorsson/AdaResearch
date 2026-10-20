# Seed study in the normal museum

The user could not find the five-view pilot in the desktop museum or the web
editor. The experiment launcher injected it into a temporary visit; it had no
registered scene or map placement. The editor also silently limited a chapter's
palette to 60 entries, hiding `seed_replay_demo`, `slot_machine` and
`trng_vs_prng` in randomness. Its overview cache did not watch direct map edits.

`seed_study` is now registered in `randomness.json` and placed at (10,17),
rotation 270, in Random_Definition. All seven existing placements are preserved.
The production scripts live under `commons/artifacts/seed_study`, since export
presets exclude `doc/`. Their bytes match the printed experiment at promotion;
the museum adapter restricts keyboard actions to a visitor at the board.

Open [Random Definition in the editor](http://localhost:3003/long-museum?hall=Random_Definition).
In desktop play, reload the room and look near its far-right end. This normal
placement supersedes the older injection launcher for visitor trials. Earlier
preview receipts remain historical evidence of that harness.

The companion `ada_encyclopedia` checkout now watches map and sequence inputs
when refreshing the overview and displays the complete chapter palette. The
editor continues to read full placement strings directly from map_data.json.

Verification:

- 37/37 checks in the actual museum builder, locating the registered artifact
  without injecting it. All eight map artifacts loaded. The board, stored-result
  replay, keyboard proximity and floor access passed. A rendered capture was
  visually inspected.
- 66/66 native checks of the promoted record implementation and 3/3 replay
  checks in a fresh process.
- Four web cache regression tests: unchanged inputs, direct artifact addition,
  removal and a failed rebuild retaining the last view with a warning.
- Live web API/map agreement on all eight placements; registry search resolves
  seed_study. Browser inspection confirms the restored palette entries.
- Only Random_Definition and its artifact counts changed in the derived strip.

The map had recent independent edits when this work began. `before/` preserves
the inspected inputs; no older arrangement was restored. The refreshed inventory
records the current map rather than the stale placement hints in the museum plan.
Physical headset usability, long-session performance and independent learner
reconstruction remain open.

[Verification record](verification.json) · [Museum checks](museum.json)
· [Web API agreement](web-api.json) · [Normal-spawn probe](museum_probe.gd)

Re-run the installed museum check:

```powershell
python -X utf8 tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-14-seed-study-install/museum_probe.gd --output-tag seed-study-installed-review
```

In `ada_encyclopedia`, run `node --test tests/long-museum/strip.test.mjs`.
