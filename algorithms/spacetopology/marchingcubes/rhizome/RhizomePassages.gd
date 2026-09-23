extends "res://algorithms/spacetopology/marchingcubes/rhizome/RhizomeCaveGenerator.gd"
## An inhabitable, authored connection study using the cave's marching-cubes code.
## The graph is a composition, not evidence that a random growth rule found these routes.
## Its floor heights belong to the passages; an overcrossing is not automatically a junction.

signal passages_ready

const CELL := 0.45
const FIELD_ORIGIN := Vector3(-14.4, -0.9, -15.75)
const FIELD_SIZE := Vector3i(65, 24, 71)
const WALL := 0.24
const RADIUS := 1.65
const CACHE := "res://algorithms/spacetopology/marchingcubes/rhizome/rhizome_passages_mesh.res"

var ready_to_walk := false
var points: Array[Vector3] = []
var links: Array[Vector2i] = []
var shell_mesh: ArrayMesh

func _ready() -> void:
	call_deferred("build_passages")

func build_passages() -> void:
	# First nine places form several ground-level circuits, with two open ends.
	# The final six lift one connection above the others before returning to ground.
	points.assign([
		Vector3(0, 0, -14), Vector3(-4, 0, -8), Vector3(4, 0, -8),
		Vector3(-8, 0, -2), Vector3(0, 0, -3), Vector3(8, 0, -2),
		Vector3(-5, 0, 5), Vector3(4, 0, 5), Vector3(0, 0, 14),
		Vector3(-11, 1.3, 4), Vector3(-9, 2.8, 11), Vector3(-3, 3.7, 8),
		Vector3(2, 3.7, 1), Vector3(10, 3.7, -6), Vector3(11, 1.0, -11)
	])
	links.assign([
		Vector2i(0,1), Vector2i(0,2), Vector2i(1,3), Vector2i(1,4),
		Vector2i(2,4), Vector2i(2,5), Vector2i(3,6), Vector2i(4,6),
		Vector2i(4,7), Vector2i(5,7), Vector2i(6,7), Vector2i(6,8), Vector2i(7,8),
		Vector2i(3,9), Vector2i(9,10), Vector2i(10,11), Vector2i(11,12),
		Vector2i(12,13), Vector2i(13,14), Vector2i(14,2)
	])
	voxel_scale = CELL
	threshold = 0.0
	var signature := FileAccess.get_sha256(get_script().resource_path) + FileAccess.get_sha256("res://algorithms/spacetopology/marchingcubes/rhizome/RhizomeCaveGenerator.gd")
	if ResourceLoader.exists(CACHE):
		var cached := load(CACHE) as ArrayMesh
		if cached != null and cached.get_meta("source_signature", "") == signature:
			shell_mesh = cached
	if shell_mesh == null:
		shell_mesh = await _generate_shell()
		shell_mesh.set_meta("source_signature",signature)
		# Only the explicit capture path writes a cache. Museum visitors never save assets.
		if synchronous:
			ResourceSaver.save(shell_mesh,CACHE)
	_install_shell()

func _generate_shell() -> ArrayMesh:
	var air := PackedFloat32Array()
	air.resize(FIELD_SIZE.x * FIELD_SIZE.y * FIELD_SIZE.z)
	air.fill(100.0)
	for link in links:
		_carve_passage(air, points[link.x], points[link.y])
		if not synchronous:
			await get_tree().process_frame
	var chunk := RhizomeVoxelChunk.new(FIELD_SIZE, CELL)
	chunk.world_position = FIELD_ORIGIN
	return await _double_surface(chunk, air)

func _install_shell() -> void:
	var skin := MeshInstance3D.new()
	skin.name = "PassageShell"
	skin.mesh = shell_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.36,0.49,0.45)
	material.metallic = 0.12
	material.roughness = 0.72
	material.emission_enabled = true
	material.emission = Color(0.025,0.034,0.030)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	skin.material_override = material
	add_child(skin)
	var body := StaticBody3D.new()
	body.name = "WalkableShell"
	var shape := CollisionShape3D.new()
	var trimesh := shell_mesh.create_trimesh_shape()
	trimesh.backface_collision = true
	shape.shape = trimesh
	body.add_child(shape)
	add_child(body)
	_add_landmarks()
	ready_to_walk = true
	passages_ready.emit()

func _index(x: int, y: int, z: int) -> int:
	return (x * FIELD_SIZE.y + y) * FIELD_SIZE.z + z

func get_density_at_world_pos(chunk: RhizomeVoxelChunk, world_pos: Vector3) -> float:
	# Interpolate the field for normals; nearest-voxel gradients made flat floors glitter.
	var q := (world_pos-chunk.world_position)/chunk.voxel_scale
	var p := Vector3i(q.floor())
	var f := q-Vector3(p)
	var low := lerpf(lerpf(chunk.get_density(p),chunk.get_density(p+Vector3i(1,0,0)),f.x),lerpf(chunk.get_density(p+Vector3i(0,0,1)),chunk.get_density(p+Vector3i(1,0,1)),f.x),f.z)
	var high := lerpf(lerpf(chunk.get_density(p+Vector3i(0,1,0)),chunk.get_density(p+Vector3i(1,1,0)),f.x),lerpf(chunk.get_density(p+Vector3i(0,1,1)),chunk.get_density(p+Vector3i(1,1,1)),f.x),f.z)
	return lerpf(low,high,f.y)

func _carve_passage(air: PackedFloat32Array, a: Vector3, b: Vector3) -> void:
	var pad := Vector3(2.2,4.1,2.2)
	var lo := ((a.min(b)-pad-FIELD_ORIGIN)/CELL).floor()
	var hi := ((a.max(b)+pad-FIELD_ORIGIN)/CELL).ceil()
	var run := Vector2(b.x-a.x,b.z-a.z)
	for x in range(maxi(0,int(lo.x)),mini(FIELD_SIZE.x,int(hi.x)+1)):
		for z in range(maxi(0,int(lo.z)),mini(FIELD_SIZE.z,int(hi.z)+1)):
			var world_x := FIELD_ORIGIN.x + float(x)*CELL
			var world_z := FIELD_ORIGIN.z + float(z)*CELL
			var t := clampf(Vector2(world_x-a.x,world_z-a.z).dot(run)/run.length_squared(),0.0,1.0)
			var centre := a.lerp(b,t)
			var across := Vector2(world_x-centre.x,world_z-centre.z).length()
			for y in range(maxi(0,int(lo.y)),mini(FIELD_SIZE.y,int(hi.y)+1)):
				var world_y := FIELD_ORIGIN.y + float(y)*CELL
				var vertical := (world_y-centre.y-1.45)/1.1
				var round_wall := sqrt(across*across + vertical*vertical)-RADIUS
				var passage := maxf(round_wall,centre.y-world_y)
				var index := _index(x,y,z)
				air[index] = minf(air[index],passage)

func _double_surface(chunk: RhizomeVoxelChunk, air: PackedFloat32Array) -> ArrayMesh:
	# Extract inner and outer boundaries separately so a thin wall cannot fall
	# between samples. The floor is the same implicit surface as the tunnel wall.
	var result := ArrayMesh.new()
	for offset in [0.0, WALL]:
		for x in range(FIELD_SIZE.x):
			for y in range(FIELD_SIZE.y):
				for z in range(FIELD_SIZE.z):
					chunk.set_density(Vector3i(x,y,z), air[_index(x,y,z)]-offset)
		var part := await generate_mesh_from_chunk_async(chunk)
		if part.get_surface_count() == 0:
			continue
		var source := part.surface_get_arrays(0)
		var vertices: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = source[Mesh.ARRAY_NORMAL]
		var kept := PackedVector3Array()
		var kept_normals := PackedVector3Array()
		for i in range(0,vertices.size(),3):
			var centre := (vertices[i]+vertices[i+1]+vertices[i+2])/3.0
			# Open portals. Both surfaces end on this cut, leaving a thin exposed rim.
			if absf(centre.z) >= 13.85:
				continue
			for j in range(3):
				kept.append(vertices[i+j])
				kept_normals.append(normals[i+j] * (-1.0 if offset == 0.0 else 1.0))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = kept
		arrays[Mesh.ARRAY_NORMAL] = kept_normals
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

func _add_landmarks() -> void:
	var colours: Array[Color] = [Color(0.94,0.53,0.24),Color(0.3,0.75,0.95),Color(0.72,0.38,0.88)]
	# Recognisable places, not arrows: the same light can be met by several routes.
	for k in range(3):
		var place: Vector3 = points[[3,4,7][k]]
		var light := OmniLight3D.new()
		light.position = place + Vector3(0,2.6,0)
		light.light_color = colours[k]
		light.light_energy = 1.8
		light.omni_range = 8.0
		add_child(light)
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.30
		torus.outer_radius = 0.34
		ring.mesh = torus
		ring.position = place + Vector3(0,2.9,0)
		var ink := StandardMaterial3D.new()
		ink.albedo_color = colours[k]
		ink.emission_enabled = true
		ink.emission = colours[k]
		ink.emission_energy_multiplier = 2.0
		ring.material_override = ink
		add_child(ring)
	# Seven local lights total, within Mobile's per-mesh light budget. Keep the upper
	# crossing readable rather than filling that budget with lamps near the entrance.
	for index in [9,11,12,14]:
		var lamp := OmniLight3D.new()
		lamp.position = points[index]+Vector3(0,2.5,0)
		lamp.omni_range = 7.5
		lamp.light_energy = 1.1
		lamp.light_color = Color(0.63,0.84,0.8)
		add_child(lamp)
