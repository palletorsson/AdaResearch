# Primitives_Ignorance — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The ruling (Palle, 2026-09-02)

Three movements in one room. The Platonic primitives. Then "the space of
primitives in different resolutions, that says resolution can produce form: a
lower-res sphere is a prism." Then, more important, symmetry: "how an odd number
of segments breaks visual symmetry and makes the back side harder to derive.
This is how the 3D pill that only has five segments is an anti-Platonic
primitive, because it is not symmetrical. This is queerly important. The
artifact is just called `capsule`."

The instruments are already in the room: `platonic_grabbables`, `sphere_low`,
`sphere_mid`, `sphere_high`, `capsule`. `capsule_radials_rings` exists in the
registry with the segment count as its knob and is the right station for the
odd/even argument.

## The exact form of the capsule claim

Say it without "queer" doing all the work; the room should be able to state it
so that it can be checked.

An even number of radial segments gives a cross-section with **central
symmetry**: rotate it 180° and it lands on itself, so the far side is the near
side turned round, and you can derive the back from the front. **An odd number
has no centre of symmetry.** A pentagon with a vertex facing you has an edge
facing away; the silhouette from behind is not the silhouette from the front.
The back is genuinely unknown from here, which is the room's name.

The Platonic solids are the ideal *because* every face and vertex is
equivalent. The five-segment capsule is a body the machine's own limit made
unequal to itself, shipping in the same primitive menu as the ideals, under the
plainest name in it. The irreducible one, in the standard set. That is the
thesis's sense of queer (see `doc/CONSERVATION_OF_THE_IRREDUCIBLE.md`), and
here it is a fact about a mesh.

One more, offered not pressed: the tetrahedron is the only Platonic solid
without a centre of symmetry. The odd one was in the ideal set from the start.

## Resolution produces form

`SphereMesh` at low `radial_segments` is a polyhedron; a cylinder at low
segments is a prism. The same call, a different integer, a different solid.
Form is a parameter of resolution, and the three spheres on their plinths are
that sentence as objects. This connects back to Point_Trace's lattice and
forward to Portals' circle that is never reached.

## Written (2026-09-02)

- **The plain `capsule` IS the five-segment pill.** Its authored mesh is
  5 radial segments, 5 rings, radius 0.25, height 1.0, spinning at 45°/s; the
  `facture` axis makes the bands pointable. Palle's "this artifact is just
  called capsule" was literal. No second capsule was placed.
- **The five are derived, not listed.** `regular_corner_defect` +
  `platonic_candidates` in the tutorial: regular faces, same count per corner,
  positive defect → exactly (3,3) (3,4) (3,5) (4,3) (5,3), and 720/defect gives
  4, 6, 12, 8, 20 vertices. This completes the corner room's Descartes law.
  Proven by `probe_ignorance_tutorial.gd`.
- **Resolution as form, exactly.** `prism_from_segments`: a round body at n
  segments is a prism (n+2 faces, 2n vertices, 3n edges), Euler holds. The
  ladder is 32 → 16 → 8 walking south; the text says 8 is "a different solid
  with eight-fold symmetry and no name in the menu," not "a rougher sphere."
- **The symmetry claim uses `rotated()`**, not `cos`/`sin`, so no trig is
  named in primitives; the method hides it the way `length()` hides Pythagoras.
- **The tutorial's encapsulation register was kept** and given the closing
  section: a primitive is the most enclosed thing, "an interface that shows you
  a sphere and keeps thirty-two integers behind it."
- **Curriculum honesty:** `roughrock` is noise-perturbed, and noise is not
  taught before sequence 8. The text calls it "corners pushed off their ideal
  places" and does not teach the noise.

## The tutorial that is currently in Polythedra

The five-solids enumeration (`face_count`, `interior_angle_sum`, `euler_check`,
`solid_volume`) belongs to this room's first movement and should move here
when Polythedra's tutorial is rewritten around the corner.
