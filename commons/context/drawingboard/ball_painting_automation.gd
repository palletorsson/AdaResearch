extends Node3D
## The same drawing surface accepts authored machine strokes and hand strokes.
var automated := false
var elapsed := 0.0
var clock_accum := 0.0
var strokes := 0
var previous := Vector2(-1,-1)
var surface: MeshInstance3D
var pigment: MeshInstance3D

func _ready() -> void:
	automated = str(get_meta("config_automated", "false")) in ["true","1","yes"]
	surface = get_node("DrawingArea3D/PaperDrawSurface")
	set_process(automated)
	if automated: _build_brush()

func apply_grid_config(config: Dictionary) -> void:
	if str(config.get("automated", "false")) in ["true","1","yes"] and not automated:
		automated = true
		if is_node_ready(): _build_brush(); set_process(true)

func _build_brush() -> void:
	if is_instance_valid(pigment): return
	var tray := MeshInstance3D.new()
	tray.name = "PigmentTray"
	var tray_mesh := BoxMesh.new()
	tray_mesh.size = Vector3(2.9, 0.06, 0.58)
	tray.mesh = tray_mesh
	tray.position = Vector3(0, 0.61, 1.275)
	var tray_mat := StandardMaterial3D.new()
	tray_mat.albedo_color = Color("dfcfbf")
	tray.material_override = tray_mat
	add_child(tray)
	tray.create_convex_collision()
	for x in [-1.2, 1.2]:
		var leg := MeshInstance3D.new()
		leg.name = "PigmentTrayLeg"
		var leg_mesh := BoxMesh.new()
		leg_mesh.size = Vector3(0.06, 1.11, 0.08)
		leg.mesh = leg_mesh
		leg.material_override = tray_mat
		leg.position = Vector3(x, 0.055, 1.275)
		add_child(leg)
		leg.create_convex_collision()
	pigment = MeshInstance3D.new(); pigment.name = "AutomatedPigmentBall"
	var mesh := SphereMesh.new(); mesh.radius = 0.085; mesh.height = 0.17
	pigment.mesh = mesh; pigment.material_override = StandardMaterial3D.new(); add_child(pigment)
	# Scene-owned preview lighting/camera must not replace the museum environment.
	for n in ["WorldEnvironment","Camera3D","DirectionalLight3D"]:
		var child := get_node_or_null(n)
		if child: remove_child(child); child.queue_free()

func _process(delta: float) -> void:
	elapsed += delta; clock_accum += delta
	if clock_accum < 1.0/30.0 or not is_instance_valid(surface): return
	clock_accum = 0.0
	var uv := Vector2(0.5+0.43*sin(elapsed*0.71),0.5+0.4*sin(elapsed*1.13+0.6))
	var color := Color.from_hsv(fposmod(elapsed*0.035,1.0),0.85,0.95)
	surface.draw_line(previous,uv,color,12,256)
	previous = uv; strokes += 1
	pigment.global_position = surface.to_global(Vector3((uv.x-0.5)*4.0,0.09,(uv.y-0.5)*2.5))
	pigment.material_override.albedo_color = color
