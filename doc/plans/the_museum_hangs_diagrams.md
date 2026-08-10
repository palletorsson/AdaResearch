# The museum hangs diagrams and judges them as paintings

> Measured 2026-08-10, while the plinth/prop/gallery pass was running. Not a
> rendering finding — a finding about what the collection *is*.

## The number

Of the 646 spine artifacts whose code resolves:

```
DIAGRAM-LIKE  445  (69%)   Label3D, ImmediateMesh line primitives, wireframe,
                           SHADING_MODE_UNSHADED, no_depth_test
solid object  201  (31%)
unresolved    153
```

**Sixty-nine percent of the curriculum draws itself with labels, lines and
unshaded marks.** `CoordinateSystem3M`, `origin`, `you_are_here`,
`frame_counter_display`, `dgrid`, `player_trace`, `grabbable_line`.

## Why this matters more than any texture

Three separate critics, across three rounds, independently reported "debug
chrome in the shipping frame" and each named specific offenders:

- *"an RGB tri-arrow with literal X and Y glyphs and a yellow |a| = … readout,
  sitting on the floor with no plinth"*
- *"a tan box outlined in unlit magenta with the triangulation diagonal drawn
  across the face — the universal signature of a debug draw"*
- *"a hard-edged near-white dome … reads as a light gizmo, not illumination"*

Every one of those was a **correctly functioning curriculum artifact**. The dome
was `origin` — an emissive octahedron whose subject *is* the point (0,0,0). The
tri-arrow is a coordinate system doing exactly what a coordinate system must do.
The magenta wireframe is a mesh showing its own triangulation, in a chapter
about meshes.

The critics were not wrong about the *frame*. They were wrong about the *cause*,
and they were wrong in the same direction every time, because a diagram
photographed as architecture reads as an unfinished asset. This is the project's
recurring disease at its largest scale so far: an instrument reporting a fact
about one thing as a fact about another.

## The consequence for "AAA"

A AAA interior is made of objects that have been *observed* — scanned, worn,
lit, and above all *mute*. A teaching diagram is the opposite: it is authored to
be **read**, and reading requires labels, unshaded lines that ignore depth, and
colour that means rather than describes. Those are not deficiencies to be
polished out. They are the artifact's argument.

So the honest position:

- **The building can reach AAA.** Walls, floors, trim, light, plinths, props,
  density — all of that is architecture, and all of it is procedurally reachable
  (see [museum_render_ceiling.md](museum_render_ceiling.md)).
- **The collection cannot, and should not.** Making `CoordinateSystem3M` look
  like a photoscanned prop would destroy the thing it exists to say. You cannot
  photoreal a diagram; you can only stop it from being one.
- The 31% that ARE solid objects — the machines, benches, cabinets, specimens —
  can and should carry the AAA read, and they are what a store-page frame should
  be composed around.

## What to do about it, in order

1. **Stop treating diagram-ness as a defect.** Critics must be told the
   collection is 69% diagram, or they will keep filing the same false bug and a
   fix pass will keep dimming real lights to chase it (this already happened
   once: the hero key was cut 3.8 → 2.1 to chase `origin`).
2. **Compose the frame around the 31%.** The set dealer already knows footprint
   and rank; it could also know DIAGRAM vs SOLID and put solids on the sightline
   where a screenshot lands, with diagrams in the bays.
3. **Give diagrams a housing.** A coordinate gizmo on a bare floor reads as
   debris; the same gizmo inside a vitrine, on a plinth, under its own spot
   reads as an exhibit. The plinth pass now running is exactly this move — it
   should be extended deliberately to the diagram class rather than only to the
   short class.
4. **Never gate on "does it look like CoD".** Gate on: does the building read as
   built, and does the exhibit read as *deliberately shown*. Those are
   answerable; the first is not.

## The flag this raises

`classify: diagram | solid` is a property the registry does not have and should.
It is derivable today from the code (the regex above), and once declared it lets
the dealer, the lighting rig and the critics all stop guessing.
