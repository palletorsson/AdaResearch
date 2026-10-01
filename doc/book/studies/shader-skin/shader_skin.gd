extends Node3D

const Look := preload("res://supplied/look.gd")
const Member := preload("res://parts/member.gd")
const POWERS := [0.5, 1.0, 3.0, 8.0]   # the axis: four exponents for the rim

@export_range(0.25, 8.0) var rim_power := 3.0   # the rim's exponent
@export_range(0.0, 1.0) var drift := 0.1        # how many bands a second the stripes crawl

var material := ShaderMaterial.new()

func _ready() -> void:
	var member: MeshInstance3D = Member.make(64)
	add_child(member)
	material.shader = load("res://skin.gdshader")
	member.material_override = material
	material.set_shader_parameter("body_colour", Look.BODY)
	material.set_shader_parameter("band_colour", Look.SHADE)
	material.set_shader_parameter("rim_colour", Look.SECOND)
	material.set_shader_parameter("drift", drift)
	material.set_shader_parameter("rim_power", rim_power)
	print("the member wears ", material.get_class(), " with ", material.shader.get_shader_uniform_list().size(), " uniforms; rim_power ", material.get_shader_parameter("rim_power"))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		rim_power = POWERS[(POWERS.find(rim_power) + 1) % POWERS.size()]
		material.set_shader_parameter("rim_power", rim_power)
		print("rim_power ", rim_power)
