# Triangle: a drawing revealed

The next monitor follows Trace sampling with the Triangle drawing tool. It films a private, genuinely three-dimensional Godot scene: stored corners, boundary edges, the source's fan triangles, a separated view and their return. An orbiting camera reveals depth and the reverse view. The physical monitor inherits gaze activation and the existing desktop/XR pointer buttons.

## Source and limits

- Existing source: `commons/primitives/point/draw_triangle_faces.gd`.
- Read-only snapshot: `get_experiment_state()`, `placed_points`, `current_path`, and the latest completed drawing's existing mesh arrays.
- The mesh already emits six vertices per logical triangle: ABC and ACB with opposing normals. Its material disables culling. The monitor does not teach that turning this particular face over makes it disappear.
- Source world positions are transformed into the tool's local frame. Mesh normals use the inverse transpose. The display centers the copied positions and scales them uniformly to fit the camera. The original positions and mesh remain intact.
- An unfinished path takes precedence over the previous closed loop and supplies no face. Clearing the source clears the monitor. Hiding the fill at the tool also hides it on the monitor.
- The tool fans from its first stored corner. Its existing START operation can therefore change the film's internal connections. No alternative triangulation is substituted for concave or non-planar outlines.
- The animated separation, pacing, colours and numbered labels belong to the illustration; the source does not physically disassemble. The monitor preserves the emitted geometry while making its parts visible.
- The display supports up to 256 selected corners; larger or invalid records show an explicit message instead of silently truncating the drawing.

## Placement

Added `triangle_reveal_monitor` at map cell **(1,16)**, facing into `Point_Triangle_Context`, with its own stand. The drawing tool, enlarged twin and construction plate retain their previous placements. Only this hall's entry was regenerated in the active and shipped museum plans. Backups of the prior map and plan rows are beside this document.

The original drawing algorithm, twin, shared monitor logic, manuscript, tutorials and storyboards were not edited.

## Evidence

- `tools/probes/triangle_reveal_record.gd`: 52 runtime checks using the real drawing tool. Includes exact emitted vertices and normals, fan indices, independent mesh/source transforms, nonuniform scale, START changes, open paths, clear, fill visibility, invalid records, copy isolation and unchanged TraceData.
- `tools/probes/triangle_reveal_monitor.gd`: controls, gaze pause/resume, read-only operation, open boundaries, face separation and exact reassembly, real hall placement and unobstructed button access. Results in `report.json`.
- `tools/run_triangle_reveal_monitor.py`: renders through a private copy of the real museum with redirected runtime output; verifies protected source hashes and rejects script errors.
- `museum.png` and `museum-feed.png` show the actual hall's existing drawing. The film frames and other stage images use explicitly supplied test outlines passed through the actual tool. They are not a recorded visitor gesture.
- No new script errors in the verified run. Existing museum warnings about audio identifiers, a weapon material and entrance fallback remain outside this change.
- Physical headset performance, hand reach and gaze feel still need a headset check.

Open the native scene `res://commons/artifacts/concept_monitor/triangle_reveal_preview.tscn` for live playback. D cycles supplied triangle, four-corner, six-corner and open-path examples; arrows turn the filmed camera. The monitor in the museum follows the existing creator automatically.
