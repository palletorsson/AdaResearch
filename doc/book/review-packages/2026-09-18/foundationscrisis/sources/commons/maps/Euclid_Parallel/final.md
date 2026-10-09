Click the plaque five times and you arrive back at the first postulate. The counter wraps:

```gdscript
# euclid_postulates_plaque.gd:202
func next_postulate():
	current_postulate = (current_postulate + 1) % 5
```

Five clicks, five postulates, one closed loop. Four of them fit on two short lines. The fifth needs four lines and a parenthesis. That is the whole principle, and you can repeat it after one walk: this space is flat because the room says so, not because anyone measured it.

## 1 — The five, stored as text

<!-- @euclid_postulates_plaque -->
<!-- ~tutorial#p2 ~tutorial#p4 ~critical#the-rule-that-could-not-be-proven -->

Let's start where the build starts. The tutorial keeps the five postulates as strings in a constant array — text, not logic, so a plinth can show them without a parser. The shipped plaque makes the same choice, and bakes its own line breaks in:

```gdscript
# euclid_postulates_plaque.gd:46
	"IV. All right angles are\nequal to one another.",
	"V. If a line crosses two lines\nand interior angles sum < 180°,\nthe two lines meet on that side.\n\n(The Parallel Postulate)"
```

Read those two as sentences. The fourth states an equality and stops. The fifth carries a condition, a threshold, a prediction — and then names itself.

The difference is not length. The first four hand you permissions: what a hand with a straightedge may do. The fifth tells you what will happen once your hand has done it. It is a rule shaped like a forecast, and a forecast asks to be checked. Twenty-three centuries of checking failed, and the failure was read as a gap in the mathematicians.

Fair — and let's say what the array does about it. The fifth is the only entry carrying a blank line inside itself.

It uses that blank line to introduce itself. Nothing else on the plaque has to.

## 2 — Marked before anyone argues

<!-- @euclid_postulates_plaque -->
<!-- ~tutorial#p10 ~tutorial#p11 ~critical#performativity-of-the-obvious -->

Before you have read a word, the room has told you which postulate matters. The gold arrives ahead of the argument.

It does, and we can point at the line that does it. The tutorial tints the fifth plinth and scales it by 1.2; the shipped plaque runs the same move as a branch:

```gdscript
# euclid_postulates_plaque.gd:121
	var is_fifth = current_postulate == 4
	var title_color: Color
	var text_color: Color
	if is_fifth and highlight_fifth:
		title_color = Color(1.0, 0.7, 0.3)
		text_color = Color(1.0, 0.9, 0.7)
```

Two conditions, not one. The same pair guards the announcement further down: `parallel_highlighted.emit()` sits inside `if is_fifth and highlight_fifth:` at line 163. Colour and signal come out of one branch.

Repetition is how obviousness gets made — every grid, every Cartesian axis, every drawn pair of parallels performs the fifth postulate again. Here the performance is one branch, repeated on every click. You are asked to follow the gold, and following feels like noticing.

So let's break the branch. `highlight_fifth` is an exported bool. Set it false and the fifth reads in the same warm grey as the rest, and `parallel_highlighted` never fires — the branch that shouted was the branch that coloured. `postulate_selected` still emits at index four, the way it does at every other. Cycle again and ask whether the fifth still feels like the odd one.

## 3 — Three lines that never meet

<!-- @parallel_lines -->
<!-- ~tutorial#p13 ~tutorial#p14 ~artifacts#parallel-lines ~critical#the-state-of-exception -->

The tutorial draws five lines at `y := -2.0 + i * 1.0` — even spacing, one unit apart, a picture in which Euclid's claim looks like a property of the world. The shipped scene has three, placed by hand:

```gdscript
# parallel_lines.tscn:7
[node name="Line1" parent="." instance=ExtResource("1_line")]
transform = Transform3D(0.258819, 0, 0.965926, 0.965926, 0, -0.258819, 0, 1, 0, -0.0648265, 0, 0)
```

Let's count the gaps. Line2 sits at 0.204004, Line3 at 0.305252. The first gap is about 0.27, the second about 0.10. The registry calls this artifact three line modules arranged to visualize equidistant lines. The transforms are not equidistant.

The parallelism survives. All three share a basis, so they run forever without meeting, whatever the spacing. Equidistance is a consequence the fifth postulate guarantees, and it is the part the declaration asserted instead of building. The word carried what the numbers did not.

Try it yourself: move Line3's offset out to 0.4 and count the gaps again. They change, and the lines still never meet. Spacing you can set by hand; parallelism comes from the shared basis.

And nothing in the room says the word out loud: the scene's `Label3D` ships with `visible = false`.

So you supply it. You look at three lines, name them parallel, and the naming arrives as sight.

## 4 — The triangle that says sixty

<!-- @angle_sum_triangle -->
<!-- ~summary#p3 ~blurb#p3 ~critical#what-the-axiom-conceals -->

The triangle's three corners are literals — apex at `size * 0.5`, base corners at `-size * 0.4` and `size * 0.4`. Then we hand the labels their text:

```gdscript
# angle_sum_triangle.gd:151
	var angles = ["60°", "60°", "60°"]
	var sum_text = "60° + 60° + 60° = 180°"
```

The shape those vertices make is isoceles, not equilateral. The file records its own measured corners: 53.1, 63.4, 63.4. Both triples sum to 180. The three sixties are shipped bytes, handed back rather than measured.

So the sum is true and the parts are ornament. Three equal numbers describe a triangle you are not looking at. It is the plaque's move again in another material: one surface makes unlike things look alike — five postulates in a single row, three identical angles under one figure. What gets hidden is not a falsehood. It is a difference.

The file already knows better, in a function just above. `_angles()` reads each corner off the polyline it actually drew, and at any curved opening the labels print what was measured. At `flat` it prints the shipped strings, because three placements ship them.

Keeping three maps byte-identical is a reason to print sixty. It is a reason about shipping, not about triangles. The geometry never asked for it.

## 5 — The setting you cannot reach from here

<!-- @angle_sum_triangle -->
<!-- ~tutorial#p16 ~tutorial#p17 ~critical#performativity-of-the-obvious -->

Let's measure how far the other spaces sit from this floor. The tutorial toggles the fifth and a second preview fractures. The shipped artifact has a real axis:

```gdscript
# angle_sum_triangle.gd:49
@export_enum("flat", "hyperbolic", "elliptic") var opening: String = "flat"
```

Map tokens reach it only through one gate:

```gdscript
# angle_sum_triangle.gd:203
	if config_data.has("opening"):
		var want: String = str(config_data["opening"]).strip_edges().to_lower()
		if OPENING_VALUES.has(want) and want != opening:
```

Every placement here ships the bare token, so that `has("opening")` is never true and `_polyline()` short-circuits past the arc loop. What happens if a placement hands it `opening=elliptic`? The edges bow outward at six percent of each chord, the corners open, and the printed sum climbs near 260. Hyperbolic falls near 100. Both are legal geometries. Try the token and watch the equation stay true while the number stops being 180.

So the other two spaces are already here, priced in degrees, one word away — and no move a body makes on this floor arrives at them. What a body can reach is the whole question. A geometry that ships in the file and waits on a placement is not absent; it is held back. The room offers one space and lets the absence of the others do the arguing.

## 6 — A screen with nothing to flatten

<!-- @science_screen -->
<!-- ~artifacts#science-screen ~summary#p2 ~critical#the-state-of-exception -->

The screen scans eight metres for neighbours that answer `get_grid_data()` and paints their cells at 768 by 576. Neither script here defines that method. The plaque offers `apply_grid_config`, two signals and three exports; the triangle offers `apply_grid_config` and two exports, `opening` and `size`. Nothing offers the one call the screen makes. So we open on the fallback:

```gdscript
# science_screen.gd:317
	_point_mode = true
```

The fallback is not a blank panel. It is a grid: white, square, right-angled, drawn before anything arrives to be drawn. The screen does not wait to learn what space it is in. It draws right angles whether or not anything is there, and right angles are this room's postulate in pixels.

Test it. Cross the room and watch the picture — it does not change, because nothing here gives it anything to change into. And this file has been fooled by its own paperwork before: its axis block once declared value names that were never in its enum. The sweep set them, the artifact fell back to its default, and sixteen identical frames were published — sixteen pictures of the same screen, filed as four variants. Nothing failed loudly.

A declaration outrunning its code, twice in one room. Here it arrives as a white grid rather than an error, which is how such things usually arrive.

## 7 — What the spec asked for and what stands here

<!-- @angle_sum_triangle -->
<!-- ~intent#p1 ~tutorial#p19 ~walked#what-it-opens ~summary#p4 ~blurb#p2 ~critical#the-state-of-exception -->

The tutorial closes with a scroll — 300 BCE Euclid, 1733 Saccheri, 1829 Lobachevsky, 1832 Bolyai, 1854 Riemann — and a door that unlocks after two seconds of reading. The spec asked for two interactive demos, `parallel_line_demo` and `euclid_parallel_demo`, that let you drag the lines. Neither is placed.

We can see that absence from inside the code. Every placement here ships a bare token, and a bare token arrives as an empty dictionary:

```gdscript
# angle_sum_triangle.gd:197
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
```

Three lines, and the only door into the geometry shuts before it opens. What stands here is a plaque, three lines, a triangle, a screen — and the building itself: an eleven by fifteen floor, pillars three units tall in mirror symmetry down both sides, a walkway left open between them. Walk that walkway and you are standing inside the assumption. The colonnade is the axiom, built at the size of a body.

The absence is honest about the work. You are not here to bend a parallel. You are here to stand where bending is out of reach, and to feel how little effort that costs. The exit asks the question the furniture declines, and the next room takes the fifth away.

Count once more: five postulates, three lines, one triangle, one screen, two rows of pillars. Every number is true. Not one of them is necessary.

You can stand on a floor and still ask what is holding it up.