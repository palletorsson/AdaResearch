extends Node3D
## The warped field becomes the visitor's surrounding surface. Its support and
## collision stay fixed: RELIEF gives the small comparison bodies another use.
const RADIUS := 5.0
const CENTRE := Vector3(0, 1.5, 0.2)
const FLOOR_Y := 0.06
const DOOR_TOP := 2.5
const DOOR_HALF_ANGLE := 0.24
const DISPLAY_GAIN := 0.65
var surface: MeshInstance3D
var directions := PackedVector3Array()
var revision: int = 0
var sample_ring: MeshInstance3D
var sample_direction := Vector3.ZERO
const WITNESS_RADIUS := RADIUS - 0.025

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
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)
	refresh(study)
	var wall := StaticBody3D.new()
	wall.name = "ShellCollision"
	var wall_shape := CollisionShape3D.new()
	var shell_shape: ConcavePolygonShape3D = surface.mesh.create_trimesh_shape()
	shell_shape.backface_collision = true
	wall_shape.shape = shell_shape
	wall.add_child(wall_shape)
	add_child(wall)

func direction(latitude: float, angle: float) -> Vector3:
	return Vector3(cos(latitude) * cos(angle), sin(latitude), cos(latitude) * sin(angle))

func refresh(study: Node3D) -> void:
	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	for d in directions:
		vertices.append(CENTRE + d * RADIUS)
		var value: float = study.value_at(Vector2(d.x, d.z) * 3.0, study.strength())
		var c: Color = study.colour(value)
		colours.append(Color(c.r * DISPLAY_GAIN, c.g * DISPLAY_GAIN, c.b * DISPLAY_GAIN))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colours
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	surface.mesh = mesh
	revision += 1


## One destination on the surrounding body, matching the small yellow witnesses.
## Only the selected direction moves it. WARP changes the sampled address/value;
## RELIEF changes the small pair. Neither moves this ring or the enclosing shell.
func select_direction(selected_direction: Vector3) -> void:
	var d := selected_direction.normalized()
	if sample_ring != null and sample_direction.is_equal_approx(d): return
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
				corners.append(CENTRE + (d * cos(radius) + around * sin(radius)) * WITNESS_RADIUS)
		vertices.append_array(PackedVector3Array([corners[0], corners[1], corners[2], corners[2], corners[1], corners[3]]))
	var data: Array = []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	sample_ring.mesh = mesh
