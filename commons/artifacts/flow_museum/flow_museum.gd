extends Node3D
## Bounded live view of the existing field. Keep its physics in its own world.
var viewport: SubViewport
var flow: Node3D
var screen: MeshInstance3D
var caption: Label3D
var pending_config := {}

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(1024,1024)
	viewport.own_world_3d = true
	viewport.world_3d = World3D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	flow = preload("res://algorithms/pathfinding/flow_field/FlowFieldMain.tscn").instantiate()
	viewport.add_child(flow)
	if not pending_config.is_empty(): flow.apply_grid_config(pending_config)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 46.0
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
	screen.position.y = .94
	add_child(screen)
	box(Vector3(2.95,.12,2.95),Vector3(0,.87,0))
	box(Vector3(.8,.8,.8),Vector3(0,.4,0))
	caption = Label3D.new()
	caption.position = Vector3(0,1.55,-1.35)
	caption.font_size = 30
	caption.pixel_size = .002
	add_child(caption)

func _process(_delta: float) -> void:
	if flow != null:
		var modes := ["OPEN", "BLOCK", "U WALL", "ZIGZAG", "WIND", "NOISE"]
		caption.text = "FLOW / " + modes[flow.sequence_mode] + "\n%d agents / live field, viewed from above" % flow.agents.size()

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
	if flow != null: flow.apply_grid_config(config)
