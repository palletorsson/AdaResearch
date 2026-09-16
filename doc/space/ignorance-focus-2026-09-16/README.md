# Primitives_Ignorance: what the polygons cannot hold

Follow-up: Palle restored the five-segment capsule to the main encounter. See [capsule-return/README.md](capsule-return/README.md) for the current six-primary order and its geometry checks. The record below describes the preceding pass.

2026-09-16. Responds to Palle's instruction that ignorance refers to Plato, reversed toward what polygons cannot hold.

The chapter asks the visitor to inspect a familiar sphere, compare matched shaded and edge-marked pairs, and choose possible uses before revealing triangle counts. The reversal is methodological: investigate the implemented figure's omissions and possibilities. Plato already distinguishes drawn figures from the geometric objects considered in thought. A finite triangle mesh's inability to retain continuous spherical curvature is a claim about this representation, not about mathematics' ability to describe curves.

## Walk and preservation

Primary order: `sphere` → `sphere_high` → `sphere_mid` → `sphere_low` → `budget_of_smoothness`. The resolution pairs already stand in that physical order. The prose explicitly returns to the counter beside the inscription after the comparison.

All 26 placements and all runtime sources are retained. Five primary types account for eight placements. The five regular solids, octahedron, truncated tetrahedron, capsule, star, rock, right triangle and cone opening remain available as return studies. The tutorial retains their useful earlier prose while correcting the generic tutorial's claim that every low-resolution sphere is a prism. A capsule's failure to coincide after a particular half-turn does not establish a complete absence of symmetry.

Updated final, intent, blurb, tutorial, technical, critical, inventory and summary. Historical field and walk notes are retained beneath scope notices. The primary group title and order are synchronized with the book. Only this room's existing spine entries were reordered; global first-occurrence membership was preserved. No new controls, geometry changes or artifact removals are claimed.

The `before/` tree contains fourteen exact file copies. `archive.json` records their checksums and the runtime source checksums.

## Source grounding

- [Plato, Republic, Book VI](https://classics.mit.edu/Plato/republic.7.vi.html), Benjamin Jowett translation: the divided-line discussion distinguishes diagrams from the objects of geometric reasoning. The hall's reversal is our interpretation of a method, not a claim that Plato failed to notice imperfect drawings.
- [The Academy of Plato](https://mathshistory.st-andrews.ac.uk/Societies/Plato/), MacTutor: the familiar doorway inscription is a later tradition. The main text names the tradition and the footnote explains its uncertain historical status.
- [Godot 4.6 SphereMesh](https://docs.godotengine.org/en/4.6/classes/class_spheremesh.html): API reference for radius, height, rings and radial segments. The local scripts and component probe establish this room's actual settings and counts.
- Local implementation: `commons/artifacts/budget_of_smoothness/budget_of_smoothness.gd`, `commons/primitives/shared/mesh_inspection.gd`, the three sphere inspection scripts/scenes, and `commons/primitives/sphere/sphere.gd`.

The counter measures generated triangle triples and those exceeding a squared-cross-product tolerance of `1e-16`. Submitted/with-area pairs are 24/16, 80/64, 288/256 and 4224/4096. These are mesh counts, not frame-time measurements or a ranking of artistic value. Overlays and furniture are excluded. The ordinary entrance sphere is smaller than the inspection pairs and is not presented as a controlled size comparison.

## Verification

- Existing `commons/testing/probe_ignorance_primary.gd`: 38 checks pass. Tests cover actual button callbacks, count/edge visibility independence, generated mesh counts, matched pairs, and the museum-derived counter placement.
- `content-checks.json`: 15 checks pass, covering exact archives, unchanged map/runtime, scoped metadata edits, primary/book agreement, retained placements and optional studies, live authored sections and scoped diff whitespace. Live sections were rechecked after the final citation correction.
- `render-checks.json`: 13 checks pass using the encyclopedia's installed ReactMarkdown and remark-gfm. All seven authored sections render; all three footnotes have valid targets and backlinks. An initial check incorrectly required an empty-valued footnote attribute; accepting the renderer's attribute value corrected the check without changing the document.

Probe output includes an unrecognized resource UID and a root certificate-store error during startup. They did not fail the 38 component checks; this is not a claim of a clean whole-project boot. Full-room reach, legibility and headset comfort remain unverified. Rendering checks use the real Markdown renderer, not a visual browser or headset inspection.

[Read the chapter](http://localhost:3003/book?map=Primitives_Ignorance&section=final).
