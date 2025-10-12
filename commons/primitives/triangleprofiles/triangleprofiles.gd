# res://profiles/EditableProfile_PinkFold.gd
extends Node3D
## One editable "folded paper (narrow pleats)" profile built from triangles.
## Baseline is at y = base_y, and the mesh is pink.

@export var base_y: float = 1.2
@export var segment_width: float = 1.0
@export var height: float = 1.2
@export var segment_count: int = 16
@export var double_sided: bool = true
@export var sphere_scale: float = 0.5

# Pink color
@export var color_profile := Color(1.0, 0.08, 0.58) # deep pink-ish

var _profile := {
	"name": "Folded_Pink",
	"node": null,
	"mesh": null,
	"verts": [],
	"drag_points": null,
	"color": null
}

func _ready() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	_create_profile_folded_narrow(0.0) # z-offset 0

# -----------------------------------------------------------------------------------
# Builder: standing open folded paper (narrow pleats), pink

func _create_profile_folded_narrow(z_offset: float) -> void:
	var parent := Node3D.new()
	parent.name = "Profile_Folded_Pink"
	parent.position = Vector3(0.0, 0.0, z_offset)
	add_child(parent)

	var mi := MeshInstance3D.new()
	mi.name = "Mesh_Folded_Pink"
	parent.add_child(mi)

	# Ridge vertices: alternate crest/trough above baseline
	var verts: Array[Vector3] = []
	var w := segment_width
	var crest := base_y + height * 1.0
	var trough := base_y + height * 0.1

	for i in range(segment_count + 1):
		var x := float(i) * w
		var y_val := crest
		if (i % 2) == 1:
			y_val = trough
		verts.append(Vector3(x, y_val, z_offset))

	var drag_points := DragPointSet.new()
	drag_points.name = "GrabPoints"
	parent.add_child(drag_points)
	drag_points.point_moved.connect(_on_drag_point_moved)

	var point_configs: Array = []
	for i in range(verts.size()):
		point_configs.append({
			"id": i,
			"name": "Grab_Pink_%02d" % i,
			"position": verts[i],
			"meta": {"point_index": i},
			"scale": sphere_scale,
			"color": color_profile
		})

	drag_points.setup(point_configs, {
		"freeze_on_drop": true,
		"unfreeze_on_pickup": true
	})

	drag_points.for_each_sphere(func(sphere: Node3D) -> void:
		var mesh_instance: MeshInstance3D = sphere.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if mesh_instance:
			var mat := mesh_instance.material_override as StandardMaterial3D
			if mat:
				mat.emission_enabled = true
				mat.emission = Color(0.25, 0.0, 0.15) * 0.7
	)

	# Stash profile
	_profile["node"] = parent
	_profile["mesh"] = mi
	_profile["verts"] = verts
	_profile["drag_points"] = drag_points
	_profile["color"] = color_profile

	_update_profile_mesh_from_verts()

# -----------------------------------------------------------------------------------
# Mesh update: triangulate the strip to baseline y = base_y

func _update_profile_mesh_from_verts() -> void:
	var mi: MeshInstance3D = _profile["mesh"]
	var verts: Array = _profile["verts"]
	var color: Color = _profile["color"]

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.emission_enabled = true
	mat.emission = color * 0.3  # Add subtle emission using the profile color

	var z_off := (_profile["node"] as Node3D).position.z

	for i in range(verts.size() - 1):
		var x0 = verts[i].x
		var x1 = verts[i + 1].x
		var v0 := Vector3(x0, base_y, z_off)      # baseline left
		var v1 := Vector3(x1, base_y, z_off)      # baseline right
		var v2 := Vector3(verts[i + 1].x, verts[i + 1].y, z_off)  # ridge right
		var v3 := Vector3(verts[i].x,     verts[i].y,     z_off)  # ridge left

		_add_face(st, v0, v1, v2)
		_add_face(st, v0, v2, v3)

	var mesh := st.commit()
	mi.mesh = mesh
	mi.material_override = mat

# -----------------------------------------------------------------------------------
# Helpers

func _on_drag_point_moved(index: int, position: Vector3, meta: Dictionary) -> void:
	var verts: Array = _profile["verts"]
	var point_index: int = int(meta.get("point_index", index))
	if point_index >= 0 and point_index < verts.size():
		if verts[point_index] != position:
			verts[point_index] = position
			_update_profile_mesh_from_verts()

func _add_face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)

	if double_sided:
		var n2 := -n
		st.set_normal(n2)
		st.add_vertex(a)
		st.set_normal(n2)
		st.add_vertex(c)
		st.set_normal(n2)
		st.add_vertex(b)
