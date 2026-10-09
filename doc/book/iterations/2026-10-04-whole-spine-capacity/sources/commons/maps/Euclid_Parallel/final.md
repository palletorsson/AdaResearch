# The Fifth Postulate

Press NEXT on the plaque five times and you arrive back at the first postulate. The counter wraps:

```gdscript
# euclid_postulates_plaque.gd
func next_postulate():
	current_postulate = (current_postulate + 1) % 5
```

Five presses, five postulates, one closed loop. Four of them fit on two short lines. The fifth needs four lines and a parenthesis. Before measuring anything, we have agreed to begin here. The room gives us flat coordinates; the plaque gives us sentences about what can be done in them. Walk between the columns. How much of that agreement already feels like the world?

## The five, stored as text

<!-- @euclid_postulates_plaque -->
<!-- ~tutorial#p2 ~tutorial#p4 ~critical#the-rule-that-could-not-be-proven -->

Start where the build starts. The tutorial keeps the five postulates as strings in a constant array: text, not logic, so a plinth can show them without a parser. The shipped plaque makes the same choice, and bakes its own line breaks in:

```gdscript
# euclid_postulates_plaque.gd
	"IV. All right angles are\nequal to one another.",
	"V. If a line crosses two lines\nand interior angles sum < 180°,\nthe two lines meet on that side.\n\n(The Parallel Postulate)"
```

Read those two as sentences. The fourth states an equality and stops. The fifth carries a condition, a threshold, a prediction — and then names itself.

The difference is not length. The first four hand you permissions: what a hand with a straightedge may do. The fifth tells you what will happen once your hand has done it. It is a rule shaped like a forecast, and a forecast asks to be checked. For centuries, attempts to derive the fifth from the others failed. A rule can feel inevitable long before we have established that it follows.

The array says the same in its own way. The fifth is the only entry carrying a blank line inside itself.

It uses that blank line to introduce itself. Nothing else on the plaque has to.

## Marked before anyone argues

<!-- @euclid_postulates_plaque -->
<!-- ~tutorial#p10 ~tutorial#p11 ~critical#performativity-of-the-obvious -->

Before you have read a word, the room has told you which postulate matters. The gold arrives ahead of the argument.

The line that does it can be pointed at. The tutorial tints the fifth plinth and scales it by 1.2; the shipped plaque runs the same move as a branch:

```gdscript
# euclid_postulates_plaque.gd
	var is_fifth = current_postulate == 4
	var title_color: Color
	var text_color: Color
	if is_fifth and highlight_fifth:
		title_color = Color(1.0, 0.7, 0.3)
		text_color = Color(1.0, 0.9, 0.7)
```

Two conditions, not one. The same pair guards the announcement further down: `parallel_highlighted.emit()` sits inside `if is_fifth and highlight_fifth:`. Colour and signal come out of one branch.

Repetition is how obviousness gets made — every grid, every Cartesian axis, every drawn pair of parallels performs the fifth postulate again. Here the performance is one branch, repeated on every press. You are asked to follow the gold, and following feels like noticing.

Now press GOLD. It switches `highlight_fifth` off: the fifth reads in the same warm grey as the rest, and `parallel_highlighted` never fires — the branch that shouted was the branch that coloured. `postulate_selected` still emits at index four, the way it does at every other. Cycle again and ask whether the fifth still feels like the odd one.

## Three lines that never meet

<!-- @parallel_lines -->
<!-- ~tutorial#p13 ~tutorial#p14 ~artifacts#parallel-lines ~critical#the-state-of-exception -->

The tutorial draws five lines at `y := -2.0 + i * 1.0` — even spacing, one unit apart, a picture in which Euclid's claim looks like a property of the world. The shipped scene has three, placed by hand:

```gdscript
# parallel_lines.tscn:7
[node name="Line1" parent="." instance=ExtResource("1_line")]
transform = Transform3D(0.258819, 0, 0.965926, 0.965926, 0, -0.258819, 0, 1, 0, -0.0648265, 0, 0)
```

Count the gaps. Line2 sits at 0.204004, Line3 at 0.305252. The first gap is about 0.27, the second about 0.10. The registry calls this artifact three line modules arranged to visualize equidistant lines. The transforms are not equidistant.

The parallelism survives. All three share a basis: extend the segments along those directions and their supporting lines do not meet. Each pair keeps a constant perpendicular separation. That does not require the gap between the first and second to equal the gap between the second and third. Uneven spacing breaks an evenly spaced pattern; it does not break parallelism. We have to decide which regularity we were looking for.

Imagine Line3 pushed out to 0.4: the gaps change, and the lines still never meet. Spacing you can set by hand; parallelism comes from the shared basis.

And nothing in the room says the word out loud: the scene's `Label3D` ships with `visible = false`.

So you supply it. You look at three lines, name them parallel, and the naming arrives as sight.

## The triangle that says sixty

<!-- @angle_sum_triangle -->
<!-- ~summary#p3 ~blurb#p3 ~critical#what-the-axiom-conceals -->

The triangle's three corners are literals — apex at `size * 0.5`, base corners at `-size * 0.4` and `size * 0.4`. Then the labels are handed their text:

```gdscript
# angle_sum_triangle.gd
	var angles = ["60°", "60°", "60°"]
	var sum_text = "60° + 60° + 60° = 180°"
```

The shape those vertices make is isosceles, not equilateral. The file records its own measured corners: 53.1, 63.4, 63.4. Both triples sum to 180. The three sixties are shipped bytes, handed back rather than measured.

So the sum is true and the parts are ornament. Three equal numbers describe a triangle you are not looking at. It is the plaque's move again in another material: one surface makes unlike things look alike — five postulates in a single row, three identical angles under one figure. What gets hidden is not a falsehood. It is a difference.

The file already knows better, in a function just above. `_angles()` reads each corner off the polyline it actually drew, and at any curved opening the labels print what was measured. At `flat` it prints the shipped strings; the file says three maps ship them, and today two halls of the walk do.

Keeping those halls byte-identical is a reason to print sixty. It is a reason about shipping, not about triangles. The geometry never asked for it.

## Bowing a line is not enough

<!-- @angle_sum_triangle -->
<!-- ~tutorial#p16 ~tutorial#p17 ~critical#performativity-of-the-obvious -->

Measure how far the other spaces sit from this floor. The tutorial toggles the fifth and a second preview fractures. The shipped artifact has three named settings:

```gdscript
# angle_sum_triangle.gd
@export_enum("flat", "hyperbolic", "elliptic") var opening: String = "flat"
```

Map tokens reach it only through one gate:

```gdscript
# angle_sum_triangle.gd
	if config_data.has("opening"):
		var want: String = str(config_data["opening"]).strip_edges().to_lower()
		if OPENING_VALUES.has(want) and want != opening:
```

The triangle here receives no `opening` setting, so its edges remain segments. In the source, selecting `elliptic` bows the edges outward; `hyperbolic` bows them inward. The corner labels change because the directions at the corners change.

But the drawing still lies in one flat plane. Curved sides can make a triangle-shaped outline whose corner sum is not 180°. That alone does not demonstrate spherical or hyperbolic geometry: we have changed the lines without specifying a different way of measuring space.

This is a useful limit to meet before the next room. A name can promise a world; a bend can make the promise look convincing. What else must change for a line to count as straight there?

## A screen with nothing to flatten

<!-- @science_screen -->
<!-- ~artifacts#science-screen ~summary#p2 ~critical#the-state-of-exception -->

The screen scans eight metres for neighbours that answer `get_grid_data()` and paints their cells at 768 by 576. Neither script here defines that method. The plaque offers configuration and selection signals; the triangle offers `apply_grid_config` and two exports, `opening` and `size`. Nothing offers the one call the screen makes. And the map asked for a grid anyway: the screen's token carries `#mode:grid`. So it looked eight metres for anything with a grid to give it, found nothing, and drew what it was asked for with nothing behind it, sixteen by sixteen dead cells:

```gdscript
# science_screen.gd
	_point_mode = true
```

What it draws is not a blank panel. It is a grid: white, square, right-angled, drawn before anything arrives to be drawn. The screen does not wait to learn what space it is in. It draws right angles whether or not anything is there, and right angles are this room's postulate in pixels.

Test it. Cross the room and watch the picture: it does not change, because nothing here gives it anything to change into.

A declaration outrunning its code: the token asked for a grid, and the grid arrived as a white picture rather than an error, which is how such things usually arrive.

## What the spec asked for and what stands here

<!-- @angle_sum_triangle -->
<!-- ~intent#p1 ~tutorial#p19 ~walked#what-it-opens ~summary#p4 ~blurb#p2 ~critical#the-state-of-exception -->

The tutorial closes with a scroll — 300 BCE Euclid, 1733 Saccheri, 1829 Lobachevsky, 1832 Bolyai, 1854 Riemann — and a door that unlocks after two seconds of reading. The spec asked for two interactive demos that let you drag the lines. Neither is placed.

The plaque now lets you cycle the sentences and remove their gold emphasis. The lines and triangle remain comparisons to look at; they do not yet offer a handhold for changing their geometry. A control for reading is not a control for bending space.

What stands here is a plaque, three lines, a triangle, a screen — and the building itself: an eleven by fifteen floor, a colonnade along the approach, a walkway between its repeated uprights. Walk that walkway and the assumption acquires the size of a body.

You can follow the path without agreeing that it is the only possible one. Carry that distinction through the exit. In the next room, the triangle gets a different host, and we can ask its corners again.

Count once more: five postulates, three lines, one triangle, one screen, two rows of pillars. Every number is true. Not one of them is necessary.

You can stand on a floor and still ask what is holding it up.