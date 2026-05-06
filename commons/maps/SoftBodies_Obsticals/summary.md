# Breathing Rooms and Flag Dancers — Summary

The third Soft Bodies map introduces obstacle interaction — soft bodies negotiating static and dynamic rigid geometry. The breathing_room artifact features SoftBody3D walls with sinusoidally oscillating pressure coefficients, creating corridors that rhythmically contract and expand. Soft bodies caught mid-contraction experience bilateral compression, thinning along the squeeze axis while extending along free axes, demonstrating force distribution through the spring network.

The flagdancer artifact demonstrates wind-cloth interaction. A cloth surface pinned along one edge responds to an aerodynamic force field that varies with the angle between the wind direction and the local surface normal — full exposure produces billowing, edge-on orientation produces slack. Spatial turbulence via sine functions creates rippling rather than uniform displacement. The implementation uses skeletal bone displacement for computational efficiency while preserving the visual character of wind-driven cloth.

Three collision modes emerge across the obstacle scenarios: wrapping (soft body conforms around convex obstacles), compression (bilateral squeeze between parallel surfaces), and sliding (tangential motion with friction). Surface friction in Verlet systems works through old_position manipulation — reducing tangential velocity while preserving normal response. The breathing room's continuous oscillation prevents equilibrium, forcing perpetual re-adaptation. When the wall's breathing frequency matches the soft body's natural frequency (f = sqrt(k/m) / 2pi), resonance amplifies deformation dramatically.

Through Ahmed, the breathing room is a space not built for the body that enters it — the architecture demands compression, timing, accommodation, and the cost is borne entirely by the yielding material. Through Merleau-Ponty, the flag that reveals the wind and the soft body that maps an obstacle's surface through deformation demonstrate that yielding is a form of perception: the body that gives knows more about what touched it than the body that resists.

**Artifacts:** breathing_room (dynamic oscillating walls), flagdancer (wind-cloth interaction), grab_long_stick, pick_up_cube (interactive tools).
**Sequence position:** 3 of 9 in Soft Bodies (integration phase). Follows SoftBodies_Carusell, leads to SoftBodies_Obsticals_Part2.
