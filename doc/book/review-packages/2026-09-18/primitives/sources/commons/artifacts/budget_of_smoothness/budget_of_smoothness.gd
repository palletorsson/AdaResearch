extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BudgetOfSmoothness

## Four sphere meshes share radius, material, spin and viewing context.
## The cost is read from the engine's triangle stream, not inferred from a formula.
const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const STEPS := [4, 8, 16, 64]
const Inspection = preload("res://commons/primitives/shared/mesh_inspection.gd")
const Casing = preload("res://commons/ui/instrument_panel_case.gd")

@export var seed: int = 55
@export var spin: float = 0.18

@export var discovery: bool = false
var _spheres: Array = []
var _tags: Array = []
var _counts: Array = []
var _wires: Array = []
var costs_visible: bool = false
var edges_visible: bool = false

func _ready() -> void:
	if has_meta("config_discovery"):
		discovery = str(get_meta("config_discovery")) in ["1","true"]
	_rng.seed = seed
	_build_counter()
	_build_wares()
	if discovery:
		_build_controls()
	else:
		_build_plaque()
	costs_visible = not discovery
	_update_tags()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("discovery"):
		discovery = str(config_data["discovery"]) in ["1","true"]
		if discovery and is_inside_tree() and not _spheres.is_empty():
			_build_controls()
			var plaque := get_node_or_null("BudgetPlate")
			if plaque: plaque.visible = false
			costs_visible = false
			_update_tags()
	for key in ["seed", "spin"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	for s in _spheres:
		s.rotation.y += spin * delta

func _build_counter() -> void:
	var counter := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(3.0, 0.85, 0.7)
	counter.mesh = cm
	counter.position = Vector3(0.0, 0.425, 0.0)
	counter.material_override = _matte_mat(Color(0.14, 0.13, 0.15), 0.85)
	add_child(counter)

func _build_wares() -> void:
	for i in range(STEPS.size()):
		var seg: int = STEPS[i]
		var mesh := SphereMesh.new()
		mesh.radius = 0.26
		mesh.height = 0.52
		mesh.radial_segments = seg
		mesh.rings = maxi(seg / 2, 2)
		var data := Inspection.inspect(mesh)
		_counts.append(data)
		var ware := MeshInstance3D.new()
		ware.mesh = mesh
		ware.position = Vector3(-1.14 + 0.76 * float(i), 1.40, 0.0)
		ware.material_override = _matte_mat(Color.from_hsv(0.55, 0.25, 0.85), 0.35, 0.15)
		add_child(ware)
		_spheres.append(ware)
		var stand := MeshInstance3D.new()
		var stem := CylinderMesh.new()
		stem.top_radius = 0.035
		stem.bottom_radius = 0.08
		stem.height = 0.29
		stand.mesh = stem
		stand.position = Vector3(ware.position.x,0.995,0)
		stand.material_override = _matte_mat(Color(0.28,0.30,0.33),0.5,0.6)
		add_child(stand)
		var wire := Inspection.overlay(mesh, data)
		wire.visible = false
		ware.add_child(wire)
		_wires.append(wire)
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.64
		tag.position = Vector3(ware.position.x, 0.86, 0.51)
		add_child(tag)
		_tags.append(tag)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "BudgetPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.75, 0.24, 0.7)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("BUDGET OF SMOOTHNESS",
			"Compare from near and far. Which sphere serves your chosen use? Counts describe these meshes, not frame time.")

func toggle_costs() -> void:
	costs_visible = not costs_visible
	_update_tags()

func toggle_edges() -> void:
	edges_visible = not edges_visible
	for wire in _wires: wire.visible = edges_visible

func _update_tags() -> void:
	for i in _tags.size():
		var mesh: SphereMesh = _spheres[i].mesh
		var body := "Choose a use.\nThen reveal the count."
		if costs_visible:
			body = "%d sides / %d rings\n%d mesh triangles\n%d with area" % [mesh.radial_segments,mesh.rings,_counts[i].submitted,_counts[i].surface_triangles]
		_tags[i].set_text("SPHERE "+str(i+1),body)

func _build_controls() -> void:
	if has_node("ExperimentPanel"): return
	var panel := Node3D.new()
	panel.name = "ExperimentPanel"
	panel.position = Vector3(0,0.42,0.43)
	add_child(panel)
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.70,0.56)
	screen.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.025,0.035,0.055)
	screen.material_override = material
	panel.add_child(screen)
	var casing := Casing.new()
	panel.add_child(casing)
	casing.fit_rect(Vector2.ZERO,quad.size,Color(0.4,0.8,1.0))
	var prompt := Label3D.new()
	prompt.text = "Which is enough? Choose before counting."
	prompt.font_size = 32
	prompt.pixel_size = 0.0015
	prompt.position = Vector3(0,0.19,0.006)
	panel.add_child(prompt)
	for item in [["CostButton","SHOW / HIDE COUNTS",-0.43,toggle_costs],["EdgeButton","SHOW / HIDE EDGES",0.43,toggle_edges]]:
		var button: Node3D = preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = item[0]
		button.position = Vector3(item[2],-0.15,0.035)
		button.pressed.connect(item[3])
		panel.add_child(button)
		var label := Label3D.new()
		label.text = item[1]
		label.font_size = 28
		label.pixel_size = 0.0015
		label.position = Vector3(item[2],-0.055,0.006)
		panel.add_child(label)
