# Soft Body Deformation — Summary

The first map in the Soft Bodies sequence introduces the spring-mass system: a cube whose eight vertices are particles connected by twenty-eight springs (structural, shear, and bend). Dropped from elevated platforms in a bouncy room, the jelly cube deforms on impact — flattening, oscillating, recovering — demonstrating that form is a dynamic equilibrium between internal constraints and external forces.

The technical substrate is Verlet integration, which stores velocity implicitly as the difference between current and previous position, providing energy-stable simulation without explicit velocity variables. Hooke's law governs each spring (F = -kx), with three spring types at different geometric scales: structural springs resist edge stretching, shear springs prevent angular collapse, bend springs maintain volumetric integrity. Constraint satisfaction through Jakobsen-style iterative relaxation corrects any drift after integration, and per-vertex collision against rigid platforms completes the pipeline.

The softmill artifact adds continuous mechanical force — a rotating arm that pushes through the cube, displacing mass points and revealing how the spring topology distributes localized pressure into global deformation. The cube wraps around the obstacle rather than shattering, demonstrating the cooperative behavior of the three spring types.

Critically, the rest lengths stored in each spring encode the cube's memory — its original shape. Deformation is deviation from that memory. Recovery is the springs asserting what the body was before the world intervened. The stiffness parameter k governs the strength of this memory: high k means rigid insistence on form, low k means dissolution, moderate k means negotiation. Through Ahmed's orientation theory, the rest shape is a norm the body was given, and through Merleau-Ponty's flesh, deformation is the body's way of perceiving the forces that act upon it. The QFEP integration phase positions this at lambda = 0.5 — halfway between rigid order and fluid disorder, where interesting material behavior lives.

**Artifacts:** jelly_cube (spring-mass deformation), softmill (continuous mechanical force).
**Sequence position:** 1 of 9 in Soft Bodies (integration phase). Leads to SoftBodies_Carusell.
