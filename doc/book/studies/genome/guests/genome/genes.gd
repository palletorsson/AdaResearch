extends Resource

@export var segments: int = 3                 # balls in the trunk, from the ground up
@export var limb_count: int = 4               # limbs around the lowest ball
@export var limb_angle: float = 25.0          # degrees the limbs are raised
@export var colour: Color = Color("c6ff3d")   # BODY, written out
@export var body_seed: int = 1                # which individual: the size of each ball

func mutate(gene: String, value: Variant) -> void:
	set(gene, value)
	emit_changed()
