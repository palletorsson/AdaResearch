extends Node3D
## The bench's owned-set remover, now with physical floor cells.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Remover = preload("res://algorithms/randomness/RemoveRandom.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const SPEEDS: Array[float] = [0.5,1.0,2.0,3.0,4.0,6.0,8.0]
@export_range(0.5,8.0,0.5) var speed_multiplier := 3.0
var speed_buttons: Array[Node3D] = []
var columns: int = 9
var rows: int = 11
var full_crossing := false
var tesla_coils := false
var coils: Node3D
var charged_index := -1
var strike_index := -1
var strike_left := 0.0
var wait_left := 0.0
var timing_rng := RandomNumberGenerator.new()
var remover: Node3D
var colliders: Array[CollisionShape3D] = []
var zone: Area3D
var last_position := Vector3.ZERO
var entered: bool = false
var walked: float = 0.0
var readout: Label3D
var museum: Node

func apply_grid_config(cfg: Dictionary) -> void:
	columns = clampi(int(cfg.get("columns",columns)),3,15)
	rows = clampi(int(cfg.get("rows",rows)),3,19)
	full_crossing = str(cfg.get("full_crossing",false)).to_lower() == "true"
	tesla_coils = str(cfg.get("tesla_coils",false)).to_lower() == "true"
	set_speed(float(cfg.get("speed",speed_multiplier)))

func _ready() -> void:
	set_meta("em_keep_scale",true)
	set_meta("em_visibility_bounds",AABB(Vector3(-columns/2.0-0.2,-0.6,-rows/2.0-2),Vector3(columns+0.4,5.3,rows+4)))
	museum = get_parent()
	while museum != null and not museum.has_method("_basin_burned"): museum = museum.get_parent()
	remover = Remover.new(); remover.name = "OwnedFloorRemover"
	remover.selection_mode = "All"; remover.replay_on_reset = true
	remover.highlight_duration = warning_seconds()
	var grid := Node3D.new(); grid.name = "LocalGrid"; remover.add_child(grid)
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true
	var cube := BoxMesh.new(); cube.size = Vector3(0.98,0.6,0.98)
	var mat := StandardMaterial3D.new(); mat.vertex_color_use_as_albedo = true; mat.roughness = 0.65
	cube.material = mat; mm.mesh = cube; mm.instance_count = columns*rows
	var mi := MultiMeshInstance3D.new(); mi.name = "GridMultiMesh"; mi.multimesh = mm; grid.add_child(mi)
	for z in range(rows):
		for x in range(columns):
			var i: int = z*columns+x
			var p := Vector3(x-(columns-1)/2.0,-0.3,z-(rows-1)/2.0)
			mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,p))
			var body := StaticBody3D.new(); body.position = p; grid.add_child(body)
			var col := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = cube.size
			col.shape = shape; body.add_child(col); colliders.append(col)
	add_child(remover)
	remover.instance_removed.connect(_removed)
	remover.state_changed.connect(_update_readout)
	remover.set_random_seed(17031); remover.reset_and_find_instances()
	timing_rng.seed=17031+901
	if tesla_coils:
		coils=load("res://commons/artifacts/randomness_space/tesla_canopy.gd").new()
		coils.columns=columns;coils.rows=rows
		add_child(coils)
	# End banks remain. Only the legacy exhibit has a permanent side route.
	if not full_crossing:
		for x in [-1.0,1.0]: Stage.box(self,Vector3(x*(columns/2.0+0.5),-0.15,0),Vector3(1,0.3,rows+2),Color(0.2,0.28,0.3),true)
	for z in [-1.0,1.0]: Stage.box(self,Vector3(0,-0.15,z*(rows/2.0+0.5)),Vector3(columns,0.3,1),Color(0.2,0.28,0.3),true)
	zone = Area3D.new(); zone.name = "WalkingTrigger"; zone.collision_layer = 0; zone.collision_mask = 1 | 524288
	var trigger := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = Vector3(columns,2.5,rows)
	trigger.shape = shape; trigger.position.y = 1.25; zone.add_child(trigger); add_child(zone)
	readout = Stage.label(self,"",Vector3(0,1.5,-rows/2.0-1.35),PI)
	readout.font_size = 24; readout.pixel_size = 0.0015; readout.outline_size = 1
	# the label faces -z (yaw PI); a 35 mm plate centred 16 mm behind it put its front
	# face 1.5 mm IN FRONT of the text and hid the readout (2026-09-24): 20 mm clears it
	Stage.box(self,readout.position+Vector3(0,0,0.02),Vector3(1.55,0.25,0.035),Color(0.07,0.13,0.17))
	var panel := Rack.create_panel("FLOOR / WITHOUT REPLACEMENT",[
		[{"type":"button","label":"SLOWER","shape":"rect"},{"type":"button","label":"FASTER","shape":"rect"}],
		[{"type":"button","label":"REPLAY","shape":"rect"},{"type":"button","label":"NEW SEED","shape":"rect"}]])
	panel.position = Vector3(0,1.1,-rows/2.0-1.4); panel.rotation.y = PI; panel.scale = Vector3.ONE*2.2; add_child(panel)
	for i in 4:
		# Panel captions face +Z; put each cap and its hand area on that side.
		panel.find_child("Btn_"+str(i),true,false).rotation.x=PI/2
	speed_buttons.assign([panel.find_child("Btn_0",true,false),panel.find_child("Btn_1",true,false)])
	speed_buttons[0].pressed.connect(func():change_speed.call_deferred(-1))
	speed_buttons[1].pressed.connect(func():change_speed.call_deferred(1))
	panel.find_child("Btn_2",true,false).pressed.connect(func():reset_arena.call_deferred())
	panel.find_child("Btn_3",true,false).pressed.connect(func():new_run.call_deferred())
	_update_readout()

func warning_seconds() -> float:
	return 0.8/speed_multiplier

func walk_spacing() -> float:
	return 0.6/speed_multiplier

func set_speed(value: float) -> void:
	if not is_finite(value):return
	var previous:=speed_multiplier
	speed_multiplier=clampf(value,SPEEDS[0],SPEEDS[-1])
	# Retain the sampled interval's progress; changing speed draws no numbers.
	wait_left*=previous/speed_multiplier
	if remover!=null:remover.highlight_duration=warning_seconds()
	# A warning already underway finishes its original timer. New draws use this rate.
	_update_readout()

func change_speed(direction: int) -> void:
	var values:=SPEEDS.duplicate()
	if direction<0:values.reverse()
	for value in values:
		if (direction>0 and value>speed_multiplier) or (direction<0 and value<speed_multiplier):
			set_speed(value);return

func new_run() -> void:
	remover.new_seed();reset_arena()

func _physics_process(delta: float) -> void:
	if strike_left>0:
		strike_left=maxf(0,strike_left-delta)
		if strike_left==0 and coils!=null:coils.clear_strike()
	var player: Node3D = null
	for body in zone.get_overlapping_bodies():
		if is_player(body): player = body; break
	if player == null:
		entered = false; walked = 0.0; return
	var p := to_local(player.global_position)
	if not entered:
		entered = true; last_position = p; request_removal()
	else:
		walked += Vector2(p.x-last_position.x,p.z-last_position.z).length()
		last_position = p
		if walked >= walk_spacing() and not remover.get_state().busy:
			walked = 0.0; request_removal()
		elif tesla_coils and not remover.get_state().busy:
			wait_left -= delta
			if wait_left<=0:request_removal()

func request_removal() -> void:
	var state: Dictionary=remover.get_state()
	if state.busy or state.remaining==0:return
	remover.remove_one()
	wait_left=timing_rng.randf_range(1.5,3.0)/speed_multiplier

func is_player(body: Node) -> bool:
	if museum == null:
		return body.is_in_group("player")
	var walker = museum.get("_player")
	if walker != null:
		return body == walker
	# The headset branch returns before the museum builds its desktop walker, so
	# _player stays null, and comparing against it recognised nobody: in VR the
	# floor removed nothing (2026-09-24). There the body is XR Tools' PlayerBody,
	# in group player_body, as approach_wall and approach_scale read it.
	return body.is_in_group("player_body") or body.is_in_group("vr_player")

func _removed(index: int) -> void:
	colliders[index].set_deferred("disabled",true)
	if coils!=null:
		strike_index=index;strike_left=0.45
		coils.strike(index,remover.removed_count)

func reset_arena() -> void:
	remover.reset_and_find_instances()
	for col in colliders: col.set_deferred("disabled",false)
	entered = false; walked = 0.0
	timing_rng.seed=remover.run_seed+901
	charged_index=-1;strike_index=-1;strike_left=0;wait_left=0
	if coils!=null:coils.clear_strike();coils.charge(-1)

func _update_readout() -> void:
	if readout == null: return
	var state: Dictionary = remover.get_state()
	if coils!=null and state.busy and charged_index!=state.last_selected:
		charged_index=state.last_selected;coils.charge(charged_index)
	if tesla_coils:
		readout.text="%d TILES / %d LEFT / SEED %d\nSPEED %.1fx / NEXT WARNING %.2f s\nSLOWER / FASTER. REPLAY restores support." % [columns*rows,state.remaining,state.seed,speed_multiplier,warning_seconds()]
	else:
		readout.text = "WALK TO REMOVE / %d LEFT\nSPEED %.1fx / NEXT WARNING %.2f s\nThe apron stays. REPLAY restores support." % [state.remaining,speed_multiplier,warning_seconds()]

func get_state() -> Dictionary:
	var result: Dictionary = remover.get_state()
	result["disabled_colliders"] = colliders.filter(func(c): return c.disabled).size()
	result["inside"] = entered
	result["speed"] = speed_multiplier
	result["warning_seconds"] = warning_seconds()
	result["walk_spacing_metres"] = walk_spacing()
	result["wait_left"] = wait_left
	return result
