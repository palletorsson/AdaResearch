extends Node3D
## One retained X/Z array, shown as a plan and extruded along Y.
## A declared passage mask keeps the room traversable under every seed/driver.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const SIDE := 8
const PITCH := 1.1
const TURN_COLUMNS := [4,4,3,3,5,5,2,0]
var seed_value := 42
var driver := "independent"
var frequency := 0.12
var raised := true
var lift := 1.0
var values: Array[float] = []
var independent: Array[float] = []
var heights: Array[float] = []
var passage: Array[int] = []
var blocks: Array[MeshInstance3D] = []
var boundaries: Array[CollisionShape3D] = []
var plan_cells: Array[MeshInstance3D] = []
var zone: Area3D
var panel: Node3D
var status: Label3D
var museum: Node
var _busy_notice := false

func apply_grid_config(cfg: Dictionary) -> void:
	seed_value=int(cfg.get("seed",seed_value))

func _ready() -> void:
	set_meta("em_keep_scale",true)
	set_meta("em_visibility_bounds",AABB(Vector3(-4.5,0,-5.8),Vector3(9,4.3,10.3)))
	museum=get_parent()
	while museum!=null and not museum.has_method("_basin_burned"):museum=museum.get_parent()
	_build_passage()
	_build_geometry()
	_build_console()
	zone=Area3D.new();zone.collision_layer=0;zone.collision_mask=1|524288
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(SIDE*PITCH,4.5,SIDE*PITCH)
	shape.shape=box;shape.position.y=2.2;zone.add_child(shape);add_child(zone)
	generate()

func _build_passage() -> void:
	for z in range(SIDE):
		var from:int=TURN_COLUMNS[maxi(0,z-1)]
		var to:int=TURN_COLUMNS[z]
		for x in range(mini(from,to),maxi(from,to)+1):passage.append(z*SIDE+x)

func centre(index: int) -> Vector3:
	return Vector3((index%SIDE-3.5)*PITCH,0,(index/SIDE-3.5)*PITCH)

func _build_geometry() -> void:
	for i in range(SIDE*SIDE):
		var block:=Stage.box(self,centre(i),Vector3(1.04,1,1.04),Color.WHITE)
		blocks.append(block)
		var body:=StaticBody3D.new();body.position=centre(i);add_child(body)
		var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(1.04,1,1.04)
		collision.shape=box;body.add_child(collision);boundaries.append(collision)
		# A matching address grid, at the entrance and facing the approaching body.
		var x:=i%SIDE;var z:=i/SIDE
		plan_cells.append(Stage.box(self,Vector3(-2.4+(x-3.5)*0.17,1.9+(3.5-z)*0.17,-5.36),Vector3(0.16,0.16,0.025),Color.WHITE))
	Stage.box(self,Vector3(-2.4,1.9,-5.30),Vector3(1.55,1.55,0.07),Color("172830"))
	var title:=Stage.label(self,"A PLAN BECOMES A ROOM",Vector3(0,3.85,-4.5),PI)
	title.font_size=48;title.pixel_size=0.002
	var caption:=Stage.label(self,"X / Z PLAN   →   Y HEIGHT",Vector3(-2.4,2.79,-5.39),PI)
	caption.font_size=25;caption.pixel_size=0.0017
	var entry:=Stage.label(self,"ENTER THE BLUE PATH\nThese cells are kept open by a rule.",Vector3(1.4,0.08,-4.83),PI)
	entry.rotation_degrees.x=-75;entry.pixel_size=0.0015;entry.font_size=30

func _build_console() -> void:
	panel=Rack.create_panel("SEED / PLAN / HEIGHT",[
		[{"type":"button","label":"REPLAY","shape":"rect"},{"type":"button","label":"NEXT SEED","shape":"rect"},{"type":"button","label":"FLAT / RAISE","shape":"rect"}],
		[{"type":"button","label":"INDEPENDENT","shape":"rect"},{"type":"button","label":"PERLIN","shape":"rect"},{"type":"button","label":"FREQUENCY","shape":"rect"}]])
	panel.position=Vector3(-2.4,1.01,-5.60);panel.rotation_degrees=Vector3(-25,180,0);panel.scale=Vector3.ONE*3
	panel.set_meta("em_local_instrument",true);add_child(panel)
	for i in range(6):panel.find_child("Btn_"+str(i),true,false).pressed.connect(activate.bind(i))
	Stage.box(self,Vector3(-2.4,0.5,-5.4),Vector3(0.2,1,0.2),Color("283b42"),true)
	status=Stage.label(self,"",Vector3(-2.4,3.25,-5.3),PI)
	status.font_size=25;status.pixel_size=0.0014;status.outline_size=0
	Stage.box(self,status.position+Vector3(0,0,0.035),Vector3(2.3,0.65,0.05),Color("172830"))

func generate() -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var noise:=FastNoiseLite.new();noise.seed=seed_value
	noise.noise_type=FastNoiseLite.TYPE_PERLIN;noise.fractal_type=FastNoiseLite.FRACTAL_NONE;noise.frequency=frequency
	independent.clear();values.clear();heights.clear()
	for i in range(SIDE*SIDE):
		var u:=rng.randf();independent.append(u)
		if driver=="perlin":u=clampf(0.5+noise.get_noise_2d(i%SIDE,i/SIDE)*0.9,0,1)
		values.append(u)
		var solid:=u>=0.48 and not passage.has(i)
		heights.append(1.7+1.7*u if solid else 0.025)
		var colour:=Color("d88a59").lerp(Color("5a4582"),u)
		if passage.has(i):colour=Color("74d6ce")
		elif not solid:colour=colour.lightened(0.35)
		blocks[i].material_override.albedo_color=colour
		plan_cells[i].material_override.albedo_color=colour
	apply_height()
	show_status()

func apply_height() -> void:
	for i in range(blocks.size()):
		var height:=lerpf(0.025,heights[i],lift)
		blocks[i].mesh.size.y=height
		blocks[i].position.y=height/2.0
		boundaries[i].shape.size.y=height
		boundaries[i].position.y=height/2.0

func _physics_process(delta: float) -> void:
	var target:=1.0 if raised else 0.0
	if not is_equal_approx(lift,target):
		# A visitor who enters during extrusion arrests the rise, instead of
		# being caught by a growing wall. Lowering is likewise held for clarity.
		if occupied():
			if not _busy_notice:show_status("Step out to continue raising or lowering.");_busy_notice=true
			return
		if _busy_notice:_busy_notice=false;show_status()
		lift=move_toward(lift,target,delta*0.65);apply_height()

func occupied() -> bool:
	for body in zone.get_overlapping_bodies():
		if body.is_in_group("player") or body.is_in_group("player_body") or body.is_in_group("vr_player"):return true
		if museum!=null and body==museum.get("_player"):return true
	return false

func activate(index: int) -> void:
	if occupied():show_status("Return to the entrance before changing the room.");return
	match index:
		0: pass
		1: seed_value=(seed_value+1)%100000
		2:
			raised=not raised;show_status();return
		3: driver="independent"
		4: driver="perlin"
		5: frequency=0.32 if frequency<0.2 else 0.12
	generate()

func show_status(message: String = "") -> void:
	status.text="SEED %d · %s\n8 × 8 addresses · frequency %.2f\n%s\nThe blue path stays open." % [seed_value,driver.to_upper(),frequency,message if message!="" else ("RAISED / Same plan, new height." if raised else "FLAT / RAISE keeps these values.")]

func capture_museum_state() -> Dictionary:
	return {"seed":seed_value,"driver":driver,"frequency":frequency,"raised":raised}

func restore_museum_state(saved: Dictionary) -> void:
	seed_value=int(saved.get("seed",42));driver=str(saved.get("driver","independent"))
	frequency=float(saved.get("frequency",0.12));raised=bool(saved.get("raised",true));lift=1.0 if raised else 0.0
	generate()
