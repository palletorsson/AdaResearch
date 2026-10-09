Twenty-four objects in six rows across a wide room, and eighteen of them are things this museum has never shown.

Every artifact in the boolean chapter is a family. Each one declares an axis — a named dial with four settings — and every placement anywhere else in the building shows you exactly one of those settings, the one it shipped with. This hall is the only place the other three stand up. One artifact per band, its four values laid across the room, two on your left and two on your right with the walking lane between them, so you meet the family two at a time and have to cross the floor to finish the sentence.

The six you have already met are here too, one per band, and in five of the six they are the first thing you come to on the left. That is a convention rather than an accident: the registry lists a family's values with the default first, and this hall was laid out from the registry. So each row starts with the object as you know it and then shows you what else it was willing to be.

## A variant is a claim somebody published

The four settings are not in the object. They are in a file. Each artifact's code holds a list of the values it will accept, and the registry — `commons/artifacts/registry/boolean_surfaces.json` and its neighbours — holds a second list, which is what every tool in this project reads: the catalogue builder, the sweep, the deck, the audit. The object obeys the first list. The museum, the gallery pages and this room are built from the second.

So a band in this hall is a published claim about an object, standing next to the object. That is a rare arrangement, and it makes the room usable for something other than looking: you can check.

Three of the six bands here disagree with their own code about what order the ladder goes in. Two agree exactly. One agrees and then checks itself at runtime, which no other artifact in the chapter does.

## The band that agrees

<!-- @csg_difference_demo -->

```gdscript
# csg_difference_demo.gd:73
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]
```

Four readings of one cut. At `outcome` you get the answer and nothing else, a box with a bite out of it. At `trace` the removed material comes back as a ghost, occupying the space it was taken from. At `operands` both original solids return, transparent, so you can see the box and the sphere that were consumed. At `expression` a labelled rod names the operation out loud.

The registry declares those four words in that order, and so does the code, and so does the second axis. This is the only band in the room where the published claim and the object match on both dials, and it is worth standing in front of because it shows what the ladder is *for*: it is not four decorations, it is one operation shown at four degrees of disclosure. The object gets progressively less confident about its own result as you walk right.

There is one seam even here, and it is small and revealing. The dial that positions the cut names only two of its four settings in the code that reads it; `centred` — the one the artifact advertises as producing a clean internal void — arrives through the wildcard. It is not a rung. It is what happens when nothing matches.

## The ladder, published out of order

<!-- @csg_union_demo -->

```gdscript
# csg_union_demo.gd:119 — the code's ladder
const FUSIONS: PackedStringArray = ["distinct", "necked", "lobed", "single"]
```

In the code those four are monotonic. They are four multiples of one offset, running down: far apart, nearly touching, overlapping, concentric. Walk them in that order and you watch two things become one, in four steps, with the topology changing under you.

Walk this band left to right and you get `lobed, distinct, necked, single` — the registry's order, which is the order this hall was built from, and which starts you two-thirds of the way up the ladder, sends you back to the bottom, then part way up again, then to the top. The sequence is the same four states. The *argument* is gone, because the argument was the monotonicity.

The registry did not do this carelessly; the entry says the order is the sweep's tile order, default leftmost. But the disagreement has consequences past this room: a third file, `fusion_ladder.json`, declares the ladder in the code's order and states that it took that order character for character from `csg_union_demo.gd:128`. So one artifact cites this object's code as canonical while the object's own registry entry publishes something else, and both are read by tools.

## A rung that is only a name

<!-- @csg_intersection_demo -->

```gdscript
# csg_intersection_demo.gd:234 — three of the four are here
match consensus:
    "unanimous": ...
    "narrow": ...
    "token": ...
    _: ...
```

The same displacement, one band down. `consensus` asks how much has to be shared before anything survives, and the four values run from complete agreement to a token overlap.

`broad` is not in the match. It reaches its position through the wildcard, which means it is not a defined rung at all — it is the label the artifact wears when nothing matched. The value exists in both lists, in the code and in the registry, and in neither of them does it correspond to a line that says what it is. It is the name of the default, promoted to a name.

And it is the one the registry puts first, so this band opens on it.

## Four degrees of removal, read from somewhere else

<!-- @subtraction_suite -->

```gdscript
# subtraction_suite.gd:162
## The vocabulary and the ratios, read from the family rather than retyped.
var _breach_table: Dictionary = FONTANA_SOURCE.BREACH
```

Here is the counter-example, and the hall needs one. `breach` asks how far a removal can go before the thing is gone, and its four rungs — pierced, opened, severed, husk — are not four numbers in this file. They are read out of `fontana_puncture.gd`, another artifact entirely, which holds them as ratios of the body's own size: 0.54, 0.68, 0.74, 0.80. The enum, the table and the registry agree on all four words, in the same order.

The bench makes an argument out of that: because the ratios are read rather than retyped, they cannot drift. Which is true of every one of them except the one the file retypes fifty lines later as a literal `0.68`, inside the function whose whole purpose is the anti-drift claim. One number, in the file that exists to say numbers do not need to be repeated.

## The degenerate case, painted

<!-- @coincident_face -->

```gdscript
# coincident_face.gd:257 — the coin toss
col = color_a if (i % 2 == 0) else color_b
```

This band is about what happens when two faces occupy the same plane and the depth test has no answer — the flicker every 3D artist has seen, where a surface tears into stripes of two materials because the comparison is a coin toss at every pixel.

The artifact contains no boolean operation and no z-fight. There is not one CSG node in the file; the four places the string "CSG" appears are all text on labels. The stripes are the line above: even bars one colour, odd bars the other, alternating by index. And they are drawn at an explicitly unambiguous depth, four millimetres in front of everything else, so the renderer is never asked the question the artifact is named after. It is a diagram of a failure, executed by a mechanism that cannot fail.

That is not a cheat, exactly — a picture of z-fighting that actually z-fights would be unphotographable and would look different on every machine. But it is worth knowing what you are looking at, because there *is* a real coincident face in this file and it is not the one on the wall: at the `coincident` setting the two rectangle fills are placed at the same depth, the same thickness, overlapping in x, and they genuinely contest. The artifact produced the thing it is about by accident, behind the drawing of it, and says nothing about it.

The band's other seam is the same one union has: code and registry disagree on order, this time by moving the failure state to the front. The registry declares it in its own note, so it is a known disagreement rather than a hidden one.

## The one that checks

<!-- @removal_room -->

```gdscript
# removal_room.gd:341 — reading its own hint string back out
func _check_vocabularies() -> void:
```

Three copies of one cut lattice, differing only in how the removed cells are recorded: not drawn at all, drawn full-size and pale, or shrunk to a fifth and left as a scar. The axis underneath asks which deletion rule made the hole — a cross, a middle third, a gasket, a figure.

Alone in this chapter, this artifact does not trust its own declaration. At runtime it pulls its exported enum's hint string back out of the property list and compares it, both directions, against the constant beside it and against the vocabulary of the upstream artifact it borrowed the registers from. Code, constant and registry agree, and the file makes sure of it every time it builds.

Which makes the error in it more interesting, not less. The header explains why the three copies stand side by side rather than stacked, and derives it from an arithmetic: a scar is 0.22 cubed of its ghost, about one percent. Four hundred lines later the same file says the upstream rule keeps the removed part's length and thins only the section, and implements it that way — which makes a scar 0.22 squared, nearly five percent, four and a half times bigger. The room is built correctly. The justification printed at the top of it is wrong, and it is wrong about the one artifact it names.

## What the room is for

Six bands. Two published exactly as the code has them, one of those checked at runtime. Three published in a different order from the ladder the code walks, one of which scrambles the argument the ladder existed to make. One that measures its own ratios from another file and then retypes one of them anyway. One that has no boolean operation in it at all.

None of that is damage. It is what happens when an object is also a claim about itself, maintained in two places by different hands at different times, and it is only visible from a room where the claim and the object are standing next to each other. Everywhere else in this museum you meet these objects at their default and have no way to know there was a ladder.

The other question this hall raises, it cannot answer: all six of these families were promoted for the still camera, one photograph per value, judged on whether the picture changed. What none of them has ever been asked is whether the *space* changes — whether a variant is something you could walk differently. The heavy hall is where that gets tested, and where it mostly fails.
