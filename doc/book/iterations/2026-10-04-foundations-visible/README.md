# Make the concept visible

4 October 2026. Visual companion to Foundations before Randomness: Primitives, Transformation, Arrays and Colour. Teaching proposals only; no Godot runtime, map order, tutorial or approval changes.

[Interactive page](http://localhost:3003/research/foundation-visuals/index.html) · [Read-only evidence page](http://localhost:3003/book-review/doc/book/iterations/2026-10-04-foundations-visible/index.html)

Six browser sketches cover a position value, sampling and traversing a trace, frame/state changes, a function with parameters, array addresses, and independent versus shared object state. The hall atlas covers all 35 halls, including reflective halls that need no additional programming exercise. Twelve capability links connect this page to the foundation plan.

Museum pictures are saved captures of existing work. Their provenance is in `manifest.json`; some show an earlier arrangement. Browser diagrams are reduced authored examples, not controls for those museum objects. A still image cannot verify interaction, transfer between halls or learning.

## Edit and rebuild

Edit the three sequence visual-plan JSON files for hall choices. Edit `build.py` for the six comparisons and page layout; `demos.js` contains browser-only interaction. Run from the main repository:

```powershell
python -X utf8 doc/book/iterations/2026-10-04-foundations-visible/build.py
```

The build creates `visual-plan.json`, `manifest.json` and the read-only `index.html`. It also publishes the interactive page to the sibling `ada_encyclopedia/public/research/foundation-visuals/index.html`. The book-review route keeps its existing script-blocking security policy.

## Checked

All 36 image sources and the live page returned HTTP 200. Browser actions checked rejection/acceptance and adjacent-pair traversal, coordinate-frame contrast, retained state after leaving, column parameters, an empty cell retaining its address, and independent/shared palette state. See `verification.json` for the bounded checks.

Museum integration and learner testing remain future work. Preserve the distinctions in each card when expanding one tutorial at a time.
