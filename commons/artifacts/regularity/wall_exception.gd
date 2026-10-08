extends Node3D
## A hinged part of the actual museum enclosure, with a floored return outside.
## The map declares the cells it replaces; the museum omits both wall layers there.
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
const PUSH = preload("res://commons/interactables/push_button.tscn")
const WALL_HEIGHT = preload("res://commons/scenes/em/em_detail.gd").WALL_H
var hinge: AnimatableBody3D
var clearance: Area3D
var turn_button: Node3D
var caption: Label3D
var face: MeshInstance3D
var study: Node3D
var open := false
var moving := false
var angle := 0.0

func _ready() -> void:
	# Coordinates relative to map cell (20,25): hinge at x20.5,z25.
	# The ordinary hall floor stops at x21. This landing starts just before it.
	Kit.box(self,"OutsideLanding",Vector3(2.45,-0.10,0.5),Vector3(4.1,0.2,4.0),Color(0.40,0.40,0.40))
	_make_rail(Vector3(4.42,0,0.5),Vector3(0.05,1,4.0))
	_make_rail(Vector3(3.0,0,-1.5),Vector3(2.9,1,0.05))
	_make_rail(Vector3(3.0,0,2.5),Vector3(2.9,1,0.05))
	# Thin stationary returns seal the gap between the map wall and outer skin.
	for z in [-0.53,1.53]:
		Kit.box(self,"Return",Vector3(0.5,WALL_HEIGHT/2,z),Vector3(1.15,WALL_HEIGHT,0.06),Color(0.86,0.85,0.82))
	hinge = AnimatableBody3D.new()
	hinge.name = "TurningWall"
	hinge.position = Vector3(0,0,-0.5)
	hinge.sync_to_physics = true
	add_child(hinge)
	Kit.box(hinge,"Paper",Vector3(0,WALL_HEIGHT/2,1),Vector3(0.025,WALL_HEIGHT,1.98),Color(0.92,0.91,0.87),false)
	var shape := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(0.025,WALL_HEIGHT,1.98)
	shape.shape = slab; shape.position = Vector3(0,WALL_HEIGHT/2,1)
	hinge.add_child(shape)
	face = Kit.textured_plane(hinge,"PatternFace",Vector2(1.94,WALL_HEIGHT-0.06),Vector3(-0.014,WALL_HEIGHT/2,1),Vector3(0,-90,0),null)
	# Only the inside is printed. The reverse remains a plain, finite sheet.
	(face.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_BACK
	for y in [0.25,2.1,4.1]:
		Kit.box(self,"Hinge",Vector3(0,y,-0.5),Vector3(0.085,0.13,0.085),Color(0.24,0.24,0.24),false)
	Kit.box(self,"ButtonStand",Vector3(-1.25,0.48,0.35),Vector3(0.42,0.96,0.55),Color(0.24,0.24,0.24))
	turn_button = PUSH.instantiate()
	turn_button.name = "TurnWallButton"
	turn_button.position = Vector3(-1.25,0.975,0.35)
	turn_button.rotation = Vector3.ZERO
	turn_button.scale = Vector3.ONE * 1.6
	turn_button.released_color = Color(0.8,0.8,0.8)
	turn_button.pressed_color = Color.WHITE
	add_child(turn_button)
	turn_button.pressed.connect(turn_wall)
	caption = Kit.label(self,"TURN WALL",Vector3(-1.25,1.40,0.35),-90)
	caption.font_size = 24; caption.pixel_size = 0.0017
	clearance = Area3D.new()
	clearance.name = "OccupiedLanding"
	clearance.collision_layer = 0; clearance.collision_mask = 0xFFFFFFFF
	var volume := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(5.1,3.0,4.6)
	volume.shape = bounds; volume.position = Vector3(2.05,1.4,0.5)
	clearance.add_child(volume); add_child(clearance)
	_bind_pattern.call_deferred()

func _make_rail(at: Vector3, size_: Vector3) -> void:
	# Glass is a visible boundary of this small authored landing, not infinite ground.
	var glass := Kit.box(self,"LandingGlass",at+Vector3(0,0.58,0),size_,Color(0.75,0.85,0.9,0.14))
	var mat := glass.material_override as StandardMaterial3D
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rail := Vector3(size_.x,0.035,size_.z)
	Kit.box(self,"Handrail",at+Vector3(0,1.10,0),rail,Color(0.65,0.65,0.65),false)

func _find_study(node: Node) -> Node3D:
	if node.has_method("texture_for") and node.has_signal("patterns_changed"): return node as Node3D
	for child in node.get_children():
		var found := _find_study(child)
		if found != null: return found
	return null

func _bind_pattern() -> void:
	study = _find_study(Kit.room_root(self))
	if study == null: return
	study.patterns_changed.connect(_refresh_pattern)
	_refresh_pattern()

func _refresh_pattern() -> void:
	# Share the very same texture as ONE EXCEPTION; moving the sheet changes no pixel.
	face.material_override.albedo_texture = study.surfaces[5].material_override.albedo_texture

func occupied() -> bool:
	for body in clearance.get_overlapping_bodies():
		if body is CharacterBody3D or body.is_in_group("player") or body.is_in_group("xr_player"):
			return true
	return false

func turn_wall() -> void:
	if moving: return
	if occupied():
		caption.text = "RETURN INSIDE\nBEFORE TURNING"
		return
	open = not open
	moving = true
	caption.text = "TURNING"

func _physics_process(delta: float) -> void:
	if not moving: return
	if occupied():
		caption.text = "STEP CLEAR\nOF THE WALL"
		return
	var target := PI/2.0 if open else 0.0
	angle = move_toward(angle,target,delta*PI/5.0)
	hinge.rotation.y = angle
	if is_equal_approx(angle,target):
		moving = false
		caption.text = "TURN WALL"

func apply_grid_config(_config: Dictionary) -> void:
	pass
