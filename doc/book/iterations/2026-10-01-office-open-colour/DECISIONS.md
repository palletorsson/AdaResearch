# Colour between the walls

The supplied photograph calls for overlapping transparent planes and open views, rather than repeating closed cubicles. Twelve single-sheet panes replace forty box-shaped glass panels in the active Color_Walls placement. Three workstations retain the office association. The layout has pale interrupted wings and a split canopy, three small angled accents, a staggered central route and a rear exit.

The first multiplier material trial was rejected after inspecting the native images. Even an isolated white multiplier darkened the background in this Compatibility museum; a minimal shader reproduced it. The final installation uses unshaded alpha tint at 0.52, disables fog on the pane itself and uses one QuadMesh per sheet. Opaque mode preserves RGB values and geometry, sets alpha to 1.0 and enables shadow casting. Transparent sorting remains order-dependent. No spectral glass, refraction, projected coloured lighting or Quest performance claim.

The pale architectural backing is deliberately unshaded and casts no shadow: it is display apparatus inside the existing museum, with openings at its edges. Furniture and panes collide; the thin floor overlay and overhead visual canopy do not replace the museum's existing collision floor. All dimensions are in the editable PANES table, separate from furniture/support construction.

Canonical final.md, tutorial.md, technical.md, critical.md, summary.md, blurb.md and intent.md now follow this arrangement. History is retained with dated current notes. The colour models and gradient encounter remain as before. Existing unconfigured and layout=cubicles placements retain their own geometry and behaviour; the active Color_Walls token opts in to layout=planes.

Replay from repository root:

```powershell
python tools/run_encounter_probe.py Color_Walls --sequence color --render --probe doc/book/iterations/2026-10-01-office-open-colour/probe.gd
python doc/book/iterations/2026-10-01-office-open-colour/build.py
```

The route driver uses real supplied key events and a 15 cm waypoint tolerance, with a brief key-release interval between legs. Earlier runs exposed an oscillation at an 11 cm threshold and a missed key transition; the apparatus was corrected without changing collisions. Final runtime report: 47 checks pass, including both complete routes, pane blocking, pointer callbacks, material state, preserved bodies and the two legacy configurations.

Reference attribution remains the user's supplied image; its artist and title are not established here. The photo is a spatial prompt, not a recovered score. Technical reference: [Godot BaseMaterial3D](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html), including alpha blending and disable_fog. Native checks establish this implementation's desktop behaviour, not headset comfort or student understanding.
