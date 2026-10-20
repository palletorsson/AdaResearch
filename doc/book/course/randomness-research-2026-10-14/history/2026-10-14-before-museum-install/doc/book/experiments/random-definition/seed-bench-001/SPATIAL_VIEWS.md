# One retained set, five spatial assignments

The user asks to see flat colour, bars and their combination together, with random values also controlling object scale and rotation. A larger border should give the display more impact. The [exact request and clarification](../../../course/randomness-research-2026-10-14/implementation/003/evidence/space-views-feedback.json) initiate this revision.

All five panels now appear at once: FLAT, BARS and COMBO across the back; SCALE and ROTATE in front. Each repeats the same sixteen ordered triples from the 48-value seed bench. Colour uses `(a,b,c)` directly; spatial mappings use `u = (a+b+c)/3`. This is shared input with different assignments, not five independent random acquisitions and not a claim that RGB is one scalar.

| Panel | Assignment |
| --- | --- |
| FLAT | RGB; constant 4 cm height |
| BARS | Neutral colour; height `0.04 + 0.12*u` m |
| COMBO | RGB from FLAT, geometry from BARS |
| SCALE | Neutral cube, uniformly shrunk to `0.09*(0.35+0.65*u)` m per side |
| ROTATE | Neutral 9 x 4 x 4 cm rectangular piece; yaw `360*u` degrees |

Bars and scaled cubes retain their bottoms at 8 cm. A small orange end mark makes rotation legible. The rectangular piece fits within the cell at any yaw; rotation is periodic, so a full turn repeats zero. First compare FLAT/COMBO for added height, then BARS/COMBO for added colour. Scale/turn use different fixed shapes, which must be named when comparing them.

The first three grids retain 9 cm cell widths and 1.5 cm gutters, filling the dark inset. Each tray now has a 54 cm bronze frame and a 46 cm dark inset, giving a 4 cm visible border around the inset. Scale and rotation change the visible gaps as part of their assignment. Button spacing remains unchanged.

RESET 42 regenerates the deterministic baseline. CURRENT VIEWS explicitly brings an older saved recipe into this five-view apparatus without drawing again. KEEP, REPLAY, EXPORT, IMPORT, CLEAR KEPT and NEXT SEED retain their previous roles. All views stay visible; F1/F2 are no longer a flat/bar toggle.

Schema v3 records `space-assignments.v1` and the scale/rotation/layout parameters. Earlier v1/v2 imports still rebuild their two-view cell geometry; CURRENT VIEWS forks them with a parent ID and preserves the kept original. Sources and old results remain recoverable.

The [tutorial](tutorial.md) prints the complete reconstruction. Its next question is what the mean loses: different colours with equal sums produce the same bar height, scale and rotation. The final source remains open because this apparatus revision illustrates choosing assignments without establishing a learning benefit. The next human encounter should trace one cell across views, preserve a result and propose a change. Physical VR, independent reconstruction and sustained performance remain separate unfinished tests.
