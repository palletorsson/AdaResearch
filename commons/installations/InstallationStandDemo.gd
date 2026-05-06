extends Node3D

const DEFAULT_LAYOUT := {
	"unit_m": 1.0,
	"metal_color": [0.76, 0.79, 0.83, 1.0],
	"dark_color": [0.08, 0.09, 0.11, 1.0],
	"accent_color": [0.98, 0.60, 0.18, 1.0],
	"screen_color": [0.04, 0.12, 0.15, 1.0],
	"light_color": [1.0, 0.92, 0.78, 1.0],
	"floor_color": [0.14, 0.15, 0.17, 1.0],
}

@export var auto_build: bool = true

var installation_info: Dictionary = {}
var layout: Dictionary = DEFAULT_LAYOUT.duplicate(true)
var frame: Dictionary = {}
var platform: Dictionary = {}
var shelves: Array = []
var screens: Array = []
var speakers: Array = []
var lights: Array = []
var panels: Array = []
var boxes: Array = []


func _ready() -> void:
	if not auto_build:
		return
	_build()


func load_installation_config_from_dict(data: Dictionary) -> void:
	installation_info = data.get("installation_info", {})
	layout = DEFAULT_LAYOUT.duplicate(true)
	if data.has("layout") and data["layout"] is Dictionary:
		for key in data["layout"]:
			layout[key] = data["layout"][key]
	frame = data.get("frame", {})
	platform = data.get("platform", {})
	shelves = (data.get("shelves", []) as Array).duplicate(true)
	screens = (data.get("screens", []) as Array).duplicate(true)
	speakers = (data.get("speakers", []) as Array).duplicate(true)
	lights = (data.get("lights", []) as Array).duplicate(true)
	panels = (data.get("panels", []) as Array).duplicate(true)
	boxes = (data.get("boxes", []) as Array).duplicate(true)


func _build() -> void:
	_build_platform()
	_build_frame()
	_build_shelves()
	_build_screens()
	_build_speakers()
	_build_lights()
	_build_panels()
	_build_boxes()


func _build_platform() -> void:
	if platform.is_empty():
		return
	var width: float = float(platform.get("width", 2.0))
	var depth: float = float(platform.get("depth", 1.0))
	var height: float = float(platform.get("height", 0.14))
	var y: float = float(platform.get("y", height * 0.5))
	_add_box(
		"Platform",
		Vector3(width, height, depth),
		Vector3(float(platform.get("x", 0.0)), y, float(platform.get("z", 0.0))),
		_color_from_value(layout.get("floor_color"), Color(0.14, 0.15, 0.17))
	)


func _build_frame() -> void:
	var metal := _metal_material()
	for i in range((frame.get("uprights", []) as Array).size()):
		var upright: Dictionary = frame["uprights"][i]
		var height: float = float(upright.get("height", 2.0))
		var thickness: float = float(upright.get("thickness", 0.10))
		var node := MeshInstance3D.new()
		node.name = "Upright_%d" % i
		var mesh := BoxMesh.new()
		mesh.size = Vector3(thickness, height, thickness)
		node.mesh = mesh
		node.material_override = metal
		node.position = Vector3(
			float(upright.get("x", 0.0)),
			float(upright.get("y", height * 0.5)),
			float(upright.get("z", 0.0))
		)
		add_child(node)

	for i in range((frame.get("beams", []) as Array).size()):
		var beam: Dictionary = frame["beams"][i]
		var size := Vector3(
			float(beam.get("width", 1.0)),
			float(beam.get("thickness", 0.10)),
			float(beam.get("depth", 0.10))
		)
		_add_box(
			"Beam_%d" % i,
			size,
			Vector3(float(beam.get("x", 0.0)), float(beam.get("y", 1.0)), float(beam.get("z", 0.0))),
			_color_from_value(layout.get("metal_color"), Color(0.76, 0.79, 0.83))
		)

	for i in range((frame.get("braces", []) as Array).size()):
		var brace: Dictionary = frame["braces"][i]
		var height: float = float(brace.get("height", 1.5))
		var thickness: float = float(brace.get("thickness", 0.04))
		var node := MeshInstance3D.new()
		node.name = "Brace_%d" % i
		var mesh := BoxMesh.new()
		mesh.size = Vector3(thickness, height, thickness)
		node.mesh = mesh
		node.material_override = metal
		node.position = Vector3(float(brace.get("x", 0.0)), float(brace.get("y", height * 0.5)), float(brace.get("z", 0.0)))
		node.rotation_degrees = Vector3(float(brace.get("rot_x", 0.0)), float(brace.get("rot_y", 0.0)), float(brace.get("rot_z", 18.0)))
		add_child(node)


func _build_shelves() -> void:
	var metal := _metal_material()
	for i in range(shelves.size()):
		var shelf: Dictionary = shelves[i]
		var width: float = float(shelf.get("width", 1.0))
		var depth: float = float(shelf.get("depth", 0.5))
		var thickness: float = float(shelf.get("thickness", 0.06))
		var node := MeshInstance3D.new()
		node.name = "Shelf_%d" % i
		var mesh := BoxMesh.new()
		mesh.size = Vector3(width, thickness, depth)
		node.mesh = mesh
		node.material_override = metal
		node.position = Vector3(float(shelf.get("x", 0.0)), float(shelf.get("y", 1.0)), float(shelf.get("z", 0.0)))
		add_child(node)


func _build_screens() -> void:
	var bezel := _dark_material()
	var screen_mat := _screen_material()
	for i in range(screens.size()):
		var screen: Dictionary = screens[i]
		var width: float = float(screen.get("width", 1.0))
		var height: float = float(screen.get("height", 0.6))
		var depth: float = float(screen.get("depth", 0.08))
		var frame_thickness: float = float(screen.get("frame", 0.08))
		var center := Vector3(float(screen.get("x", 0.0)), float(screen.get("y", 1.2)), float(screen.get("z", 0.0)))
		var bezel_node := MeshInstance3D.new()
		bezel_node.name = "ScreenBezel_%d" % i
		var bezel_mesh := BoxMesh.new()
		bezel_mesh.size = Vector3(width + frame_thickness * 2.0, height + frame_thickness * 2.0, depth)
		bezel_node.mesh = bezel_mesh
		bezel_node.material_override = bezel
		bezel_node.position = center
		add_child(bezel_node)

		var screen_node := MeshInstance3D.new()
		screen_node.name = "Screen_%d" % i
		var screen_mesh := BoxMesh.new()
		screen_mesh.size = Vector3(width, height, depth * 0.4)
		screen_node.mesh = screen_mesh
		screen_node.material_override = screen_mat
		screen_node.position = center + Vector3(0, 0, depth * 0.16)
		add_child(screen_node)
	if screens.is_empty():
		return


func _build_speakers() -> void:
	var dark := _dark_material()
	for i in range(speakers.size()):
		var spec: Dictionary = speakers[i]
		var modules: int = int(spec.get("modules", 1))
		var width: float = float(spec.get("width", 0.35))
		var height: float = float(spec.get("height", 0.40))
		var depth: float = float(spec.get("depth", 0.35))
		var gap: float = float(spec.get("gap", 0.03))
		var total_h: float = modules * height + maxf(0.0, float(modules - 1)) * gap
		for j in range(modules):
			var node := MeshInstance3D.new()
			node.name = "Speaker_%d_%d" % [i, j]
			var mesh := BoxMesh.new()
			mesh.size = Vector3(width, height, depth)
			node.mesh = mesh
			node.material_override = dark
			var y_base: float = float(spec.get("y", total_h * 0.5))
			var y_pos: float = y_base - total_h * 0.5 + height * 0.5 + j * (height + gap)
			node.position = Vector3(float(spec.get("x", 0.0)), y_pos, float(spec.get("z", 0.0)))
			add_child(node)


func _build_lights() -> void:
	var housing := _dark_material()
	var glow := _light_material()
	for i in range(lights.size()):
		var light_def: Dictionary = lights[i]
		if light_def.has("count"):
			var count: int = int(light_def.get("count", 4))
			var width: float = float(light_def.get("width", 2.0))
			var y: float = float(light_def.get("y", 2.5))
			var z: float = float(light_def.get("z", 0.0))
			var start_x: float = float(light_def.get("x", 0.0)) - width * 0.5
			for j in range(count):
				var t := 0.5 if count <= 1 else float(j) / float(count - 1)
				_add_light_can(
					"Light_%d_%d" % [i, j],
					Vector3(lerpf(start_x, start_x + width, t), y, z),
					housing,
					glow
				)
		else:
			_add_light_can(
				"Light_%d" % i,
				Vector3(float(light_def.get("x", 0.0)), float(light_def.get("y", 2.5)), float(light_def.get("z", 0.0))),
				housing,
				glow
			)


func _add_light_can(name: String, pos: Vector3, housing: StandardMaterial3D, glow: StandardMaterial3D) -> void:
	var body := MeshInstance3D.new()
	body.name = "%s_Body" % name
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.06
	body_mesh.bottom_radius = 0.05
	body_mesh.height = 0.10
	body_mesh.radial_segments = 16
	body.mesh = body_mesh
	body.material_override = housing
	body.rotation_degrees.x = 90.0
	body.position = pos
	add_child(body)

	var lens := MeshInstance3D.new()
	lens.name = "%s_Lens" % name
	var lens_mesh := CylinderMesh.new()
	lens_mesh.top_radius = 0.045
	lens_mesh.bottom_radius = 0.045
	lens_mesh.height = 0.018
	lens_mesh.radial_segments = 16
	lens.mesh = lens_mesh
	lens.material_override = glow
	lens.rotation_degrees.x = 90.0
	lens.position = pos + Vector3(0, 0, 0.04)
	add_child(lens)


func _build_panels() -> void:
	var panel_mat := _panel_material()
	for i in range(panels.size()):
		var panel: Dictionary = panels[i]
		var node := MeshInstance3D.new()
		node.name = "Panel_%d" % i
		var mesh := BoxMesh.new()
		mesh.size = Vector3(float(panel.get("width", 0.18)), float(panel.get("height", 1.0)), float(panel.get("depth", 0.08)))
		node.mesh = mesh
		node.material_override = panel_mat
		node.position = Vector3(float(panel.get("x", 0.0)), float(panel.get("y", 2.0)), float(panel.get("z", 0.0)))
		add_child(node)


func _build_boxes() -> void:
	var metal := _metal_material()
	for i in range(boxes.size()):
		var box_def: Dictionary = boxes[i]
		var node := MeshInstance3D.new()
		node.name = "Box_%d" % i
		var mesh := BoxMesh.new()
		mesh.size = Vector3(float(box_def.get("width", 0.4)), float(box_def.get("height", 0.3)), float(box_def.get("depth", 0.3)))
		node.mesh = mesh
		node.material_override = metal
		node.position = Vector3(float(box_def.get("x", 0.0)), float(box_def.get("y", 0.5)), float(box_def.get("z", 0.0)))
		add_child(node)


func _add_box(name: String, size: Vector3, center: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.35
	mat.roughness = 0.55
	node.material_override = mat
	node.position = center
	add_child(node)


func _metal_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color_from_value(layout.get("metal_color"), Color(0.76, 0.79, 0.83))
	mat.metallic = 0.85
	mat.roughness = 0.25
	return mat


func _dark_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color_from_value(layout.get("dark_color"), Color(0.08, 0.09, 0.11))
	mat.metallic = 0.15
	mat.roughness = 0.82
	return mat


func _screen_material() -> StandardMaterial3D:
	var color := _color_from_value(layout.get("screen_color"), Color(0.04, 0.12, 0.15))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color.lightened(0.35)
	mat.emission_energy_multiplier = 0.9
	mat.metallic = 0.0
	mat.roughness = 0.12
	return mat


func _light_material() -> StandardMaterial3D:
	var color := _color_from_value(layout.get("light_color"), Color(1.0, 0.92, 0.78))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.3
	mat.metallic = 0.0
	mat.roughness = 0.1
	return mat


func _panel_material() -> StandardMaterial3D:
	var color := _color_from_value(layout.get("accent_color"), Color(0.98, 0.60, 0.18))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.2
	mat.roughness = 0.48
	return mat


func _color_from_value(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is Array:
		var c: Array = value
		if c.size() >= 3:
			return Color(float(c[0]), float(c[1]), float(c[2]), float(c[3]) if c.size() > 3 else 1.0)
	return fallback

