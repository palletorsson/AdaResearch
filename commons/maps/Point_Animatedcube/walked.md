# Point_Animatedcube — walked

> R-021, amended: the considered critical tutorial for a walked, working map.
> The ghost drafts from what the map IS; Palle rules the voice. Two trajectories
> woven: the walk (tutorial) and the turn (critical).
>
> PILOT (ruling pending): the dwell register. The walk keeps its walking tempo;
> at three stations it stops, and an inset long-take opens — distilled from the
> map's own thinking files, provenance shown. The page is paced like the map:
> walk → dwell → walk. Each dwell carries its computed reading time (P-6).

## What this map holds (seed)

A manipulable quad-based object where you can drag cube corners. This map transitions from rigid relational closure to over-stabilization and manipulation. Quads relax the rigidity of triangles and introduce interactive constraint: agency within system limits. Geometry becomes something that can be touched and perturbed without collapsing.

## Why it was built (seed)

Concept: The cube as manipulable quad-based enclosure — full volumetric closure achieved, but through flexible quads rather than rigid triangles. Drag corners to deform; agency operates within constraint.
Sequence role: Eighth map. Completes the closure arc from triangle to trihedron to full enclosure. The cube is over-determined — quads flex where triangles would not — introducing deformation as interactive possibility.
Critical angle: Enclosure as both achievement and confinement. The cube as modernist container (the white cube, the box). Stability maintained by convention, not necessity.

## The cast

animatedcubebuilder · polyhedron_nets_cube · science_screen · floating_sphere_field

## The walk

Here is the sequence's arrival: full enclosure. `animatedcubebuilder` gives you the cube — six faces, a sealed inside, the first form with an unambiguous interior. And then the map does the thing that makes it more than a trophy: it lets you **grab a corner and pull.** The cube deforms. It leans, it skews, it stretches — and it does *not* break, because it is built from quads, which flex where the triangle would have ruptured. You are handed mastery (the closed solid) and, in the same gesture, permission to perturb it. Stability you can push on.

> **Dwell — `animatedcubebuilder` · ~60s**
>
> Before you pull the corner, watch one being born. Call `BoxMesh.new()` and
> a cube simply appears — no process, no visible work. This builder refuses
> that instantaneity: vertices first, eight spheres at the corners, then
> edges, then faces, then the final sealed mesh. The cube is not atomic. It
> is assembled — and the animation makes the labor visible: faces require
> edges, edges require vertices, order matters, construction takes time even
> when that time is usually microseconds. Look closer and the parts do not
> even know the whole: the function that draws an edge knows only two points;
> that a cube has twelve edges is a separate fact, held in a list — topology
> and geometry distinct even where they seem merged. Four builders run in
> parallel around you, synchronized, and the repetition is the point: this is
> a protocol, not an event. The geometry emerges from time, not from a stored
> description; eight Vector3 values are the only thing the cube is —
> everything else is how it appears. Against the mystification that
> computational objects are just there, the builder is critical pedagogy in
> the plainest sense: nothing simply exists; everything is constructed. So
> the question the cube leaves standing: who controls the procedures, and
> what forms do they never build?
>
> *distilled from critical.md · technical.md*

`polyhedron_nets_cube` opens the other door onto the same object: the cube *unfolded* — the flat cross of six squares, the 2D net that folds up into the 3D box. Fold it and unfold it and you see the enclosure was always a pattern in disguise, a plane that agreed to close. Between the deformable solid and the unfoldable net, the map teaches the cube twice: as the achievement of an inside, and as a convention you can take apart with your hands.

> **Dwell — `polyhedron_nets_cube` · ~60s**
>
> Lay the cube flat and it stops being a container. The net is a cross of six
> squares — the cube's entire surface with its volume subtracted, topology
> preserved, spatial relations deferred. Everything the box will be is
> already here, and none of it encloses. The folding is driven by a single
> number: `fold_progress`, zero to one. At zero, a flat pattern; at one, a
> sealed cube; and every hinge — one node per folding edge, the code
> mirroring the cardboard — reads that one float and rotates. Even the
> physical constraint that the back face cannot close until the right arm has
> swung up survives only as arithmetic, a remapped range that delays one
> hinge. Physics becomes a number line. Watch the moment the last face
> closes, because a threshold crosses there that no earlier primitive had: an
> inside comes into existence. A point has position, a line has length, a
> triangle has area — the cube has an interior you can be in or be shut out
> of. And with it, the harder facts: the closed volume blocks passage, blocks
> sight, takes space nothing else can occupy. Enclosure is the spatial logic
> of possession. The net is the honest diagram of that power — unfolded, it
> is only a pattern; the politics arrive exactly at `fold_progress` one.
>
> *distilled from technical.md · critical.md*

## The turn (critical)

The cube is where **enclosure reveals itself as both achievement and confinement**, and the map is careful to give you the second reading with the first. The sealed interior is the sequence's goal — an inside, at last, distinct from an outside — and it is also the box, the cell, the container, the white cube of the gallery that presents itself as neutral and is nothing of the kind. Modernism made the box its emblem of purity and universality; this map lets you grab that emblem's corner and watch its "necessary" stability turn out to be a *convention* — held up not by geometric law but by the quiet agreement not to push. Drag the corner and the neutral container admits it was a choice all along.

That is the map's gift to the book's argument: it undoes the innocence of the container at the exact moment it delivers one. You wanted an inside; here it is; and the first thing the map teaches you to do with it is deform it, so that you never mistake "enclosed" for "fixed" or "given." Which is precisely why the next map, `Primitives_Ignorance`, can afford to detonate the whole confidence you've built — because this map already slipped a crack into the keystone. The cube looks like the sequence's mastery. It is also the sequence's first admission that mastery is maintained, not owned.

## Room for improvement

*(Palle: the corner-drag "stability is convention" beat is the load-bearing one.
Note whether deforming the cube reads as unsettling the container or just as physics.)*
