extends Node3D
## The body of parts, as a guest of the room: four parts of different origin
## under one root, each on a pivot. It is the lesson's body.gd with three things
## changed. The parts are read from this folder. The pivots stand close enough
## together for the body to fit on one place, 1.6 m wide and deep. And each part
## is painted in one colour of the course look, written out here as hex, because
## a guest names nothing outside its folder.
## Who is whose parent is the second word of each add_part() line. It is yours.

const BODY := Color("c6ff3d")     # the cube
const SECOND := Color("22d9ff")   # the plane
const THIRD := Color("ff8b1f")    # the limb
const BONE := Color("f4efe6")     # the point, and any part with no colour in the list
const COLOURS := {"point": BONE, "plane": SECOND, "cube": BODY, "limb": THIRD}

# where each pivot stands, in the body's own numbers: metres from the root
var point_at := Vector3(0.6, 0.075, 0.5)
var plane_at := Vector3(0.0, 0.02, 0.0)
var cube_at := Vector3(-0.2, 0.25, -0.45)
var limb_at := Vector3(-0.2, 0.25, -0.2)
var walk_middle := Vector3(1.2, 1.12, 0.45)   # the middle of our walk, in the walk's own numbers

var speed := deg_to_rad(30.0)   # radians per second
var limit := deg_to_rad(30.0)   # the turn stops here
var angle := 0.0
var pivots: Array[Node3D] = []

func _ready() -> void:
	add_part("point", self, point_at, Vector3.ZERO)
	add_part("plane", self, plane_at, walk_middle)
	add_part("cube", self, cube_at, Vector3.ZERO)
	add_part("limb", self, limb_at, Vector3.ZERO)

func add_part(kind: String, parent: Node3D, at: Vector3, middle: Vector3) -> Node3D:
	var pivot := Node3D.new()
	parent.add_child(pivot)
	pivot.global_position = to_global(at)
	var part: Node3D = load("res://guests/body-of-parts/" + kind + "_part.tscn").instantiate()
	pivot.add_child(part)
	part.position = -middle
	pivot.name = part.name + "Pivot"
	pivots.append(pivot)
	paint(part, COLOURS.get(kind, BONE))
	return pivot

## Supplied: one matt material in `colour` on the part and on every mesh below it.
func paint(part: Node, colour: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.8
	var meshes: Array[Node] = part.find_children("*", "MeshInstance3D", true, false)
	meshes.append(part)
	for mesh in meshes:
		if mesh is MeshInstance3D:
			mesh.material_override = material

func _process(delta: float) -> void:
	angle += speed * delta
	if angle > limit:
		angle = limit
	for pivot in pivots:
		pivot.rotation.y = angle
