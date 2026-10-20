extends RefCounted
## Small, supported controls using the museum's desktop and XR button path.
const Objects = preload("objects.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")

static func button(parent: Node3D, p: Vector3, words: String, action: Callable, primary:=false) -> Node3D:
	var node: Node3D = preload("res://commons/interactables/push_button.tscn").instantiate()
	parent.add_child(node)
	node.position = p
	# This strip's captions face +Z. The source scene faces -Z, which
	# buried the cap and most of its hand target inside the backing plate.
	node.rotation.x = PI / 2.0
	# The hand-pose sphere requires uniform body scale in Jolt.
	node.scale = Vector3.ONE * 1.8
	Rack.make_button_rectangular(node)
	# A quiet, steady cap cue survives the darker wall lighting. This is
	# an available-action colour, not a claim that a choice is selected.
	node.released_color = Color("8cbbb0") if primary else Color("c5c9be")
	node.released_emission_energy = 0.18
	node.pressed.connect(func(): action.call_deferred())
	Objects.ink(parent, words, p + Vector3(0,-0.12,0.01), 25, 0.0015)
	return node
