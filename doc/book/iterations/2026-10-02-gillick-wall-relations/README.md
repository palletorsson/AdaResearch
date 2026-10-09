# Wall relations — 2 October 2026

User asked to try some of Liam Gillick's wall works after the twelve-panel room study. Built three original native Godot responses, photographed under fixed gallery lighting. These are independent companions proposed for Color_Walls; no installed hall, sequence order or canonical final.md is revised.

## References and differences

| Reference | What the Ada study takes up | What it changes |
|---|---|---|
| Gillick's repeated rail works, including *Reached Horizon* (2017), listed by [Kerlin Gallery](https://www.kerlingallery.com/artists/liam-gillick) | Spacing, serial colour, wall visible between elements | Our study uses 24 vertical bars and a six-colour RGB palette. It does not reproduce the original's 30 horizontal elements, dimensions or colour specification. |
| *Extended Complex* (2022), documented in [Kerlin's ART SG presentation](https://www.kerlingallery.com/fairs/art-sg); the wall-complex family also appears in [Casey Kaplan's artist archive](https://caseykaplangallery.com/artists/liam-gillick/) | Intersecting coloured members and a composition that projects from the wall | Our six-by-six crossing is enlarged and has an authored depth control. The gap opens kinematically; there is no claim to reconstruct fasteners or physical load. |
| *Fact Structures Amount Structures Language Structures* (2024), [Casey Kaplan exhibition and primary text](https://caseykaplangallery.com/?exhibitions=liam-gillick-3) | Open-ended linear configurations and aluminium extrusion as an industrial component | Our twelve-segment composition and missing-rail operation are invented. The face groove is a simplified cue, not an accurate T-slot profile. Original titles, prototype book-jacket prints and production histories are not replaced by this exercise. |

These are source-grounded operation studies rather than measured reconstructions. Palette, enlargement, geometry and interactive rules are Ada's. The references' material and institutional histories cannot be inferred from the Godot primitive alone. The 2024 gallery text makes production and representation central; a tidy assembly should not be taken as evidence that its social process is equally legible.

## Implementation

`commons/artifacts/colour_wall_studies/` contains the component and viewer. Forty-eight persistent bar nodes in all: 24 intervals, 12 crossing members, 12 open-line segments. Each has a solid collider. Colour materials are assigned independently of geometry. Omitting a segment also removes its collision, without deleting its identity. Reset restores the original values and camera.

The companion viewer extends `colour_assembly/study.gd` to reuse its desktop movement. The existing panel-study files are unchanged. The wall viewer refuses geometry changes while the visitor is within the approach strip beside the wall. Its furniture, room, lamps and camera positions are fixed across comparison states. The studies do not simulate material weight, joint strength or productive networks.

## Evidence and reproduction

Run `python tools/capture_colour_wall_studies.py`. It creates a private minimal project, imports it using Godot 4.6, renders twelve native 1800 × 1200 images and packages `wall-relations-study.zip`. Production source hashes and reports accompany the images. No existing game session or runtime control file is touched.

Nineteen behaviour checks and twelve image saves pass: persistent identity, spacing and centring, depth changes preserving X/Y, geometry/colour independence, omission/restoration including collision, camera selection, proximity guard and reset. These exercise actual button signals and physics rays; they are not physical-keyboard, headset or full walking-route trials. The gallery uses Compatibility/OpenGL and standard raster shadow maps. The first image inspection revealed shadow acne; corrected light bias and lower lamp energy removed that artefact before the published capture.

Run this folder's `build.py` to regenerate the page from READING.md and MAKING.md. The page's switches compare fixed-camera native captures using CSS; the downloadable project supplies the live scene. Supporting sources: [verification](figures/verification.json), [provenance](figures/provenance.json). Browser automation was unavailable in the preceding companion pass because its helper failed; publication validation here uses local-link, hash, archive and HTTP checks, with no rendered-browser claim.


## Museum placement, 2 October 2026

The study now has an installed museum adapter and an application passage in the book. See the [current spine integration](../2026-10-02-studies-in-the-spine/index.html). This page preserves the earlier companion evidence.
