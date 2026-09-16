# Primitives_Portals: what would count as arriving?

2026-09-16. Continues the hall-by-hall book revision after Primitives_Ignorance. Palle clarified that the feedback concerns `final.md`; this pass changes that book chapter and records its evidence here. Supporting chapter files, map, artifact roles, spine order and runtime sources are retained.

## The encounter

The opening carries forward the capsule: a finite construction can offer a form that its familiar name did not prepare us to notice. Portals then asks what repeated refinement would need to accomplish before we called it arrival.

The two existing primary artifacts retain their order:

1. `combine_portals`: choose a sufficiently round ring before counting; select and locate it; distinguish the unit-polygon perimeter calculation from the torus geometry; reverse the progression and inspect the direction assigned to refinement.
2. `achilles_tortoise`: predict a manual stage, read the residual gap at the finite endpoint, then use autoplay and pause to compare the current position with its stage target. The museum keeps running while this instrument waits.

The closing distinguishes ending a finite encounter from exhausting its question. It hands off to Melencolia's question of what would make the work complete. The main text has approximately 780 words including its two short source excerpts and artifact markers; four footnotes retain mathematical, historical and implementation detail.

No new interaction is promised. The text does not treat a torus as a teleporter, conflate a planar perimeter gap with a portal's overall error, treat a ten-stage animation as an infinite race, or claim that marker overlap means coordinate equality. Both code excerpts occur in the current source, including the track's negative Z sign.

## Sources

- [Godot 4.6 TorusMesh](https://docs.godotengine.org/en/4.6/classes/class_torusmesh.html): distinguishes the torus's two subdivision directions. The local script and scene determine the actual twenty-member sequence and its panel behavior.
- [Aristotle, Physics, Book VI](https://classics.mit.edu/Aristotle/physics.6.vi.html), R. P. Hardie and R. K. Gaye translation: parts 2 and 9 discuss infinite divisibility, the bisection argument and Achilles. The museum stages a particular halving model, with its own display timing; it is not a literal reconstruction of the ancient argument.
- Local `combine_portals.gd`, `achilles_tortoise.gd` and `limit_experiment_panel.gd`: actual controls, selected mesh counts, polygon calculation, stage targets, timing and readout labels.

The planar polygon note gives the chord formula and distinguishes exact convergence from floating-point rounding. The torus note retains the former Euler calculation by counting an identified quadrilateral grid and its triangulation. It distinguishes the surface's vertices from duplicated rendering-buffer vertices.

## Preservation and remaining editorial work

`before/` preserves twelve exact project files, including the longer previous final. `archive.json` records those hashes and five runtime hashes. All five map artifact placements remain; the capsule is a secondary comparison in this hall, even though it is primary in Ignorance.

The older tutorial and field notes contain claims needing a separate reconciliation: "the only way the machine can" draw a circle is too broad; the fifty-four-step saturation calculation belongs to a separate numerical exercise, not the installed ten-stage instrument; the portal transform fragment is not an interaction implemented by the ring meshes. This pass links the verified technical chapter and does not use those older passages as evidence. The former long topology comparison and perimeter-loop example remain preserved in the archived final.

## Checks

- Existing `commons/testing/probe_portals_primary.gd`: 30 checks pass. It exercises actual pointer callbacks, mesh selection/reversal, planar perimeter gaps, manual endpoints, tween pause/restart, configured museum stamps and local-control footprint classification. Output is copied to `component-checks.json`.
- `content-checks.json`: 12 checks pass, including exact archives, unchanged supporting files and runtime, two source excerpts, book/spine/live primary agreement, retained five placements and a scoped whitespace check.
- `render-checks.json`: 8 checks pass using the encyclopedia's installed ReactMarkdown and remark-gfm. Both code blocks and all four footnotes render with valid links and backlinks.

These checks do not establish the accessibility or comfort of the whole portal corridor. The existing twenty origins span 85.5 metres and the probe reports approximately 87.1 metres of live depth. Full-route approach, distant legibility and headset comfort remain to be reviewed. Runtime logs are retained; a component probe is not a claim of a clean whole-project boot.

[Read final.md in the book](http://localhost:3003/book?map=Primitives_Portals&section=final).
