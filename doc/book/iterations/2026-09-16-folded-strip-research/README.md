# Folded strip: bounded form research

Date: 2026-09-16. Review page: http://localhost:3003/research/possible-bodies/triangle-strip-research.html

## Scope

Study the existing `commons/primitives/folded_strip/folded_strip.gd` through its real `update_mesh()` and four facture modes. The production artifact, triangle hall, roles, and book text have not been changed by this study. This is a proposal for reviewing forms before changing the hall.

The starting vertices come from Godot, not a reconstruction in Python. The baseline is planar to numerical precision, even though its alternating colours and normals suggest articulation. All candidates retain its 26 vertex indices and 24 triangle connections. These experiments change the geometric embedding; they do not by themselves establish a new abstract topology.

## Results

- 47 deterministic candidates across hinge, bend, twist, wave and collapse families.
- Eight cases selected for contrasts, including two failures; selection criteria are in JSON.
- 18 analytic checks pass (areas, winding, rigid folding, intersections and degeneracy).
- 64 Godot captures: eight cases × four production treatments × two fixed views.
- Paired 40-degree hinges are a promising visual candidate. The single 70-degree hinge is easier to read as a first operation.
- Hinge edge lengths are preserved to floating-point tolerance. Bend, twist and wave are labeled deformations and report edge-length drift.
- Alternating 60-degree hinges preserve lengths but produce 99 detected intersections between disjoint faces. This is a retained failure.
- The collapsed case has 24 degenerate source triangles. The production shell skips them and can have no mesh surfaces. A blank capture is an expected result, not a missing image.

## Rendering is part of the finding

The production strip emits consecutive triples without correcting alternating strip winding. The cast mode indexes those vertices and generates normals from that winding, so its flat control already has triangular shading. Repair this before treating cast as a reliable smooth-surface comparison. The facet mode duplicates front/back triangles and disables culling; coincident faces are another rendering concern.

The armature adds unshaded tubes of radius 0.012 m. The shell adds an independent 0.06 m prism for every nondegenerate triangle; it is not a welded watertight shell. Brightness and thickness are not controlled material-only variables here, and the page says so.

Each case is recentered by translation only. The lowest ideal vertex is placed 0.04 m above the plinth top, leaving room for tube radius and shell half-thickness. Same geometry, scale, cameras and lighting across its four treatments. Orthographic camera width 6.2 m, 960 × 640 images, compatibility renderer. See the render harness for exact transforms and lights.

Grab handles are hidden and their processing disabled for this static surface study. The first capture attempt found empty mesh surfaces on the collapse; the second found hidden handle updates changing vertex arrays. Both harness issues were addressed, and every final capture checks that the source vertex array remains unchanged. This is not an interaction, collision, comfort or headset test.

## Measurement limits

Coherent winding is used for angle measurements only; the production renderer is unchanged. Intersections are finite-precision tests between ideal zero-thickness faces with no shared vertex. Shared-vertex pairs, tube/shell thickness, handles, physics and clearance in the museum are not tested. A count of zero is not proof that the object is collision-free or physically foldable. Extents are local axis-aligned dimensions, not a room footprint. Metrics do not rank beauty or determine the book's interpretation.

## Files and reproduction

From the AdaResearch repository root, with Godot 4.6 and Python 3.10 or later:

```powershell
$godotStudyExe = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
& $godotStudyExe --headless --xr-mode off --audio-driver Dummy --path . --log-file ada_run/folded-strip-export.log --script res://ada_run/folded_strip_export.gd --quit-after 120
python -X utf8 ada_run/research_folded_strip.py
& $godotStudyExe --xr-mode off --audio-driver Dummy --path . --rendering-method gl_compatibility --resolution 960x640 --log-file ada_run/folded-strip-render.log --scene res://ada_run/folded_strip_render.tscn --quit-after 3600
python -X utf8 ada_run/build_folded_strip_gallery.py
```

The generator stores the source/export/generator hashes; the renderer refuses a source mismatch and records selected-case and image hashes. The gallery builder checks that all 64 captures belong to the current selection, match image hashes, and preserve the assigned vertex arrays. Godot cache-write warnings can occur in the sandbox; read the capture manifest and inspect images rather than assuming process exit alone establishes success.

- `baseline.json`: production vertices exported by Godot.
- `all-cases.json`: complete search with parameters, metrics, fixture results and limits.
- `selected-cases.json`: selected eight cases, with explicit reasons.
- `render-report.json`: real render counts, source/image hashes and invariant checks.
- `renders/`: actual Godot image output.
- `triangle-strip-research.html`: generated review page.
- `ada_run/research_folded_strip.py`: deterministic search and analytic checks.
- `ada_run/folded_strip_export.gd`: production geometry export.
- `ada_run/folded_strip_render.gd` and `.tscn`: isolated capture stage.
- `ada_run/build_folded_strip_gallery.py`: verified gallery generation.

To serve in the local encyclopedia, publish the generated HTML at `public/research/possible-bodies/triangle-strip-research.html` and the JSON, README and renders under `public/research/possible-bodies/triangle-strip-research/`.

## Proposed next experiment

Repair winding/normals, repeat the flat control, then animate the existing strip from flat through a single hinge to the paired fold. Preserve those steps as observable operations. Review the resulting encounter before revising the hall or final.md. No automatic claim is made that the most complex candidate is the best one.
