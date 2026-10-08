# Foundation studies on museum monitors

These six native 3D scenes implement the six working comparisons on
`http://localhost:3003/research/foundation-visuals/index.html`.
The source JavaScript is retained in [foundation_source.js](foundation_source.js).
The 35 hall cards on that page are proposals, not additional working sketches.

| Study | Hall | Try on the monitor |
| --- | --- | --- |
| A value places a body | Point_Coordinates | Change height; compare an incorrect extra frame offset |
| A movement becomes a record | Point_Trace | Read a candidate; keep or reject it; join retained neighbours |
| A response can remember | Trans_Body | Step the clock; approach and leave; compare current and retained state |
| One rule makes a family | Primitives_Columns | Change height or radial count while the other column stays fixed |
| An address survives an absence | Array | Read another slot; write a value; apply the checker rule |
| The same methods, separate lives | Color_Grid_Pallet | Advance two independent palettes; compare two references to one palette |

The upper controls play, replay, step through and turn the demonstration.
The lower controls pause it and keep the learner's chosen state. Looking away
does not lose that state. The upper **DEMO** control restarts the demonstration.
Controls use the existing XRTools pointer-button interface, including desktop
mouse clicks in the preview.

These are explanatory studies in private `World3D` viewports. Their controls
do not alter the neighbouring exhibits. The trace uses the browser's supplied
eight candidates, not a captured visitor stroke. The columns use its straight
two-ring profile. Palette is a small class implemented for this study, not a
claim about the existing colour floor's internal implementation.

Open `spine_preview.tscn` with `-- --collection=foundation` to try just these six.
The gallery's **Six foundation studies** filter shows native Godot recordings
and their actual Endless Museum placements.

Verification commands:

```powershell
python tools/render_spine_films.py --only foundation_point foundation_trace foundation_state foundation_function foundation_array foundation_class --headless
python tools/verify_foundation_monitors.py
```

The second command also requires the completed movie, museum, pointer-control
and visual review reports. Physical Quest interaction remains a separate check.
