# MetaballScene.gd
# Display-only — just shows the metaballs, no player interaction
extends Node3D

@onready var metaball_generator: MetaballGenerator = $MetaballGenerator

func _ready() -> void:
	# Just let the generator do its thing
	if metaball_generator:
		print("MetaballScene: Generator ready")

func apply_grid_config(config: Dictionary) -> void:
	# THE AXES WERE UNREACHABLE FROM ANY MAP TOKEN UNTIL THIS FORWARDED, and
	# nothing would have said so. GridInteractablesComponent stamps config_* and
	# calls apply_grid_config on the ROOT (:1665-1673); the generator that owns
	# every export is a CHILD, and this body was the single word `pass`. Because
	# the root does answer has_method(), the component's own rescue branch for
	# child-held config (:1695) is skipped by construction — so the token would
	# have declared two axes, swept them green on the bench, and dropped every
	# key a player's map ever wrote.
	#
	# The child's own guard compares a signature of every value its build reads
	# and returns before touching the mesh when none of them moved, so
	# curation_station's {"emissive": false} — which is the only config any of
	# the eleven placements passes — is byte for byte the no-op it always was.
	if metaball_generator:
		metaball_generator.apply_grid_config(config)
