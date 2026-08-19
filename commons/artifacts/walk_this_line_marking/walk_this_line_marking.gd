extends Node3D
class_name WalkThisLineMarking

## The floor half of the `do_not_cross_line` asset — and it does NOT say what the
## tape says. The tape reads DO NOT CROSS. The paint reads WALK THIS LINE.
##
## That is the pair, and it is sharper than one prohibition rendered twice: the
## two artifacts stand in PERPENDICULAR relations to the same line. The barrier
## forbids crossing it. The marking commands following it. A body meeting both
## has been told the line is impassable in one direction and obligatory in the
## other — which is what a line does when it is also a rule, and exactly the
## claim the map they were made for makes:
##
##   "Measure is also violence. What doesn't fit the grid is remainder, error,
##    erased. The line inherits this: efficient, relentless, forgetting
##    everything but endpoints."   — Point_Lines/blurb.md
##
## The barrier stops a body; the paint only informs one. Nothing about paint
## prevents anything — it works entirely by being read and obeyed.
##
## THIS WAS FOUND BY LOOKING. The first version of this file called the marking
## "the same prohibition painted on the floor", which is what the asset filename
## implies and what the node hierarchy alone cannot tell you. The capture showed
## the legend and it says something else. The mesh was always right; the
## description was mine.
##
## SOURCE ASSET. Both artifacts instantiate ONE glTF, res://assets/models/
## do_not_cross_line.glb, and each keeps only its own assembly. See the note in
## do_not_cross_barrier.gd for why that is not the "one scene, many names" fault
## this corpus keeps finding: these two draw DISJOINT subtrees and are different
## objects on screen.
##
## Assembly kept here: floor_marking (floor_legend · guide_stripe).
##
## Authored geometry, measured off the asset: floor_legend lies at z = 1.18,
## rotated -90 degrees about X so it reads from above; guide_stripe sits at
## z = 1.6, 2 mm proud of the floor, spanning x = ±1.45.

const SOURCE_GLB: PackedScene = preload("res://commons/models/do_not_cross_line.glb")

## The part of the glTF this artifact owns. Its two children come with it.
const KEEP: PackedStringArray = ["floor_marking"]

## Metres the marking sits from the artifact origin, along +Z. The asset places
## the legend 1.18 m out; this shifts the whole marking as a unit so a map can
## set the paint back from whatever it is warning about.
@export var standoff_m: float = 1.18

## Draw the guide stripe. Without it the legend is a statement; with it the line
## has a position, and the two are different claims — which is the whole reason
## this artifact and the barrier are a pair rather than one object.
@export var show_stripe: bool = true

## Wear on the paint, 0 (fresh) to 1 (nearly gone), applied as transparency on
## the floor_paint surfaces. A rule nobody has repainted is still a rule, and
## this is the cheapest way for a map to say how long it has been one.
@export_range(0.0, 1.0, 0.01) var wear: float = 0.0

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
		push_error("walk_this_line_marking: %s did not instantiate as Node3D" % SOURCE_GLB.resource_path)
		return

	var root: Node = src
	var wrapper: Node = src.get_node_or_null("do_not_cross_line")
	if wrapper != null:
		root = wrapper

	var mount := Node3D.new()
	mount.name = "Marking"
	add_child(mount)

	var moved: int = 0
	for part_name in KEEP:
		var part: Node = root.get_node_or_null(NodePath(part_name))
		if part == null:
			push_warning("walk_this_line_marking: '%s' is not in the source asset" % part_name)
			continue
		root.remove_child(part)
		mount.add_child(part)
		part.owner = null
		moved += 1

	# The posts and tape belong to the companion artifact.
	src.queue_free()

	if moved == 0:
		push_error("walk_this_line_marking: nothing was taken from the asset — the node names have changed")
		return

	_apply_standoff(mount)
	_apply_stripe(mount)
	if wear > 0.0:
		_apply_wear(mount)


## Shift the marking along +Z as a unit. The asset's own legend sits at 1.18 m,
## so the delta rather than the absolute is what moves.
func _apply_standoff(mount: Node3D) -> void:
	var marking: Node3D = mount.get_node_or_null("floor_marking") as Node3D
	if marking != null:
		marking.position.z += standoff_m - 1.18


func _apply_stripe(mount: Node3D) -> void:
	var marking: Node3D = mount.get_node_or_null("floor_marking") as Node3D
	if marking == null:
		return
	var stripe: Node3D = marking.get_node_or_null("guide_stripe") as Node3D
	if stripe != null:
		stripe.visible = show_stripe


## Fade the paint. Applied as a per-instance material override so the shared
## glTF material is left alone — two placements at different wear must not
## edit each other's surfaces.
func _apply_wear(mount: Node3D) -> void:
	for mesh in _meshes_under(mount):
		var mat := StandardMaterial3D.new()
		var base: Material = mesh.get_active_material(0)
		if base is StandardMaterial3D:
			mat.albedo_color = (base as StandardMaterial3D).albedo_color
		else:
			mat.albedo_color = Color(0.86, 0.82, 0.30)
		mat.albedo_color.a = clampf(1.0 - wear, 0.0, 1.0)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat


func _meshes_under(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		out.append_array(_meshes_under(child))
	return out


## Grid hook. Called by GridInteractablesComponent on the scene ROOT, e.g.
##     walk_this_line_marking:0:0#standoff_m:2.0#wear:0.6
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("standoff_m"):
		standoff_m = float(config_data["standoff_m"])
	if config_data.has("show_stripe"):
		show_stripe = bool(config_data["show_stripe"])
	if config_data.has("wear"):
		wear = clampf(float(config_data["wear"]), 0.0, 1.0)
	if _built:
		_built = false
		_build()
