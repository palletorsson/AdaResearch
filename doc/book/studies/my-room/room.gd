extends Node3D
## My room. Every chapter hands it one body, a guest, and the room stands each
## guest on the next free place. To add a guest: copy its folder into guests/,
## then add its scene to the list below. That is the only thing to edit here.

const GUESTS: Array[String] = [
	"res://guests/example/example.tscn",
]

const Look := preload("res://room_look.gd")   # the room's own colours and light: yours to change
const COLUMNS := 8      # places in one row
const ROWS := 5         # rows: 8 x 5 is 40 places
const STEP := 2.0       # metres from one place to the next in its row
const AISLE := 4.0      # metres from one row to the next: room for a walker between two rows

var guests: Array[Node3D] = []   # who stands in the room: guests[0] is at place 1
var said: Array[String] = []     # every line the room has printed

func _ready() -> void:
	_dress()
	_mark_places()
	place_guests(GUESTS)

## Where a place is. Place 1 is the first of the front row, straight ahead of
## where the walker starts; place 9 is the first of the second row.
func place(number: int) -> Vector3:
	var index := number - 1
	@warning_ignore("integer_division")
	var row := index / COLUMNS
	return Vector3((index % COLUMNS - (COLUMNS - 1) / 2.0) * STEP, 0.0, -row * AISLE)

## Stands one guest for each path of the list, in order, each on the next free
## place. A path that does not give a guest gets one printed line and no place.
func place_guests(paths: Array) -> void:
	for guest in guests:
		guest.free()
	guests.clear()
	for path: String in paths:
		if guests.size() == COLUMNS * ROWS:
			say("My room has %d places and all are taken: %s was not placed, and nothing after it in GUESTS" % [COLUMNS * ROWS, path])
			break
		var guest := _load_guest(path)
		if guest == null:
			continue
		guest.position = place(guests.size() + 1)
		add_child(guest)
		guests.append(guest)
		say("My room: place %d is %s" % [guests.size(), path])

## The guest a path gives, or null and one line that says why not.
func _load_guest(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		say("My room: no scene at %s. Check the line in GUESTS against the folder in guests/. The room goes on without it" % path)
		return null
	var scene: Resource = load(path)
	if not scene is PackedScene or not scene.can_instantiate():
		say("My room: %s is there but does not load as a scene; Godot's own lines above say why. The room goes on without it" % path)
		return null
	var guest: Node = scene.instantiate()
	if not guest is Node3D:
		say("My room: %s loads, but its first node is a %s. A guest's first node has to be a Node3D, or a kind of it. The room goes on without it" % [path, guest.get_class()])
		guest.free()
		return null
	return guest

func say(line: String) -> void:
	print(line)
	said.append(line)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("drop"):
		# One metre in front of the walker, from above its head.
		$Marble.drop($Walker.global_position - $Walker.global_basis.z + Vector3(0.0, 2.2, 0.0))

## The sky, the sun and the floor's colour, from room_look.gd.
func _dress() -> void:
	var sky := WorldEnvironment.new()
	sky.name = "Sky"
	sky.environment = Look.environment()
	add_child(sky)
	var sun := Look.sun()
	sun.name = "Sun"
	sun.shadow_blur = Look.SHADOW_BLUR
	add_child(sun)
	var fill := Look.fill()
	fill.name = "Fill"
	add_child(fill)
	$Floor.material_override = Look.paint(Look.GROUND)

## A dark square for each place, the size a guest may take, and its number.
func _mark_places() -> void:
	var square := PlaneMesh.new()
	square.size = Vector2(1.6, 1.6)
	square.material = Look.paint(Look.SHADE)
	for number in range(1, COLUMNS * ROWS + 1):
		var mark := MeshInstance3D.new()
		mark.mesh = square
		mark.position = place(number) + Vector3(0.0, 0.01, 0.0)
		add_child(mark)
		var label := Look.label(str(number))
		label.font_size = 96
		label.rotation.x = -PI / 2.0    # flat on the floor, its top away from the walker's start
		label.position = place(number) + Vector3(0.0, 0.02, 1.0)
		add_child(label)
