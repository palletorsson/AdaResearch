extends "res://algorithms/cellularautomata/volumetric_fog/volumetric_fog_ca.gd"
## The tower's adapter for volumetric_fog_ca (floor_content.gd sets it). It drew a central Z slice on the Mobile
## renderer because the base drew only a FogVolume, which Mobile cannot render. The base draws its live cells as soft
## puffs in every renderer since 2026-11-10 (and the FogVolume only where an environment enables volumetric fog), so
## the adapter adds nothing; it stays because the tower preloads it.
