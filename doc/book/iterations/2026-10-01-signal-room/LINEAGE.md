# A room made from capabilities already learned

This is an application of existing rungs, rather than a new fundamental rung or a claim that every artist's practice reduces to code.

| Existing rung | Used here | New demand on the learner |
| --- | --- | --- |
| `array` | Flat index, row, column and a value at an address | Relate an inspectable 4 × 4 window to the surrounding display. |
| `tile` | A small alternating rule repeated across a surface | Keep the rule visible when its scale exceeds one glance. |
| `clock_pattern` | A chosen step changes the displayed offset | Distinguish moving a window from drawing another sample. |
| `random` | A local seeded generator | Permute rows or individual cells; state which relations survive. |

**Primary home: Randomness, as a return after Random_Entropy.** The earlier array lesson supplies the coordinates and repetition. The entropy lesson gives the comparison a reason: the count can remain correct while it says nothing about changed neighbours. The floor remains solid in every state, separating a displayed zero from withdrawn support.

The working study is in `doc/book/studies/signal-room`. It is registered as `signal_room` with `map_ready: false` and `include_in_map_data: false`. Its 14 × 24 m room has not been inserted into the active spine. The next installation work is a dedicated bay with main-player controls and connected entrance/exit, followed by a production-museum capture and collision route. Its standalone viewer already supplies walking and editable controls.

Borrowed now: texture upload, UV unfolding, the built room, camera and walking controller. Later: inspect that renderer in Shaders or encode a declared source in a data exercise. This distinction lets a student make a consequential change now without requiring them to write the whole display engine first.

Native evidence: `doc/book/iterations/2026-10-01-signal-room/index.html`. Companion prose lives in `ENCOUNTER.md`, learner work in `MAKING.md`, canonical runtime construction in `commons/artifacts/signal_room`. These are related sets; the building code is not all compulsory lesson code.
