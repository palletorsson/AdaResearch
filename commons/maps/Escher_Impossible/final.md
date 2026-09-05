A staircase that goes up on all four sides and comes back to where it started.

Check any corner of it. The riser is a sensible height, the tread is level, the joint between this flight and the next is square. Check the next corner and the same is true. Walk the whole loop checking as you go, approve every junction individually, and you will arrive back at the step you began on having climbed the entire way. Nothing you inspected was wrong. The object cannot exist.

That is the room, and it is the same result as the one two doors back, arrived at through the eye instead of through arithmetic. Russell's box could not be built because a rule contained itself. This staircase cannot be built because sixteen local truths do not add up to a global one — and there is no local inspection that could ever have told you.

## Sixteen joints, and the impossibility has to live in one of them

<!-- @escher_staircase -->

```gdscript
# escher_staircase.gd:169
@export_enum("none", "hairline", "gap", "scaffold", "field") var seam: String = "none"
```

That line is the best thing in this room, because it is a dial whose settings are *where to put the contradiction*.

The artifact's own header spells the five out: smoothed into one quiet descending side and never named (`none`); gathered into a single closing riser you can point at (`hairline`); refused outright, so the loop is left open with two cut ends facing each other (`gap`); that same opening rigged with a tower and a landing so the walk becomes possible by cheating (`scaffold`); or spread evenly into all sixteen joints so the ring comes out level and no joint can be blamed (`field`).

The impossibility is conserved. It cannot be removed, only relocated — concentrated where it can be pointed at, or distributed until it is undetectable anywhere. That is exactly the property the room is arguing about consistency, expressed as a property of a Godot export.

The staircase here is placed as a bare token, so it stands at `none`: smoothed, and never named. The room's thesis is that the contradiction is in the whole rather than in any step, and its main body is set to the value that makes precisely that true. Whether that is a curatorial decision or an unset default, it is the right setting, and it is the reason the object reads as calm.

## The step you cannot take

```gdscript
# escher_staircase.gd:426
func climb_step() -> void:
```

The artifact has an API for walking it. Completing a full loop fires a `paradox_completed` signal. There is no `_input` handler in the file and no interaction volume anywhere in the scene, so nothing ever calls it — the header says as much, *has climb_step() API but no physical trigger*.

So the staircase whose desire is written down as *climb "up" forever and arrive where you started — feel the paradox in your legs* cannot be climbed. The signal for finishing the loop has no sender.

Worth sitting with rather than logging. The whole claim of this room is that walking the thing step by step is the procedure that fails to detect the fault — that local verification is exactly the method that cannot see a global contradiction. The one interaction that would let you perform that failure is the one that was not wired. You are left doing what the argument says you must do instead: standing back and taking in the whole, because there is no way to check it a piece at a time.

## Where you have to stand

<!-- @penrose_triangle -->

```gdscript
# penrose_triangle.gd:41
@export_enum("marker", "bare", "seam", "exploded", "sealed") var disclosure: String = "marker"
```

Three bars, three right angles, each corner square. The Penrose triangle — published by Roger Penrose and his father Lionel in 1958, described by them as impossibility in its purest form, and the direct source for Escher's *Waterfall*.

It has two settings and both matter. `disclosure` is how much the object confesses, running from a small marker through bare, to a visible seam, to exploded, to sealed. And `_is_at_sweet_spot` tracks whether you are standing in the one place from which the illusion coheres — because a Penrose triangle built in three dimensions is a real object with a gap in it, and there is exactly one line of sight along which the gap is hidden by perspective.

That second parameter is the honest one. The impossibility is not in the object; it is in the relationship between the object and a viewpoint. From anywhere else in this room the triangle is an ordinary bent thing with a break. Move to the sweet spot and it closes. Nothing about the bars changed.

Which reframes the staircase too. Consistency here is not a property the object has. It is a property of a *view* of the object, and the view is a position you can be standing in without knowing you chose it.

## Two prongs, or three

<!-- @impossible_trident -->

```gdscript
# impossible_trident.gd:13
## truth: two prongs become three; the drawing is consistent locally and impossible
##   globally — every junction is fine on its own, no assembly of them is.
```

The blivet, at the far end of the room. Read the base and you count two rectangular prongs. Follow them up and there are three round ones. There is no point along the drawing where the change happens; every band of it, covered at both ends, is a coherent picture.

It is the cleanest of the three because it removes the staircase's narrative and the triangle's perspective trick and leaves only the arithmetic: a count that is well-defined at both ends and different. The contradiction is not at a location. It is distributed across the transition, in the same way the staircase's `field` setting distributes it across sixteen joints so that no joint can be blamed.

## This is not a pipe

<!-- @magritte_pipe -->

```gdscript
# magritte_pipe.gd:2
# essence: sign != signified -- a procedural pipe mesh with label saying this is not a pipe
```

The one tangent, and the blurb seats it deliberately. Magritte's painting is not an impossible object — it is perfectly coherent — and its trouble is one level up: the image of a pipe is not a pipe, and the sentence saying so is not a sentence about pipes but about images.

It is in this room because the other three all depend on the same move. A drawing of a staircase can be locally valid in a way no staircase can, because a drawing is not the thing. The impossible objects are only impossible once you insist the representation is a claim about a buildable world. Take away that insistence and they are just marks that agree with each other locally.

Which is the room's argument pointed at itself: *every data structure is a Magritte painting*, as the header puts it. A model is consistent internally and says nothing, by itself, about whether the thing modelled can be.

## What checking cannot do

Consistency is not compositional. You can verify every step and learn nothing about the loop, and this is not a limitation of care or of time — it is a fact about what local verification is. The information that the staircase does not close is not present at any junction. It appears only in the sum.

That result is about to arrive in its formal version, which is worse, because there the whole under inspection is the checking system itself. Hold on to the trident: a count that is well-defined at both ends and different, with no place in between where it went wrong.

The contradiction isn't in any single step. It's in the whole.
