# res://profiles/EditableProfile_PinkFold.gd
extends Node3D

# @identity
# essence: zigzag(n_triangles, height_high, height_low) — a strip of alternating triangles forming a pleat profile
# desire: learner feels how a complex perimeter shape is just many small triangles sharing edges
# critical_parameter: grab_point_count — how many vertex handles exist along the zigzag strip perimeter
# triggers: dragging any grab handle — the triangle strip deforms, showing how local edits ripple through profile
# emerges: the strip as a minimal surface description — pleats and folds arise from alternating vertex heights
# needs: [has many grabbable vertex handles [has], missing global height/frequency sliders]
# relationships: sibling to triangle; demonstrates that profiles and extrusions are just strips of triangles
# truth: a complex surface profile is built from the simplest unit — a triangle — repeated with shared edges

## One editable "folded paper (narrow pleats)" profile built from triangles.
## Baseline is at y = base_y, and the mesh is pink.

@export var base_y: float = 0.5
@export var segment_width: float = 0.5
@export var height: float = 0.2
@export var segment_count: int = 32 # Higher res for perimeter
@export var double_sided: bool = true
@export var sphere_scale: float = 0.3

# Pink colors
@export var color_profile := Color(1.0, 0.08, 0.58) # deep pink-ish
@export var color_alt := Color(0.8, 0.0, 0.4) # darker pink

## AXIS — HOW MUCH OF ITS OWN MAKING THE PLEAT ADMITS. The ridge vertices never move: the
## same square path, the same crest/trough alternation, the same 33 handles on the same
## corners. What changes is what the profile is willing to say it is. A primitive is met
## before any argument has been made, so this is the first argument it makes — whether a
## surface is a thing the world has or a thing somebody built out of parts.
##
##   facet     the unit announced — one flat plane per triangle, alternating pink and
##             darker pink, hard normals. You can count what it is made of.
##   cast      one colour, normals averaged across the shared edges. The triangles vanish
##             and the pleat reads as a single creased sheet that was never assembled.
##   armature  the faces gone, only the edges standing as thin tubes: ridge line, baseline
##             and the verticals between them. The profile as a drawing of itself.
##   shell     every triangle given thickness, so the wall gains rims you can see end-on.
##             A surface has no thickness; a made thing does.
##
## Shared word for word with [[folded_strip]], the same pleat run straight instead of
## wrapped, so the two cannot stand in one room with one calling its triangles evidence
## and the other calling them nothing.
##
## APPEARANCE ONLY, and deliberately so: this artifact hands its mesh to
## create_trimesh_shape(). The collider is built from the LEGACY mesh in every case — see
## the tail of _update_profile_mesh_from_verts — so what you can walk into and what the
## grab handles ride on are identical under all four values.
@export var facture: String = "facet"
const FACTURES: PackedStringArray = ["facet", "cast", "armature", "shell"]
## Rim depth for `shell`, in metres. The wall is 0.2 m tall and 5 m across; 5 cm is card.
const SHELL_THICKNESS := 0.05
## Tube radius for `armature`, in metres. Fat enough to survive a capture downscale.
const WIRE_RADIUS := 0.022

var _profile := {
	"name": "Folded_Pink",
	"node": null,
	"mesh": null,
	"verts": [],
	"drag_points": null,
	"color": null,
	"collision_shape": null
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
	
	# Collision Setup
	var sb := StaticBody3D.new()
	sb.name = "StaticBody"
	parent.add_child(sb)
	
	var col := CollisionShape3D.new()
	col.name = "CollisionShape"
	sb.add_child(col)
	_profile["collision_shape"] = col

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
	var _f: String = str(facture).strip_edges().to_lower()
	facture = _f if FACTURES.has(_f) else "facet"

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
	
	# Update Collision
	if _profile["collision_shape"]:
		var col_shape_node: CollisionShape3D = _profile["collision_shape"]
		col_shape_node.shape = mesh.create_trimesh_shape()

	# FACTURE, appended LAST — after the collider has been built from the legacy mesh, so
	# the body is identical under every value. "facet" falls through and the profile is
	# exactly what it has always been; the other three replace what is DRAWN, nothing else.
	if facture != "facet":
		_apply_facture(mi, verts)

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


# ── FACTURE ──────────────────────────────────────────────────────────────────
# Three restatements of a profile that has already been built and already handed its
# trimesh to the collider. Each reads the same ridge verts the legacy path read and writes
# only mi.mesh and mi.material_override.

func _apply_facture(mi: MeshInstance3D, verts: Array) -> void:
	var st := SurfaceTool.new()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = color_profile * 0.2

	match facture:
		"cast":
			# One colour, normals averaged over the shared verticals. The alternation
			# that was announcing every segment stops being visible and the pleat reads
			# as one creased sheet standing on the square.
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range(verts.size() - 1):
				var q: Array = _segment_quad(verts, i)
				_tri(st, q[0], q[1], q[2], color_profile, false)
				_tri(st, q[0], q[2], q[3], color_profile, false)
			st.index()
			st.generate_normals()
		"armature":
			# Faces gone, the profile left as a drawing of itself: baseline, ridge line
			# and the verticals that connect them. Tubes, not PRIMITIVE_LINES — a
			# one-pixel wire disappears when a capture is downscaled, and an axis that
			# disappears measures the same as an axis that does nothing.
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var seen: Dictionary = {}
			for i in range(verts.size() - 1):
				var q: Array = _segment_quad(verts, i)
				for pair in [[0, 1], [1, 2], [2, 3], [3, 0]]:
					var a: Vector3 = q[int(pair[0])]
					var b: Vector3 = q[int(pair[1])]
					var key: String = _edge_key(a, b)
					if seen.has(key):
						continue
					seen[key] = true
					_tube(st, a, b, WIRE_RADIUS, color_profile)
		"shell":
			# Every triangle given a body. The wall keeps its exact surface and gains
			# rims you can see end-on — the moment a described surface becomes a made one.
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range(verts.size() - 1):
				var q: Array = _segment_quad(verts, i)
				var c: Color = color_profile if (i % 2 == 0) else color_alt
				_prism(st, q[0], q[1], q[2], SHELL_THICKNESS, c)
				_prism(st, q[0], q[2], q[3], SHELL_THICKNESS, c)
		_:
			return

	mi.mesh = st.commit()
	mi.material_override = mat


## The four corners of segment i, in the legacy order: baseline left, baseline right,
## ridge right, ridge left. Same arithmetic as _update_profile_mesh_from_verts.
func _segment_quad(verts: Array, i: int) -> Array:
	var vc: Vector3 = verts[i]
	var vn: Vector3 = verts[i + 1]
	return [Vector3(vc.x, base_y, vc.z), Vector3(vn.x, base_y, vn.z), vn, vc]


## Position-keyed so the vertical shared by two neighbouring segments is drawn once.
func _edge_key(a: Vector3, b: Vector3) -> String:
	var ka: String = "%.3f_%.3f_%.3f" % [a.x, a.y, a.z]
	var kb: String = "%.3f_%.3f_%.3f" % [b.x, b.y, b.z]
	if ka < kb:
		return ka + "|" + kb
	return kb + "|" + ka


## One triangle. flat=true stamps the face normal on all three corners (hard edges);
## flat=false leaves normals unset so SurfaceTool.generate_normals() can average them.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color, flat: bool) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	if flat:
		st.set_normal(n)
	st.set_color(col)
	st.add_vertex(a)
	if flat:
		st.set_normal(n)
	st.set_color(col)
	st.add_vertex(b)
	if flat:
		st.set_normal(n)
	st.set_color(col)
	st.add_vertex(c)


func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, col: Color) -> void:
	_tri(st, p0, p1, p2, col, true)
	_tri(st, p0, p2, p3, col, true)


## A three-sided tube from a to b — the cheapest thing that still reads as a wire at
## capture distance.
func _tube(st: SurfaceTool, a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var d: Vector3 = b - a
	if d.length_squared() < 0.000001:
		return
	var n: Vector3 = d.normalized()
	var seed_up: Vector3 = Vector3.UP
	if absf(n.dot(Vector3.UP)) > 0.9:
		seed_up = Vector3.RIGHT
	var u: Vector3 = n.cross(seed_up).normalized() * r
	var v: Vector3 = n.cross(u).normalized() * r
	var off: Array = []
	for k in range(3):
		var ang: float = TAU * float(k) / 3.0
		off.append(u * cos(ang) + v * sin(ang))
	for k in range(3):
		var o0: Vector3 = off[k]
		var o1: Vector3 = off[(k + 1) % 3]
		_quad(st, a + o0, a + o1, b + o1, b + o0, col)


## One triangle extruded into a slab of thickness t, rims in a darker tone so the edge
## you can now see end-on is legible against the face.
func _prism(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, t: float, col: Color) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	if n.length_squared() < 0.5:
		return
	var h: Vector3 = n * (t * 0.5)
	var a0: Vector3 = a + h
	var b0: Vector3 = b + h
	var c0: Vector3 = c + h
	var a1: Vector3 = a - h
	var b1: Vector3 = b - h
	var c1: Vector3 = c - h
	_tri(st, a0, b0, c0, col, true)
	_tri(st, a1, c1, b1, col, true)
	var rim: Color = col.darkened(0.42)
	_quad(st, a0, b0, b1, a1, rim)
	_quad(st, b0, c0, c1, b1, rim)
	_quad(st, c0, a0, a1, c1, rim)
