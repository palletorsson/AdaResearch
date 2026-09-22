extends Node3D
## Two finite-sequence instruments; each reads its subject's current data.
const Casing = preload("res://commons/ui/instrument_panel_case.gd")
var subject: Node3D
var text_label: Label3D
var play_caption: Label3D
var portal_mode: bool
var elapsed: float = 0.0
func _ready() -> void:
	set_meta("em_local_instrument",true)
	subject = get_parent()
	portal_mode = subject.has_method("select_next")
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.55,1.10)
	screen.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.025,0.035,0.055)
	screen.material_override = material
	add_child(screen)
	var casing := Casing.new()
	add_child(casing)
	casing.fit_rect(Vector2.ZERO,quad.size,Color(0.8,0.55,1.0))
	text_label = Label3D.new()
	text_label.name = "Readout"
	text_label.font_size = 32
	text_label.pixel_size = 0.0015
	text_label.width = 940
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_label.position = Vector3(-0.70,0.49,0.006)
	text_label.outline_size = 0
	add_child(text_label)
	if portal_mode:
		_button("PreviousButton","PREVIOUS",-0.5,subject.select_previous)
		_button("NextButton","NEXT RING",0.0,subject.select_next)
		_button("ReverseButton","REVERSE",0.5,subject.reverse_discovery_order)
	else:
		_button("StepButton","NEXT STEP",-0.5,subject.next_discovery_step)
		play_caption = _button("PlayButton","PLAY",0.0,subject.toggle_discovery_play)
		_button("RestartButton","RESTART",0.5,subject.restart_discovery)
	update_readout()
func _button(node_name: String,caption: String,x: float,action: Callable) -> Label3D:
	var button: Node3D = preload("res://commons/interactables/push_button.tscn").instantiate()
	button.name = node_name
	button.position = Vector3(x,-0.41,0.035)
	button.pressed.connect(action)
	button.pressed.connect(update_readout)
	add_child(button)
	var label := Label3D.new()
	label.text = caption
	label.font_size = 26
	label.pixel_size = 0.0015
	label.position = Vector3(x,-0.32,0.006)
	label.outline_size = 0
	add_child(label)
	return label
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 0.1:
		elapsed = 0.0
		update_readout()
func update_readout() -> void:
	var data: Dictionary = subject.discovery_snapshot()
	if data.is_empty(): return
	if portal_mode:
		text_label.text = "FINITE PORTAL LADDER\nSelected: %d / %d | %s\nRings: %d | Tube sides: %d\nMesh triangles: %d\nSeparate unit polygon: n = %d\nPerimeter: %.6f | Circle: %.6f\nPerimeter gap: %.6f\nSelection highlights a ring; you stay here." % [data.index,data.count,data.rule,data.rings,data.segments,data.triangles,data.rings,data.perimeter,TAU,data.gap]
	else:
		text_label.text = "ACHILLES / TORTOISE\nStage: %d / %d | %s\nA to limit now: %.6f m\nA to T now: %.6f m\nA to limit at stage target: %.6f m\n%s\nLocal distances; autoplay eases movement." % [data.step,data.count,"held" if data.manual else "playing",data.remaining,data.gap,data.target_remaining,"Final finite stage. Restart when ready." if data.step==data.count else "Next step places the next stage directly."]
		play_caption.text = "PLAY" if data.manual else "PAUSE"
