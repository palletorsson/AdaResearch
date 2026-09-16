extends "res://commons/primitives/point/draw_dot.gd"
## Hand position plus an accumulated, bounded random walk. Original dot unchanged.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
var walk_rng := RandomNumberGenerator.new()
var walk_offset := Vector3.ZERO
var walk_clock: float = 0.0
var wandering: bool = true
var tip: MeshInstance3D
var mode_label: Label3D
const STEP_TIME: float = 1.0 / 30.0
const STEP_SIZE: float = 0.012
const RADIUS: float = 0.25

func _ready() -> void:
	super._ready()
	walk_rng.seed = 1955
	_grab_point.position.y = 1.05
	tip = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.018; sphere.height = 0.036
	tip.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.1,1,0.8)
	material.emission_enabled = true; material.emission = material.albedo_color
	tip.material_override = material
	add_child(tip)
	tip.global_position = _grab_point.global_position
	_draw_sphere = tip
	_last_global_position = tip.global_position
	Stage.box(self,Vector3(0,0.45,0),Vector3(0.5,0.9,0.5),Color(0.12,0.2,0.24),true)
	var panel := Rack.create_panel("HAND + CHANCE",[[{"type":"button","label":"HAND / RANDOM"},{"type":"button","label":"CLEAR / REPLAY"}]])
	panel.position = Vector3(0,1.05,-0.55); panel.rotation.y = PI
	add_child(panel)
	panel.find_child("Btn_0",true,false).pressed.connect(toggle_walk)
	panel.find_child("Btn_1",true,false).pressed.connect(reset_walk)
	mode_label = Stage.label(self,"HAND + RANDOM / HOLD THE DOT",Vector3(0,1.4,0),PI)
	mode_label.font_size = 22; mode_label.pixel_size = 0.0015

func _process(delta: float) -> void:
	if not is_instance_valid(tip): return
	var drawing: bool = not record_only_when_grabbed or _grab_point.is_picked_up()
	if drawing and wandering:
		# Bound catch-up after stalls; no unbounded work on the headset.
		walk_clock += minf(delta, 0.1)
		while walk_clock >= STEP_TIME:
			walk_clock -= STEP_TIME
			var direction := Vector3(walk_rng.randfn(),walk_rng.randfn(),walk_rng.randfn()).normalized()
			walk_offset = (walk_offset + direction * STEP_SIZE).limit_length(RADIUS)
	else:
		walk_clock = 0.0
	tip.global_position = _grab_point.global_position + walk_offset
	super._process(delta)

func toggle_walk() -> void:
	wandering = not wandering
	walk_offset = Vector3.ZERO; walk_clock = 0.0
	tip.global_position = _grab_point.global_position
	# Separate experiments, rather than drawing an artificial jump between modes.
	clear_trail()
	mode_label.text = "HAND + RANDOM / HOLD THE DOT" if wandering else "HAND ONLY / HOLD THE DOT"

func reset_walk() -> void:
	walk_rng.seed = 1955; walk_offset = Vector3.ZERO; walk_clock = 0.0
	tip.global_position = _grab_point.global_position
	clear_trail()
