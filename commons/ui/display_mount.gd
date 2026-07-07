## DisplayMount — canonical placement for a workbench's visualization.
##
## Reads a web-composed layout (interface-composer → display_layout.json in the
## artifact folder), mounts the existing viz roots onto a movable anchor at that
## transform, and drops an ADAPTIVE FLOOR STAND under it so the panel is carried
## by structure, never floating. Shared by every split-workbench so placement is
## dragged in the browser, not guessed. See project_canonical_ui_catalog memory.
##
## Usage (in an artifact, after its viz roots are built — call deferred from _ready):
##   const DisplayMount = preload("res://commons/ui/display_mount.gd")
##   func _mount_display() -> void:
##       var center := Vector3(0.0, panel_height, panel_depth)
##       _display_root = DisplayMount.make_anchor(self, "ca_rules_workbench", center, 1.0, 0.0)
##       DisplayMount.mount_cluster(_display_root, [_panel_root, _readout_root, ...], center)
##       DisplayMount.build_stand(self, _display_root)
class_name DisplayMount
extends RefCounted


## Read <res://commons/artifacts/<artifact>/display_layout.json>. Empty if none.
static func load_layout(artifact: String) -> Dictionary:
	var p := "res://commons/artifacts/%s/display_layout.json" % artifact
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


## Build the display anchor, honoring a composed layout if present (it overrides
## the defaults). With NO layout the anchor sits at default_offset — pass the
## cluster's current center so the viz stays exactly where it is now.
static func make_anchor(parent: Node3D, artifact: String, default_offset: Vector3, default_scale: float, default_tilt_deg: float) -> Node3D:
	var offset := default_offset
	var scale := default_scale
	var rot := Vector3(default_tilt_deg, 0.0, 0.0)
	var layout := load_layout(artifact)
	if not layout.is_empty():
		offset = _arr_to_vec3(layout.get("display_offset", []), offset)
		if layout.has("display_scale"):
			scale = float(layout["display_scale"])
		rot = _arr_to_vec3(layout.get("display_rotation_degrees", []), rot)
	var anchor := Node3D.new()
	anchor.name = "Display"
	anchor.position = offset
	anchor.scale = Vector3.ONE * scale
	anchor.rotation_degrees = rot
	parent.add_child(anchor)
	return anchor


## Re-parent existing viz roots onto the anchor, preserving their relative layout
## (each position becomes relative to cluster_center). The anchor then carries the
## whole cluster to wherever the composer placed it. No per-root edits needed.
static func mount_cluster(anchor: Node3D, roots: Array, cluster_center: Vector3) -> void:
	for r in roots:
		if r == null or not (r is Node3D):
			continue
		var node := r as Node3D
		var local: Vector3 = node.position - cluster_center
		var p := node.get_parent()
		if p:
			p.remove_child(node)
		anchor.add_child(node)
		node.position = local


## Drop an adaptive floor stand under the mounted display: a base + pole + mount
## rising from `floor_y` to the screen's lower edge (measured from the anchor's
## actual extent), so a re-dragged screen is always held. All in parent-local space.
static func build_stand(parent: Node3D, anchor: Node3D, floor_y: float = 0.40, body_color: Color = Color(0.60, 0.62, 0.64)) -> void:
	var a_local := _local_aabb(anchor)
	if a_local.size == Vector3.ZERO:
		return
	var a_in_parent: AABB = anchor.transform * a_local
	var bottom_y: float = a_in_parent.position.y
	var cx: float = anchor.position.x
	var cz: float = anchor.position.z
	var steel := StandardMaterial3D.new()
	steel.albedo_color = body_color
	steel.roughness = 0.55
	steel.metallic = 0.3
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.17, 0.18, 0.20)
	dark.roughness = 0.7
	var pole_z: float = cz - 0.10
	var pole_h: float = maxf(0.2, bottom_y - floor_y)
	_box(parent, "StandFoot", Vector3(cx, floor_y + 0.04, pole_z), Vector3(0.55, 0.08, 0.46), steel)
	_box(parent, "StandPole", Vector3(cx, floor_y + pole_h * 0.5, pole_z), Vector3(0.13, pole_h, 0.13), dark)
	_box(parent, "StandMount", Vector3(cx, bottom_y + 0.05, cz - 0.02), Vector3(0.36, 0.24, 0.16), steel)


static func _box(parent: Node3D, n: String, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = n
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


static func _arr_to_vec3(a: Variant, fallback: Vector3) -> Vector3:
	if a is Array and a.size() == 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return fallback


## AABB of a node's visual descendants, expressed in that node's OWN local frame.
static func _local_aabb(root: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	var inv := root.global_transform.affine_inverse()
	for v in _vis(root):
		var vi := v as VisualInstance3D
		var ab: AABB = vi.get_aabb()
		ab = (inv * vi.global_transform) * ab
		if first:
			combined = ab
			first = false
		else:
			combined = combined.merge(ab)
	return combined


static func _vis(node: Node) -> Array:
	var out := []
	if node is VisualInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_vis(c))
	return out
