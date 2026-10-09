extends Node3D
## A solid, uniformly enlarged receiver of the existing growing tree.
## Branching and its queue remain owned by the original source.
var source: Node3D
var geometry: Node3D
var source_signature: Array = []
var segment_count := 0
var _elapsed := 0.0

func _ready() -> void:
	source = get_parent().source
	position = Vector3(-4, 0, -2)
	scale = Vector3.ONE * 1.8
	refresh_geometry()

func _process(dt: float) -> void:
	_elapsed += dt
	if _elapsed >= 0.2:
		_elapsed = 0.0
		# Also follow a reset requested outside the physical lesson desk.
		refresh_geometry()

func refresh_geometry() -> void:
	if not is_instance_valid(source) or not is_instance_valid(source.generated): return
	var children: Array[Node] = source.generated.get_children()
	var signature: Array = [source.segment_count, source.current_depth, source.branch_angle_min, source.length_reduction, source.branch_count, children[0].get_instance_id() if not children.is_empty() else 0]
	if signature == source_signature: return
	source_signature = signature
	if is_instance_valid(geometry):
		remove_child(geometry)
		geometry.queue_free()
	geometry = Node3D.new()
	geometry.name = "SolidBranches"
	add_child(geometry)
	segment_count = 0
	for branch: Node3D in children:
		if not branch.has_meta("branch_data"): continue
		var data: Dictionary = branch.get_meta("branch_data")
		var solid := StaticBody3D.new()
		solid.name = "Segment%03d" % segment_count
		solid.transform = branch.transform
		solid.set_meta("generation", int(data.depth))
		solid.set_meta("source_start", data.position)
		solid.set_meta("source_end", data.position + data.direction * data.length)
		geometry.add_child(solid)
		for original: Node in branch.get_children():
			if not original is MeshInstance3D or original.mesh == null: continue
			var visible := MeshInstance3D.new()
			visible.mesh = original.mesh
			visible.material_override = original.material_override
			visible.transform = original.transform
			solid.add_child(visible)
			var collision := CollisionShape3D.new()
			collision.shape = original.mesh.create_convex_shape()
			collision.transform = original.transform
			solid.add_child(collision)
		segment_count += 1
