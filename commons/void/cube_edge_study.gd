extends Node3D
## A measuring instrument for the existing paired-cube experiment.
## The original artifact still owns its vertices, faces, grabbing and reset.
const G = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")
const STEP := 0.25
var pair: Node3D
var readout: Label3D
var markers: Array[MeshInstance3D] = []
var depths := Vector2.ZERO
var difference := 0.0
var last_reading := ""

func _ready() -> void:
	pair = get_parent() as Node3D
	# Everything travels with the paired cubes when moved in the editor.
	G.box(self,"ReadingPlate",Vector3(0,2.08,-.64),Vector3(2.9,.72,.035),Color("24222b"),false)
	readout = G.label(self,"",Vector3(0,2.08,-.615),40)
	readout.modulate = Color("f3e9e8")
	readout.no_depth_test = false
	G.box(self,"TrialRail",Vector3(1.16,.71,1.08),Vector3(.68,.05,.38),Color("3d434b"))
	var button := ButtonScene.instantiate() as Node3D
	button.name = "Try25cm"
	button.position = Vector3(1.16,.75,1.08)
	button.rotation.x = -PI/2
	add_child(button)
	button.pressed.connect(try_step)
	var label := G.label(self,"TRY 25 cm",Vector3(1.16,.745,1.26),20)
	label.rotation.x = -PI/2
	label.modulate = Color("f3e9e8")
	for side in 2:
		var marker := MeshInstance3D.new()
		marker.name = "EdgeMidpointA" if side == 0 else "EdgeMidpointB"
		var mesh := SphereMesh.new()
		mesh.radius = .023
		mesh.height = .046
		mesh.radial_segments = 12
		mesh.rings = 6
		marker.mesh = mesh
		var material := G.material(Color("ffd8aa"))
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		marker.material_override = material
		add_child(marker)
		markers.append(marker)
	update_reading()

func try_step() -> void:
	if pair.held() or pair.replaying:
		return
	pair.restore()
	if pair.free_edit:
		pair.toggle_free()
	# The same real handle that the hand moves. The original _process mirrors it.
	pair.cubes[0].handle_nodes[6].position.z += STEP

func _process(_delta: float) -> void:
	update_reading()

func update_reading() -> void:
	if not is_instance_valid(pair) or pair.cubes.size() != 2:
		return
	depths = Vector2(pair.centre_depth(0),pair.centre_depth(1))
	difference = absf(depths.y-depths.x)
	for side in 2:
		# Mark the midpoint of the ACTUAL shared triangle edge, not a new vertex.
		var cube: Node3D = pair.cubes[side]
		markers[side].position = cube.transform * pair.diagonals[side].position
		markers[side].visible = not pair.replaying
	var explanation := "White dots mark edge midpoints."
	if pair.free_edit:
		explanation = "FREE: midpoints may differ in x and y too."
	var reading := "SHARED EDGE / LOCAL z\nA %.3f m      B %.3f m\nDEPTH DIFFERENCE %.3f m\n%s" % [depths.x,depths.y,difference,explanation]
	if pair.replaying:
		reading = "REPLAYING THE CURRENT CONSTRUCTION\nThe positions have not been reset."
	if reading != last_reading:
		readout.text = reading
		last_reading = reading
