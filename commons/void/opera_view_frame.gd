extends Node3D
## An open viewfinder. Its +Z side faces the visitor.
var caption := ""
var aperture := Vector2(1.08, 0.64)
var ink := StandardMaterial3D.new()
var lit := false

## Floor-local metres and Godot's YXZ Euler angles, also used by the Three.js lens.
func apply_floor_pose(host: Node3D, spec: Dictionary) -> void:
	caption = str(spec.get("title",caption))
	for child in get_children():
		if child is Label3D: child.text = caption
	var at: Array = spec.position
	var angles: Array = spec.rotation
	var orientation := Basis.from_euler(Vector3(angles[0], angles[1], angles[2]) * PI / 180.0)
	var size_change := Vector3(float(spec.width)/(2*aperture.x), float(spec.height)/(2*aperture.y), 1)
	global_transform = host.global_transform * Transform3D(orientation.scaled_local(size_change), Vector3(at[0],at[1],at[2]))

func _ready() -> void:
	add_to_group("opera_view_frames")
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = Color("785967")
	var length := minf(0.2, aperture.x * 0.32)
	var height := minf(0.16, aperture.y * 0.36)
	var thickness := minf(0.022, aperture.x * 0.04)
	for x in [-1, 1]:
		for y in [-1, 1]:
			stroke(Vector3(x*(aperture.x-length/2), y*aperture.y, 0), Vector3(length+thickness, thickness, 0.018))
			stroke(Vector3(x*aperture.x, y*(aperture.y-height/2), 0), Vector3(thickness, height+thickness, 0.018))
	var label := Label3D.new()
	label.text = caption
	label.pixel_size = minf(0.0014, aperture.x * 0.0026)
	label.position = Vector3(0, aperture.y+0.065, 0)
	label.modulate = Color("ede4db")
	add_child(label)

func stroke(at: Vector3, size: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = ink
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.position = at
	add_child(mesh)

func illuminate(active: bool) -> void:
	if lit == active: return
	lit = active
	ink.albedo_color = Color("ff9dcd") if active else Color("785967")

func inside_aperture(p: Vector3) -> bool:
	return absf(p.x) < aperture.x and absf(p.y) < aperture.y

func sees(camera: Camera3D, target_world: Vector3, subject: Node3D = null) -> bool:
	if camera == null: return false
	var eye := to_local(camera.global_position)
	if eye.z < 0.12 or eye.z > 2.8 or absf(eye.x) > 1.7 or absf(eye.y) > 1.3: return false
	var forward := to_local(camera.global_position-camera.global_basis.z)-eye
	if forward.z >= -0.01 or not inside_aperture(eye-forward*eye.z/forward.z): return false
	var target := to_local(target_world)
	if target.z >= 0 or not inside_aperture(eye+(target-eye)*eye.z/(eye.z-target.z)): return false
	var ray := PhysicsRayQueryParameters3D.create(camera.global_position, target_world, 1)
	var body: Node = camera.get_parent()
	while body != null and not body is CollisionObject3D: body = body.get_parent()
	if body is CollisionObject3D: ray.exclude = [body.get_rid()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or (subject != null and (hit.collider == subject or subject.is_ancestor_of(hit.collider)))
