# Museum tutorial storyboards

For the live project → sequence → hall → evidence workspace, open [Project memory](http://localhost:3003/project-memory). It reads these authored proposals and keeps separate working notes and findings in the repository, with saved revision history. [Memory guide](../../memory/README.md). The offline route below remains useful for reading and its own browser-local corrections.

The current proposal covers Day Zero and all 204 halls in the 25-sequence spine. It is a selection of learning encounters for Palle to correct before full tutorials are written. Each summary has a full paragraph and a compact AI alternative; see BRIEF.md. The review switches between Full and Short AI for the same hall. The 192 later full paragraphs are preserved; Primitives has full prose counterparts to its earlier compact trial. Summary edits do not authorize code or map changes.

Open `../../iterations/2026-10-04-museum-tutorial-storyboards/index.html` for the museum route, photographs, storyboard paragraphs and artifact references. The visual route works from a local file without a server. `../TUTORIAL_STORYBOARDS.md` contains both versions. `../TUTORIAL_STORYBOARDS_SHORT.md` (also `storyboards-short.md` in the review) contains only compact summaries with shared writing constraints, for a future AI.

## Authored sources

- `CONTEXT.md`: compact orientation and the whole → sequence → map → evidence → whole working loop.
- `SEQUENCES.md`: generated overview of the 25 authored arcs; read this before loading all 204 hall summaries.
- `BRIEF.md`: the durable teaching agreement.
- `preparation.json`: Day Zero.
- `opening.json`: Primitives, retaining the proposed opening paragraphs.
- `early.json`: Transformation through Waves.
- `growth.json`: Randomness through Soft Bodies.
- `later.json`: Isosurfaces through the final sequence.

Maintain `storyboard` and `storyboard_short` together without changing their teaching selection. Edit these paragraphs deliberately, not by applying a template to every map. `build.py` assembles them in the current spine order and regenerates the combined Markdown and visual route. It does not write `tutorial.md`, `final.md`, map geometry or sequence order. `opening.py` was a one-time import of the opening draft, not a regeneration step.

## Rebuild

Run `collect.py`, then `build.py` using Python with Pillow installed and Node available for JavaScript syntax checking. The inventory reads the real spine, sequence definitions, saved museum plan, map placements and attributed native captures. Photos are copied as smaller WebP versions with source links and a provenance manifest. `checks.json` records count, order, links, syntax and map hashes. Photography is not lesson acceptance.

`capture_missing.py` optionally photographs planned halls with no attributed image using `capture.gd` and the existing museum probe runner. It creates isolated probe output beneath `ada_run/encounter_pilot/<map>_storyboard/`; it does not replace the active museum control file. `contact_sheets.py` creates image-inspection sheets, not replacement museum illustrations.

## State

Every storyboard is proposed. Some teaching adapters, saved-work transfers and lesson splits still need agreement and implementation. The route includes usable museum photographs for 199 halls. Two spine halls are absent from the saved museum plan: Lab_Path and LSystems_Shape_Grammars. Three further halls have rejected, obstructed camera views; `photo-gaps.json` identifies these. The saved plan still includes Chamber_Color, removed from the Colour sequence by the author, plus five biome side encounters. The review exposes these disagreements without changing the route files. Browser interaction has not been verified; the page's data, element references, linked files and JavaScript syntax were checked.

Corrections typed in the HTML are kept in that browser when storage is available. Export the corrections JSON to return them; they do not edit these source files automatically. After correction, expand and verify one tutorial at a time. The older subject register remains planning material until first teaching, supplied use and later return are reconciled with the agreed paragraphs.
