extends Node3D
class_name SpinePortal

## Spine Portal — walk into this to enter corridor mode.
##
## Fires VRStaging's request_load_scene signal, targeting the spine runner
## scene. VRStaging handles the transition fade + XR viewport setup, so we
## go through the proper staging machinery (no main_scene hack needed).
##
## Place in any map's interactables layer as `spine_portal:0:0`.

@export var target_scene: String = "res://commons/scenes/vr_spine_runner.tscn"
@export var portal_color: Color = Color(0.95, 0.70, 0.20)
@export var trigger_radius: float = 0.8

var _triggered: bool = false
var _label: Label3D


func _ready() -> void:
	_build_visual()
	_build_trigger()


func _build_visual() -> void:
	# Glowing pillar of light
	var pillar := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.3
	cyl.height = 3.0
	cyl.radial_segments = 24
	pillar.mesh = cyl
	pillar.position = Vector3(0, 1.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(portal_color.r, portal_color.g, portal_color.b, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = portal_color
	mat.emission_energy_multiplier = 2.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pillar.material_override = mat
	add_child(pillar)

	# Ring base
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.5
	torus.outer_radius = 0.65
	ring.mesh = torus
	ring.position = Vector3(0, 0.06, 0)
	ring.material_override = mat
	add_child(ring)

	# Label
	_label = Label3D.new()
	_label.text = "SPINE CORRIDOR\nstep in to enter"
	_label.font_size = 36
	_label.outline_size = 6
	_label.modulate = portal_color
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 3.3, 0)
	add_child(_label)


func _build_trigger() -> void:
	var area := Area3D.new()
	area.name = "PortalTrigger"
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = trigger_radius
	shape.shape = sph
	area.add_child(shape)
	area.position = Vector3(0, 1.0, 0)
	# Match layer to xr-tools player body
	area.collision_layer = 0
	area.collision_mask = 1 | (1 << 19)   # player_body layer (xr-tools uses bit 20 = 524288)
	area.monitoring = true
	area.body_entered.connect(_on_body_entered)
	add_child(area)


func _on_body_entered(body: Node) -> void:
	if _triggered: return
	# Only react to the player
	if not body.is_in_group("player_body") and body.name != "PlayerBody":
		return
	_triggered = true
	_label.text = "ENTERING CORRIDOR..."
	print("SpinePortal: entering corridor mode → %s" % target_scene)
	_request_scene_load()


func _request_scene_load() -> void:
	# Walk up the tree to find XRToolsSceneBase (the current scene root)
	# and emit its request_load_scene signal. VRStaging listens and handles
	# the transition.
	var scene_root: Node = _find_scene_base()
	if scene_root == null:
		push_error("SpinePortal: no XRToolsSceneBase ancestor found")
		return
	if not scene_root.has_signal("request_load_scene"):
		push_error("SpinePortal: scene root missing request_load_scene signal")
		return
	scene_root.emit_signal("request_load_scene", target_scene, null)


func _find_scene_base() -> Node:
	var n: Node = self
	while n != null:
		if n.has_signal("request_load_scene"):
			return n
		n = n.get_parent()
	return null


func apply_grid_config(config: Dictionary) -> void:
	if config.has("target_scene"):
		target_scene = str(config["target_scene"])
	if config.has("portal_color") and config["portal_color"] is Array:
		var a: Array = config["portal_color"]
		if a.size() >= 3:
			portal_color = Color(float(a[0]), float(a[1]), float(a[2]))
