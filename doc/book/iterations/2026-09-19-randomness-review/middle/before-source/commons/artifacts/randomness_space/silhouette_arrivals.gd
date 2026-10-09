extends Node3D
## Sampling without replacement: arrivals occupy six authored, safe positions.
## Separate streams keep changing dress from changing the arrival sequence.
const Sprite = preload("res://commons/hazards/catalyst_foe/silhouette_sprite.gd")
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
var rng := RandomNumberGenerator.new()
var run_seed: int = 27183
var dress_seed: int = 800
var repertoire: int = 0
var people: Array[Node3D] = []
var available: Array[int] = []
var history: Array[int] = []
var remaining: float = 1.0
var automatic: bool = true
var plate: Label3D

func _ready() -> void:
	Stage.box(self,Vector3(0,0.015,0),Vector3(2.8,0.025,2.4),Color(0.22,0.29,0.34))
	var panel := Rack.create_panel("WHO ARRIVES?",[[{"type":"button","label":"ARRIVE"},{"type":"button","label":"AUTO"}],[{"type":"button","label":"REPLAY"},{"type":"button","label":"DRESS"}],[{"type":"button","label":"FORMS"}]])
	panel.position = Vector3(0,1.1,-1.65); panel.rotation.y = PI; add_child(panel)
	panel.find_child("Btn_0",true,false).pressed.connect(arrive)
	panel.find_child("Btn_1",true,false).pressed.connect(func(): automatic = not automatic; _readout())
	panel.find_child("Btn_2",true,false).pressed.connect(replay)
	panel.find_child("Btn_3",true,false).pressed.connect(redress)
	panel.find_child("Btn_4",true,false).pressed.connect(change_forms)
	plate = Stage.label(self,"",Vector3(0,0.58,-1.65),PI)
	plate.font_size = 22; plate.pixel_size = 0.0015
	Stage.box(self,plate.position+Vector3(0,0,0.025),Vector3(1.2,0.22,0.03),Color(0.07,0.12,0.16,0.8))
	replay()

func _process(delta: float) -> void:
	if not automatic or available.is_empty(): return
	remaining -= delta
	if remaining <= 0.0: arrive()

func replay() -> void:
	for person in people: remove_child(person); person.queue_free()
	people.clear(); history.clear(); available.assign([0,1,2,3,4,5])
	rng.seed = run_seed; remaining = rng.randf_range(1.5,3.5)
	_readout()

func arrive() -> void:
	if available.is_empty(): return
	var index: int = rng.randi_range(0,available.size()-1)
	var slot: int = available[index]; available.remove_at(index); history.append(slot)
	var person := MeshInstance3D.new(); person.name = "Visitor%d" % slot
	var mesh := QuadMesh.new(); mesh.size = Vector2(0.64,1.8)
	person.mesh = mesh
	person.position = Vector3((slot%3-1)*0.85,0.93,(slot/3)*1.1-0.55)
	person.set_meta("slot",slot); person.material_override = _dress(slot)
	add_child(person); people.append(person)
	remaining = rng.randf_range(1.5,3.5); _readout()

func _dress(slot: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(Sprite.make_dressed_image(run_seed+slot,dress_seed,repertoire))
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func redress() -> void:
	dress_seed += 1
	for person in people: person.material_override = _dress(int(person.get_meta("slot")))
	_readout()

func change_forms() -> void:
	repertoire = 1-repertoire
	for person in people: person.material_override = _dress(int(person.get_meta("slot")))
	_readout()

func _readout() -> void:
	if plate: plate.text = "SEED %d / %d OF 6 / %s\nDRESS %d / %s" % [run_seed,people.size(),"AUTO" if automatic else "MANUAL",dress_seed,"TAILORED + BRANCHES" if repertoire == 1 else "TAILORED"]
