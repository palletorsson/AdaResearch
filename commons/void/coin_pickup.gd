extends "res://commons/scenes/mapobjects/pick_up_cube.gd"
## Coin skin for the existing motion, collection and array vacancy contract.

const Coin := preload("cylinder_coin.gd")
@export var battery_boost: float = 8.0
var coin_model: Node3D
var timing_shape: CollisionShape3D
var timing_hitbox: BoxShape3D

func _ready() -> void:
	if has_meta("config_battery_boost"):
		battery_boost = clampf(float(get_meta("config_battery_boost", 8.0)), 0.0, 100.0)
	super()
	_base_mesh().hide()
	var mono := bool(get_meta("config_monochrome", false))
	coin_model = Coin.model(0.24, 0.075, mono)
	coin_model.position.y = 0.5
	add_child(coin_model)
	if bool(get_meta("config_grow_on_descent", false)):
		_enable_timing_hitbox()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("battery_boost"):
		battery_boost = clampf(float(config_data["battery_boost"]), 0.0, 100.0)
		set_meta("config_battery_boost", battery_boost)
	super(config_data)
	if config_data.has("monochrome"):
		set_meta("config_monochrome", bool(config_data["monochrome"]))
		if coin_model != null and is_instance_valid(coin_model):
			coin_model.queue_free()
			coin_model = Coin.model(0.24, 0.075, bool(config_data["monochrome"]))
			coin_model.position.y = 0.5
			add_child(coin_model)
	if bool(get_meta("config_grow_on_descent", false)):
		_enable_timing_hitbox()

func _enable_timing_hitbox() -> void:
	if timing_hitbox != null:
		return
	timing_shape = $DetectionArea/CollisionShape3D
	timing_hitbox = timing_shape.shape.duplicate() as BoxShape3D
	timing_shape.shape = timing_hitbox

func _apply_pulse(factor: float) -> void:
	super(factor)
	if timing_hitbox != null:
		factor = 2.0 - factor
		timing_hitbox.size = Vector3(0.48, 0.48, 0.13) * factor
	if coin_model != null:
		coin_model.scale = Vector3.ONE * factor

func pickup_bottom_offset() -> float:
	return 0.26

func _play_collection_effect() -> void:
	if battery_boost > 0.0 and get_tree() != null:
		var hp: Node = get_tree().get_first_node_in_group("void_health")
		if hp != null and hp.has_method("set_charge") and hp.has_method("get_charge"):
			hp.call("set_charge", float(hp.call("get_charge")) + battery_boost, "power_coin")
	if coin_model != null:
		create_tween().tween_property(coin_model,"scale",coin_model.scale * 1.5,0.10)
