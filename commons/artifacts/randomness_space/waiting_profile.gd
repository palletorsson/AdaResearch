extends Node3D
## Restore the wooden pickup-cube encounter with two bounded arrival slots.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const CUBE = preload("res://commons/primitives/cubes/grab_cube_wood.tscn")
var rng := RandomNumberGenerator.new()
var cubes: Array[Node3D] = [null,null]
var running: bool = true
var next_wait: float = 1.0
var waits: Array[float] = []
var slot: int = 0
var plate: Label3D

## THE PROFILE AS A LANDSCAPE (Palle, 2026-09-16): several profiles stacked in +z, away from
## the visitor, with the random ridge line around eye height so the eye looks ACROSS the
## ridges instead of down at one, and the front panels darkest so the layers read as depth.
## ProfileRandom draws its ridge around base_height 1.0 above its own origin, so a layer
## origin at RIDGE_EYE_Y - 1.0 puts the mean ridge at RIDGE_EYE_Y. The front layer keeps the
## original seed 1955, so the first ridge a visitor saw before this change is unchanged.
const PROFILE_LAYERS := 5
const LAYER_STEP_Z := 0.3
const RIDGE_EYE_Y := 1.7
const PROFILE_BASE_HEIGHT := 1.0
const LAYER_COLOR_FRONT := Color(0.06, 0.06, 0.07)
const LAYER_COLOR_BACK := Color(0.62, 0.62, 0.66)
var profiles: Array[Node3D] = []

func _ready() -> void:
	rng.seed = 1955
	Stage.box(self,Vector3(-1.7,0.35,0),Vector3(2,0.7,2),Color(0.23,0.31,0.35),true)
	Stage.label(self,"WAIT / TWO PLACES",Vector3(-1.7,0.95,1),PI).font_size = 24
	var layer_y := RIDGE_EYE_Y - PROFILE_BASE_HEIGHT
	var profile_scene: PackedScene = load("res://algorithms/randomness/profile_random.tscn")
	for i in PROFILE_LAYERS:
		var layer: Node3D = profile_scene.instantiate()
		layer.profile_seed = 1955 + i; layer.point_count = 17; layer.profile_width = 2.6; layer.max_height_variation = 0.6
		# Darkest at the front (i = 0, nearest the visitor at -z), lightest at the back.
		# Set BEFORE add_child: ProfileRandom caches this material in _ready and re-applies it
		# on every PROFILE press, so the ramp survives regeneration.
		var plane := layer.get_node_or_null("RandomPlane") as MeshInstance3D
		if plane != null:
			var mat := StandardMaterial3D.new()
			var t := float(i) / float(maxi(PROFILE_LAYERS - 1, 1))
			mat.albedo_color = LAYER_COLOR_FRONT.lerp(LAYER_COLOR_BACK, t)
			mat.roughness = 0.95
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			plane.material_override = mat
		layer.position = Vector3(1.4, layer_y, i * LAYER_STEP_Z)
		add_child(layer)
		profiles.append(layer)
	# One plinth under every layer, its top 1 cm below the layers' base so the faces do not z-fight.
	var depth := (PROFILE_LAYERS - 1) * LAYER_STEP_Z + 0.3
	Stage.box(self,Vector3(1.4,(layer_y - 0.01) * 0.5,(PROFILE_LAYERS - 1) * LAYER_STEP_Z * 0.5),Vector3(2.8,layer_y - 0.01,depth),Color(0.23,0.31,0.35),true)
	# Above the highest possible ridge (RIDGE_EYE_Y + max_height_variation = 2.3 m), in front of the first layer.
	Stage.label(self,"17 HEIGHTS / FIXED ENDS",Vector3(1.4,2.55,-0.2),PI).font_size = 24
	var panel := Rack.create_panel("WAIT / SEE",[[{"type":"button","label":"RUN / STOP"},{"type":"button","label":"REPLAY"}],[{"type":"button","label":"PROFILE"}]])
	panel.position = Vector3(0,1.1,-1.7); panel.rotation.y = PI; add_child(panel)
	panel.find_child("Btn_0",true,false).pressed.connect(func(): running = not running)
	panel.find_child("Btn_1",true,false).pressed.connect(replay)
	panel.find_child("Btn_2",true,false).pressed.connect(next_profile)
	plate = Stage.label(self,"First arrival after 1 second",Vector3(0,0.55,-1.72),PI)
	plate.font_size = 22; plate.pixel_size = 0.0015
	Stage.box(self,plate.position+Vector3(0,0,0.02),Vector3(1.5,0.2,0.03),Color(0.08,0.13,0.17))

func _held() -> bool:
	for cube in cubes:
		if is_instance_valid(cube) and cube.is_picked_up(): return true
	return false

func _process(delta: float) -> void:
	if not running or _held(): return
	next_wait -= delta
	if next_wait <= 0: arrive()

func arrive() -> void:
	if _held(): return
	if is_instance_valid(cubes[slot]):
		remove_child(cubes[slot]); cubes[slot].queue_free()
	var cube: Node3D = CUBE.instantiate()
	cube.position = Vector3(-1.7+(-0.45 if slot==0 else 0.45),3,0)
	add_child(cube)
	cube.freeze = false; cube.sleeping = false
	cubes[slot] = cube; slot = 1-slot
	next_wait = rng.randf_range(0.3,1.3); waits.append(next_wait)
	if waits.size()>64: waits.pop_front()
	plate.text = "LAST DRAW %.2f s / TWO CUBES MAX\nHolding a cube suspends arrivals" % next_wait

func replay() -> void:
	if _held(): return
	for cube in cubes:
		if is_instance_valid(cube): remove_child(cube); cube.queue_free()
	cubes.assign([null,null]); slot=0; waits.clear(); rng.seed=1955; next_wait=1.0
	plate.text = "REPLAY / First arrival after 1 second"

func next_profile() -> void:
	for layer in profiles:
		layer.profile_seed += 1
		layer.rng.seed = layer.profile_seed
		layer.generate_random_profile()
