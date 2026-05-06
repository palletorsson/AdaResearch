# mario_cube.gd — Listens for NextCube signal, removes DarkSphere, shows rainbow
extends Node3D

# @identity
# essence: event -> destroy(DarkSphere) + reveal(Rainbow) — one-shot state transition from darkness to color
# desire: to punch a block and break the darkness open, rainbow erupting where void used to be
# critical_parameter: _activated — boolean gate that ensures the transformation happens exactly once, making it feel like a revelation
# triggers: NextCube.next_requested signal or player body collision — either path leads to the same irreversible moment
# emerges: the elastic tween on the rainbow and the back-ease shrink on the sphere create a visual call-and-response that feels choreographed
# needs: NextCube signal [has]; DarkSphere reference [has]; player collision [has]; VR grab [missing]
# relationships: depends on dark_sphere (destroys it); depends on NextCube (trigger); rainbow echoes the rainbow artifact's color bands
# truth: joy is not the presence of color — it is the moment darkness becomes color

## Reacts to NextCube activation or player collision by removing a DarkSphere
## (with a shrink-to-zero tween) and revealing a 7-band rainbow arc.
## Each band is a procedural half-circle ArrayMesh at increasing radii.

class_name MarioCube

var _dark_sphere_ref: Node3D = null
var _rainbow_ref: Node3D = null
var _activated: bool = false
var _connected_next_cubes: Array[Node] = []

func _ready() -> void:
	# Wait a frame so NextCubes are ready
	await get_tree().process_frame
	_connect_to_next_cubes()
	_cache_dark_sphere()
	_create_rainbow()

## Finds all NextCube nodes in the "next_cube" group and connects their signal.
func _connect_to_next_cubes() -> void:
	var count := 0
	for node in get_tree().get_nodes_in_group("next_cube"):
		if node is NextCube and not node.next_requested.is_connected(_on_next_requested):
			node.next_requested.connect(_on_next_requested)
			_connected_next_cubes.append(node)
			count += 1
	# Fallback: find by class
	if count == 0:
		_find_next_cubes_recursive(get_tree().current_scene)
	print("MarioCube: Connected to %d NextCubes" % count)

## Recursively searches the scene tree for NextCube nodes to connect to.
func _find_next_cubes_recursive(node: Node) -> void:
	if node is NextCube:
		if not node.next_requested.is_connected(_on_next_requested):
			node.next_requested.connect(_on_next_requested)
			_connected_next_cubes.append(node)
	for child in node.get_children():
		_find_next_cubes_recursive(child)

## Called when a connected NextCube emits next_requested.
func _on_next_requested(_from_position: Vector3) -> void:
	_activate()

## Called when a physics body enters (player collision trigger).
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("vr_player") or body.is_in_group("player_body"):
		_activate()

## Triggers the one-shot activation: remove DarkSphere and reveal rainbow.
func _activate() -> void:
	if _activated:
		return
	_activated = true
	_remove_dark_sphere()
	_show_rainbow()

func _exit_tree() -> void:
	# Disconnect signals from external NextCube nodes
	for node in _connected_next_cubes:
		if is_instance_valid(node) and node is NextCube:
			if node.next_requested.is_connected(_on_next_requested):
				node.next_requested.disconnect(_on_next_requested)
	_connected_next_cubes.clear()
	# Free created child nodes
	if _rainbow_ref and is_instance_valid(_rainbow_ref):
		_rainbow_ref.queue_free()
		_rainbow_ref = null

# ---------------------------------------------------------------------------
# Dark sphere
# ---------------------------------------------------------------------------

## Searches groups and scene tree to cache a reference to the DarkSphere node.
func _cache_dark_sphere() -> void:
	for node in get_tree().get_nodes_in_group("dark_sphere"):
		if node is Node3D:
			_dark_sphere_ref = node as Node3D
			return
	_dark_sphere_ref = _find_by_name(get_tree().current_scene, "DarkSphere")

func _find_by_name(root: Node, target: String) -> Node3D:
	if root.name == target and root is Node3D:
		return root as Node3D
	for child in root.get_children():
		var found := _find_by_name(child, target)
		if found:
			return found
	return null

## Animates the DarkSphere to scale zero then frees it.
func _remove_dark_sphere() -> void:
	if not _dark_sphere_ref or not is_instance_valid(_dark_sphere_ref):
		_cache_dark_sphere()
	if _dark_sphere_ref and is_instance_valid(_dark_sphere_ref):
		var tween := create_tween()
		tween.tween_property(_dark_sphere_ref, "scale", Vector3.ZERO, 1.2) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		tween.tween_callback(_dark_sphere_ref.queue_free)
		print("MarioCube: Removing DarkSphere")
	else:
		print("MarioCube: No DarkSphere found")

# ---------------------------------------------------------------------------
# Rainbow
# ---------------------------------------------------------------------------

## Builds 7 rainbow arc bands as MeshInstance3D children, initially hidden.
## Note: Each band has unique geometry (different radii), so MultiMesh
## cannot be used here — it requires identical meshes for all instances.
func _create_rainbow() -> void:
	_rainbow_ref = Node3D.new()
	_rainbow_ref.name = "Rainbow"
	_rainbow_ref.visible = false

	var colors: Array[Color] = [
		Color(1.0, 0.0, 0.0),
		Color(1.0, 0.5, 0.0),
		Color(1.0, 1.0, 0.0),
		Color(0.0, 1.0, 0.0),
		Color(0.0, 0.5, 1.0),
		Color(0.3, 0.0, 0.8),
		Color(0.6, 0.0, 1.0),
	]

	var inner_radius := 4.0
	var band_width := 0.6

	for i in colors.size():
		var r_in := inner_radius + i * band_width
		var r_out := r_in + band_width * 0.9
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.mesh = _arc_mesh(r_in, r_out, 32)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[i]
		mat.emission_enabled = true
		mat.emission = colors[i]
		mat.emission_energy_multiplier = 1.5
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_inst.material_override = mat
		_rainbow_ref.add_child(mesh_inst)

	_rainbow_ref.position = Vector3(0.0, 3.0, 0.0)
	add_child(_rainbow_ref)

## Reveals the rainbow with an elastic scale-in tween.
func _show_rainbow() -> void:
	if not _rainbow_ref:
		return
	_rainbow_ref.visible = true
	_rainbow_ref.scale = Vector3.ZERO
	var tween := create_tween()
	tween.tween_property(_rainbow_ref, "scale", Vector3.ONE, 1.0) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

## Generates a half-circle arc ArrayMesh between r_in and r_out with front+back faces.
func _arc_mesh(r_in: float, r_out: float, segs: int) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if segs <= 0:
		return mesh

	var front_vert_count := (segs + 1) * 2
	var total_vert_count := front_vert_count * 2  # front + back
	var total_index_count := segs * 6 * 2  # front + back

	var verts := PackedVector3Array()
	verts.resize(total_vert_count)
	var normals := PackedVector3Array()
	normals.resize(total_vert_count)
	var indices := PackedInt32Array()
	indices.resize(total_index_count)

	var vi := 0  # vertex write index
	var ii := 0  # index write index

	# Front face vertices
	for i in range(segs + 1):
		var a := PI * float(i) / maxf(float(segs), 0.0001)
		var x := cos(a)
		var y := sin(a)
		verts[vi] = Vector3(x * r_in, y * r_in, 0.0)
		normals[vi] = Vector3.BACK
		vi += 1
		verts[vi] = Vector3(x * r_out, y * r_out, 0.0)
		normals[vi] = Vector3.BACK
		vi += 1
		if i < segs:
			var b := i * 2
			indices[ii] = b; ii += 1
			indices[ii] = b + 1; ii += 1
			indices[ii] = b + 2; ii += 1
			indices[ii] = b + 1; ii += 1
			indices[ii] = b + 3; ii += 1
			indices[ii] = b + 2; ii += 1

	# Back face (duplicate verts with flipped normals)
	var vc := front_vert_count
	for i in vc:
		verts[vi] = verts[i]
		normals[vi] = Vector3.FORWARD
		vi += 1
	for i in range(segs):
		var b := vc + i * 2
		indices[ii] = b + 2; ii += 1
		indices[ii] = b + 1; ii += 1
		indices[ii] = b; ii += 1
		indices[ii] = b + 2; ii += 1
		indices[ii] = b + 3; ii += 1
		indices[ii] = b + 1; ii += 1

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func apply_grid_config(config_data: Dictionary) -> void:
	pass
