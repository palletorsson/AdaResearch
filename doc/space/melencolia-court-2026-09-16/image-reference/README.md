# Melencolia court: the supplied drawing

16 September 2026. The user supplied the selected manuscript image after the archive page could not be opened in the previous restoration. `reference.png` preserves that supplied reference. This pass refines the existing court before the separate Dürer tableau.

The four corner pyramids now have pale blue opaque finishes and slender 0.6 × 0.6 × 2.4 metre proportions. The centre uses a pink pyramid, 0.8 metres across and 2.8 metres tall, on a matching 0.8-metre cubical pedestal. Four ochre cubes, also 0.8 metres across, form the cross around it. The grey 5 × 5 metre museum platform and its ramp remain in place. These are museum dimensions adapted from the drawing's relationships, not dimensions measured from a perspective image. The drawing's small bird is not reproduced.

`solid_color` is an optional instance setting shared by the three existing primitive scripts. Missing, empty or invalid colours use the original material; no existing scene material resource is mutated. The corner's optional `height` and the central pyramid's optional `pedestal_height` preserve the original dimensions and absence of a pedestal when unconfigured. The pedestal is part of the central artifact, so the room retains eighteen placements and all eleven artifact types.

The source map and both cached museum plans carry those settings. Platform geometry, utilities, other plan rows and primary roles are preserved. `final.md`, `tutorial.md` and `artifacts.md` describe the visible colours, support and sizes. The accepted editorial changes, five book artifact families and three footnotes remain intact.

## Verification

- 23 headless component checks pass: original dimensions and materials, optional pigment, matching pedestal collision, repeated configuration, removing the pedestal, cube material isolation and the existing lattice variant.
- 146 actual endless-museum checks pass: original deck and ramp checks plus configured dimensions, colours and seating of all nine court placements. Godot exited 0 with no GDScript parse or script errors. Existing shader-cache, material deprecation and exit resource messages remain in the log.
- Ten content/API/scope checks pass, including unchanged structure/utilities, preservation of other rooms' plan entries, live book text, primary agreement and grid reachability from the authored entrance. Grid reachability is not a physical avatar walkthrough.
- The book's ReactMarkdown/remark-gfm renderer produces three footnote references, three backlinks and two code blocks.
- Screenshots come from the actual endless museum. `reference-court.png` shows the refined court; `court-and-tableau.png` shows its relationship to the next platform. `court-entrance.png` records the lower arrival view.
- Headset comfort and embodied passage remain for later testing. No commit was made.

Pre-edit files are under `before/`; script snapshots use `.gd.txt` to avoid loading duplicate Godot classes. `before-hashes.json` records their source hashes. The preceding restoration and editorial reports remain historical records of those earlier passes.
