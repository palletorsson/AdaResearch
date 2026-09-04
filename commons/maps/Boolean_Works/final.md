The room gets taller here, and the things in it stop being demonstrations. A workbench, a catalogue rack, a wall with a door cut through it, a five-metre block of rock with a tunnel bored out of the middle. These are the boolean operations at the size where they would have to be architecture, and the question this hall asks is the one the small rooms could not: when the negative gets big enough to stand in, can you stand in it?

You cannot. Not in any of them. That answer took eight bodies to arrive at, and it is the most useful thing in the chapter.

## The bench you cannot reach

<!-- @csg_compose_workbench -->

```gdscript
# csg_compose_workbench.gd:9 — the promise, in the file's own header
# stand at the bench, see all three operators side by side, pick one with the bracelet,
```

Three solids turning slowly above a table, each labelled with the operation that made it. The file calls itself a workbench, the registry sells it with the tag `catalyst_affordance`, and the header above says you pick one up with the bracelet.

There is no picking. Three hundred and fifty-eight lines and not one input handler, no interaction volume, no signal, no mention of the bracelet outside comments. The only thing that happens at runtime is that the presets rotate. And the geometry has already given it away before you try: the bench top is at 0.56 metres and the work is placed at 1.1, so the objects float just over half a metre above the surface they are supposedly on, out of reach, turning. The file half-admits it in a line called `needs` — *Missing: a live player-built composition surface beside the three fixed presets.*

Its dial is the interesting part. `algebra` has four settings, and one of them, `complete`, builds symmetric difference out of two nested combiners and labels it longhand as `(A ∪ B) − (A ∩ B)` — the artifact's own argument that XOR is derived rather than primitive, which is a real and good point about what an algebra holds versus what a tool exposes. The default is `triad`. Eleven placements exist in this museum and not one of them passes a config value. So XOR is in the repository and has never once been in the building.

## The two stations that were supposed to be identical

<!-- @subtraction_suite -->

```gdscript
# subtraction_suite.gd:254 — the one line that breaks the claim
art_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
```

One cube with a sphere taken out of it, built twice, side by side: once dressed as an art object and once as an instrument reading. The bench's stated result — its smallest and firmest, by its own account — is that these are the same object and *what differs between them is the furniture and the palette*.

Cull mode is neither. It is a property of the surface, and the operator's copy does not get it: that station keeps back-face culling, and at every setting past the first the void has already broken through the faces, so the mouths of the cavity are exactly where your eye goes in. One station renders its carved interior. The other deletes it at the moment you look inside. The claim that the difference is not in the object is undone by a line in the object.

Worth a count while you are here: the whole bench builds four CSG combiners and eighty-five plain meshes, sixty-eight of which are the catalogue tray beside it, which contains no boolean operation at all.

## Four of five are not booleans

<!-- @sphere_splitting_showcase -->

```gdscript
# sphere_splitting_showcase.gd:182 — the caption
_add_info_label(csg_sphere, "CSG CUTTING\nBoolean ops\nfor real cuts\n\nPieces: 1\nSplits: 0")
```

Five destructible spheres in a row with balls to throw at them, each shattering by a different algorithm. It stands in a boolean hall today for the first time, though it has been placed five times before in the forces chapter, which is where it comes from and where its registry entry still files it.

Four of the five contain no boolean operation. They are fracture algorithms — segmentation, planar cuts, physics shards — and only one of them reaches for CSG at all, which it uses for an *intersection*, baked offline, to mask a mesh. The caption above sits on that one. The room's name claims all five.

None of them is seeded, either: the cut planes are three unseeded random floats, so two placements of this token are two different objects the instant anything is thrown. It is the most honest thing in the hall about what a boolean is *for* — a tool used once, offline, to make a mesh — and it is filed as the opposite.

## The hole that was never made

<!-- @recursive_boolean_cube -->

```gdscript
# recursive_boolean_cube.gd:118 — the whole mechanism
if zeros >= 2:
    continue
```

A Menger sponge. A cube with square holes bored through it, and smaller holes in what remains, recursively. Of everything in this hall it looks the most like subtraction, and it is the hinge of the entire chapter.

It performs no boolean operation. There is no CSG node anywhere in the hundred and fifty-eight lines, no subtraction operator, nothing but boxes and materials. The holes come from the two lines above: walking the twenty-seven cells of each subdivision, if a cell is on the axial cross, the loop does not build it. Nothing is removed. A cube is declined.

The file's own comment calls this *boolean-like subtraction through recursive geometry*, and the registry, which files it under procedural generation and tags it `procedural`, never uses the word boolean at all. Both are more accurate than the room it now stands in.

And it is the only body here that is fully reproducible — no random number in the file, two placements byte-identical — which is a small joke at the chapter's expense: the artifact that does not do the thing is the one that does it the same way twice.

Take the mechanism seriously and it reframes everything upstream. A boundary model has no interior, so nothing in it can be removed; what looks like removal is always a redrawing of the skin. This artifact skips even that. It gets the appearance of a hole by never putting anything there and then narrating the absence as a cut. Which is not a lesser version of what the verbs do. It is the same thing with the arithmetic taken out.

## Equals room

<!-- @csg_architecture_cavity -->

```gdscript
# csg_architecture_cavity.gd:20 and :52 — thirty-two lines apart
# truth: Every architectural cavity is a difference. A room is a wall that has been subtracted from.
...
#   operator and never delivers the truth line: a wall has no interior.
```

A wall, three and a half metres of it, with a door and an opening and a bitten arch cut through. Floating above it in large text: `wall − (door + porthole + window) = room`.

It is one wall. It has been one wall at all twelve of its placements, because the setting that would add returning runs defaults to `none` and no map in the project sets it otherwise. The two lines above are both in the file, thirty-two apart, and the second one is right: a wall has no interior. One difference makes a hole, not an inside. You read the payoff from outside, which is the only place there is.

Then walk into it. You will not be stopped. There is no collision anywhere in this artifact — no static body, no shape, and the CSG root's own collision flag is never set. This is not something the engine could not do; a tunnel in the alternative-geometries chapter turns exactly that flag on, one line, and you can walk through it. Here the doorway and the wall are the same to your body. The one architectural distinction the object exists to make — that a cut in a solid produces somewhere you can be — is the distinction it does not implement.

Even the porthole is not a hole. Its centre is set 1.4 metres up on a wall whose half-height is 1.3, so it is a scallop bitten out of the top edge.

## Walk the hollow

<!-- @sdf_cavern_room -->

```gdscript
# sdf_cavern_room.gd:55 — the only text in the world
_billboard_label("CARVE THE FUNCTION, WALK THE HOLLOW", Vector3(0.0, 3.6, 0.0), 28, ...)
```

Five metres of rock rendered as a crust of nearly five thousand small boxes, with five spheres subtracted out of the middle of it to make a cave. It is the most beautiful object in the chapter and the sign over it is the plainest instruction in the building.

There is no collider, and this time it would not help. The block is lifted so its underside sits fifteen centimetres off the floor, and the lowest carved air anywhere inside it is 1.2 metres up — more than a metre of unbroken rock between the ground you are standing on and the bottom of the hollow. The tunnel's floor is above your head. There is a floor in this artifact, a seven-metre plate, and it belongs to the tray, not the cave; it also sways, because the whole node rocks gently on its vertical axis and takes the ground with it.

So it is a model of a cavern on a table. Which would be fine — most of this museum is models on tables — except that the verb in its own truth line is the one operation it does not implement, and it is the artifact in the entire chapter that is actually shaped like an interior. It carries no declared axis at all, while the word `interior` has been borrowed from the wall next door by three other registry entries as the term for *whether a solid encloses a void you could occupy*.

## Seventy-five things that look grabbable

<!-- @booleanvariations -->

```gdscript
# booleanvariations.gd:632 — after wrapping each solid in a VR grab cube
grab_cube.set_script(stability_script)
```

A three-by-five-by-five rack of boolean combinations, seventy-five of them, each one wrapped in the project's standard grab cube so it can be picked up. Then the line above replaces that cube's script with a fourteen-line stub, and the pickable behaviour is gone. The highlight ring is removed first, because it would throw errors against the stub. Seventy-five objects built to be handled, presented as handleable, inert.

Two more things about it that are visible if you look. It clears its own children on the first frame with an unconditional loop, and its scene file's camera and its only light are among them, so standalone it goes black. And of the twenty-five distinct variations it advertises, thirteen are marked `# Placeholder` in the source and call another variation's builder, leaving eleven.

## The degenerate case, kept

<!-- @coincident_face -->

At the back wall, the flat plate about two faces in the same plane — the failure mode, the one condition under which the whole boolean grammar has no answer. The gallery next door explains what it is and how it is drawn. It is here as well, at the end of the heavy hall, because it is the only object in the chapter that takes the position that a case where the machinery breaks is worth an exhibit rather than a bug report.

## What the physics never turned up for

An interior, in this engine, is an agreement between two systems: the renderer will not draw the surfaces facing away from you, and the physics will not let you through. Hold both and you have an inside. Drop either and you have a picture of one.

In this hall the physics never arrives. Twelve of the chapter's thirteen artifacts contain no collision construct of any kind — no static body, no shape, no collision flag set on a CSG root. The thirteenth has exactly one: a two-metre grab volume on objects scaled to a tenth of that, bolted to a script the same file throws away eleven lines later. `= room` hangs over a wall you pass through. `WALK THE HOLLOW` hangs over a metre of rock. The workbench floats half a metre above the workbench. Seventy-five objects offer themselves to your hand and are not there.

The project has already written this down, in a place nobody reads. Its own interaction probe filed both the wall and the cavern under `"verdict": "no affordance"` — zero controls, zero grabbables, zero wired. And the still camera reached the same conclusion from the other direction without anyone noticing what it had said: the sweep that grades whether a dial changes the picture rates the wall's `interior` setting at 4.372 percent of pixels for the step from one wall to a four-walled room. That step is the artifact's entire argument, the rung its own source calls *the first rung on which the player is INSIDE*, and it registers as a rounding error — because a camera standing outside a room cannot see the difference between having an inside and not having one. It sees three more slabs, edge-on.

Which is the last thing this chapter has to teach, and the most uncomfortable. The instrument that decides whether a variant is worth keeping is a photograph taken from outside. An interior is precisely the claim that cannot be photographed from outside. So the one property this whole chapter is about is the one property the apparatus is built to miss.

That is the chapter's dark spot, and it is worth being precise about which kind it is. In the small room the missing interior is generative: because a boundary model stores no inside, difference has to *invent* the cavity wall out of the outside, and that invention is the best idea in the chapter. Here the same absence has gone sterile. The claim got bigger — from *this surface is manufactured* to *this is a room* — and nothing underneath it grew to match. The negative was supposed to become inhabitable at this scale. It became a sign saying so.

Which leaves the honest version of what these three halls demonstrate, and it is not the one the labels promise. A solid is a lie told by its skin, and so is its hole. The grammar that carves has no word for *partly*, no word for *becoming*, and nothing to put inside the thing it cuts. Every absence in this chapter is performed rather than found — by inversion, by omission, by parity, by a caption. What you can walk through, you were always going to walk through.
