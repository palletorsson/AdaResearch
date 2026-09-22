extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Same samples / different marks, followed by a floor that keeps its support.
const SEED := 1010
const ODDS := [0.5, 0.75, 1.0, 0.0, 0.25]
var model: Node3D
var held: Node3D
var held_choices: Array = []
var held_samples: Array = []
var held_alphabet := ""
var seed_value := SEED
var odds_index := 0
var steps := 0
var floor_marks: Node3D
var held_label: Label3D
var notice := "HOLD the choices, then change ALPHABET."

func _ready() -> void:
	_build_compact_console(["STEP", "ALPHABET", "ODDS", "HOLD", "SEED", "RESET"], "ASSEMBLAGE / TWO MARKS, MANY PATHS")
	model = load("res://commons/artifacts/ten_print_textile/ten_print_textile.tscn").instantiate()
	model.cols = 12;model.rows = 12;model.weave_seed = SEED;model.weaving = false
	model.position = Vector3(-2.3, -0.2, -3);model.scale = Vector3.ONE*2.7
	add_child(model)
	# One continuous backing helps the gaps between the small marks remain visible.
	var dark := material("152a32")
	for x in [-2.3, 2.3]:
		box(Vector3(x, 2.37, -3.08), Vector3(3.05, 2.65, 0.08), dark, true)
		for side in [-1,1]:box(Vector3(x+side*1.55, 1.7, -3.1), Vector3(0.06,3.4,0.12), material("66818a"),true)
	label("EDITING / 144 stored samples", Vector3(-2.3,0.92,-2.87),0.0011)
	held_label=label("HOLD / leave a witness", Vector3(2.3,0.92,-2.87),0.0011)
	label("THE CHOICE / THE MARK / THE PATH", Vector3(0,4.15,-3.2),0.0016)
	# The floor stays solid for every alphabet and every outcome.
	box(Vector3(0,0.006,-8),Vector3(5.2,0.012,5.2),material("1a303b"))
	label("SAME CHOICES UNDERFOOT / THE FLOOR STAYS SOLID",Vector3(0,0.55,-5.2),0.00105)
	model.cloth_changed.connect(_refresh)
	stage_original()
	_stage_collection.call_deferred()
	_refresh()
	for at in [Vector3(-5,4,-3),Vector3(5,4,-3),Vector3(0,4,-9),Vector3(0,4,-18)]:
		var lamp:=OmniLight3D.new();lamp.position=at;lamp.omni_range=13;lamp.light_energy=3;add_child(lamp)

func stage_original() -> void:
	var source: Node3D=get_parent()
	for n in source.get_children():
		if n==self:continue
		if n is Node3D and not n.has_meta("assemblage_staged"):
			n.position+=Vector3(-6,0.2,-14);n.set_meta("assemblage_staged",true)

func _stage_collection() -> void:
	var hall: Node = get_parent()
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	if hall == null or str(hall.get_meta("em_map")) != "Assemblage_Same_Desire": return
	# Keep the loom's spatial panels; its desktop demo HUD is not an exhibit.
	for info in hall.find_children("InfoLabel", "Label", true, false): info.hide()
	box(Vector3(4,0.5,-27),Vector3(0.9,1.0,0.6),material("263a44"),true)
	for at in [Vector3(5,4,27),Vector3(13,4,27),Vector3(9,4,33)]:
		var lamp:=OmniLight3D.new();lamp.position=at;lamp.omni_range=12;lamp.light_energy=3;hall.add_child(lamp)

func act(id: String) -> void:
	match id:
		"STEP":
			steps+=1;notice="One oldest row leaves; one new row arrives.";model.step_row()
		"ALPHABET":
			var index: int=model.ALPHABETS.find(model.alphabet)
			notice="Same samples and choices; different marks."
			model.reinterpret(model.ALPHABETS[(index+1)%3],model.odds)
		"ODDS":
			odds_index=(odds_index+1)%ODDS.size()
			notice="Same samples; compare them with another threshold."
			model.reinterpret(model.alphabet,ODDS[odds_index])
		"HOLD":
			if is_instance_valid(held):remove_child(held);held.queue_free()
			held=model._bolt.duplicate() as Node3D;add_child(held)
			held.position=Vector3(2.3,-0.2,-3);held.scale=Vector3.ONE*2.7
			held_choices=model.choices().duplicate(true);held_samples=model.samples().duplicate(true);held_alphabet=model.alphabet
			held_label.text="HELD / %s / p=%.2f" % [model.alphabet,model.odds]
			notice="Held marks and choices remain while editing continues."
		"SEED":
			seed_value+=1;steps=0;notice="A new seeded sheet; the held one stays.";model.reset_cloth(seed_value)
		"RESET":
			seed_value=SEED;steps=0;odds_index=0;notice="Opening choices restored; held sheet stays."
			model.alphabet="diagonals";model.odds=0.5;model.reset_cloth(seed_value)
	_refresh_readout()

func _refresh() -> void:
	if is_instance_valid(floor_marks):remove_child(floor_marks);floor_marks.queue_free()
	floor_marks=Node3D.new();add_child(floor_marks)
	# Map each stored row/column into a fixed 0.4 m floor cell. Geometry only:
	# no collision toggle or path-finding is smuggled into the mark choice.
	for r in model.rows:
		for c in model.cols:
			var sample: MeshInstance3D=model._woven[r][c]
			var m:=MeshInstance3D.new();m.mesh=sample.mesh;m.material_override=sample.material_override
			m.position=Vector3((c-5.5)*0.4,0.035,-8+(r-5.5)*0.4)
			m.basis=Basis(Vector3.RIGHT,-PI/2)*Basis(Vector3.BACK,sample.rotation.z)
			m.scale=Vector3(4.8,4.8,0.5);floor_marks.add_child(m)
	_refresh_readout()

func _refresh_readout() -> void:
	var bits: Array=model.choices();var count:=0
	for row in bits:
		for b in row:if b:count+=1
	readout.text="%s / p %.2f / seed %d / row +%d\n%d of 144 choose A | sample[0,0] %.3f\n%s" % [model.alphabet,model.odds,seed_value,steps,count,model.samples()[0][0],notice]

func _build_compact_console(ids: Array, title: String) -> void:
	# All six controls fit within one standing position. Keep the physical
	# button size; compact the spacing instead of shrinking the touch targets.
	var casing := material("263a44")
	box(Vector3(0, 0.95, 2.0), Vector3(1.12, 0.12, 0.44), casing, true)
	for x in [-0.42, 0.42]:
		box(Vector3(x, 0.445, 2.0), Vector3(0.08, 0.89, 0.30), casing, true)
	for i in ids.size():
		var id: String = ids[i]
		var column: int = i % 3
		var row: int = i / 3
		var button = PUSH.instantiate()
		button.position = Vector3((column - 1) * 0.32, 1.045, 1.88 + row * 0.23)
		button.rotation = Vector3.ZERO
		button.scale = Vector3.ONE * 1.15
		add_child(button)
		buttons[id] = button
		button.pressed.connect(act.bind(id))
		var caption := label(id, button.position + Vector3(0, 0.01, 0.09), 0.00065)
		caption.rotation_degrees.x = -70
	box(Vector3(0, 0.90, 2.235), Vector3(1.12, 0.15, 0.025), casing)
	label(title, Vector3(0, 0.90, 2.252), 0.00063)

	# A single transparent plane avoids the doubled opacity of a glass box.
	# Text keeps an opaque outline, so the exhibit is visible behind the panel
	# while the reading remains distinct from its changing background.
	var panel := Node3D.new()
	panel.name = "TextPanel"
	add_child(panel)
	panel.position = Vector3(0, 1.27, 1.58)
	panel.rotation_degrees.x = -35
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var pane := QuadMesh.new()
	pane.size = Vector2(1.18, 0.36)
	glass.mesh = pane
	var tint := StandardMaterial3D.new()
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	tint.albedo_color = Color(0.12, 0.25, 0.30, 0.14)
	glass.material_override = tint
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.add_child(glass)
	for y in [-0.19, 0.19]:
		box(Vector3(0, y, 0), Vector3(1.22, 0.016, 0.016), casing, false, panel)
	for x in [-0.60, 0.60]:
		box(Vector3(x, 0, 0), Vector3(0.016, 0.38, 0.016), casing, false, panel)
	for x in [-0.48, 0.48]:
		box(Vector3(x, 1.09, 1.70), Vector3(0.018, 0.22, 0.018), casing)
	readout = label(title, Vector3.ZERO, 0.0011)
	readout.font_size = 28
	readout.outline_size = 7
	readout.outline_modulate = Color(0.025, 0.04, 0.055, 0.95)
	readout.reparent(panel, false)
	readout.position = Vector3(0, 0, 0.009)
