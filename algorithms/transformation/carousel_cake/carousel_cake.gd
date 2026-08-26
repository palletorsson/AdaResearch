@tool
extends Node3D
class_name CarouselCake

# @identity
# essence: layer_speed[i] = base_speed * multiplier^i — exponential speed escalation across 8 rotating layers
# desire: learner watches layers spin at different speeds and feels how a single rule creates complex motion
# critical_parameter: rotation_speed_multiplier — each layer is this factor faster than the one below it
# triggers: _process(delta) — updates MultiMesh transforms every frame; each layer rotates at its own rate
# emerges: visual interference patterns as fast and slow layers pass each other — complexity from simple scaling
# needs: [missing VR controls — no live speed or layer-count slider]
# relationships: used in Trans_RotationSpectacle; sibling to spin.gd; stripe shader syncs visually with rotation
# truth: geometric progression means small multiplier differences create enormous speed ratios after many layers

@export var layer_radii: Array[float] = [4.0, 3.5, 3.0, 1.6, 3.0, 3.5, 4.0, 5.0]
@export var layer_heights: Array[float] = [0.05, 0.05, 0.05, 3.0, 1.0, 0.5, 0.5, 0.5]

# ── STAGE-2 DNA ───────────────────────────────────────────────────────────────
## AXIS — PROFILE. The silhouette the eight layers cut. The artifact's claim is that one
## multiplicative rule (each layer spins rotation_speed_multiplier times faster than the
## one below) turns into spectacle — but a speed is a rate, and a rate is exactly what a
## still frame cannot hold. What a still holds is the STACK: which shape the progression
## has been poured into, and therefore what the escalation reads as.
##
##   cake      THE DEFAULT and the legacy lineage, byte for byte: three thin plates, a
##             narrow 3 m waist, then a widening flare to a 5 m brim. A wedding cake, or a
##             carousel — a shape that already means festivity before anything turns.
##   ziggurat  every layer strictly smaller than the one below, 5 m down to 1 m. The
##             progression read as hierarchy: the fastest layer is also the smallest, so
##             the escalation looks like a diminishing.
##   column    every layer the same 3 m radius — a plain drum. The shape cue removed
##             entirely, so the speed ratios have nothing to hide behind and the only
##             thing distinguishing the layers is how fast they go.
##   spindle   wide, pinched, wide, pinched — a bobbin. Two waists instead of one, so the
##             stack reads as machined stock rather than as a confection.
##   flare     the ziggurat inverted, 1 m up to 5 m. Top-heavy: the biggest and fastest
##             layer overhangs everything under it, which is the geometric progression
##             stated as an object about to fall over.
##
## The heights are NOT touched by this — only the radii — so every layer stays at the same
## elevation and the eight speed ratios are unchanged. Neither are the COLLIDERS: those
## keep following layer_radii, so what the player can stand on is identical for all five
## values. This axis is appearance only.
@export_enum("cake", "ziggurat", "column", "spindle", "flare") var profile: String = "cake"
const PROFILES: PackedStringArray = ["cake", "ziggurat", "column", "spindle", "flare"]

# The radii the MULTIMESH draws with. Filled by generate_carousel; on "cake" it is a copy
# of layer_radii, which is what every existing placement gets.
var _vis_radii: Array[float] = []
var _baked_retargeted: bool = false
var _stack_anchor: MeshInstance3D = null
@export var base_radial_segments: int = 32
@export var segments_increment: int = 2
@export var base_rotation_speed: float = 0.5
@export var rotation_speed_multiplier: float = 1.2  # Each layer spins faster
@export_group("Colliders")
@export var enable_colliders: bool = true
@export var collision_layer: int = 1
@export var collision_mask: int = 1
@export_group("Materials")
@export var alternating_colors: bool = true
@export var use_stripe_shader: bool = true
@export var color_a: Color = Color(0.992, 0.323, 0.882, 1.0)  # Cake color
@export var color_b: Color = Color(0.228, 0.867, 1.0, 1.0)  # Frosting color
@export_subgroup("Stripe Shader Settings")
@export var base_stripe_count: float = 12.0
@export var stripe_width: float = 0.5
@export var stripe_density_multiplier: float = 1.3  # Match rotation_speed_multiplier for visual sync
@export var stripe_time_scale: float = 0.0  # Set >0 for shader animation preview
@export var regenerate: bool = false: set = _set_regenerate

const STRIPE_SHADER = preload("res://algorithms/transformation/carousel_cake/carousel_stripes.gdshader")

@onready var mm_inst: MultiMeshInstance3D = MultiMeshInstance3D.new()
var _rotation_angle: float = 0.0
var _collider_bodies: Array[StaticBody3D] = []

func _ready() -> void:
	generate_carousel()
	set_process(true)

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		_rotation_angle += delta
		update_carousel_rotation()

func _set_regenerate(value: bool) -> void:
	if value:
		generate_carousel()
		regenerate = false

func generate_carousel() -> void:
	_read_dna()
	# Same freed-reference story from the other end: rebuild after a teardown and
	# mm_inst is a ghost, so get_parent() below would throw instead of returning
	# null. Build a new one rather than dereference the old.
	if not is_instance_valid(mm_inst):
		mm_inst = MultiMeshInstance3D.new()
	# Clear existing multimesh instance
	if mm_inst.get_parent():
		mm_inst.get_parent().remove_child(mm_inst)

	# Clear existing colliders
	_clear_colliders()

	add_child(mm_inst)
	if Engine.is_editor_hint():
		mm_inst.owner = get_tree().edited_scene_root

	var mm := MultiMesh.new()
	mm_inst.multimesh = mm
	mm.use_colors = alternating_colors

	# Validate arrays
	if layer_radii.is_empty() or layer_heights.is_empty():
		push_error("CarouselCake: layer_radii and layer_heights cannot be empty")
		return

	var layer_count = min(layer_radii.size(), layer_heights.size())
	# PROFILE: the radii the drawn stack uses. "cake" returns layer_radii unchanged.
	_vis_radii = _profile_radii(layer_count)

	# Create base cylinder mesh (unit cylinder, will be scaled per instance)
	var cylinder := CylinderMesh.new()
	cylinder.height = 1.0  # Unit height
	cylinder.top_radius = 1.0  # Unit radius
	cylinder.bottom_radius = 1.0
	cylinder.radial_segments = base_radial_segments

	# Create material
	var mat: Material
	if use_stripe_shader:
		var shader_mat := ShaderMaterial.new()
		shader_mat.shader = STRIPE_SHADER
		shader_mat.set_shader_parameter("color_a", color_a)
		shader_mat.set_shader_parameter("color_b", color_b)
		shader_mat.set_shader_parameter("base_stripe_count", base_stripe_count)
		shader_mat.set_shader_parameter("stripe_width", stripe_width)
		shader_mat.set_shader_parameter("stripe_density_multiplier", stripe_density_multiplier)
		shader_mat.set_shader_parameter("time_scale", stripe_time_scale)
		shader_mat.set_shader_parameter("layer_count", float(layer_count))
		mat = shader_mat
	else:
		var std_mat := StandardMaterial3D.new()
		std_mat.vertex_color_use_as_albedo = true
		mat = std_mat
	cylinder.material = mat

	mm.mesh = cylinder
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true  # Enable custom data for layer index
	mm.instance_count = layer_count

	var cumulative_y: float = 0.0

	for i in range(layer_count):
		var transform := Transform3D.IDENTITY

		var current_radius: float = _vis_radii[i]
		var current_height: float = layer_heights[i]

		# Stack vertically at same XZ position (0, 0)
		# Position at center of cylinder (half height up from base)
		transform.origin.y = cumulative_y + current_height / 2.0

		# Scale the cylinder to the current radius and height
		transform.basis = transform.basis.scaled(Vector3(current_radius, current_height, current_radius))

		mm.set_instance_transform(i, transform)

		# Set layer index as custom data for shader (x = layer index)
		mm.set_instance_custom_data(i, Color(float(i), 0.0, 0.0, 1.0))

		# Set alternating colors (only used when not using stripe shader)
		if alternating_colors and not use_stripe_shader:
			var use_color_a := i % 2 == 0
			mm.set_instance_color(i, color_a if use_color_a else color_b)

		# Update cumulative height for next layer
		cumulative_y += current_height

	# Generate colliders if enabled. These read layer_radii, NOT _vis_radii: the profile
	# axis is appearance only and never changes what the player can stand on.
	if enable_colliders:
		_generate_colliders()

	# Appended LAST, so nothing above shifts. Both are no-ops on the default "cake".
	_retarget_baked_stack()
	_add_stack_anchor()

func update_carousel_rotation() -> void:
	# mm_inst is built in code and added as an OWNERLESS child, which is exactly what
	# _exit_tree queue_frees — so this reference outlives its object every time the
	# artifact leaves the tree, and _process keeps running until the free lands.
	#
	# `not mm_inst.multimesh` read a PROPERTY to decide whether to go on, and that
	# read is itself the access that throws on a freed instance ("Invalid access to
	# property or key 'multimesh' on a base object of type 'previously freed'"). The
	# test has to be on the REFERENCE, before any property is touched.
	if not is_instance_valid(mm_inst) or mm_inst.multimesh == null:
		return

	var mm := mm_inst.multimesh
	var cumulative_y: float = 0.0

	for i in range(mm.instance_count):
		# Each layer rotates at different speed (faster as you go up)
		var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
		var angle: float = _rotation_angle * layer_speed

		var current_radius: float = _vis_radii[i] if i < _vis_radii.size() else 1.0
		var current_height: float = layer_heights[i] if i < layer_heights.size() else 1.0

		# Create transform with rotation and scale
		var transform := Transform3D.IDENTITY
		transform.origin.y = cumulative_y + current_height / 2.0
		transform.basis = Basis.IDENTITY.rotated(Vector3.UP, angle)
		transform.basis = transform.basis.scaled(Vector3(current_radius, current_height, current_radius))

		mm.set_instance_transform(i, transform)

		# Update cumulative height for next layer
		cumulative_y += current_height

	# Update colliders rotation
	if enable_colliders:
		_update_colliders_rotation()

func _generate_colliders() -> void:
	var cumulative_y: float = 0.0

	for i in range(min(layer_radii.size(), layer_heights.size())):
		var current_radius: float = layer_radii[i]
		var current_height: float = layer_heights[i]

		# Create StaticBody3D
		var body := StaticBody3D.new()
		body.name = "ColliderLayer_%d" % i
		body.collision_layer = collision_layer
		body.collision_mask = collision_mask
		add_child(body)
		if Engine.is_editor_hint():
			body.owner = get_tree().edited_scene_root

		# Create CylinderShape3D
		var shape := CylinderShape3D.new()
		shape.radius = current_radius
		shape.height = current_height

		# Create CollisionShape3D
		var collision_shape := CollisionShape3D.new()
		collision_shape.shape = shape
		collision_shape.position.y = cumulative_y + current_height / 2.0
		body.add_child(collision_shape)
		if Engine.is_editor_hint():
			collision_shape.owner = get_tree().edited_scene_root

		_collider_bodies.append(body)
		cumulative_y += current_height

func _update_colliders_rotation() -> void:
	for i in range(_collider_bodies.size()):
		var body := _collider_bodies[i]
		if not is_instance_valid(body):
			continue

		# Each layer rotates at different speed
		var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
		var angle: float = _rotation_angle * layer_speed

		body.rotation.y = angle

func _clear_colliders() -> void:
	for body in _collider_bodies:
		if is_instance_valid(body):
			body.queue_free()
	_collider_bodies.clear()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# WAS `pass` — nothing a map wrote ever reached this artifact.
	# GridInteractablesComponent sets config_<key> metadata BEFORE add_child, so
	# _read_dna() inside generate_carousel() has normally already applied it; the guard
	# below makes this a no-op in that case and in every legacy one.
	if config.is_empty():
		return
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var was_profile: String = profile
	_read_dna()
	if profile != was_profile:
		generate_carousel()


# ── PROFILE ───────────────────────────────────────────────────────────────────
# Read from the map's config_<key> metadata and normalised, so an unknown word keeps the
# default rather than silently rendering as one.
func _read_dna() -> void:
	if has_meta("config_profile"):
		var p: String = str(get_meta("config_profile")).strip_edges().to_lower()
		profile = p if PROFILES.has(p) else profile


## The drawn radii for each layer. "cake" hands back layer_radii itself, so the eight
## existing placements are unchanged. Every other value keeps the same layer COUNT and the
## same heights, and tops out at the same 5 m, so only the silhouette moves.
func _profile_radii(n: int) -> Array[float]:
	var out: Array[float] = []
	match profile:
		"ziggurat":
			for i in range(n):
				out.append(lerpf(5.0, 1.0, float(i) / float(maxi(n - 1, 1))))
		"flare":
			for i in range(n):
				out.append(lerpf(1.0, 5.0, float(i) / float(maxi(n - 1, 1))))
		"column":
			for _i in range(n):
				out.append(3.0)
		"spindle":
			# wide / pinched / wide / pinched — a bobbin, two waists instead of one.
			var beads: Array[float] = [5.0, 3.0, 1.2, 3.0]
			for i in range(n):
				out.append(beads[i % beads.size()])
		_:
			# "cake" — the legacy lineage.
			for i in range(n):
				out.append(layer_radii[i] if i < layer_radii.size() else 1.0)
	return out


## THE SCENE SHIPS A SECOND, BAKED COPY OF THE STACK. carousel_cake.tscn contains a saved
## MultiMeshInstance3D holding the same eight layers (this script is @tool and once wrote
## its output into the scene), and _ready() then builds a second one on top of it. On the
## default that is invisible — two coincident stacks of identical cylinders — but a moved
## profile would leave the baked one standing as a ghost of the old cake behind the new
## shape, and the bite report would be a picture of that ghost.
##
## So on any non-default profile the baked twin is retargeted to the same radii rather than
## switched off: the frame keeps exactly the material mix it has on the default, and the
## only thing that changes between variants is the silhouette. The multimesh is DUPLICATED
## first because a .tscn sub-resource is shared between instantiations, so mutating it in
## place would make two carousel_cakes in one map fight over the profile.
##
## The duplicate stack itself is a pre-existing bug, not something this axis introduced;
## it is reported rather than quietly removed, because removing it would change what all
## eight existing placements look like.
func _retarget_baked_stack() -> void:
	# Never touched on the default until something else moved it: a cake that has been
	# swept away from "cake" and back again is written with layer_radii, which reproduces
	# the baked buffer exactly.
	if profile == "cake" and not _baked_retargeted:
		return
	_baked_retargeted = true
	for child in get_children():
		if child == mm_inst or not (child is MultiMeshInstance3D):
			continue
		var mmi := child as MultiMeshInstance3D
		if mmi.multimesh == null:
			continue
		var baked := mmi.multimesh.duplicate() as MultiMesh
		mmi.multimesh = baked
		var cumulative_y: float = 0.0
		for i in range(baked.instance_count):
			var r: float = _vis_radii[i] if i < _vis_radii.size() else 1.0
			var h: float = layer_heights[i] if i < layer_heights.size() else 1.0
			var xf := Transform3D.IDENTITY
			xf.origin.y = cumulative_y + h / 2.0
			xf.basis = xf.basis.scaled(Vector3(r, h, r))
			baked.set_instance_transform(i, xf)
			cumulative_y += h


## The capture rig fits the frame by the subtree's bounding-box DIAGONAL, and it walks the
## subtree for MeshInstance3D ONLY. This cake is nothing but MultiMeshInstance3D and
## collision shapes, so that walk finds no geometry at all and falls back to a 1 m box —
## a camera 5 m from a 10 m wide, 5.65 m tall stack, framing the middle of one layer.
##
## layers = 0, NOT visible = false: a zero-layer VisualInstance3D is in no camera's cull
## mask, draws nothing, and still reports its AABB. Sized from layer_radii and
## layer_heights, which no profile touches, so all five variants are framed identically.
## Its bottom sits exactly at y = 0 so GridInteractablesComponent._auto_ground_artifact
## reads "already grounded" and leaves the cake where it has always stood.
func _add_stack_anchor() -> void:
	if is_instance_valid(_stack_anchor):
		return
	var span: float = 0.0
	for h in layer_heights:
		span += float(h)
	var widest: float = 1.0
	for r in layer_radii:
		widest = maxf(widest, float(r))
	var anchor := MeshInstance3D.new()
	anchor.name = "StackAnchor"
	var box := BoxMesh.new()
	box.size = Vector3(widest * 2.0, maxf(span, 0.1), widest * 2.0)
	anchor.mesh = box
	anchor.position = Vector3(0.0, maxf(span, 0.1) * 0.5, 0.0)
	anchor.layers = 0
	anchor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(anchor)
	_stack_anchor = anchor
