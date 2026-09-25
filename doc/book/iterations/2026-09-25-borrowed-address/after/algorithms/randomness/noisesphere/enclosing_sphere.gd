extends Node3D
## The warped field becomes the visitor's surrounding surface. Its support and
## collision follow the same sampled relief. Floor and doorway edges stay pinned.
const RADIUS := 5.0
const CENTRE := Vector3(0, 1.5, 0.2)
const FLOOR_Y := 0.06
const DOOR_TOP := 2.5
const DOOR_HALF_ANGLE := 0.24
const DISPLAY_GAIN := 0.65
const RELIEF_DEPTH := 0.8
var surface: MeshInstance3D
var directions := PackedVector3Array()
var revision: int = 0
var sample_ring: MeshInstance3D
var sample_direction := Vector3.ZERO
const WITNESS_INSET := 0.025
var _witness_strength: float = -1.0
var _witness_relief: bool = false
var _wall_shape: ConcavePolygonShape3D
var displaced_vertices := PackedVector3Array()

func build(study: Node3D) -> void:
	name = "EnclosingSphere"
	var floor_radius: float = sqrt(RADIUS * RADIUS - pow(CENTRE.y - FLOOR_Y, 2))
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = floor_radius
	floor_mesh.bottom_radius = floor_radius
	floor_mesh.height = FLOOR_Y
	floor_mesh.radial_segments = 128
	var floor_node := MeshInstance3D.new()
	floor_node.name = "CircularFloor"
	floor_node.mesh = floor_mesh
	floor_node.position = Vector3(0, FLOOR_Y / 2, CENTRE.z)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.15, 0.18, 0.21)
	stone.roughness = 0.9
	floor_node.material_override = stone
	add_child(floor_node)
	var floor_body := StaticBody3D.new()
	floor_body.name = "FloorCollision"
	floor_body.position = floor_node.position
	var floor_shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = floor_radius
	cylinder.height = FLOOR_Y
	floor_shape.shape = cylinder
	floor_body.add_child(floor_shape)
	add_child(floor_body)

	# Include exact portal edges in both angular partitions. Openings are part
	# of the triangle mesh and its collision, not transparent painted doors.
	var low: float = asin((FLOOR_Y - CENTRE.y) / RADIUS)
	var door_lat: float = asin((DOOR_TOP - CENTRE.y) / RADIUS)
	var latitudes: Array[float] = [door_lat]
	for i in range(49): latitudes.append(lerpf(low, PI / 2, float(i) / 48))
	latitudes.sort()
	var angles: Array[float] = [DOOR_HALF_ANGLE, PI - DOOR_HALF_ANGLE, PI + DOOR_HALF_ANGLE, TAU - DOOR_HALF_ANGLE]
	for i in range(129): angles.append(TAU * float(i) / 128)
	angles.sort()
	for row in range(latitudes.size() - 1):
		for col in range(angles.size() - 1):
			var a: float = angles[col]
			var b: float = angles[col + 1]
			var middle: float = (a + b) / 2
			var in_door: bool = absf(sin(middle)) < sin(DOOR_HALF_ANGLE)
			if in_door and latitudes[row + 1] <= door_lat + 0.00001: continue
			var p: Vector3 = direction(latitudes[row], a)
			var q: Vector3 = direction(latitudes[row], b)
			var r: Vector3 = direction(latitudes[row + 1], a)
			var s: Vector3 = direction(latitudes[row + 1], b)
			directions.append_array(PackedVector3Array([p, r, q, q, r, s]))
	surface = MeshInstance3D.new()
	surface.name = "InnerSurface"
	var material := ShaderMaterial.new()
	material.shader = load("res://algorithms/randomness/noisesphere/enclosing_relief.gdshader")
	material.set_shader_parameter("sphere_centre", CENTRE)
	surface.custom_aabb = AABB(CENTRE - Vector3.ONE * (RADIUS + RELIEF_DEPTH), Vector3.ONE * 2.0 * (RADIUS + RELIEF_DEPTH))
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)
	refresh(study)
	var wall := StaticBody3D.new()
	wall.name = "ShellCollision"
	var wall_shape := CollisionShape3D.new()
	_wall_shape = ConcavePolygonShape3D.new()
	_wall_shape.set_faces(displaced_vertices)
	_wall_shape.backface_collision = true
	wall_shape.shape = _wall_shape
	wall.add_child(wall_shape)
	add_child(wall)

func direction(latitude: float, angle: float) -> Vector3:
	return Vector3(cos(latitude) * cos(angle), sin(latitude), cos(latitude) * sin(angle))

func refresh(study: Node3D) -> void:
	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	var samples := PackedVector2Array()
	displaced_vertices.clear()
	var depth: float = RELIEF_DEPTH if study.relief else 0.0
	for d in directions:
		vertices.append(CENTRE + d * RADIUS)
		var value: float = study.value_at(Vector2(d.x, d.z) * 3.0, study.strength())
		var weight: float = relief_weight(d)
		samples.append(Vector2(value, weight))
		displaced_vertices.append(CENTRE + d * (RADIUS + value * weight * depth))
		var c: Color = study.colour(value)
		colours.append(Color(c.r * DISPLAY_GAIN, c.g * DISPLAY_GAIN, c.b * DISPLAY_GAIN))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_TEX_UV] = samples
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	surface.mesh = mesh
	surface.material_override.set_shader_parameter("relief_depth", depth)
	if _wall_shape != null: _wall_shape.set_faces(displaced_vertices)
	revision += 1


## One destination on the surrounding body, matching the small yellow witnesses.
## The direction still names the same destination. In RELIEF, its radial position
## follows the displaced surface; in SKIN, WARP changes colour without moving it.
func select_direction(selected_direction: Vector3, study: Node3D) -> void:
	var d := selected_direction.normalized()
	if sample_ring != null and sample_direction.is_equal_approx(d) and _witness_relief == study.relief:
		if not study.relief or is_equal_approx(_witness_strength, study.strength()): return
	_witness_relief = study.relief
	_witness_strength = study.strength()
	sample_direction = d
	if sample_ring == null:
		sample_ring = MeshInstance3D.new()
		sample_ring.name = "SelectedDirection"
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.9, 0.25)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		sample_ring.material_override = mat
		sample_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sample_ring)
	# An open band follows the inside surface; the sampled patch remains visible.
	var tangent := d.cross(Vector3.UP if absf(d.y) < 0.99 else Vector3.RIGHT).normalized()
	var bitangent := d.cross(tangent).normalized()
	var vertices := PackedVector3Array()
	for i in range(48):
		var corners: Array[Vector3] = []
		for angle in [TAU * i / 48.0, TAU * (i + 1) / 48.0]:
			var around: Vector3 = tangent * cos(angle) + bitangent * sin(angle)
			for radius in [0.036, 0.045]:
				var ring_direction: Vector3 = d * cos(radius) + around * sin(radius)
				corners.append(CENTRE + ring_direction * (radius_at(ring_direction, study) - WITNESS_INSET))
		vertices.append_array(PackedVector3Array([corners[0], corners[1], corners[2], corners[2], corners[1], corners[3]]))
	var data: Array = []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	sample_ring.mesh = mesh


## Keep the floor seam and both real doorway boundaries fixed. The fade is a
## spatial constraint, not another noise field; the rest of the surface can bulge.
func relief_weight(d: Vector3) -> float:
	var y: float = CENTRE.y + d.y * RADIUS
	var floor_fade: float = smoothstep(FLOOR_Y, FLOOR_Y + 0.5, y)
	var angle: float = atan2(absf(d.z), absf(d.x))
	var away_from_jamb: float = smoothstep(DOOR_HALF_ANGLE, DOOR_HALF_ANGLE + 0.16, angle)
	var above_lintel: float = smoothstep(DOOR_TOP, DOOR_TOP + 0.55, y)
	return floor_fade * maxf(away_from_jamb, above_lintel)

func radius_at(d: Vector3, study: Node3D) -> float:
	var value: float = study.value_at(Vector2(d.x, d.z) * 3.0, study.strength())
	return RADIUS + value * relief_weight(d) * (RELIEF_DEPTH if study.relief else 0.0)
