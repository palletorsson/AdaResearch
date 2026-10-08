extends "res://commons/artifacts/force_play/play_space.gd"
## A hand-sized companion to the tower. Order is a physical arrangement, not a preset.
const TOP := 0.94
var pieces: Array[RigidBody3D]=[]

func _init() -> void:
	kind="stacking_table"

func _ready() -> void:
	super()
	status.position=Vector3(0,1.07,-0.55)
	status.pixel_size=0.0004
	status.text="Grab / turn / stack / release"

func build() -> void:
	extent=Vector2(2.4,1.8)
	fixed(Vector3(0,0.90,0),Vector3(1.64,0.08,1.05),pale)
	for x in [-0.66,0.66]:
		for z in [-0.37,0.37]:fixed(Vector3(x,0.46,z),Vector3(0.12,0.84,0.12),pale)
	# Flat ink insets mark a workspace and spare positions without snapping objects.
	box(Vector3(0,TOP+0.001,0),Vector3(0.43,0.002,0.43),ink)
	for x in [-0.57,0.57]:
		for z in [-0.30,0.0,0.30]:box(Vector3(x,TOP+0.001,z),Vector3(0.33,0.002,0.25),ink)
	# A modest starting stack: cube -> cylinder -> brick. All three are loose bodies.
	pieces.append(solid(Vector3(0,TOP+0.122,0),Vector3.ONE*0.24,0.25,pale))
	pieces.append(cylinder_body(Vector3(0,TOP+0.334,0),0.10,0.18,0.18))
	pieces.append(solid(Vector3(0,TOP+0.466,0),Vector3(0.30,0.08,0.16),0.15,blue))
	# Six alternatives remain within reach on either side.
	pieces.append(solid(Vector3(-0.57,TOP+0.092,-0.30),Vector3.ONE*0.18,0.15,pink))
	pieces.append(solid(Vector3(-0.57,TOP+0.052,0),Vector3(0.30,0.10,0.18),0.18,pale))
	pieces.append(cylinder_body(Vector3(-0.57,TOP+0.112,0.30),0.075,0.22,0.16))
	pieces.append(sphere(Vector3(0.57,TOP+0.112,-0.30),0.11,0.16))
	pieces.append(solid(Vector3(0.57,TOP+0.072,0),Vector3(0.26,0.14,0.19),0.20,blue))
	pieces.append(solid(Vector3(0.57,TOP+0.102,0.30),Vector3.ONE*0.20,0.20,ink))
	for i in pieces.size():
		var piece=pieces[i]
		piece.name="StackPiece"+str(i+1)
		piece.physics_material_override=physics_material(0.8,0)
		piece.set_meta("no_trail",true)
		piece.set_meta("stacking_piece",true)
	words("THE ORDER IS IN YOUR HANDS",Vector3(0,1.83,0.39),0.0004)
	words("Change the bottom. Turn a brick. Try the point.",Vector3(0,1.70,0.39),0.00024)
	words("Loose shapes. Gravity decides what stays.",Vector3(0,1.62,0.39),0.00024)

func control(id: String,_at: Vector3) -> void:
	# Reset is alongside the front edge, within the same reach as the pieces.
	super.control(id,Vector3(1.02,0,-0.45))

func after_reset() -> void:
	recovered=0
