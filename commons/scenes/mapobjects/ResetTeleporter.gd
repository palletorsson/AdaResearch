# Minimal Reset Teleporter
# Simple scene reset when player enters area

extends Node3D

@export var reset_delay: float = 1.0

@onready var area: Area3D = $ResetArea
var is_resetting: bool = false

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if is_resetting:
		return
	
	# Check if it's the player
	if not (body.is_in_group("player_body") or body.is_in_group("player")):
		return
	
	print("Reset: Player entered - resetting scene in %.1fs" % reset_delay)
	is_resetting = true
	
	# Wait then reset
	await get_tree().create_timer(reset_delay).timeout
	get_tree().reload_current_scene()
