extends "res://commons/artifacts/spine_studies/study_forms.gd"
## An original Ada application in relation to Gonzalez-Torres's paired clocks.
## All input is supplied by the museum's pointer buttons; no new player/camera.
var score = preload("res://commons/artifacts/spine_studies/paired_time_score.gd").new()
var hands: Array[Node3D] = []
var readout: Label3D
var reveal := false

func _ready() -> void:
	block(Vector3(0,2.3,-3.5),Vector3(8.2,4.6,0.18),Color("eeeae2"),true)
	inscription("A SECOND TOGETHER",Vector3(0,4.15,-3.38),0.0034)
	for i in 2: make_dial(Vector3(-0.97 if i == 0 else 0.97,2.8,-3.25))
	inscription("12 s / TURN  ·  SIMULATED TIME",Vector3(0,1.55,-3.36),0.0021,Color("68616b"))
	readout = inscription("",Vector3(0,0.85,-3.35),0.0028,Color("8b3c5b"))
	sync_display()

func disc(at: Vector3, radius: float, depth: float, colour: Color) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius; cylinder.bottom_radius = radius
	cylinder.height = depth; cylinder.radial_segments = 96; cylinder.rings = 1
	var mesh := MeshInstance3D.new(); mesh.mesh = cylinder
	mesh.material_override = material(colour); mesh.position = at
	mesh.rotation.x = PI / 2.0; add_child(mesh)

func make_dial(at: Vector3) -> void:
	disc(at,0.97,0.15,Color("29272b"))
	disc(at+Vector3(0,0,0.086),0.9,0.018,Color("f7f4ec"))
	for i in 60:
		var angle := TAU * i / 60.0
		var major := i % 5 == 0
		var radial := Vector3(sin(angle),cos(angle),0)
		var mark := block(at + radial * 0.81 + Vector3(0,0,0.103),Vector3(0.023 if major else 0.009,0.11 if major else 0.035,0.008),Color("3a373e"))
		mark.rotation.z = -angle
	var pivot := Node3D.new(); add_child(pivot); pivot.position = at+Vector3(0,0,0.13)
	var needle := block(Vector3(0,0.29,0),Vector3(0.025,0.78,0.014),Color("28252d"))
	needle.reparent(pivot,false)
	var tip := block(Vector3(0,0.67,0.004),Vector3(0.033,0.12,0.018),Color("b34e78"))
	tip.reparent(pivot,false)
	disc(at+Vector3(0,0,0.15),0.043,0.025,Color("b34e78"))
	hands.append(pivot)

func _process(delta: float) -> void:
	score.advance(delta)
	sync_display()

func sync_display() -> void:
	hands[0].rotation.z = -score.left_angle
	hands[1].rotation.z = -score.right_angle
	readout.visible = reveal
	readout.text = "LEFT × 1.00    RIGHT × %.2f\nRIGHT AHEAD: %.1f°    %s" % [score.right_ratio,score.gap_degrees(),"HELD" if score.paused else "RUNNING"]

func control(index: int) -> void:
	match index:
		0: score.drift()
		1: score.same_rate()
		2: score.offset()
		3: score.align()
		4: score.paused = not score.paused
		5: reveal = not reveal
		6: score.reset(); reveal = false
	sync_display()
