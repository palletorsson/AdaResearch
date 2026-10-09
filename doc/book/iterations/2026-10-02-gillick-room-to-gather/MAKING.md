# One collection, two decisions

The supplied scene contains twelve panels. Each keeps its array index, its frame and its collider. The room, camera positions, benches and lights are supplied too. Start with a running scene, as established in Day Zero.

## What this returns to

Coordinates locate a panel. Rotation turns its local plane. An array keeps twelve identities available. A colour assignment groups those identities without changing their positions. Colour → **Color_Walls** is the proposed home for this return, after the earlier array and transformation lessons. It introduces no new foundational capability node.

The encounter is about the place these decisions leave for someone. The first making task is deliberately smaller: change one known property while keeping the rest inspectable.

## Change the colour rule first

In `colour_assembly.gd`, `colour_for(index, rule)` chooses from four colours. The two relevant expressions are:

```gdscript
var palette_index := index % PALETTE.size()
```

and:

```gdscript
palette_index = floori(index / 3.0)
```

For twelve indices and four colours, the first produces `0 1 2 3 0 1 2 3 0 1 2 3`. The second produces `0 0 0 1 1 1 2 2 2 3 3 3`. The groups follow array order; they need not form spatial stripes in every arrangement.

As a first edit, shift the alternating rule by one:

```gdscript
var palette_index := (index + 1) % PALETTE.size()
```

Keep the camera and arrangement fixed. Predict which frame will become pink, then run the scene. No position, collision shape or panel count has changed. Carry the same edit into another arrangement: does a group still look like a group?

## Then move one known panel

At the end of `panel_transform()`, immediately before its `return`, add:

```gdscript
if layout == 1 and index == 10:
	origin.x += 0.7
```

This is an optional second exercise. It moves the front middle screen to the right in the Screens arrangement. Its material and identity stay attached. Compare the route beside it with the view through it, then undo the two lines. Move to the edge before changing arrangements.

## The seam in the real implementation

These are excerpts from the working component, with bookkeeping omitted:

```gdscript
panels[i].transform = panel_transform(i, arrangement)
```

```gdscript
materials[i].albedo_color = colour_for(i, colour_rule)
```

One assignment changes a transform; the other changes a material. Neither recreates the panel. The room is their joint consequence. The supplied desktop controls make these two operations independently available; they do not teach interface construction or an XR grab system here.

The panes use two-sided alpha compositing and a separate solid collision shape. Seeing through a surface does not imply walking through it. Alpha blending is not a spectral model of coloured glass: the transparent sheets do not cast coloured transmitted shadows. The metal frames cast ordinary shadows.

## Run and inspect

[Download the small Godot project](colour-assembly-study.zip), import its `project.godot` in Godot 4.6, then run. Choose Canopy, Screens or Gathering, and separately choose Alternating, Groups of three or One colour. Walk uses WASD and the mouse; Escape releases the pointer. Overview and At the edge restore fixed views; Reset restores the initial comparison.

Source scene in Ada: `res://commons/artifacts/colour_assembly/study.tscn`. The reusable component is `colour_assembly.tscn` in the same directory. The download includes the actual four scene/script files, without the museum's other dependencies.

The three arrangements are authored possibilities. Naming one Gathering does not establish that it produces conversation, equal access or collective control. That judgement belongs to people occupying and changing the space.
