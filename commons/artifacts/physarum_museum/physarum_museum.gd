extends Node3D
## Display adapter: the original 50 m colony keeps its own simulation world.
## This wrapper changes presentation only; a frame is not an optimisation proof.
var viewport: SubViewport
var colony: Node3D
var screen: MeshInstance3D
var caption: Label3D
var pending_config := {}

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(768,768)
	viewport.own_world_3d = true
	viewport.world_3d = World3D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	colony = preload("res://algorithms/swarmintelligence/physarum/PhysarumColony.tscn").instantiate()
	var relief: MeshInstance3D = colony.get_node("ResultMesh")
	relief.set_surface_override_material(0, relief.get_active_material(0).duplicate())
	viewport.add_child(colony)
	if not pending_config.is_empty(): colony.apply_grid_config(pending_config)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 54.0
	camera.position = Vector3(0,60,0)
	camera.rotation_degrees = Vector3(-90,0,0)
	camera.current = true
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	screen = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.8,2.8)
	screen.mesh = plane
	screen.material_override = material
	screen.position.y = 0.94
	add_child(screen)
	box(Vector3(2.95,0.12,2.95),Vector3(0,.87,0))
	box(Vector3(.8,.80,.8),Vector3(0,.4,0))
	caption = Label3D.new()
	caption.position = Vector3(0,1.55,-1.35)
	caption.font_size = 32
	caption.pixel_size = .002
	add_child(caption)
	set_process(true)

func _process(_delta: float) -> void:
	if colony != null:
		caption.text = "PHYSARUM / " + str(colony.CAROUSEL[colony.dist_mode]).to_upper() + "\n%d points / live colony, viewed from above" % colony.num_agents

func box(size: Vector3, at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("30333b")
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func apply_grid_config(config: Dictionary) -> void:
	pending_config.merge(config,true)
	if colony != null:
		colony.apply_grid_config(config)
