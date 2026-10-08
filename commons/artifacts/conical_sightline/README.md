# Conical sightline

An original study after the spatial question in Gordon Matta-Clark's *Conical Intersect* (1975). Three separate walls receive copies of one conical cutter. A witness display keeps the intersections. No historical building is reconstructed.

- Component: `conical_sightline.tscn` — CSG geometry, collision, supplied setting methods.
- Desktop viewer: `study.tscn` — three camera positions and Before / cut, Shift cut, Reset buttons.
- API: `set_cut_x(float)` clamps to −0.65…0.85 m; `set_cut_enabled(bool)` toggles the cutting operation and witness display.
- Main solids use difference; witnesses use intersection. Side doors remain in both states.
- Capture and behavioural checks: `python tools/capture_conical_sightline.py`.

The collider supports ray/geometry comparison. Desktop capture checks do not establish VR comfort, accessibility or structural feasibility. No gravity or architectural load model is supplied. This is a proposed Boolean Works companion, not an installed hall.

Source and separate reading/making score: `doc/book/iterations/2026-10-01-matta-clark-one-cut/READING.md`.
