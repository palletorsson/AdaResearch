extends RefCounted
## Shared machine finish: black structure, pink touch surfaces, outlined ivory subjects.
const LineStyle = preload("res://commons/primitives/line/museum_line_style.gd")
const PINK = LineStyle.PINK
const IVORY = LineStyle.WHITE
const STEEL := Color("191d26")
static var _edge_mesh: ArrayMesh

static func steel() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = STEEL;mat.metallic = .82;mat.roughness = .28
	return mat

static func pink() -> StandardMaterial3D:return LineStyle.pink()
static func ivory() -> StandardMaterial3D:return LineStyle.white()

static func outline(subject: MeshInstance3D, edge: float) -> void:
	if _edge_mesh == null:
		# Twelve box edges merged into one surface, rather than twelve nodes
		# or a screen-space outline pass for every cube.
		var surface := SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for axis in 3:
			for a in [-1,1]:
				for b in [-1,1]:
					var size := Vector3.ONE*.014;size[axis] = 1.014
					var at := Vector3.ZERO;at[(axis+1)%3] = a*.5;at[(axis+2)%3] = b*.5
					var bar := BoxMesh.new();bar.size = size
					surface.append_from(bar,0,Transform3D(Basis.IDENTITY,at))
		_edge_mesh = surface.commit()
	var lines := MeshInstance3D.new();lines.name = "AbstractOutline"
	lines.mesh = _edge_mesh;lines.scale = Vector3.ONE*edge
	var mat := StandardMaterial3D.new();mat.albedo_color = Color("171922");mat.roughness = .8
	lines.material_override = mat;subject.add_child(lines)

static func console_finish(console: Node3D) -> void:
	console.get_node("Case").material_override = steel()
	console.get_node("Face").material_override = ivory()
	for slider in console.sliders:
		if not is_instance_valid(slider):continue
		slider.get_node("Bezel").material_override = steel()
		slider.get_node("Face/Panel").material_override = ivory()
		slider.get_node("SliderOrigin/Track/Cap").material_override = pink()
		slider.get_node("SliderOrigin/Track/Index").material_override = steel()
	for button in console.buttons:
		button.released_color = PINK.darkened(.3);button.selected_color = PINK
		button.pressed_color = IVORY;button.update_colors()
