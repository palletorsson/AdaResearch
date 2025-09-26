extends Node3D

@export var portal_count: int = 10
@export var portal_spacing: float = 4.5
@export var base_path: NodePath = NodePath("Lowrestorus")

var _base_portal: MeshInstance3D
var _base_mesh: TorusMesh

func _ready() -> void:
	_base_portal = get_node_or_null(base_path) as MeshInstance3D
	if _base_portal == null:
		push_warning("CombinePortals: Base portal node not found at %s" % base_path)
		return

	if _base_portal.get_parent() != self:
		push_warning("CombinePortals: Base portal must be a direct child of CombinePortals")
		return

	_base_mesh = _base_portal.mesh as TorusMesh
	if _base_mesh == null:
		push_warning("CombinePortals: Base portal requires a TorusMesh")
		return

	spawn_portals()

func spawn_portals() -> void:
	if _base_portal == null or _base_mesh == null:
		return

	_clear_existing_portals()
	_base_portal.visible = false

	var count = max(portal_count, 1)
	var spacing = max(portal_spacing, 0.1)
	var base_transform := _base_portal.transform

	var start_rings = max(_base_mesh.rings, 3)
	var start_segments = max(_base_mesh.ring_segments, 3)

	for i in range(count):
		var portal_instance := _base_portal.duplicate()
		portal_instance.visible = true
		portal_instance.name = "Portal_%02d" % i

		var transform := base_transform
		transform.origin.z += float(i) * spacing
		portal_instance.transform = transform

		var mesh_copy := _base_mesh.duplicate() as TorusMesh
		mesh_copy.rings = start_rings + i
		mesh_copy.ring_segments = start_segments + i * 2
		portal_instance.mesh = mesh_copy

		if owner:
			portal_instance.owner = owner
		add_child(portal_instance)

func _clear_existing_portals() -> void:
	for child in get_children():
		if child == _base_portal:
			continue
		if child.name.begins_with("Portal_"):
			child.queue_free()
