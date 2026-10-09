# Possible bodies: working state, 10 September 2026

Research post: http://localhost:3003/blog/2026-09-10-what-bodies-are-possible

Filterable guide: http://localhost:3003/research/possible-bodies/index.html

Scope: Colour, Patterns (tiling), Change and Forces. The authored sequence lists contain 32 maps; the effective museum order adds four Change ribbons. All 36 receive a question, proposed lead encounter, carry-forward distinction, next action, closing evidence and reusable method. The guide records explicit primary assignments and final.md anchors separately from proposals. The initial guide pass changed no maps or book text; the subsequent Flashlight action is recorded below.

Updated snapshot: 29 halls have final.md, 7 do not; 12 need primary/book review (including four unassigned Change ribbons); seven ribbon halls require curation. No book artifact anchor or explicit primary in this scope is absent from its source map placements after excluding editorial sub: markers. These are source checks, not demonstrations of runtime reachability or teaching quality.

First action completed: Color_Flashlight has a discovery-led final.md, corrected supporting texts and standing installation, and 40 passing desktop museum checks. Handles start at 1.1 metres, the full board stands above the floor, white starts aimed aside, and the side cube leaves the initial comparison clear. The same flashlight_demo is primary, placed and book-anchored. Tracked-hand usability remains open. Runtime evidence and its source fingerprints live in verification.json; the builder marks it stale if those sources change.

Next action: Pattern_Foundry. All nine Colour rooms now have text; tracked-hand walkthroughs remain open.

Edit `curation.tsv` to change editorial proposals. Run `python tools/build_possible_bodies_guide.py` to refresh facts and regenerate `audit.json`, `working-guide.md`, and `index.html`. The builder checks exact effective-route coverage and the placement of every proposed lead. Source hashes record what was read. Re-running does not update game data or automatically sync the encyclopedia.

Installed encyclopedia copies live under `C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/research/possible-bodies/`. The post is in its `src/content/blog/` folder and its two unmodified Godot captures are under `public/blog-images/2026-09-10-what-bodies-are-possible/`.

Publication verification: 36 unique HTML hall IDs and 36 Markdown hall entries; JavaScript syntax check; updated guide, audit, Markdown, Flashlight report and capture return HTTP 200. The encyclopedia's live roles API reports flashlight_demo as primary and from_book; the compose API sees the new 581-word manuscript with no stale source segments. Evidence: `ada_run/flashlight-publication-check.json`. The initial blog check is preserved in `ada_run/possible_bodies_publication_check.json`. Browser automation failed to initialise its kernel, so browser layout and filter interaction have not been manually reviewed. No remote deployment or headset validation performed; the 40 desktop museum checks are recorded separately.


Colour cleanup, 10 September: removed eight pattern-machine placements from Context Placed, Pillar, Paint and Walls, plus one loom in the older Color_Showcase map. Updated roles, sequence groups and inventories. Existing final.md texts are unchanged. Source comparison verifies that only the requested placement cells changed; live encyclopedia inventories are clear. Evidence: doc/space/color-pattern-removal-2026-09-10/verification.json. Continue through Pillar, then address Grid Pallet and its missing manuscript.


Grid Pallet completed: its actual floor receives one-cell edits through a reachable console; RULE replaces exceptions using real cube coordinates. Source, text and desktop evidence recorded together. See commons/maps/Color_Grid_Pallet/field_notes.md.


Walls completed: glass/opaque walls retain identical collision bodies; standing coordinate and interpolation exhibits now have their own supports. final.md, tutorial, technical, intent and critical agree on three mechanisms. See commons/maps/Color_Walls/field_notes.md and walls-encounter-check.json. Desktop captures include both wall states and both benches. Next: Chamber_Color and the closing Colour manuscript.


Chamber_Color completed: a mounted native chromatic projectile reaches a framed target, with distinct target and grid responses. 32 desktop checks and before/after captures accompany the closing manuscript. All nine Colour rooms have final.md; this is text coverage, not a claim of complete headset validation. Known unrelated scene-load and proximity-spawner warnings are recorded in the room field notes.


Patterns requirements revised, 10 September: see patterns-plan.html / patterns-plan.md, generated from doc/plans/patterns-room-body-shaders-2026-09-10.md. Requires multiple motif/carrier forms, whole-hall controls, explicitly engaged gestures, shared fabric recipes and a terminal shader/fabric studio. Current runtime capability is distinguished from planned adapters. No live artifact, primary assignment or sequence order changes in this planning pass. Render the plan with Python Markdown (tables and fenced_code) and sync the resulting files with the guide.
