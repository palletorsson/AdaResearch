# Obstacle Gallery Part 2 — Summary

The fourth Soft Bodies map expands the obstacle catalog to twelve scenarios, each isolating a different collision edge case. The softbody_gallery_part2 artifact arranges pairings across a 20x30 arena: narrow gap compression, sharp edge contact, curved surface wrapping, soft-on-soft collision, drop impacts at varying heights, constrained L-shaped passages, rounded vs sharp geometry, mass ratio asymmetry, stiffness mismatch, friction variation, rotational velocity contact, and under-constrained bodies.

Each scenario tests one variable while holding the soft body system constant. Narrow gaps reveal the relationship between stiffness and navigability — stiffer bodies need wider openings. Sharp edges concentrate contact force into few vertices, testing propagation speed through the spring network. Soft-on-soft collision eliminates the rigid reference, requiring mass-weighted correction where both bodies deform. Rounded geometry produces smoother collision normals and more stable contact than sharp edges.

The gallery format treats soft body simulation as empirical investigation. The equations are known, but emergent behavior from hundreds of interacting constraints exceeds hand-computable prediction. The pick_up_cube and grab_long_stick artifacts provide interactive perturbation — the learner can introduce their own variables into each scenario.

Through Ahmed, the gallery maps the unevenness of orientation: the same body succeeds or fails depending on the geometry it encounters, and the narrow gap reveals that passage through constrained spaces costs the body its shape. Through Merleau-Ponty, the empirical stance of observe-don't-predict aligns with phenomenological method — the body learns what it can do by doing it.

**Artifacts:** softbody_gallery_part2 (twelve collision scenarios), grab_long_stick, pick_up_cube (interactive tools).
**Sequence position:** 4 of 9 in Soft Bodies (integration phase). Follows SoftBodies_Obsticals, leads to SoftBodies_Cloth_Physics.
