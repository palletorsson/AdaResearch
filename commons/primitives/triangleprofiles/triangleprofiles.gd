# res://profiles/EditableProfile_PinkFold.gd
extends Node3D
## One editable "folded paper (narrow pleats)" profile built from triangles.
## Baseline is at y = base_y, and the mesh is pink.

@export var base_y: float = 0.5
@export var segment_width: float = 0.5
@export var height: float = 0.8
@export var segment_count: int = 32 # Higher res for perimeter
@export var double_sided: bool = true
@export var sphere_scale: float = 0.3

# Pink colors
@export var color_profile := Color(1.0, 0.08, 0.58) # deep pink-ish
@export var color_alt := Color(0.8, 0.0, 0.4) # darker pink

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
	var crest := base_y + height * 1.0
	var trough := base_y + height * 0.1
	
	# Square Perimeter Logic
	var side_len = 5.0
	var total_perimeter = side_len * 4.0
	
	var h = side_len / 2.0
	var corners = [
		Vector3(-h, 0, -h),
		Vector3(h, 0, -h),
		Vector3(h, 0, h),
		Vector3(-h, 0, h),
		Vector3(-h, 0, -h)
	]

	for i in range(segment_count + 1):
		# Normalized position 0..1
		var t = float(i) / float(segment_count)
		var pos_on_perim = _get_point_on_square_path(t, corners)
		
		var y_val := crest
		if (i % 2) == 1:
			y_val = trough
			
		# Used to rely on 'z_offset' for the straight line depth.
		# The prompt says "wrapped around a square perimeter". 
		# This likely implies the profile *extrudes* along this path or *stands* on it.
		# The current profile is a vertical zigzag wall.
		# So x/z are determined by the path, y is by crest/trough.
		
		verts.append(Vector3(pos_on_perim.x, y_val, pos_on_perim.z + z_offset))

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

func _get_point_on_square_path(t: float, corners: Array) -> Vector3:
	var total_len = 0.0
	var lengths = []
	for i in range(corners.size() - 1):
		var l = corners[i].distance_to(corners[i+1])
		lengths.append(l)
		total_len += l
		
	var target_dist = t * total_len
	var current_dist = 0.0
	
	for i in range(corners.size() - 1):
		var l = lengths[i]
		if current_dist + l >= target_dist - 0.001: 
			var seg_t = (target_dist - current_dist) / l
			return corners[i].lerp(corners[i+1], seg_t)
		current_dist += l
	
	return corners[corners.size()-1]

# -----------------------------------------------------------------------------------
# Mesh update: triangulate the strip to baseline y = base_y

func _update_profile_mesh_from_verts() -> void:
	var mi: MeshInstance3D = _profile["mesh"]
	var verts: Array = _profile["verts"]
	var color: Color = _profile["color"]

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.emission_enabled = true
	mat.emission = color * 0.2

	for i in range(verts.size() - 1):
		# Use actual x,z from vertices (following square perimeter)
		var vert_curr: Vector3 = verts[i]
		var vert_next: Vector3 = verts[i + 1]
		var v0 := Vector3(vert_curr.x, base_y, vert_curr.z)   # baseline left
		var v1 := Vector3(vert_next.x, base_y, vert_next.z)   # baseline right
		var v2 := vert_next                                    # ridge right
		var v3 := vert_curr                                    # ridge left

		# Alternate colors for segments
		var c = color_profile if (i % 2 == 0) else color_alt

		_add_face(st, v0, v1, v2, c)
		_add_face(st, v0, v2, v3, c)

	var mesh := st.commit()
	mi.mesh = mesh
	mi.material_override = mat

func _on_drag_point_moved(index: int, position: Vector3, meta: Dictionary) -> void:
	var verts: Array = _profile["verts"]
	var point_index: int = int(meta.get("point_index", index))
	if point_index >= 0 and point_index < verts.size():
		if verts[point_index] != position:
			verts[point_index] = position
			_update_profile_mesh_from_verts()

func _add_face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var n := (b - a).cross(c - a).normalized()
	
	st.set_color(color)
	st.set_normal(n)
	st.add_vertex(a)
	
	st.set_color(color)
	st.set_normal(n)
	st.add_vertex(b)
	
	st.set_color(color)
	st.set_normal(n)
	st.add_vertex(c)

	if double_sided:
		var n2 := -n
		st.set_color(color)
		st.set_normal(n2)
		st.add_vertex(a)
		
		st.set_color(color)
		st.set_normal(n2)
		st.add_vertex(c)
		
		st.set_color(color)
		st.set_normal(n2)
		st.add_vertex(b)
