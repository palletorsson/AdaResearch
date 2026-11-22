extends "res://commons/scenes/mapobjects/pick_up_cube.gd"
## A collectible parcel. Its contents stay on the floor as a physical prefab.

const Items := preload("res://commons/player/inventory_items.gd")
const Carrier := preload("res://commons/player/inventory_carrier.gd")
const Kit := preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const HealthCrossScene := preload("res://commons/artifacts/health_cross/health_cross.tscn")
const RANDOM_GIFTS := [
	"rubberball", "brick", "dice", "bowlingpin", "cinderblock",
	"tincan", "woodenblock", "dominotile", "doorstop", "gem",
]

var _ribbon_holder: Node3D = null
var _health_boost := 0.0
var _drop_powerup := false
var _instant_powerup := false

func _ready() -> void:
	var mono := bool(get_meta("config_monochrome", false))
	if mono and not has_meta("config_stock"):
		set_meta("config_stock", "foam")
	_sync_powerup_meta()
	super()
	_build_ribbons(mono)

func apply_grid_config(config_data: Dictionary) -> void:
	if bool(config_data.get("monochrome", false)):
		set_meta("config_monochrome", true)
		if not config_data.has("stock") and not has_meta("config_stock"):
			set_meta("config_stock", "foam")
	if config_data.has("gift"):
		set_meta("config_gift", str(config_data["gift"]))
	if config_data.has("health_boost"):
		set_meta("config_health_boost", float(config_data["health_boost"]))
	if config_data.has("drop_powerup"):
		set_meta("config_drop_powerup", bool(config_data["drop_powerup"]))
	if config_data.has("instant_powerup"):
		set_meta("config_instant_powerup", bool(config_data["instant_powerup"]))
	_sync_powerup_meta()
	super(config_data)
	if config_data.has("monochrome") or config_data.has("gift"):
		_build_ribbons(bool(get_meta("config_monochrome", false)))

func _sync_powerup_meta() -> void:
	var raw_gift := str(get_meta("config_gift", "rubberball")).strip_edges().to_lower()
	var is_hp_pkg := raw_gift in ["health_powerup", "powerup", "health"]
	_health_boost = float(get_meta("config_health_boost", 25.0 if is_hp_pkg else 0.0))
	_drop_powerup = bool(get_meta("config_drop_powerup", is_hp_pkg))
	_instant_powerup = bool(get_meta("config_instant_powerup", is_hp_pkg))

func _build_ribbons(mono: bool) -> void:
	if _ribbon_holder != null and is_instance_valid(_ribbon_holder):
		_ribbon_holder.queue_free()
	_ribbon_holder = Node3D.new()
	_ribbon_holder.name = "RibbonHolder"
	add_child(_ribbon_holder)
	var ribbon := Color("1c1e22") if mono else Color("b33871")
	for size in [Vector3(.08, .507, .507), Vector3(.507, .507, .08)]:
		Kit.box(_ribbon_holder, "Ribbon", CORE, size, ribbon, false)
	if _health_boost > 0.0 or _drop_powerup:
		# Crisp architectural plus emblem announcing Health + Battery Power Up!
		var badge_col := Color("ededeb") if mono else Color("28c98a")
		Kit.box(_ribbon_holder, "PowerPlusH", CORE + Vector3(0, 0.275, 0), Vector3(0.24, 0.025, 0.07), badge_col, false)
		Kit.box(_ribbon_holder, "PowerPlusV", CORE + Vector3(0, 0.275, 0), Vector3(0.07, 0.025, 0.24), badge_col, false)
	if mono:
		var base := _base_mesh()
		if base != null:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color("f0f0ec")
			mat.roughness = 0.55
			mat.metallic = 0.04
			base.material_override = mat

func _apply_pulse(s: float) -> void:
	super(s)
	if _ribbon_holder != null and is_instance_valid(_ribbon_holder):
		_ribbon_holder.scale = Vector3.ONE * s
		_ribbon_holder.position = CORE * (1.0 - s)

func _play_collection_effect() -> void:
	super()
	if _instant_powerup and _health_boost > 0.0:
		_grant_unit_powerup(_health_boost)
	# Body overlap is delivered while physics is flushing. Spawn after it.
	_drop_gift.call_deferred(to_global(CORE))

func _grant_unit_powerup(amount: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var hp: Node = tree.get_first_node_in_group("void_health")
	if hp != null and hp.has_method("set_charge") and hp.has_method("get_charge"):
		hp.call("set_charge", float(hp.call("get_charge")) + amount, "package_powerup")
	var game := tree.get_first_node_in_group("void_game")
	if game != null and game.has_method("_notice"):
		game._notice("PACKAGE POWER-UP · +%d%% HEALTH & BATTERY" % int(roundf(amount)))

func _choose_gift_id() -> String:
	var raw := str(get_meta("config_gift", "rubberball")).strip_edges().to_lower()
	if raw in ["health_powerup", "powerup", "health"]:
		return "health_powerup"
	if raw == "random" or raw.is_empty():
		var pool: Array[String] = []
		for cand in RANDOM_GIFTS:
			var it := Items.item(cand)
			if not it.is_empty() and str(it.get("tool", "")).is_empty():
				pool.append(cand)
		if not pool.is_empty():
			return pool[randi() % pool.size()]
		return "rubberball"
	return raw

func _drop_gift(at: Vector3) -> void:
	var mount := get_parent() as Node3D
	if mount == null:
		return
	var id := _choose_gift_id()
	if _drop_powerup and _health_boost > 0.0:
		var cross := HealthCrossScene.instantiate() as Node3D
		cross.name = "DroppedHealthPowerUp"
		var hp: Node = get_tree().get_first_node_in_group("void_health")
		if hp != null:
			cross.set("health_provider", hp)
		cross.set("boost", _health_boost)
		cross.set("take_below", 1.0)
		cross.set("respawn_s", 0.0)
		cross.set("arm_m", 0.24)
		cross.set("hover_m", 0.36)
		if bool(get_meta("config_monochrome", false)):
			cross.set("cross_color", Color("ededeb"))
		else:
			cross.set("cross_color", Color("28c98a"))
		cross.position = mount.to_local(at) + Vector3(0.0, -0.35, 0.0)
		mount.add_child(cross)
		if id == "health_powerup":
			var fl_root := mount.get_parent()
			if fl_root != null and fl_root.has_meta("void_content_floor"):
				fl_root.get_parent().floor_changed.emit(int(fl_root.get_meta("void_content_floor")))
			return
	if id == "health_powerup":
		return
	var item := Items.item(id)
	if item.is_empty() or not str(item.get("tool", "")).is_empty(): return
	var carrier := Carrier.new()
	carrier.collision_layer = 4
	carrier.continuous_cd = true
	carrier.can_ranged_grab = true
	carrier.position = mount.to_local(at)
	mount.add_child(carrier)
	if not carrier.build(item, Items.config_for(item, {})):
		carrier.queue_free()
		return
	carrier.snap_grid = false
	carrier.set_meta("gift_cube_reward", id)
	carrier.set_meta("inventory_projectile", true)
	carrier.picked_up.connect(_stock_hands.bind(get_tree(), id), CONNECT_ONE_SHOT)
	var game := get_tree().get_first_node_in_group("void_game")
	if game != null and game.has_method("_notice"):
		var label := str(item.get("name", id)).split(" - ")[0]
		game._notice("PACKAGE -> %s\nGrab & throw to detonate a bomb" % label)
	var floor_root := mount.get_parent()
	if floor_root != null and floor_root.has_meta("void_content_floor"):
		floor_root.get_parent().floor_changed.emit(int(floor_root.get_meta("void_content_floor")))

static func _stock_hands(_who: Variant, tree: SceneTree, id: String) -> void:
	for hand in tree.get_nodes_in_group("inventory_hands"):
		hand.collect(id)
