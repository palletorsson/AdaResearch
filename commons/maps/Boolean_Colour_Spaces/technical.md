# Construction and evidence

Artifact: commons/artifacts/boolean_colour_chamber/boolean_colour_chamber.tscn.
Standalone desktop: commons/artifacts/boolean_colour_chamber/study.tscn (F6).

Configuration: #mode:path|lens|shell and #surface:0|1|2|3. Explicit height 0 prevents automatic grounding from lifting the deliberate floor-top origin. The artifact supplies CSG collision and a level StaticBody floor. Local origin y=0 is the finished walking surface; the floor body extends below it.

Path: box minus union of seven radius-3.35 spheres, with two raised cuts. Lens: box minus intersection of two radius-4.7 spheres, with cylindrical entry/exit cuts and a light well. Shell: union of two radius-4.9 spheres minus two inner spheres, doorway cylinders, five pores and a bottom trim.

Materials use procedural position fields, view-dependent colour and metallic/roughness changes. No vertex displacement, screen-space refraction or real thin-film optics is claimed. Drift is opt-in and stops advancing the local clock when held. Selecting finishes also adjusts the local light colours. CHALK is a less reflective comparison, not a claim of neutral vision.

Native images and bounded isolated collision/pointer tests: doc/book/iterations/2026-09-24-boolean-colour-spaces/. The standalone probe's capsule is 1.8 m tall and 0.30 m radius. This is not a headset, Quest performance or end-to-end museum-loader test. Scene presets are static; controls do not rebuild geometry around a visitor.
