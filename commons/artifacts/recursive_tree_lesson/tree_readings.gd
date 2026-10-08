extends Node3D
## Two lossy readings of the same source tree, plus one visitor-kept comparison.
## A saved reading never restores, modifies or ranks the source construction.
const DRAW_SCALE := 0.075
var desk: Node3D
var source: Node3D
var saved: Array = []
var saved_rule: Dictionary = {}
var current: Array = []
var layers: Array[MultiMeshInstance3D] = []
var buttons: Dictionary = {}
var readout: Label3D
var revision := -1
var root_id := 0
var elapsed := 0.0

func _ready() -> void:
	desk = get_parent()
	source = desk.source
	position = Vector3(-1.65, 0, 2.0)
	var pale = desk.material("ebe5dc")
	var dark = desk.material("28242d")
	desk.box(Vector3(0, 1.84, 0), Vector3(1.92, 0.98, 0.055), pale, false, self)
	desk.box(Vector3(0, 0.65, -0.06), Vector3(0.065, 1.30, 0.12), dark, true, self)
	desk.box(Vector3(0, 0.04, -0.06), Vector3(0.70, 0.08, 0.42), pale, true, self)
	desk.box(Vector3(0, 1.025, 0.15), Vector3(1.25, 0.08, 0.45), pale, true, self)
	caption("ONE TREE / TWO READINGS", Vector3(0, 2.28, 0.035), 0.00085)
	caption("PLAN · X / Z\nheight omitted", Vector3(-0.48, 2.18, 0.035), 0.00075)
	caption("SIDE · X / Y\ndepth omitted", Vector3(0.48, 2.18, 0.035), 0.00075)
	caption("same scale · black: now · rose: kept", Vector3(0, 1.39, 0.04), 0.00068)
	for panel in 2:
		var centre := Vector3(-0.48 if panel == 0 else 0.48, 1.81, 0.032)
		for x in [-0.41, 0.41]: desk.box(centre + Vector3(x, 0, 0), Vector3(0.004, 0.57, 0.006), dark, false, self)
		for y in [-0.285, 0.285]: desk.box(centre + Vector3(0, y, 0), Vector3(0.824, 0.004, 0.006), dark, false, self)
	# One batch per reading and history layer. Pose changes update transforms.
	for i in 4:
		var layer := MultiMeshInstance3D.new()
		var batch := MultiMesh.new(); batch.transform_format = MultiMesh.TRANSFORM_3D
		var quad := QuadMesh.new(); quad.size = Vector2.ONE; batch.mesh = quad
		layer.multimesh = batch
		var finish := StandardMaterial3D.new()
		finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		finish.cull_mode = BaseMaterial3D.CULL_DISABLED
		finish.albedo_color = Color("25212a") if i < 2 else Color("c87d96")
		layer.material_override = finish
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(layer); layers.append(layer)
	for i in 2:
		var id := "KEEP" if i == 0 else "CLEAR"
		var button = desk.PUSH.instantiate()
		button.position = Vector3(-0.3 if i == 0 else 0.3, 1.11, 0.19)
		add_child(button); buttons[id] = button
		button.pressed.connect(act.bind(id))
		var text := caption(id, button.position + Vector3(0, 0.005, 0.10), 0.00068)
		text.rotation_degrees.x = -65
	readout = caption("", Vector3(0, 1.47, 0.04), 0.00062)
	desk.box(Vector3(0, 0.88, 0.32), Vector3(1.25, 0.17, 0.035), pale, false, self)
	caption("Keep a view. Change a branch. Walk beneath it.\nReturn: what would you describe differently?", Vector3(0, 0.89, 0.345), 0.00063)
	refresh()

func caption(text: String, at: Vector3, pixels: float) -> Label3D:
	var label: Label3D = desk.label(text, Vector3.ZERO, pixels)
	label.reparent(self, false); label.position = at; label.font_size = 30
	label.modulate = Color("29252c"); label.outline_size = 0
	return label

func records() -> Array:
	var result: Array = []
	for branch in source.generated.get_children():
		if not branch.has_meta("branch_data"): continue
		var data: Dictionary = branch.get_meta("branch_data")
		result.append({"start":data.position, "end":data.position + data.direction * data.length, "depth":data.depth})
	return result

static func project(point: Vector3, panel: int) -> Vector2:
	return Vector2(point.x, -point.z) if panel == 0 else Vector2(point.x, point.y)

func draw(records_: Array, layer: MultiMeshInstance3D, panel: int, kept: bool) -> void:
	var batch := layer.multimesh
	if batch.instance_count != records_.size(): batch.instance_count = records_.size()
	var origin := Vector3(-0.48, 1.81, 0.047) if panel == 0 else Vector3(0.48, 1.57, 0.047)
	if kept: origin.z -= 0.007
	for i in records_.size():
		var a: Vector2 = project(records_[i].start, panel) * DRAW_SCALE
		var b: Vector2 = project(records_[i].end, panel) * DRAW_SCALE
		var delta := b - a
		var centre := (a + b) * 0.5
		# A branch pointing along the omitted axis becomes a visible dot.
		var length := maxf(delta.length(), 0.007)
		var width := 0.007 if kept else 0.004
		var pose := Basis(Vector3.BACK, delta.angle()) * Basis.from_scale(Vector3(length, width, 1))
		batch.set_instance_transform(i, Transform3D(pose, origin + Vector3(centre.x, centre.y, 0)))

func _process(dt: float) -> void:
	elapsed += dt
	if elapsed < 0.1: return
	elapsed = 0.0
	var children: Array = source.generated.get_children()
	var id: int = children[0].get_instance_id() if not children.is_empty() else 0
	if revision != source.geometry_revision or root_id != id or current.size() != source.segment_count:
		refresh()

func refresh() -> void:
	current = records()
	var children: Array = source.generated.get_children()
	root_id = children[0].get_instance_id() if not children.is_empty() else 0
	revision = source.geometry_revision
	for panel in 2: draw(current, layers[panel], panel, false)
	var text := "%d segments now · no view kept" % current.size()
	if not saved.is_empty():
		var changed := 0
		for i in mini(current.size(), saved.size()):
			if not current[i].start.is_equal_approx(saved[i].start) or not current[i].end.is_equal_approx(saved[i].end): changed += 1
		text = "%d now / %d kept · count changed" % [current.size(), saved.size()]
		if current.size() == saved.size(): text = "%d segments · %d spans moved since KEEP" % [current.size(), changed]
	readout.text = text

func act(id: String) -> void:
	if id == "KEEP":
		refresh()
		saved = current.duplicate(true)
		saved_rule = {"generation":source.current_depth,"ratio":source.length_reduction,"forks":source.branch_count,"angle":source.branch_angle_min}
	elif id == "CLEAR":
		saved.clear(); saved_rule.clear()
	else: return
	for panel in 2: draw(saved, layers[panel + 2], panel, true)
	refresh()
