# isosurfaces — the 24 Sept book tasks applied, 25 September 2026

Tasks `book_isosurfaces.001`–`.014`: thirteen applied and closed, one left open with a note. Walking the spine from its far end (forum 260925-tvljg). A prose-only pass: no map, scene or code was changed.

| task | hall | what landed |
|---|---|---|
| .001 | ISO_PortalLandscape | opens on the continuity (the amber field from the last hall, alone, with a bay for a held copy); the duplicated glsl block cut and its lines spent on what the second pass shows (the ladder entire, the held rung beside the live one) |
| .002 | ISO_Metaballs | the prose option: the rear body is the same raymarched scene at full size, twelve metres; not a sum; "what the small copy let you walk round, this one lets you stand under". The map option (`metaballs:0:2:0.2`) is noted on the task for Palle |
| .003 | ISO_CaveGeneration | "The striped tunnel beside it is a drawn stand-in, not an extraction" (marchingcubes.tscn, use_fallback = true) |
| .004 | ISO_ImplicitModeling | passed three times already; the smoothing constant 2.6 here against 0.4 in the earlier copies (`#fusion:necked`, FUSION_K); compare with the raymarched copy in the metaball hall |
| .006 | ISO_LookupTable | `<!-- @the_threshold_opinion -->` and a passage written from the work's identity header and code: one field as a lattice of rods, five surfaces at five thresholds, the 4 / 8 / 14 lattice row (the code's numbers; the header says 16), the brass rack, the pair caught mid-merge; tied to MARGIN (values moved, cut held; here cut moved, values shown) |
| .007 | ISO_Caves | "A second portal landscape, not the one you left: that field had no rings; this one writes seven torus fields into the ground..." |
| .008 | ISO_Sculpting | "In VR," dropped |
| .009 | ISO_Sculpting | the repair history replaced with the sign lesson |
| .010 | four halls | the four "A useful extension would" closings rewritten as something the reader can do in the hall, the instrument kept to one clause: CaveGeneration (which of the three changed settings, 13.5/3.8, 0.85/0.88, 300/280, would you move first), AnimatedNoise (which corner crossed), ImplicitModeling (a hand where the join looks solid), RhizomeBody (draw the graph you walked, narrow one passage) |
| .011 | ISO_Caves | "The terrain desk's column could count several crossings; a count was never a body" |
| .012 | ISO_Metaballs | nakama never extracts a surface; one sphere pushed in and out; no neck can pinch off |
| .013 | ISO_LookupTable | the handover sentence untangled |
| .014 | ISO_Metaballs | the pseudo-code replaced with metaballgenerator.gd:485 and :563, with one sentence reading them |

Left open:

- .005 (ISO_Caves): whether a 1.8 m body can enter the enclosing cave at token scale 0.02 needs a headset walk; the enclosure paragraph stands until then.

Verification: every replacement matched exactly once; footnotes defined; fences balanced; endings preserved per file (Metaballs, Caves, Sculpting CRLF; the rest LF). ISO_Metaballs as found had one bare LF line inside a CRLF file (it arrived with the 20 September hunk); the file is normalised to CRLF throughout, which changes no character git stores.

Disclosure: chapters that carried uncommitted hunks from another writer (20 September) and land here whole: ISO_PortalLandscape (19 lines), ISO_Metaballs (2 lines). `before/` is the tree as found, so the diffs beside it are this pass alone.
