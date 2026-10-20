# city_horizon.gd
# Lightweight distant context: one instanced silhouette mesh, no physics.
extends MultiMeshInstance3D
var material: ShaderMaterial

func _ready() -> void:
	name = "DistantCity"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader := Shader.new()
	# The tower's fog is complete at 30 m. These distant silhouettes belong
	# to the horizon layer and carry their own restrained haze colour.
	shader.code = "shader_type spatial; render_mode unshaded, fog_disabled; uniform vec4 haze: source_color; varying float height; void vertex(){height=VERTEX.y+0.5;} void fragment(){ALBEDO=haze.rgb; ALPHA=0.72*smoothstep(0.0,0.72,height);}"
	material = ShaderMaterial.new()
	material.shader = shader
	material_override = material
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = BoxMesh.new()
	instances.instance_count = 72
	multimesh = instances
	var random := RandomNumberGenerator.new()
	random.seed = 170418
	for i in range(instances.instance_count):
		var angle := float(i) / instances.instance_count * TAU
		var radius := random.randf_range(150, 245)
		var height := random.randf_range(22, 67)
		if i % 13 == 0: height += 22
		var size := Vector3(random.randf_range(9, 19), height, random.randf_range(9, 20))
		var at := Vector3(cos(angle)*radius, -92 + height/2, sin(angle)*radius)
		instances.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(size), at))
	set_haze(Color("d4b5cf"))

func set_haze(colour: Color) -> void:
	if material != null: material.set_shader_parameter("haze", colour.lerp(Color("555367"), 0.23))
