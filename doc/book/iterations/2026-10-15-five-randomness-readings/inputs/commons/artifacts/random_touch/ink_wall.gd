extends Node3D
## Equal phase samples: speed changes when marks arrive, never their positions.
const Motion = preload("motion_record.gd")
const RADIUS := 0.018
var marks: Array = [[],[],[],[],[]]
var layers: Array[MultiMeshInstance3D] = []

func build(homes: Array) -> void:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
void fragment() {
    float edge = 1.0 - smoothstep(0.91, 1.0, length(UV * 2.0 - 1.0));
    ALBEDO = vec3(0.075, 0.12, 0.14);
    ALPHA = edge * 0.035;
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	var circle := QuadMesh.new()
	circle.size = Vector2.ONE * RADIUS * 2
	circle.material = material
	for lane in Motion.LANES:
		var layer := MultiMeshInstance3D.new()
		layer.name = "InkRow%d" % lane
		layer.position = homes[lane] + Vector3(0,0,-0.085)
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.mesh = circle
		layer.multimesh.instance_count = Motion.INK_LIMIT
		layer.multimesh.visible_instance_count = 0
		layer.multimesh.custom_aabb = AABB(Vector3(-0.48,-0.15,-0.01),Vector3(0.96,0.30,0.02))
		add_child(layer)
		layers.append(layer)

func record_span(record: Dictionary, lane: int, before: float, after: float) -> void:
	var rate: float = record.rates[lane] * Motion.MARKS_PER_SEGMENT
	var first := int(floor(before*rate+0.000001))+1
	var last := int(floor(after*rate+0.000001))
	if last < first: return
	# Even a very large time step only constructs the retained tail.
	first = maxi(first,last-Motion.INK_LIMIT+1)
	for tick in range(first,last+1):
		var p := Motion.offset(record,lane,float(tick)/rate)
		marks[lane].append([p.x,p.y])
	if marks[lane].size()>Motion.INK_LIMIT: marks[lane]=marks[lane].slice(-Motion.INK_LIMIT)
	_refresh(lane)

func clear() -> void:
	marks = [[],[],[],[],[]]
	for lane in layers.size(): _refresh(lane)

func restore(saved: Array) -> void:
	marks = saved.duplicate(true)
	# JSON numbers use doubles; restore the actual 32-bit vector coordinates.
	for row in marks:
		for i in row.size():
			var p := Vector2(row[i][0],row[i][1])
			row[i] = [p.x,p.y]
	for lane in layers.size(): _refresh(lane)

func _refresh(lane: int) -> void:
	if layers.is_empty(): return # Numerical checks can run without a renderer.
	var mesh := layers[lane].multimesh
	for i in marks[lane].size():
		var p: Array = marks[lane][i]
		mesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(p[0],p[1],0)))
	mesh.visible_instance_count = marks[lane].size()
