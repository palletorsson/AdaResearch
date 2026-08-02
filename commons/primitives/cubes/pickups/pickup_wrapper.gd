extends "res://commons/scenes/mapobjects/pick_up_cube.gd"

const CubeTravel := preload("res://commons/primitives/cubes/cube_bearing.gd")

# @identity
# essence: the pickup shell — a detection volume and a Visuals slot. Three registry tokens run
#   THIS script with IDENTICAL parameters (rotation_speed 0, bob_height 0, bob_speed 0); the only
#   difference between pickup_cube_static, pickup_cube_rotating and pickup_cube_transforming is
#   which scene is dropped into the slot. It is one object wearing three names.
# desire: to stop being three names. The state a pickup is caught in is one question, not three
#   entries in a registry.
# critical_parameter: travel — what the mounting concedes (none | seat | spindle | rail | gimbal |
#   armature). Inherited from the base class: stock (what it is made of) and custody (who has
#   counted it). The three rate exports set to zero in all three scenes configure nothing.
# triggers: _ready → super._ready (stock/custody) → _disable_internal_collision → _build_travel,
#   appended last; apply_grid_config rebuilds only when the axis actually moves.
# emerges: the three tokens become three VALUES of one axis, and the two the registry never
#   spelled — a gimbal and a clamp arm — turn out to have been missing from the vocabulary.
# needs: a Visuals child containing a CubeBaseMesh [present in all three scenes]; the base class's
#   DetectionArea contract [untouched].
# relationships: subclasses [[pick_up_cube]] and inherits its stock x custody DNA whole; builds
#   its mounting through [[cube_bearing]], shared with rotating_cube and transformation_cube.
# truth: three names for one body is a taxonomy pretending to be an inventory. Naming the axis
#   costs one word and returns two states nobody had thought to place.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION. 15 placements across the three tokens.
#
# WHAT THIS SCRIPT ALREADY HAD, before a line was added: nothing of its own — but it EXTENDS
# pick_up_cube.gd, so all three tokens have silently carried that class's `stock` x `custody`
# axes since that promotion landed. They are promoted artifacts whose registry entries never
# said so. The .tscn files show zero exports; the runtime object has five.
#
# WHAT THIS SCRIPT ADDS: one axis, `travel`, and the reason it is here rather than on the body
# is that the body is shared. cube_scene.tscn is the single visual body under all five tokens in
# this group, and its script already owns a finished axis (`grain`) across 155 placements. So the
# mounting rides on the wrappers, where it belongs anyway: a fixture is not part of the thing it
# holds.
#
# WHY NOT PROMOTE THE MOTION. static/rotating/transforming is the axis the registry is already
# spelling longhand, but all three are RATES and a rate cannot be photographed. What can be
# photographed is the hardware around the body — a chock, a wear ring, a rubbed slot, a stop.
# So the axis is what the MOUNTING CONCEDES, and the three token names become three of its six
# values. See cube_bearing.gd for the full vocabulary.
#
# STRICTLY APPEARANCE. Nothing below reads or writes DetectionArea, its CollisionShape3D, the
# collision layer or mask, collect(), the GameManager call, the generated audio, or any rate.
# The mounting is MeshInstance3D children under one "TravelMount" holder; meshes do not collide,
# so a player walks into the pickup volume exactly as before.
# ─────────────────────────────────────────────────────────────────────────────

## AXIS — what the mounting concedes. `none` is the shipped look for all 15 placements: the
## build returns before creating a node.
##
##   none      no mounting. The cube floats, unexplained. THE LEGACY LINEAGE.
##   seat      bedded on a pad, chocked at four corners, keeper bar pinned over the top
##   spindle   pinned on one axis, standing in its own bright annular wear ring
##   rail      on a bounded linear guide: carriage, hard stops, a rubbed stripe of travel
##   gimbal    two trunnion rings in a yoke — orientation given away entirely
##   armature  a cranked arm off a column, jaws closed on one face, lock handle thrown
@export_enum("none", "seat", "spindle", "rail", "gimbal", "armature") var travel: String = "none"

## The mounting currently standing, so a late config knows whether anything has to move.
var _built_travel: String = ""


func _ready() -> void:
	super._ready()
	_disable_internal_collision()
	# DNA appended LAST, after the collection path and the collision pass are both settled, so
	# nothing above this line can be affected by what the mounting turns out to be.
	_build_travel()


## Extends the base class's reader rather than replacing it — `stock`, `custody` and `stock_no`
## must keep arriving exactly as they did. Called from PickupCube._ready via super, so `travel`
## is resolved before _build_travel runs.
func _read_meta_overrides() -> void:
	super._read_meta_overrides()
	if has_meta("config_travel"):
		travel = CubeTravel.pick(str(get_meta("config_travel")), travel)


## The base class stores the metadata, re-reads (through the override above) and rebuilds its own
## dressing when stock/custody/stock_no moved. Only the mounting is this class's business, so it
## checks one value and touches nothing else.
func apply_grid_config(config_data: Dictionary) -> void:
	var before: String = travel
	super.apply_grid_config(config_data)
	if travel != before:
		_build_travel()


func _disable_internal_collision() -> void:
	# Recursively find all StaticBody3D nodes in the visual instance
	# and disable them so they don't block the player from entering the pickup area
	_disable_collision_recursive(self)

func _disable_collision_recursive(node: Node) -> void:
	if node is StaticBody3D:
		# Disable collision layers/masks so it passes through everything
		node.collision_layer = 0
		node.collision_mask = 0
		# Also try to disable the collision shape specifically if present
		for child in node.get_children():
			if child is CollisionShape3D:
				child.disabled = true

	for child in node.get_children():
		_disable_collision_recursive(child)


# ── the mounting ─────────────────────────────────────────────────────────────

## THE DEFAULT PATH. travel == "none" and nothing has ever been built: this returns after two
## string compares, having created no node, hidden nothing and written no property. All 15
## existing placements land here and render exactly the pixels they rendered before promotion.
func _build_travel() -> void:
	if travel == "none" and _built_travel == "":
		return
	var old: Node = get_node_or_null("TravelMount")
	if old != null:
		remove_child(old)
		old.queue_free()
	_built_travel = travel
	if travel == "none":
		return
	var frame: Array = _body_frame()
	var centre: Vector3 = frame[0]
	var half: float = frame[1]
	CubeTravel.build(self, travel, centre, half)


## Measure the visual body in this node's own local space.
##
## Derived, not assumed. The base class's CORE constant places the display mesh at y = 0.5, which
## is right for pickup_cube_static and pickup_cube_rotating and WRONG for pickup_cube_transforming
## — transformation_cube.tscn raises CubeBaseStaticBody3D by half a metre, so under the pickup's
## half-scale Visuals that body sits at y = 0.75 (the registry's own measured aabb_center agrees).
## Measuring sidesteps the discrepancy instead of inheriting it.
func _body_frame() -> Array:
	var mesh: MeshInstance3D = _base_mesh()
	if mesh == null:
		return [Vector3(0.0, 0.5, 0.0), 0.25]
	return CubeTravel.measure(self, mesh)
