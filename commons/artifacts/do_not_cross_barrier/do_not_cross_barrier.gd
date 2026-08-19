extends Node3D
class_name DoNotCrossBarrier

## A line you must not cross, built as an OBSTACLE: two weighted posts and a
## tape strung between them at hip height.
##
## The companion artifact is `walk_this_line_marking`, the floor half of the same
## asset — and it does NOT repeat this prohibition. This tape reads DO NOT CROSS;
## that paint reads WALK THIS LINE. The two stand in PERPENDICULAR relations to
## one line: this one forbids crossing it, that one commands following it. A body
## meeting both has been told the line is impassable in one direction and
## obligatory in the other, which is what a line does when it is also a rule —
## and the claim the map they were made for makes:
##
##   "Measure is also violence. What doesn't fit the grid is remainder, error,
##    erased. The line inherits this: efficient, relentless, forgetting
##    everything but endpoints."   — Point_Lines/blurb.md
##
## (The first draft of this file called the companion "the same prohibition
## painted on the floor" — which is what the asset filename implies and what the
## node hierarchy cannot refute. The capture showed the legend. The mesh was
## always right.)
##
## SOURCE ASSET. Both artifacts instantiate ONE glTF, res://commons/models/
## do_not_cross_line.glb, and each keeps only its own assembly. That is
## deliberate and is NOT the "one scene, many names" fault this corpus has found
## nine times: those were two registry tokens running one identical script with
## nothing to tell them apart. These two draw disjoint subtrees of a shared
## asset and are different objects on screen. The asset is authored as one file
## because the barrier and the marking are dimensioned against each other — the
## posts stand at x = ±1.6 and the floor legend lies 1.18 m in front of them.
##
## Assembly kept here: post_left, post_right (base_plate · base_taper · pole ·
## grip_band · cap · tie_eye each), barrier_tape, printed_legend.

const SOURCE_GLB: PackedScene = preload("res://commons/models/do_not_cross_line.glb")

## The parts of the glTF this artifact owns. Everything else in the file is the
## companion's and is freed on build.
const KEEP: PackedStringArray = ["post_left", "post_right", "barrier_tape", "printed_legend"]

## Metres between the two posts, measured from the asset (post_left x = -1.6,
## post_right x = +1.6). Changing it slides the posts symmetrically and rescales
## the tape along its length so it still spans them.
@export var span_m: float = 3.2

## Hide the printed words on the tape. The legend is a mesh, not a label, so it
## costs nothing to keep — but at a distance it reads as noise on the tape, and
## a map that wants the line without the shouting can turn it off.
@export var show_legend: bool = true

## Lean the whole barrier off vertical, in degrees, as though it has been
## shoved. 0 is the authored upright.
@export var shove_deg: float = 0.0

var _built: bool = false


func _ready() -> void:
	_build()


func _build() -> void:
	if _built:
		return
	_built = true

	for child in get_children():
		child.queue_free()

	var src: Node3D = SOURCE_GLB.instantiate() as Node3D
	if src == null:
		push_error("do_not_cross_barrier: %s did not instantiate as Node3D" % SOURCE_GLB.resource_path)
		return

	# The glTF wraps everything in a `do_not_cross_line` node; take that as the
	# working root if it is there, and tolerate its absence rather than assuming.
	var root: Node = src
	var wrapper: Node = src.get_node_or_null("do_not_cross_line")
	if wrapper != null:
		root = wrapper

	var mount := Node3D.new()
	mount.name = "Barrier"
	add_child(mount)

	var moved: int = 0
	for part_name in KEEP:
		var part: Node = root.get_node_or_null(NodePath(part_name))
		if part == null:
			push_warning("do_not_cross_barrier: '%s' is not in the source asset" % part_name)
			continue
		root.remove_child(part)
		mount.add_child(part)
		part.owner = null
		moved += 1

	# Whatever is left belongs to the companion artifact.
	src.queue_free()

	if moved == 0:
		push_error("do_not_cross_barrier: nothing was taken from the asset — the node names have changed")
		return

	_apply_span(mount)
	_apply_legend(mount)
	mount.rotation_degrees.z = shove_deg


## Slide the posts symmetrically to `span_m` and stretch the tape to match.
## The authored span is 3.2 m, so the scale factor is span_m / 3.2 and the posts
## sit at half that either side of centre.
func _apply_span(mount: Node3D) -> void:
	var factor: float = 1.0
	if span_m > 0.0:
		factor = span_m / 3.2
	if is_equal_approx(factor, 1.0):
		return
	for part_name in ["post_left", "post_right"]:
		var post: Node3D = mount.get_node_or_null(NodePath(part_name)) as Node3D
		if post != null:
			post.position.x *= factor
	for part_name in ["barrier_tape", "printed_legend"]:
		var tape: Node3D = mount.get_node_or_null(NodePath(part_name)) as Node3D
		if tape != null:
			tape.scale.x = factor


func _apply_legend(mount: Node3D) -> void:
	var legend: Node3D = mount.get_node_or_null("printed_legend") as Node3D
	if legend != null:
		legend.visible = show_legend


## Grid hook. Called by GridInteractablesComponent on the scene ROOT with the
## `config_*` metadata a map token carries, e.g.
##     do_not_cross_barrier:0:0#span_m:2.4#show_legend:false
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("span_m"):
		span_m = float(config_data["span_m"])
	if config_data.has("show_legend"):
		show_legend = bool(config_data["show_legend"])
	if config_data.has("shove_deg"):
		shove_deg = float(config_data["shove_deg"])
	if _built:
		_built = false
		_build()
