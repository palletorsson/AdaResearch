# MinimalResetTeleporter.gd
# Simple reset with XR-Tools teleportation support

extends Node3D

@export var teleport_target: Node3D
@export var reset_delay: float = 1.0

@onready var area: Area3D = $ResetArea 
var is_resetting: bool = false

func _ready():
	area.body_entered.connect(_on_body_entered)
	
	# Auto-find spawn if no target set
	if not teleport_target:
		call_deferred("_find_spawn")

func _find_spawn():
	# Look for spawn point or create default
	teleport_target = get_tree().current_scene.find_child("SpawnPoint", true, false)
	if not teleport_target:
		teleport_target = Node3D.new()
		teleport_target.position = Vector3(0, 3, 0)
		get_tree().current_scene.add_child(teleport_target)

func _on_body_entered(body: Node3D):
	if is_resetting or not _is_player(body):
		return
	
	is_resetting = true
	await get_tree().create_timer(reset_delay).timeout
	
	# Try XR-Tools teleport first, fallback to scene reload
	var player_body = body as XRToolsPlayerBody
	if player_body and player_body.has_method("teleport") and teleport_target:
		player_body.teleport(teleport_target.global_transform)
		
		is_resetting = false
	else:
		get_tree().reload_current_scene()

func _is_player(body: Node3D) -> bool:
	return body is XRToolsPlayerBody or body.is_in_group("player_body") or body.is_in_group("player")

# XR-Tools compatibility
func is_xr_class(name: String) -> bool:
	return name == "XRToolsTeleportArea"
