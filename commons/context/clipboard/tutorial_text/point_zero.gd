extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = """[font_size=28][b]0. Point Zero[/b][/font_size]

[i][color=gray]Summary: The origin (0,0,0) is where all spatial measurement begins. Before we can explore algorithms and mathematics, we must acknowledge the invisible scaffolding—the rendering engine, coordinate system, and time itself—that makes computation possible. This scene marks the threshold between the void and the symbolic world we are about to construct.[/color][/i]

[hr]

Ada fades from black, revealing what was already present.

A [b]Symbolic Arrow[/b] hangs in space, its trajectory pointing back through [b]Vector Zero[/b]—the origin. If Vector Zero is where measurement begins, the arrow marks the accumulation of prerequisites: the scaffolding that already exists before any algorithm runs.

[color=green][b]Code[/b][/color]
[color=green][code]
var vector_zero = Vector3(0, 0, 0)
var vector_pointing = Vector3(0, 0, 1)
[/code][/color]

[hr]

[b]The Invisible Infrastructure[/b]

In this virtual world, the prerequisites include: the rendering system that draws each frame, your embodied presence within the 3D coordinate grid, and the clock that advances time—everything required to compute Euclidean space and its unfolding.

The Godot game engine, paired with the XR toolkit, already encodes functions that Ada Research depends on. There is a floor to stand on. A body to move with. These foundations are structures of endless descent, always partly ignored—functions of time, makers of space, reminders of the world's primal uncomputability.

Ada Research is another layer of what Heidegger called [i]thrownness[/i]: we arrive already in motion, inside systems we did not author, and we must set aside most of that inheritance just to take the next step.

[hr]

[b]The Symbolic Layer: Forced Convenience[/b]

We might wish to resist introducing an arrow of direction—for a pointer inevitably carries [b]authorial intent[/b], a will to steer. Yet this resistance is futile; the world slips toward convenience.

[color=yellow]Try turning around. The arrow points forward, but space exists behind you too. The system optimizes for the forward view, but the void is omnidirectional. Why does the tutorial only want you to look one way?[/color]

The arrow introduces a symbolic layer of [b]forced convenience[/b] against the [b]background void[/b]. This layer is the [b]foreground[/b]—a symbolic interface designed to guide perception and manage the vertigo of infinite possibility. It forces us to ask: [b]How did we get here? An accumulade halting problem: yes we are here now but resource should we allocate to understand the past? /b]

[hr]

[b]The Many Names of Zero[/b]

This vector has many names:

[color=cyan]Vector3(0, 0, 0) • origin • * • Vector3.ZERO • Zero Vector • World origin • Coordinate zero • The center of the coordinate system • The birth of space • The coordinate of silence • The root of all vectors[/color]

[hr]

[color=green][b]Full Code[/b][/color]
[color=green][code]
extends Node3D

## AXIOM 0: The origin (0, 0, 0) is the reference point
## from which all positions are measured.

const ORIGIN_ALIASES := [
	\"(0,0,0)\",
	\"Vector3(0, 0, 0)\",
	\"origin\",
	\"*\",
	\"Vector3.ZERO\",
	\"Zero Vector\",
	\"World origin\", 
	\"Coordinate zero\",
	\"The center of the coordinate system\",
	\"The birth of space\", 
	\"The coordinate of silence\", 
	\"The root of all vectors\"
] 

var origin = Vector3(0, 0, 0)
var _origin_label: Label3D
var _alias_index := 0
var _alias_timer: Timer

func _ready():
	print(\"The center of our 3D universe: \", origin)
	create_origin_marker()
	_start_origin_alias_cycle()

func create_origin_marker():
	\"\"\"Create a small sphere to mark the origin point\"\"\"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.01
	sphere_mesh.height = 0.025

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = origin

	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_energy = 10.0
	mesh_instance.set_surface_override_material(0, material)
	add_child(mesh_instance)

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
[/code][/color]
'''
"""
