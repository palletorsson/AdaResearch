# sim_cube.gd — the common wrapper: a 1m housing that makes a simulation
# FEEL integrated in map space (the grid cell made visible). Family styles
# from CubeWrapperLibrary (gridglass/tank/cage/shadowbox/openframe) keep
# housed artifacts recognizable by nature. Map token:
#   sim_cube#family:tank#mount:<lookup_name>
# Follows exhibit_furniture's config/mount convention exactly.
extends Node3D
class_name SimCube

const CubeLib := preload("res://commons/grid/CubeWrapperLibrary.gd")

@export var family: String = "gridglass"
@export var mount: String = ""


func _ready() -> void:
	if has_meta("config_family"):
		family = str(get_meta("config_family"))
	if has_meta("config_mount"):
		mount = str(get_meta("config_mount"))
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])


func _build() -> void:
	var lib = CubeLib.new()
	var housing: Node3D = lib.build(family)
	housing.name = "Housing"
	add_child(housing)
	if mount != "":
		_mount_artifact(mount, lib.mount_point(family), lib.mount_rotation(family))


func _mount_artifact(lookup: String, at: Vector3, rot: Vector3 = Vector3.ZERO) -> void:
	var dir := DirAccess.open("res://commons/artifacts/registry/")
	if dir == null:
		return
	var scene_path := ""
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".json"):
			var file := FileAccess.open("res://commons/artifacts/registry/" + f, FileAccess.READ)
			if file:
				var parsed = JSON.parse_string(file.get_as_text())
				if parsed is Dictionary and parsed.get("artifacts", {}).has(lookup):
					scene_path = str(parsed["artifacts"][lookup].get("scene", ""))
					break
		f = dir.get_next()
	if scene_path == "":
		return
	var scene = load(scene_path)
	if scene == null:
		return
	var inst = scene.instantiate()
	if inst is Node3D:
		inst.position = at
		inst.rotation = rot
		add_child(inst)
