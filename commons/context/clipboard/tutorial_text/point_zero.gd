extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[font_size=28][b]0. Point Zero[/b][/font_size]

Ada fade from black.
 
Revealing what was already present.

Scene Zero features a [b]Symbolic Arrow[/b] whose trajectory points back through [b]Vector Zero[/b]. If Vector Zero is the origin, the arrow marks the accumulation of prerequisites—the scaffolding that already exists.

[color=green][b]Code[/b][/color]
[color=green] [code]
var vector_zero = Vector3(0, 0, 0)
var vector_pointing = Vector3(0, 0, 1)
[/code] [/color]
[hr]

In the virtual world, those prerequisites are the rendering system, the players embodiment in the 3D coordinate grid, and the clock that advances every frame—everything required to compute Euclidean space and its unfolding time.

For Ada Research, the chosen framework—the Godot game engine paired with the XR toolkit—already encodes functions Ada Research depend on. In the scene the is a floor to stand on and a body to move with. 

These are structures of endless descent, always partly ignored. They are functions of time, makers of space, reminders of the worlds primal uncomputability. They are the elements we set aside for now or forever—the inexplicable beginnings we circle back to when time permits, the inherent background hum. Indexes turned into dust.

Ada Reseach is another onion layer of Heidegger’s thrownness: we arrive already in motion, inside systems we did not author, and we must ignore most of that inheritance just to take the next step.

---

[b]The Symbolic Layer: Forced Convenience [/b]

We might wish to resist slipping in an arrow of direction, for a pointer inevitably sirens with [b]authorial will to steer[/b]. Yet, this resistance is futile; the world slips into convenience. The arrow introduces a symbolic layer of [b]forced convenience[/b] in stark contrast to the [b]background void[/b]. This layer is the [b]foreground[/b]—the symbolic interface designed to manage the player's [b]dread[/b] and guide their perception. This forces the question: [b]How do we get here?[/b] 

[hr]

This vector has many names: Vector3(0, 0, 0), origin, *, Vector3.ZERO, Zero Vector, World origin, Coordinate zero, The center of the coordinate system, The birth of space, The coordinate of silence, The root of all vectors.


[color=green][b]Full Code[/b][/color]
[color=green] [code]
extends Node3D

## AXIOM 0: The origin (0, 0, 0) is the reference point
## from which all positions are measured.

const ORIGIN_ALIASES := [
	"(0,0,0)",
	"Vector3(0, 0, 0)",
	"origin",
	"*",
	"Vector3.ZERO",
	"Zero Vector",
	"World origin", 
	"Coordinate zero",
	"The center of the coordinate system",
	"The birth of space", 
	"The coordinate of silence", 
	"The root of all vectors"
] 
# The origin - the center of our 3D universe
var origin = Vector3(0, 0, 0)
var _origin_label: Label3D
var _alias_index := 0
var _alias_timer: Timer

func _ready():
	print("The center of our 3D universe: ", origin)

	# Create a visual representation of the origin
	create_origin_marker()
	_start_origin_alias_cycle()


func create_origin_marker():
	"""Create a small sphere to mark the origin point"""
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.01
	sphere_mesh.height = 0.025

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = origin  # At (0, 0, 0)

	# Make it a bright color so it stands out
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_energy = 10.0
	mesh_instance.set_surface_override_material(0, material)

	add_child(mesh_instance)

	# Add a label
	var label = Label3D.new()
	label.text = ORIGIN_ALIASES[_alias_index]
	label.position = Vector3(0, 0.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 12
	label.modulate = Color.PINK
	add_child(label)
	_origin_label = label


func _start_origin_alias_cycle():
	if ORIGIN_ALIASES.is_empty() or _origin_label == null:
		return

	if _alias_timer:
		return

	_alias_timer = Timer.new()
	_alias_timer.wait_time = 1.5
	_alias_timer.autostart = true
	_alias_timer.timeout.connect(_on_origin_alias_timeout)
	add_child(_alias_timer)


func _on_origin_alias_timeout():
	if not _origin_label:
		return

	_alias_index = (_alias_index + 1) % ORIGIN_ALIASES.size()
	_origin_label.text = ORIGIN_ALIASES[_alias_index]

[/code] [/color]
[hr]

",
'''
