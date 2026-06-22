extends Node3D
## Instantiates `scene_to_instantiate` in a rows x columns grid.
##
## Restored helper for the legacy randomness "collection" scenes
## (random_number_book_page_collection, random_edge_profile_collection,
## vertical_block_animator_collection). The original lived at this path under the
## old `adaresearch/` tree and was lost in the move to `commons/`, leaving those
## three .tscn pointing at a missing script (load errors in the artifact runner).
## The contract below is reconstructed exactly from the exports those scenes set.

@export var scene_to_instantiate: PackedScene
@export var rows: int = 1
@export var columns: int = 1
@export var row_spacing: float = 1.0
@export var column_spacing: float = 1.0
@export var grid_offset: Vector3 = Vector3.ZERO
@export var instance_scale: Vector3 = Vector3.ONE


func _ready() -> void:
	_populate()


func _populate() -> void:
	if scene_to_instantiate == null:
		return
	for r in range(max(rows, 1)):
		for c in range(max(columns, 1)):
			var inst := scene_to_instantiate.instantiate()
			add_child(inst)
			if inst is Node3D:
				inst.position = grid_offset + Vector3(float(c) * column_spacing, 0.0, float(r) * row_spacing)
				inst.scale = instance_scale
