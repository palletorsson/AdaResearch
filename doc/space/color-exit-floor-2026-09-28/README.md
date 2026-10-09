# Colour hall exit floors — 28 September 2026

The embedded grid used integer cube centres, while museum cells begin at integers. Its far edge stopped half a metre before the exit passage. In Color_Nails, downward physics rays measured the basin floor at -0.30 m throughout the exposed strip.

The shared embedded-grid placement now adds 0.5 m in X and Z. Cubes, walls, utilities and artifacts move together; their internal placement stays the same. Staged simulations already applied this offset, so their effective position is unchanged. No map layouts or manuscript text were edited.

All eight active Colour halls pass 1,008 floor-support rays and 32 controlled crossings: entrance and exit, both directions. Each crossing checks the lowest foot position as well as arrival. Tests build the actual museum in isolated runs. A physical headset walkthrough remains to be done. An already running museum must reload to use the corrected code.

- Evidence: [verification.json](verification.json)
- Regression probe: `tools/probes/color_exit_floor.gd`
- Example: `python tools/run_encounter_probe.py Color_Nails --sequence color --probe tools/probes/color_exit_floor.gd`

Existing uncommitted work in the shared museum script was preserved. No commit or push was made for this repair.
