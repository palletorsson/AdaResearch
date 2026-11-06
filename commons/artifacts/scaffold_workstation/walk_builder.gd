extends Node3D
## A generated walk is one ordinary, undoable workshop edit.
const Record=preload("res://commons/artifacts/constructive_walk/walk_record.gd")
const Model=preload("model.gd")
const Kit=preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Furniture=preload("shop_furniture.gd")
const ButtonScene=preload("res://commons/interactables/push_button.tscn")
var work:Node3D
var seed_value:=435
var last_run:Dictionary={}
var title:Label3D
var buttons:Array=[]
var kept_path:="user://constructive_walk_kept.json"
var spatial:=false
var mode_label:Label3D

func configure(station:Node3D)->void:
	work=station
	position=Vector3(0,1.15,.91)
	Kit.box(self,"Plate",Vector3.ZERO,Vector3(.95,.02,.18),Color("25343b"),false)
	title=Kit.label(self,"",Vector3(0,.013,-.065),10);title.rotation.x=-PI/2
	title.modulate=Color("deebe7")
	var captions:=["ADD WALK","NEXT SEED","LOAD KEPT","2D / FLAT"]
	var actions:=[generate,next_seed,load_kept,toggle_mode]
	for i in 4:
		var button:Node3D=Furniture.rectangular_button(ButtonScene)
		button.name=["AddWalk","NextSeed","LoadKept","Mode"][i]
		button.rotation=Vector3.ZERO;button.position=Vector3(-.36+i*.24,.025,-.008)
		button.pressed.connect(actions[i]);add_child(button);buttons.append(button)
		var label:=Kit.label(self,captions[i],Vector3(-.36+i*.24,.014,.055),10)
		label.rotation.x=-PI/2
		label.modulate=Color("deebe7")
		if i==3:mode_label=label
	update_title()

func update_title()->void:title.text="RANDOM WALK / SEED %d / 24 STEPS"%seed_value

func toggle_mode()->void:
	if not editable():return
	spatial=not spatial;mode_label.text="3D / RAMPS" if spatial else "2D / FLAT"
	work.feedback.text="3D: branching paths, landings and supported ramps. ADD WALK, then BUILD." if spatial else "2D: planar points and rods."

func editable()->bool:
	if work.get_meta("place_mode",false):return false
	if not work._interactive or is_instance_valid(work.held) or work.pending_revision:return false
	if work.visit!=null and work.visit.active:
		work.feedback.text="Take off the VR glasses before changing the model.";return false
	return true

func next_seed()->void:
	if not editable():return
	seed_value+=1;update_title();work.feedback.text="Seed %d selected. ADD WALK changes the model."%seed_value

func generate()->void:
	if not editable():return
	if spatial:
		if work.tier<2 or not work.prefabs_enabled:
			work.feedback.text="3D ramps need surfaces and wedges. Use the Polyhedra or later glass workstation.";return
		var route=load("res://commons/artifacts/scaffold_workstation/branching_walk.gd").new(seed_value)
		if not route.valid:work.feedback.text="Generated route failed the workshop grammar; nothing changed.";return
		if apply_walk(route):work.feedback.text="3D walk / %d landings, %d connections. BUILD, then explore with the visor."%[route.nodes.size(),route.links.size()]
		return
	var walk=Record.new(seed_value)
	for i in Record.LIMIT:walk.step()
	apply_walk(walk)

func load_kept()->void:
	if not editable():return
	var data=JSON.parse_string(FileAccess.get_file_as_string(kept_path)) if FileAccess.file_exists(kept_path) else null
	var walk=Record.new()
	if not data is Dictionary or not walk.restore(data):
		work.feedback.text="No compatible kept walk. Keep one at the walk bench first.";return
	if apply_walk(walk):
		spatial=false;mode_label.text="2D / FLAT"

func apply_walk(walk:RefCounted)->bool:
	if not editable():return false
	var trial=Model.new()
	if not trial.restore(work.model.records):return false
	var before:Array=work.model.records.duplicate(true)
	for record in walk.model.records:
		if trial.has_record(record):continue
		if not trial.add(record,work.tier):
			work.feedback.text="Walk conflicts with an existing member. Nothing changed; move it or try another seed.";return false
	# Existing BUILD, sharing, hand editing and UNDO all see the same records.
	work.model=trial;work.remember_edit(before);work.share();work.redraw()
	seed_value=walk.seed_value;last_run=walk.snapshot();update_title()
	work.feedback.text="Walk added / %d new pieces. BUILD copies this model into the glass room; wear the visor to enter."%(trial.records.size()-before.size())
	return true
