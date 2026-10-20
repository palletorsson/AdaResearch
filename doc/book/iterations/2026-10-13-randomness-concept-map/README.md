# What can return?

A standalone Godot concept map and an illustration of the Random Definition encounter.

Open **index.html** to compare the proposed atmosphere with the executable diagram. In the existing AdaResearch Godot project, open **concept_map.tscn** and press F6. The desktop buttons switch between two saved example seeds and rebuild the grids.

## The room's argument

A physical event is measured, those measurements are encoded and hashed, and a small integer is kept. That integer starts a deterministic generator. Repeat the same generator, seed, parameters and requests, assigned to the same cells, and the picture returns.

This separates three questions: where variation enters, what the program permits to vary, and what it takes to repeat the result. It does not settle whether true randomness exists.

The diagram has two source paths:

- **Movement → measurements → SHA-256 → bounded seed.** The demonstrated seed 880 comes from the existing synthetic movement test fixture. The full hash is not retained as the seed: the implementation takes 32 bits and reduces them modulo 1000. Different measurements can therefore produce the same seed.
- **Saved atmospheric number 435 → generator seed.** This is an alternative input from the existing archived RANDOM.ORG response, not something added to 880 and not a live network request in this concept scene.

A teal path returns to the seed for replay. A rose branch keeps that seed but discards one generated value before making the picture. Each 4×4 picture uses 48 floating-point requests for its RGB components; the changed branch makes 49 total requests including the discarded one. “+1 DRAW” does not mean “seed + 1.”

## What the spatial model preserves and hides

The arrows show dependency and request order. Their lengths, heights and colours do not measure entropy or time. The two matching grids make repeatability visible; the third exposes the role of request order. The fixed cells, colour channels and seed range remain decisions made by the author.

The pose traces are measurements, not an entropy meter. Hashing is deterministic and cannot add entropy. The illustration's traces and palettes are expressive drawings; exact values live in the executable model. This small seed range is an educational choice, not a security mechanism.

The scene reuses PointBody and the museum exhibit stage. It is an editable explanatory model with desktop controls, not a replacement for the installed hall or a new VR playtest. See the preceding [museum implementation](../2026-10-13-movement-becomes-a-seed/index.html).

## Validation and assets

The scene rendered successfully in Godot 4.6 using the compatibility renderer. Seven focused checks passed; see [concept-checks.json](concept-checks.json). These cover the synthetic fixture's hash, reproducible colour generation, the skipped request, cell count, the seed range, replay and the alternative source. No headset test was performed for this study.

- [Godot capture](godot-concept-map.png)
- [Illustration](illustration.png)
- [Exact image prompts and provenance](IMAGE-PROMPTS.md)

