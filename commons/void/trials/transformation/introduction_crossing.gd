extends "res://commons/void/cube_walkway.gd"
## Original wp + unit cubes form the banks; the original tc carries the visitor.
## The moving part is a fixed editor anchor with a travelling child.
const Ferry = preload("res://commons/void/portal_ferry.tscn")
const LethalPit = preload("res://commons/void/lethal_pit.gd")

func _ready() -> void:
	super._ready()
	set_meta("source_maps", ["Primitives_Polythedra", "Point_Animatedcube", "Trans_Introduction"])
	var ferry: Node3D = Ferry.instantiate()
	ferry.name = "MovingPlatform"
	ferry.position = Vector3(1.5, 0, 0)
	ferry.rotation_degrees.y = 180
	add_child(ferry)
	var bounds := _mesh_bounds(ferry, ferry)
	part_defaults["MovingPlatform"] = {
		"position": [1.5, 0, 0], "rotation": [0, 180, 0],
		"bounds": [bounds.position.x, bounds.position.y, bounds.position.z, bounds.size.x, bounds.size.y, bounds.size.z],
		"label": "Moving platform / fixed route anchor"
	}
	var pit := LethalPit.new()
	pit.name = "LethalPit"
	add_child(pit)
	part_defaults["LethalPit"] = {
		"position": [0, 0, 0], "rotation": [0, 0, 0],
		"bounds": [-2.5, 0.02, -1.5, 5, 0.06, 3],
		"label": "Lethal pit / surface + contact volume"
	}

func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	if has_node("MovingPlatform"):
		get_node("MovingPlatform").rebase()
