extends Node3D
## The bench's owned-set remover, now with physical floor cells.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Remover = preload("res://algorithms/randomness/RemoveRandom.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
var columns: int = 9
var rows: int = 11
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

func _ready() -> void:
	museum = get_parent()
	while museum != null and not museum.has_method("_basin_burned"): museum = museum.get_parent()
	remover = Remover.new(); remover.name = "OwnedFloorRemover"
	remover.selection_mode = "All"; remover.replay_on_reset = true
	remover.highlight_duration = 0.8
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
	# Permanent apron joins both doors and provides an observation route.
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
	var panel := Rack.create_panel("FLOOR / WITHOUT REPLACEMENT",[[{"type":"button","label":"REPLAY"},{"type":"button","label":"NEW SEED"}]])
	panel.position = Vector3(0,1.1,-rows/2.0-1.4); panel.rotation.y = PI; panel.scale = Vector3.ONE*2.2; add_child(panel)
	panel.find_child("Btn_0",true,false).pressed.connect(reset_arena)
	panel.find_child("Btn_1",true,false).pressed.connect(func(): remover.new_seed(); reset_arena())
	_update_readout()

func _physics_process(_delta: float) -> void:
	var player: Node3D = null
	for body in zone.get_overlapping_bodies():
		if is_player(body): player = body; break
	if player == null:
		entered = false; walked = 0.0; return
	var p := to_local(player.global_position)
	if not entered:
		entered = true; last_position = p; remover.remove_one()
	else:
		walked += Vector2(p.x-last_position.x,p.z-last_position.z).length()
		last_position = p
		if walked >= 0.6 and not remover.get_state().busy:
			walked = 0.0; remover.remove_one()

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

func reset_arena() -> void:
	remover.reset_and_find_instances()
	for col in colliders: col.set_deferred("disabled",false)
	entered = false; walked = 0.0

func _update_readout() -> void:
	if readout == null: return
	var state: Dictionary = remover.get_state()
	readout.text = "WALK TO REMOVE / %d LEFT\nRed warns for 0.8 s. Fire below.\nThe dark apron stays. REPLAY restores support." % state.remaining

func get_state() -> Dictionary:
	var result: Dictionary = remover.get_state()
	result["disabled_colliders"] = colliders.filter(func(c): return c.disabled).size()
	result["inside"] = entered
	return result
