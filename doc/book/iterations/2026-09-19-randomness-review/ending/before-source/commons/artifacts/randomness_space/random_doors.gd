extends Node3D
## One passage per round; the other doors open onto finite, warning-led fire jets.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
var rng := RandomNumberGenerator.new()
var run_seed: int = 39017
var safe_door: int = 0
var doors: Array[MeshInstance3D] = []
var locks: Array[CollisionShape3D] = []
var fire: Array[Area3D] = []
var fire_mesh: Array[MeshInstance3D] = []
var labels: Array[Label3D] = []
var state: Array[String] = ["closed","closed","closed"]
var round_id: int = 0
var museum: Node
var tweens: Array[Tween] = []

func _ready() -> void:
	museum = get_parent()
	while museum != null and not museum.has_method("_basin_burned"): museum = museum.get_parent()
	for i in range(3):
		# The visitor looks toward +Z: their left is world +X.
		var x: float = (1-i)*3.0
		for side in [-1,1]: Stage.box(self,Vector3(x+side*1.2,1.6,0),Vector3(0.25,3.2,0.5),Color(0.13,0.2,0.23),true)
		Stage.box(self,Vector3(x,3.15,0),Vector3(2.6,0.3,0.5),Color(0.14,0.23,0.28),true)
		var door := Stage.box(self,Vector3(x,1.4,0),Vector3(2.15,2.8,0.18),Color(0.27,0.5,0.57),true)
		doors.append(door); locks.append(door.find_children("*","CollisionShape3D",true,false)[0])
		labels.append(Stage.label(self,"%d / ?" % (i+1),Vector3(x,3.65,-0.2),PI))
		var area := Area3D.new(); area.name = "FireJet%d" % i; area.collision_layer = 0; area.collision_mask = 1 | 524288
		var col := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(1.65,2.0,0.1)
		col.name = "CollisionShape3D"; col.shape = bs; col.disabled = true; area.add_child(col)
		area.position = Vector3(x,1.0,-0.1); add_child(area); fire.append(area)
		var mesh := Stage.box(area,Vector3.ZERO,Vector3(1.65,2.0,0.1),Color(1.0,0.16,0.015,0.7))
		mesh.material_override.emission_enabled = true; mesh.material_override.emission = Color(1,0.22,0.015)
		mesh.visible = false; fire_mesh.append(mesh)
		area.body_entered.connect(_burn)
	for x in [-1.5,1.5]: Stage.box(self,Vector3(x,1.5,0),Vector3(0.65,3,0.5),Color(0.12,0.18,0.22),true)
	var panel := Rack.create_panel("CHOOSE / THEN WATCH",[[{"type":"button","label":"DOOR 1"},{"type":"button","label":"DOOR 2"},{"type":"button","label":"DOOR 3"}],[{"type":"button","label":"REPLAY"},{"type":"button","label":"NEW SEED"}]])
	panel.position = Vector3(0,1.1,-4.0); panel.rotation.y = PI; panel.scale = Vector3.ONE*2.2; add_child(panel)
	for i in range(3): panel.find_child("Btn_%d" % i,true,false).pressed.connect(choose.bind(i))
	panel.find_child("Btn_3",true,false).pressed.connect(replay)
	panel.find_child("Btn_4",true,false).pressed.connect(new_seed)
	var instruction := Stage.label(self,"ONE PASSAGE / TWO FIRE JETS\nChoose here. Wait behind the amber line.",Vector3(0,1.55,-4.02),PI)
	instruction.font_size = 24; instruction.pixel_size = 0.0017; instruction.outline_size = 1
	Stage.box(self,instruction.position+Vector3(0,0,0.02),Vector3(1.35,0.24,0.035),Color(0.07,0.13,0.17))
	Stage.box(self,Vector3(0,0.018,-3.2),Vector3(8.5,0.02,0.1),Color(1,0.65,0.25))
	replay()

func replay() -> void:
	round_id += 1
	for tween in tweens:
		if tween.is_valid(): tween.kill()
	tweens.clear()
	rng.seed = run_seed; safe_door = rng.randi_range(0,2)
	for i in range(3):
		state[i] = "closed"; doors[i].position.y = 1.4; locks[i].set_deferred("disabled",false)
		fire_mesh[i].visible = false; fire[i].get_node("CollisionShape3D").set_deferred("disabled",true)
		labels[i].text = "%d / ?" % (i+1)

func new_seed() -> void:
	rng.randomize(); run_seed = rng.randi_range(10000,99999); replay()

func choose(index: int) -> void:
	if index < 0 or index > 2 or state[index] != "closed": return
	var generation: int = round_id
	state[index] = "opening"; labels[index].text = "%d / OPENING" % (index+1)
	var tw := create_tween(); tweens.append(tw); tw.tween_property(doors[index],"position:y",4.25,0.9)
	# A killed tween never emits finished. The bounded timer still resumes so
	# a replay can cancel this coroutine through round_id without retaining it.
	await get_tree().create_timer(0.9).timeout
	if generation != round_id: return
	locks[index].set_deferred("disabled",true)
	if index == safe_door:
		state[index] = "passage"; labels[index].text = "%d / PASSAGE" % (index+1); return
	state[index] = "warning"; labels[index].text = "%d / FIRE IN 1 SECOND" % (index+1)
	await get_tree().create_timer(1.0).timeout
	if generation != round_id: return
	state[index] = "fire"; labels[index].text = "%d / FIRE" % (index+1)
	var col: CollisionShape3D = fire[index].get_node("CollisionShape3D")
	fire_mesh[index].visible = true; col.set_deferred("disabled",false)
	var jet := create_tween(); tweens.append(jet)
	jet.tween_method(func(length: float):
		fire[index].position.z = -length/2.0
		(col.shape as BoxShape3D).size.z = length
		(fire_mesh[index].mesh as BoxMesh).size.z = length
	,0.1,2.7,0.45)
	await get_tree().create_timer(2.6).timeout
	if generation != round_id: return
	col.set_deferred("disabled",true); fire_mesh[index].visible = false
	state[index] = "closing"
	var close := create_tween(); tweens.append(close); close.tween_property(doors[index],"position:y",1.4,0.8)
	await get_tree().create_timer(0.8).timeout
	if generation != round_id: return
	locks[index].set_deferred("disabled",false); state[index] = "spent"; labels[index].text = "%d / FIRE WAS HERE" % (index+1)

func _burn(body: Node3D) -> void:
	if museum != null: museum.call("_basin_burned",body)

func get_state() -> Dictionary:
	return {"seed":run_seed,"safe_door":safe_door,"doors":state.duplicate(),"round":round_id}
