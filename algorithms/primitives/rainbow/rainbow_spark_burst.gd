extends Node3D
## Ballistic sparks with sampled history: long, tapered tails in all renderers.
## One small MultiMesh per collection; both lifetime and instance count are bounded.
const SPARKS := 28
const SEGMENTS := 14
const LIFETIME := 2.8
const TAIL_SECONDS := 0.75
var elapsed := 0.0
var palette: Array[Color] = [Color("fff0ae")]
var trails: MultiMeshInstance3D

func _ready() -> void:
	trails = MultiMeshInstance3D.new()
	trails.name = "LongTailedSparks"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var rod := CylinderMesh.new()
	rod.top_radius = 1.0
	rod.bottom_radius = 1.0
	rod.height = 1.0
	rod.radial_segments = 4
	rod.rings = 1
	mm.mesh = rod
	mm.instance_count = SPARKS * SEGMENTS
	trails.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.disable_fog = true
	trails.material_override = mat
	add_child(trails)
	_update_trails()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= LIFETIME:
		queue_free()
		return
	_update_trails()

func _point(i: int, t: float) -> Vector3:
	var angle: float = i * 2.399963
	var radial: float = 1.3 + (i % 5) * 0.29
	var upward: float = 3.1 + (i % 7) * 0.33
	return Vector3(cos(angle) * radial * t, upward * t - 2.5 * t * t, sin(angle) * radial * t)

func _update_trails() -> void:
	for i in range(SPARKS):
		var colour: Color = palette[i % palette.size()].lerp(Color("fff6d0"), 0.3)
		for j in range(SEGMENTS):
			var slot: int = i * SEGMENTS + j
			var front_time: float = maxf(0.0, elapsed - float(j) / SEGMENTS * TAIL_SECONDS)
			var back_time: float = maxf(0.0, elapsed - float(j + 1) / SEGMENTS * TAIL_SECONDS)
			var front := _point(i, front_time)
			var back := _point(i, back_time)
			var delta := front - back
			var length: float = delta.length()
			# Below-floor tails vanish rather than shining through the walk.
			if length < 0.0001 or front.y < -position.y or back.y < -position.y:
				trails.multimesh.set_instance_transform(slot, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
				continue
			var taper: float = 1.0 - float(j) / SEGMENTS
			var radius: float = 0.034 * taper
			var basis := Basis(Quaternion(Vector3.UP, delta / length)) * Basis.from_scale(Vector3(radius, length, radius))
			trails.multimesh.set_instance_transform(slot, Transform3D(basis, (front + back) * 0.5))
			var tint := colour.lerp(Color.WHITE, 0.75 if j == 0 else 0.0)
			tint.a = taper * clampf((LIFETIME - elapsed) / 0.7, 0.0, 1.0)
			trails.multimesh.set_instance_color(slot, tint)
