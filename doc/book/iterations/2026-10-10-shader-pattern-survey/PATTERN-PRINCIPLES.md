# The pattern families missed by the map survey

10 October 2026. Gallery expansion only. Museum code and lesson texts unchanged.

The original survey followed shader and pattern map names. That missed implementations in the shader library, the tile editor, Pattern Atlas and Mamma Mönster. The visual shelf now has 76 cards; the original 44 numbers are retained.

## Added views

| Family | Views | What the code actually offers |
| --- | ---: | --- |
| Tartan | 3 | Band crossings, a smaller threshold-based pattern, and the existing crate installation |
| Tile editor | 4 | Arithmetic twill, a stored 4×4 houndstooth motif, offset rows, alternating coordinate transposition |
| Pattern Atlas | 19 | Individual existing plates: nested rules, displaced rows, radial motifs, stitch bits, shared edges and optical distortion |
| Mamma Mönster | 6 | Existing studies of winding lines, reflected feathers, turned beans, colour bands, competing checks and combined fields |

Each added view was rendered in Godot. Atlas and Mamma Mönster plates are isolated from their existing scenes with their labels retained. The pinktartan and tartan_pattern library shaders are shown on plain review quads. Tile-editor specimens use existing properties; they do not change installed hall settings.

## Useful teaching choices

- **Tiling:** compare twill's short arithmetic rule with the stored houndstooth source. Hold that source fixed while changing the repetition. Return to the physical thread loom for crossings.
- **Tiling → Shaders:** pinktartan represents a crossing through colour masks and a fine checker. This makes a precise comparison with actual thread geometry possible.
- **Shaders:** bend the same sampling coordinates before evaluating a stripe or checker. The Riley and Vasarely studies make that difference visible on unchanged planes.
- **A small rule across a field:** the hitomezashi study assigns one bit per row and column, then alternates dashes. The resulting paths are a particularly clear candidate for a controlled small-grid comparison.
- **Reflective lineage:** retain the named makers and the personal Mamma Mönster connection. These shader approximations do not replace the material practices or original works they refer to.

These are selection candidates, not new compulsory halls.

## Exactness checks

The older tartan-gallery images use an inline substitute shader in `commons/testing/render_tartan_specimen.gd`, despite the builder referring to the production shader. They are not used as evidence of the current crate material. The current crate capture is washed out and is labelled accordingly; its colour clamp and brightness controls need a separate repair decision.

The tile editor's mode called HERRINGBONE swaps x and y on alternate square tiles. It does not build an interlocking rectangular floor. The Wang plate hashes shared edge addresses directly; it is not a constraint solver or proof of aperiodicity. Moders Dröm combines procedural fields; it does not execute an image-generation model.

The cultural and artist names are the existing project's references. Captions describe source operations, not independently verified historical claims or authentic reconstructions.

## Verification

32 new images saved successfully. All 85 generated gallery pages checked: 1,552 local links resolve, 99 HTTP checks pass. The 35 sampled source files match their pre-capture hashes. See `gallery-principles-validation.json` for the scope. No headset interaction testing was performed.
