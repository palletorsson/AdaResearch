# MetaballScene.gd
# Display-only — just shows the metaballs, no player interaction
extends Node3D

@onready var metaball_generator: MetaballGenerator = $MetaballGenerator

func _ready() -> void:
	# Just let the generator do its thing
	if metaball_generator:
		print("MetaballScene: Generator ready")
