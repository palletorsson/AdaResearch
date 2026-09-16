extends Node3D
## A small companion to the axis/rotation demonstrations: uniform scale about a fixed centre.
const GRID_SHADER = preload("res://commons/resourses/shaders/Grid.gdshader")
var body: MeshInstance3D
var readout: Label3D
var elapsed := 0.0
var motion_curve := "sine"

func _ready() -> void:
	motion_curve = str(get_meta("config_motion_curve", "sine"))
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.3
	body = MeshInstance3D.new()
	body.name = "ScalingCube"
	body.mesh = box
	var material := ShaderMaterial.new()
	material.shader = GRID_SHADER
	material.set_shader_parameter("modelColor",Color(0.08,0.08,0.2))
	material.set_shader_parameter("wireframeColor",Color(0.7,0.55,1))
	material.set_shader_parameter("emissionColor",Color(0.7,0.55,1))
	material.set_shader_parameter("emission_strength",0.4)
	material.set_shader_parameter("width",3.0)
	material.set_shader_parameter("show_interior",true)
	body.material_override = material
	add_child(body)
	# Fixed maximum-size cage lets growth be compared with something that does not grow.
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	var r := 0.195
	for axis in range(3):
		for a in [-1,1]:
			for b in [-1,1]:
				var p := Vector3.ZERO
				p[axis]=-r
				p[(axis+1)%3]=a*r
				p[(axis+2)%3]=b*r
				lines.surface_add_vertex(p)
				p[axis]=r
				lines.surface_add_vertex(p)
	lines.surface_end()
	var cage := MeshInstance3D.new()
	cage.name = "FixedReference"
	cage.mesh=lines
	var ink := StandardMaterial3D.new()
	ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color=Color(0.45,0.48,0.6)
	cage.material_override=ink
	add_child(cage)
	readout=Label3D.new()
	readout.name="ScaleReadout"
	readout.font_size=48
	readout.pixel_size=0.0015
	readout.position.y=0.38
	readout.modulate=Color(0.85,0.8,1)
	add_child(readout)
	var caption := Label3D.new()
	caption.text="UNIFORM SCALE\n0.7x — 1.3x"
	caption.font_size=38
	caption.pixel_size=0.0015
	caption.position.y=-0.35
	add_child(caption)
	_process(0.0)

func _process(delta: float) -> void:
	elapsed += delta
	var factor: float
	if motion_curve == "lerp":
		factor = lerp(0.7, 1.3, pingpong(elapsed / 1.5 + 0.5, 1.0))
	else:
		factor = 1.0 + 0.3 * sin(2.0 * elapsed)
	body.scale=Vector3.ONE*factor
	readout.text="size x %.2f"%factor

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("motion_curve"):
		motion_curve = str(config_data["motion_curve"])
