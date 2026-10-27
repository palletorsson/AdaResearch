extends Node3D

const SOURCE_SCENE := preload("res://algorithms/fractals/meshfractal/fractal_scene.tscn")

var _fractal: Node3D = null


func _ready() -> void:
	_fractal = SOURCE_SCENE.instantiate() as Node3D
	if _fractal == null:
		return
	add_child(_fractal)
	call_deferred("_detach_multimesh_transforms")


func _process(_delta: float) -> void:
	_detach_multimesh_transforms()


func _detach_multimesh_transforms() -> void:
	if _fractal == null or not is_instance_valid(_fractal):
		return
	for child in _fractal.get_children():
		if child is MultiMeshInstance3D:
			var mmi := child as MultiMeshInstance3D
			if not mmi.top_level:
				mmi.top_level = true
			mmi.global_transform = Transform3D.IDENTITY
