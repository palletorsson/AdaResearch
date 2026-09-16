# Melencolia: the geometric court before Dürer

16 September 2026. Room and book revision, with actual endless-museum rendering.

The entry booth is removed so the historical composition is encountered first: four corner pyramids, a taller centre and four half-metre cubes in a cross. The first 5 × 5 metre deck sits one metre above the museum floor. A raised connection and wedge reach the separate Dürer deck, two metres above the floor. The restored second frame forms the historical pair. The puzzle stands beside the opening court so its preview does not obscure the first view. All eleven original artifact types remain: eighteen placements, including the added second frame.

The 13 × 23 metre source map retains clear floor around both stages. The grid teleporter has a landing row behind it and an explicit museum floor override at its own cell. The source and both cached museum plans agree on the revised hall. Only this hall's role, manifest and plan entries changed; other rooms compare equal to the archived inputs.

`final.md` now asks **What keeps you looking after you know the form?** Its sequence is the corner pyramids → central spire → cube composition → the connection puzzle → Dürer's tools and magic square. All five tagged artifact families are primary in the necklace API. The supporting works remain present without each becoming a separate book lesson. The tutorial uses actual source rather than its former incomplete truncated-solid example. The earlier critical essay remains, with a note distinguishing its provocations from the current reading.

## References and fidelity

- Historical floor arrangement: commit `86d423341`, saved as `historical-map-86d423341.json`. The newer room had already recovered its platforms but placed a booth before them.
- [Selected image](https://pdimagearchive.org/images/4577a16c-d0e9-43d6-96fc-f125c47c6afe/): the individual archive page returned HTTP 403/cache miss, so direct image matching was not possible. The restoration follows the known source map; it is not claimed as an exact visual reconstruction of that inaccessible image.
- [Solid Objects](https://publicdomainreview.org/collection/solid-objects/): readable collection page, identifying an anonymous sixteenth-century manuscript at the Herzog August Bibliothek. Further compound solids remain references; this pass did not fabricate unverified copies or attribute them to Dürer.
- Dürer, Plato and Kant references appear as four working book footnotes. The reading of aesthetic attention sustaining investigation is explicitly the book's proposal.

## Verification

- 110 actual-museum checks passed: fifty deck cells checked against derived heights and physical collision, all eighteen artifacts stamped, both historical frames present, and both ramps rising toward their destination decks.
- The wedges are two metres long. Their measured near-end heights are 0.025–0.975 m and 1.025–1.975 m respectively.
- 26 content/API/access checks passed. Reachability starts at the explicitly authored entrance (row 1, column 6), not the pathfinder's centroid fallback for an `sp` utility. Every placement and the exit is reachable; no grid construction warnings remain.
- ReactMarkdown/remark-gfm rendered all four footnotes and backlinks and both code blocks. Live book and necklace APIs served the revised sources.
- `git diff --check` passed for edited content. Godot exited 0. Its log still includes existing shader-cache write warnings, older material-property warnings and exit resource warnings; no GDScript parse failure was observed.
- Screenshots are from the actual endless museum, not a reconstructed showcase: `court-entrance.png`, `court-and-tableau.png`, `durer-approach.png`.
- Headset interaction and comfort remain untested.

Exact pre-edit files are under `before/`. No commit was made in this pass.
