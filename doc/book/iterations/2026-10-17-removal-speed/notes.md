# Adjustable removal pace

`random_removal_arena` now starts at **3×**, with rectangular **SLOWER / FASTER** buttons on its entrance panel. Available steps are 0.5×, 1×, 2×, 3×, 4×, 6× and 8×. The readout names the selected speed and the next warning duration. Map configuration may set `speed`; placement and map order are unchanged.

Speed divides the original 0.8-second warning and 0.6-metre walking interval. In the coil version it also divides the separately seeded 1.5–3-second wait. At 3× these become about 0.27 seconds, 0.2 metres and 0.5–1 second. A warning already started finishes its original timer; the new speed applies to subsequent warnings. The outstanding sampled wait rescales without drawing another value.

Changing pace does not advance either generator or alter the chosen tile. Busy/empty requests now return before sampling a wait. REPLAY cancels a pending removal, restores all visual/collision support and both generators, and retains the selected speed. The smaller teaching board's algorithm and student code remain unchanged.

The arena's own caps now face out of the backing panel, allowing hand contact and controller-ray activation. Native probes load both Random Remove's full crossing and Random Game's compact-console version, exercise real hand-layer overlap and pointer dispatch, compare seeded orders at 1× and 8×, test warning completion/reset cancellation, rate bounds, support removal/restoration, and the coil timer with a stationary supplied visitor. Saved reports and captures are under `Random_Remove/` and `Random_Game/`. These are software/native checks, not headset comfort or a visitor's reaction-time result.
