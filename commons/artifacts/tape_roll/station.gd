extends Node3D
## A small temporary supply point. Rolls, timber, sample board and controls stay separate.
const Roll := preload("roll.gd")
const Timber := preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const Plank := preload("res://commons/artifacts/primitive_encounters/timber_plank_1m.tscn")
const ButtonScene := preload("res://commons/interactables/cube_button.tscn")
const Design := preload("tape_design.gd")
var part_defaults: Dictionary = {}
var config_parts: Dictionary = {}
var only_parts: Array = []
var rolls: Array[Node3D] = []
var history: Array[Node3D] = []
var buttons: Dictionary = {}
var home_poses: Dictionary = {}
## The assortment: a rack beside the crate holding the printed roll and the designs in tapes.json (made at
## the tape studio page), up to eight rolls, under the same Undo and Tidy. `assortment: false` leaves the
## three rolls alone as they were.
var assortment := true

func apply_grid_config(config: Dictionary) -> void:
	config_parts = config.get("parts",{}).duplicate(true)
	only_parts = config.get("only_parts",[]).duplicate()
	assortment = bool(config.get("assortment",assortment))
	if is_inside_tree():_apply_parts()

func _ready() -> void:
	var plinth := solid("SupplyCrate",Vector3(0,.30,0),Vector3(1.7,.60,.70),true)
	remember(plinth,Vector3(1.7,.60,.70),"Temporary timber supply crate")
	var board := solid("SampleBoard",Vector3(0,1.38,-.36),Vector3(1.7,1.42,.055),true)
	remember(board,Vector3(1.7,1.42,.055),"Tape onto this board or any solid wall/object")
	var plank := Plank.instantiate();plank.name = "LoosePlank";plank.position = Vector3(0,.65,.31);add_child(plank)
	remember(plank,Vector3(1,.06,.25),"Existing one-metre timber plank / carry it with tape attached")
	for i in 3:
		var roll := Roll.new();roll.kind = Roll.TYPES[i];roll.name = ["MaskingRoll","PinkRoll","BarrierRoll"][i]
		roll.position = Vector3((i-1)*.55,1.16,.01);add_child(roll);rolls.append(roll)
		roll.tape_placed.connect(func(strip):history.append(strip))
		remember(roll,Vector3(.30,.52,.15),roll.kind.capitalize()+" tape / hold, fire A, move, fire B")
		var pin := solid("Spindle%d"%i,Vector3((i-1)*.55,1.16,-.20),Vector3(.026,.026,.34),false)
		remember(pin,Vector3(.026,.026,.34),"Black steel storage pin / not an aiming restriction")
	var controls := Node3D.new();controls.name = "Controls";controls.position = Vector3(0,.42,.42);add_child(controls)
	for row in [["UNDO",-.68,undo],["TIDY",.68,tidy]]:
		var button := ButtonScene.instantiate();button.name = row[0];button.label = row[0];button.cube_size = .055;button.cap_color = Color("ee478f");button.position.x = row[1];controls.add_child(button);button.pressed.connect(row[2]);buttons[row[0]] = button
		# Clearing tape is deliberate click/trigger input, never a plank brushing
		# a destructive control while the player carries it across the work area.
		button.get_node("PushButton/InteractableAreaButton").collision_mask = 0
	label(controls,"CLICK START / MOVE / CLICK END",Vector3(0,.035,0),17)
	label(controls,"SEPARATE OBJECTS BIND / PULL TO PEEL",Vector3(0,-.025,0),13)
	remember(controls,Vector3(1.55,.20,.14),"Undo the last strip / tidy all tape and refill rolls")
	# Short samples let the static editor show the actual skins too.
	var samples := Node3D.new();samples.name = "TapeSamples";samples.position = Vector3(0,1.83,-.326);add_child(samples)
	for i in 3:
		var sample := Roll.Strip.new();sample.name = "Sample%d"%i;samples.add_child(sample)
		sample.tape_width = Roll.WIDTHS[i];sample.material_override = rolls[i].tape_material
		var offset := Vector3((i-1)*.55,0,0)
		sample.draw_between(samples.to_global(offset+Vector3(-.21,-.035,0)),Vector3.BACK,samples.to_global(offset+Vector3(.21,.035,0)),Vector3.BACK)
	remember(samples,Vector3(1.6,.2,.02),"Masking / pink marking / striped barrier samples")
	if assortment:_build_rack()
	_apply_parts()
	for roll in rolls:home_poses[str(roll.name)] = roll.transform

## A timber board standing beside the crate with steel pegs, a roll on each: printed first, then the designs.
func _build_rack() -> void:
	var ids: Array = ["printed"]
	if FileAccess.file_exists(Design.FILE):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(Design.FILE))
		if data is Dictionary:ids.append_array(((data as Dictionary).get("tapes",{}) as Dictionary).keys())
	ids = ids.slice(0,8)
	var board := solid("TapeRack",Vector3(1.6,.95,-.36),Vector3(1.15,1.9,.055),true)
	remember(board,Vector3(1.15,1.9,.055),"Tape rack / the printed roll and the designs made at the tape studio")
	label(board,"MORE TAPE
PRINTED · DESIGNED AT /TAPE-STUDIO",Vector3(0,.84,.03),18)
	for i in ids.size():
		var at := Vector3(1.6+(-.28 if i%2==0 else .28),1.5-floor(i/2.0)*.42,.01)
		var roll := Roll.new()
		if ids[i]=="printed":roll.kind = "printed";roll.name = "PrintedRoll"
		else:roll.tape = str(ids[i]);roll.name = "Tape_"+str(ids[i])
		roll.position = at;add_child(roll);rolls.append(roll)
		roll.tape_placed.connect(func(strip):history.append(strip))
		remember(roll,Vector3(.30,.52,.15),("Printed tape" if ids[i]=="printed" else str(roll.design.get("label",ids[i])))+" / hold, fire A, move, fire B")
		var peg := solid("RackPeg%d"%i,at+Vector3(0,0,-.19),Vector3(.026,.026,.34),false)
		remember(peg,Vector3(.026,.026,.34),"Steel peg on the tape rack")

func solid(id: String,at: Vector3,size: Vector3,wood: bool) -> StaticBody3D:
	var body := StaticBody3D.new();body.name = id;body.position = at;add_child(body)
	var skin := MeshInstance3D.new();skin.mesh = Timber.mesh(size) if wood else BoxMesh.new()
	if wood:skin.material_override = Timber.material()
	else:
		skin.mesh.size = size;var material := StandardMaterial3D.new();material.albedo_color = Color("202128");material.metallic = .7;material.roughness = .4;skin.material_override = material
	body.add_child(skin);var shape := CollisionShape3D.new();var box := BoxShape3D.new();box.size = size;shape.shape = box;body.add_child(shape);return body

func label(host: Node3D,text: String,at: Vector3,font: int) -> void:
	var node := Label3D.new();node.text = text;node.font_size = font;node.pixel_size = .001;node.position = at;host.add_child(node)

func remember(node: Node3D,size: Vector3,caption: String) -> void:
	part_defaults[str(node.name)] = {"position":arr(node.position),"rotation":arr(node.rotation_degrees),"bounds":[-size.x*.5,-size.y*.5,-size.z*.5,size.x,size.y,size.z],"label":caption}

func arr(v: Vector3) -> Array:return [v.x,v.y,v.z]
func vec(a: Array) -> Vector3:return Vector3(a[0],a[1],a[2])

func _apply_parts() -> void:
	for id in config_parts:
		var node := get_node_or_null(NodePath(id)) as Node3D
		if node==null:continue
		var pose: Dictionary = config_parts[id]
		if pose.has("position"):node.position = vec(pose.position)
		if pose.has("rotation"):node.rotation_degrees = vec(pose.rotation)
		if pose.has("scale"):node.scale = vec(pose.scale) if pose.scale is Array else Vector3.ONE*float(pose.scale)
	if not only_parts.is_empty():
		for child in get_children():
			if str(child.name) not in only_parts:
				part_defaults.erase(str(child.name));child.free()
		rolls = rolls.filter(func(roll):return is_instance_valid(roll))

func undo() -> void:
	print("TAPE_UNDO")
	while not history.is_empty():
		var strip = history.pop_back()
		if not is_instance_valid(strip) or strip.is_queued_for_deletion():continue
		var roll = strip.issuer.get_ref()
		if is_instance_valid(roll):roll.remaining = minf(roll.roll_length,roll.remaining+strip.paid_length);roll.cancel()
		strip.queue_free();return

func tidy() -> void:
	print("TAPE_TIDY")
	for roll in rolls:
		roll.clear_tape()
		if not roll.is_picked_up() and home_poses.has(str(roll.name)):
			roll.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;roll.transform = home_poses[str(roll.name)];roll.linear_velocity = Vector3.ZERO;roll.angular_velocity = Vector3.ZERO
	history.clear()

func prepare_editor_preview() -> void:
	for roll in rolls:
		if is_instance_valid(roll):roll.prepare_editor_preview()
