@tool
extends Node3D

## Spawns all glass rack + big pipe preset tscns in a gallery grid.
## Open this scene in editor to preview all presets at once.

const GLASS_PRESETS: Array[String] = [
	"res://commons/glass_rack/presets/simple_tube.tscn",
	"res://commons/glass_rack/presets/spiral_tube.tscn",
	"res://commons/glass_rack/presets/spiral_condenser.tscn",
	"res://commons/glass_rack/presets/distillation_rack.tscn",
	"res://commons/glass_rack/presets/distillation_y.tscn",
	"res://commons/glass_rack/presets/fractional_distillation.tscn",
	"res://commons/glass_rack/presets/reflux_apparatus.tscn",
	"res://commons/glass_rack/presets/branching_condenser.tscn",
	"res://commons/glass_rack/presets/sbend_manifold.tscn",
	"res://commons/glass_rack/presets/complex_apparatus.tscn",
	"res://commons/glass_rack/presets/breaking_bad_coffee.tscn",
]

const PIPE_PRESETS: Array[String] = [
	"res://algorithms/wavefunctions/big_pipe_system/presets/default.tscn",
	"res://algorithms/wavefunctions/big_pipe_system/presets/straight_run.tscn",
	"res://algorithms/wavefunctions/big_pipe_system/presets/l_bend.tscn",
	"res://algorithms/wavefunctions/big_pipe_system/presets/t_distribution.tscn",
	"res://algorithms/wavefunctions/big_pipe_system/presets/serpentine.tscn",
	"res://algorithms/wavefunctions/big_pipe_system/presets/vertical_bypass.tscn",
	"res://algorithms/wavefunctions/big_pipe_system/presets/cross_manifold.tscn",
	"res://algorithms/wavefunctions/big_pipe_system/presets/industrial_branch.tscn",
]

@export var spacing_glass: float = 1.2
@export var spacing_pipe: float = 6.0
@export var rebuild: bool = false:
	set(v):
		if v:
			_clear_children()
			_build_gallery()

func _ready() -> void:
	if Engine.is_editor_hint():
		# Don't auto-build in editor to avoid duplicates
		return
	_build_gallery()

func _build_gallery() -> void:
	# Row 1: Glass rack presets
	for i in range(GLASS_PRESETS.size()):
		var scene := load(GLASS_PRESETS[i])
		if scene is PackedScene:
			var inst := (scene as PackedScene).instantiate()
			inst.position = Vector3(i * spacing_glass, 0, 0)
			add_child(inst)
			if Engine.is_editor_hint():
				inst.owner = get_tree().edited_scene_root

			# Label
			var label := Label3D.new()
			label.text = GLASS_PRESETS[i].get_file().trim_suffix(".tscn")
			label.font_size = 32
			label.position = Vector3(i * spacing_glass, -0.3, 0.15)
			label.rotation.x = -PI / 4
			add_child(label)
			if Engine.is_editor_hint():
				label.owner = get_tree().edited_scene_root

	# Row 2: Big pipe presets (offset in Z)
	for i in range(PIPE_PRESETS.size()):
		var scene := load(PIPE_PRESETS[i])
		if scene is PackedScene:
			var inst := (scene as PackedScene).instantiate()
			inst.position = Vector3(i * spacing_pipe, 0, -8)
			add_child(inst)
			if Engine.is_editor_hint():
				inst.owner = get_tree().edited_scene_root

			var label := Label3D.new()
			label.text = PIPE_PRESETS[i].get_file().trim_suffix(".tscn")
			label.font_size = 48
			label.position = Vector3(i * spacing_pipe, -0.5, -6)
			label.rotation.x = -PI / 4
			add_child(label)
			if Engine.is_editor_hint():
				label.owner = get_tree().edited_scene_root

func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
