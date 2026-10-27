extends Node3D
## Temporary visible cover. The same expanding radius blocks sentry sight.
const DURATION := 8.0
const MAX_RADIUS := 2.4
var age := 0.0
var radius := 0.0
var material: StandardMaterial3D
var puffs: Array[MeshInstance3D] = []

func _ready() -> void:
	add_to_group("void_smoke_cloud")
	# Bound transparent overdraw on the headset; an expired cloud stops blocking too.
	var clouds := get_tree().get_nodes_in_group("void_smoke_cloud")
	if clouds.size() > 3:
		clouds[0].remove_from_group("void_smoke_cloud")
		clouds[0].queue_free()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0,0.5,1.0])
	gradient.colors = PackedColorArray([Color(0.64,0.65,0.71,0.8),Color(0.57,0.58,0.64,0.55),Color(0.57,0.58,0.64,0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient=gradient; texture.width=64; texture.height=64
	texture.fill=GradientTexture2D.FILL_RADIAL
	texture.fill_from=Vector2(0.5,0.5); texture.fill_to=Vector2(1.0,0.5)
	material=StandardMaterial3D.new()
	material.albedo_texture=texture
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
	material.no_depth_test=false
	for i in range(12):
		var puff := MeshInstance3D.new()
		var mesh := QuadMesh.new(); mesh.size=Vector2.ONE*2.7
		puff.mesh=mesh; puff.material_override=material
		puff.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(puff); puffs.append(puff)
	_update_cloud()

func blocks_segment(a: Vector3,b: Vector3) -> bool:
	if age >= DURATION-0.5 or radius < 0.2 or is_queued_for_deletion(): return false
	var ab := b-a
	var t := clampf((global_position-a).dot(ab)/maxf(ab.length_squared(),0.001),0,1)
	return (a+ab*t).distance_to(global_position) < radius

func _process(delta: float) -> void:
	age+=delta
	if age >= DURATION:
		queue_free(); return
	_update_cloud()

func _update_cloud() -> void:
	radius=MAX_RADIUS*minf(1.0,(age+0.1)/0.65)
	material.albedo_color.a=minf(1.0,(DURATION-age)/1.1)
	for i in puffs.size():
		var angle := i*2.39996+age*0.07
		var y := float(i%4)/3.0-0.5
		puffs[i].position=Vector3(cos(angle)*0.55,y,sin(angle)*0.55)*radius
		puffs[i].scale=Vector3.ONE*(radius/MAX_RADIUS)*(0.85+0.12*sin(age+i))
