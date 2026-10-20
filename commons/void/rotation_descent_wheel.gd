extends Node3D
## The Rotation museum's upright end-platform, carried through a vertical
## half-turn between two storeys. The visitor's view never rolls with the wheel.
const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
const RideDeck = preload("res://commons/artifacts/rotation_studies/rotation_rider_deck.gd")
var deck: Node3D
var rotor: Node3D
var bracket: Node3D
var readout: Label3D
var elapsed := 0.0
var progress := 0.0
var radius := 3.0
var turn_speed := 12.0
var hold := 8.0
var preview := false

func _ready() -> void:
	process_physics_priority = -110
	set_meta("source_artifact", "rotation_wall_crossings / X / LevelEndPlatform")
	turn_speed = clampf(float(get_meta("config_turn_speed", 12)), 5, 20)
	hold = clampf(float(get_meta("config_pause", 8)), 6, 20)
	rotor = Node3D.new()
	rotor.name = "Wheel"
	rotor.position = Vector3(.65,-radius,-.6)
	add_child(rotor)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius-.10; torus.outer_radius = radius+.10
	torus.rings = 48; torus.ring_segments = 6
	ring.mesh=torus; ring.rotation_degrees.z=90
	var steel := StandardMaterial3D.new()
	steel.albedo_color=Color("596675"); steel.metallic=.55; steel.roughness=.65
	ring.material_override=steel;rotor.add_child(ring)
	for index in range(8):
		var spoke := Parts.box(rotor,"Spoke%d"%index,Vector3(.1,radius*2,.08),Vector3.ZERO,Color("d09b57"),false)
		spoke.rotation.x=TAU*index/8
	Parts.axis(self,rotor.position,Vector3.RIGHT,Color("a5bbc8"),4.6)
	deck=RideDeck.new()
	deck.name="LevelEndPlatform"
	deck.along_z=false # Open on the west side, directly against the slab edge.
	add_child(deck)
	bracket=Parts.box(self,"UprightBracket",Vector3(2.15,.10,.10),Vector3.ZERO,Color("d09b57"),false)
	readout=Parts.label(self,"",Vector3(-3.5,1.5,-1.8),26)
	readout.pixel_size=.0025
	readout.outline_size=3
	_pose(0)

func _physics_process(delta: float) -> void:
	if preview:return
	elapsed+=delta
	var duration:=180.0/turn_speed
	var period:=duration+hold
	var leg:=floori(elapsed/period)
	var amount:=clampf((fposmod(elapsed,period)-hold)/duration,0,1)
	progress=amount if leg%2==0 else 1.0-amount
	_pose(progress)

func _pose(amount: float) -> void:
	rotor.rotation.x=PI*amount
	var end:=Vector3(-1.5,-radius+radius*cos(PI*amount),-.6+radius*sin(PI*amount))
	deck.transport_to(end)
	bracket.position=end+Vector3(1.075,-.15,0)
	readout.text="X / RIDE THE HALF-TURN DOWN\nKEEP YOUR FEET ON THE LEVEL PLATFORM\n%s" % ("BOARD / WEST EDGE" if amount<.001 else ("STEP OFF / NEXT FLOOR" if amount>.999 else "THE AXLE STAYS / YOU FOLLOW THE ARC"))

func prepare_editor_preview() -> void:
	preview=true
	_pose(0)
