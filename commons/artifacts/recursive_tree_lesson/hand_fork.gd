extends Node3D
## A reachable receiver of the source tree. The held points edit two existing
## first branches; all rendered sizes receive those same branch records.
const POINT = preload("res://commons/artifacts/recursive_tree_lesson/fork_point.gd")
var source: Node3D
var desk: Node3D
var model: Node3D
var grips: Array[XRToolsPickable] = []
var first_branches: Array[Node3D] = []
var readout: Label3D
var signature: Array = []
var revision := -1
var elapsed := 0.0

func _ready() -> void:
	desk = get_parent()
	source = desk.source
	position = Vector3(1.65, 0, 2.0)
	var stone = desk.material("e7e2d9")
	desk.box(Vector3(0, 0.70, 0), Vector3(1.3, 0.12, 0.9), stone, true, self)
	desk.box(Vector3(0, 0.33, 0), Vector3(0.25, 0.66, 0.40), stone, true, self)
	model = Node3D.new()
	model.name = "SameBranches"
	model.position.y = 0.76
	model.scale = Vector3.ONE * 0.36
	add_child(model)
	for i in range(2):
		var point = POINT.new()
		point.name = "RosePoint" if i == 0 else "BlackPoint"
		point.tint = Color("e99db8") if i == 0 else Color("25212a")
		add_child(point)
		grips.append(point)
	for i in range(2):
		var button = desk.PUSH.instantiate()
		button.position = Vector3(-0.43 if i == 0 else 0.43, 0.80, 0.32)
		add_child(button)
		button.pressed.connect(desk.act.bind("GROW" if i == 0 else "RESET"))
		var caption = desk.label("GROW" if i == 0 else "RESET", Vector3.ZERO, 0.00065)
		caption.reparent(self, false)
		caption.position = button.position + Vector3(0, 0.005, 0.105)
		caption.rotation_degrees.x = -65
	readout = desk.label("", Vector3.ZERO, 0.0010)
	readout.reparent(self, false)
	readout.position = Vector3(0, 0.70, 0.456)
	readout.font_size = 26
	readout.modulate = Color("25212a")
	readout.outline_size = 0
	refresh_geometry()

func held() -> bool:
	for grip in grips:
		if grip.held(): return true
	return false

func _physics_process(dt: float) -> void:
	elapsed += dt
	if elapsed < 0.05: return
	elapsed = 0
	refresh_geometry()
	for i in first_branches.size():
		var grip := grips[i]
		var branch := first_branches[i]
		if not is_instance_valid(branch): continue
		var data: Dictionary = branch.get_meta("branch_data")
		var offset: Vector3 = model.to_local(grip.global_position) - data.position
		if grip.held() and offset.length() > 0.03:
			# A bounded turn; hand remains free, while the represented branch
			# keeps its length and cannot turn the canopy down through the floor.
			var horizontal := Vector3(offset.x, 0, offset.z)
			var angle := clampf(atan2(horizontal.length(), offset.y), deg_to_rad(12), deg_to_rad(65))
			if horizontal.length() > 0.001:
				var direction := Vector3.UP * cos(angle) + horizontal.normalized() * sin(angle)
				if source.steer_branch(branch, direction):
					desk._canopy.refresh_geometry()
					refresh_geometry()
		if not grip.held():
			data = branch.get_meta("branch_data")
			grip.global_position = model.to_global(data.position + data.direction * data.length)

func refresh_geometry() -> void:
	var children: Array[Node] = source.generated.get_children()
	var next: Array = [source.segment_count, children[0].get_instance_id() if not children.is_empty() else 0]
	if next != signature:
		signature = next
		for child in model.get_children():
			model.remove_child(child)
			child.queue_free()
		first_branches.clear()
		for branch in children:
			if not branch.has_meta("branch_data"): continue
			var data: Dictionary = branch.get_meta("branch_data")
			var visible := MeshInstance3D.new()
			visible.mesh = branch.get_child(0).mesh
			visible.material_override = branch.get_child(0).material_override
			model.add_child(visible)
			if data.depth == 1 and first_branches.size() < 2: first_branches.append(branch)
		for i in grips.size():
			grips[i].visible = i < first_branches.size()
			grips[i].enabled = i < first_branches.size()
			grips[i].get_child(1).set_deferred("disabled", i >= first_branches.size())
			if i < first_branches.size():
				var data: Dictionary = first_branches[i].get_meta("branch_data")
				grips[i].global_position = model.to_global(data.position + data.direction * data.length)
		revision = -1
	if revision != source.geometry_revision:
		for i in model.get_child_count():
			model.get_child(i).transform = children[i].transform * children[i].get_child(0).transform
		revision = source.geometry_revision
	readout.text = "GROW a fork. Then hold a point." if first_branches.is_empty() else "Turn ONE fork. Its children follow.\n%d branches | length stays | 12–65°" % source.segment_count
