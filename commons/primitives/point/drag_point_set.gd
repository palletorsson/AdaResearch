# DragPointSet.gd - Shared manager for grab sphere drag points
extends Node3D
class_name DragPointSet

const DEFAULT_POINT_SCENE := preload("res://commons/primitives/point/grab_sphere_point_with_text.tscn")

signal point_picked_up(index: int, pickable: Object, meta: Dictionary)
signal point_dropped(index: int, pickable: Object, meta: Dictionary)
signal point_moved(index: int, position: Vector3, meta: Dictionary)

# Configure default behavior for pickup/drop
var freeze_on_drop := true
var unfreeze_on_pickup := true
var propagate_alter_freeze := false

var _point_scene: PackedScene = DEFAULT_POINT_SCENE
var _points: Array[Dictionary] = []
var _spheres: Array[Node3D] = []
var _last_positions: Array[Vector3] = []

func clear() -> void:
	for sphere in _spheres:
		sphere.queue_free()
	_points.clear()
	_spheres.clear()
	_last_positions.clear()
	set_process(false)

func setup(points: Array, config: Dictionary = {}) -> void:
	# Remove existing spheres before building the new set
	clear()
	_point_scene = config.get("scene", DEFAULT_POINT_SCENE)
	freeze_on_drop = config.get("freeze_on_drop", true)
	unfreeze_on_pickup = config.get("unfreeze_on_pickup", true)
	propagate_alter_freeze = config.get("alter_freeze", false)
	var default_scale = config.get("default_scale", Vector3.ONE)
	if typeof(default_scale) == TYPE_FLOAT:
		default_scale = Vector3.ONE * default_scale
	var default_color = config.get("default_color", null)

	for i in range(points.size()):
		var point_cfg = points[i]
		var sphere: Node3D = _point_scene.instantiate()
		sphere.name = point_cfg.get("name", "GrabSphere_%d" % i)
		add_child(sphere)
		var position: Vector3 = point_cfg.get("position", Vector3.ZERO)
		sphere.position = position

		_apply_visual_overrides(sphere, point_cfg, default_scale, default_color)
		var meta_payload := _apply_meta(sphere, point_cfg, i)

		_points.append({
			"id": point_cfg.get("id", i),
			"meta": meta_payload,
			"position": position
		})
		_spheres.append(sphere)
		_last_positions.append(position)

		if sphere.has_signal("picked_up"):
			sphere.connect("picked_up", _on_sphere_picked_up.bind(i))
		if sphere.has_signal("dropped"):
			sphere.connect("dropped", _on_sphere_dropped.bind(i))

	set_process(_spheres.size() > 0)

func _apply_visual_overrides(sphere: Node3D, point_cfg: Dictionary, default_scale: Vector3, default_color) -> void:
	var alter_setting = point_cfg.get("alter_freeze", propagate_alter_freeze)
	if _has_property(sphere, "alter_freeze"):
		sphere.set("alter_freeze", alter_setting)

	var mesh_instance: MeshInstance3D = sphere.get_node_or_null("MeshInstance3D")
	if mesh_instance:
		var scale_override = point_cfg.get("scale", default_scale)
		if typeof(scale_override) == TYPE_FLOAT:
			scale_override = Vector3.ONE * scale_override
		mesh_instance.scale = scale_override

		var color_override = point_cfg.get("color", default_color)
		if color_override != null:
			var material := mesh_instance.material_override as StandardMaterial3D
			if material:
				_apply_material_defaults(material, color_override)

func _apply_material_defaults(material: StandardMaterial3D, color: Color) -> void:
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color * 0.3
	material.roughness = 0.1
	material.metallic = 0.0
	material.refraction = 0.05

func _apply_meta(sphere: Node3D, point_cfg: Dictionary, fallback_id: int) -> Dictionary:
	var meta_src = point_cfg.get("meta", {})
	var meta: Dictionary = meta_src.duplicate(true) if typeof(meta_src) == TYPE_DICTIONARY else {}
	for key in meta.keys():
		sphere.set_meta(key, meta[key])
	var expose_index = point_cfg.get("id", fallback_id)
	sphere.set_meta("drag_point_id", expose_index)
	meta["drag_point_id"] = expose_index
	return meta

func get_sphere(index: int) -> Node3D:
	if index < 0 or index >= _spheres.size():
		return null
	return _spheres[index]

func get_spheres() -> Array[Node3D]:
	var copy: Array = _spheres.duplicate()
	return copy

func get_point_position(index: int) -> Vector3:
	if index < 0 or index >= _points.size():
		return Vector3.ZERO
	return _points[index]["position"]

func get_positions() -> Array[Vector3]:
	var results: Array[Vector3] = []
	for point_data in _points:
		results.append(point_data.get("position", Vector3.ZERO))
	return results

func set_point_position(index: int, position: Vector3, update_meta := true, emit_signal := false) -> void:
	if index < 0 or index >= _spheres.size():
		return
	var sphere := _spheres[index]
	if sphere.position == position:
		return
	sphere.position = position
	_last_positions[index] = position
	if update_meta:
		_points[index]["position"] = position
	if emit_signal:
		point_moved.emit(index, position, _points[index]["meta"])

func set_points_positions(positions: Array[Vector3]) -> void:
	for i in range(min(positions.size(), _spheres.size())):
		set_point_position(i, positions[i], true, false)

func for_each_sphere(callback: Callable) -> void:
	for sphere in _spheres:
		callback.call(sphere)

func get_point_meta(index: int) -> Dictionary:
	if index < 0 or index >= _points.size():
		return {}
	return _points[index]["meta"]

func _on_sphere_picked_up(index: int, pickable) -> void:
	if unfreeze_on_pickup and pickable and pickable.has_method("set_freeze_enabled"):
		pickable.set_freeze_enabled(false)
	point_picked_up.emit(index, pickable, _points[index]["meta"])

func _on_sphere_dropped(index: int, pickable) -> void:
	if freeze_on_drop and pickable and pickable.has_method("set_freeze_enabled"):
		pickable.set_freeze_enabled(true)
	point_dropped.emit(index, pickable, _points[index]["meta"])

func _process(_delta: float) -> void:
	for i in range(_spheres.size()):
		var sphere := _spheres[i]
		var current_pos: Vector3 = sphere.position
		if current_pos != _last_positions[i]:
			_last_positions[i] = current_pos
			_points[i]["position"] = current_pos
			point_moved.emit(i, current_pos, _points[i]["meta"])

func _has_property(obj: Object, property: String) -> bool:
	for entry in obj.get_property_list():
		if entry.has("name") and entry["name"] == property:
			return true
	return false
