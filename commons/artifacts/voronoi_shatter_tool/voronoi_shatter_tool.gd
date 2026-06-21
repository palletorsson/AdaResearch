extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name VoronoiShatterTool

## @identity
## name: Voronoi Shatter Tool
## tier: applied
## truth: break a whole into the regions of its seeds — then break it differently
##
## A device (~1m) that shatters a slab into Voronoi cells. The slab's footprint
## is diced into a fine grid; each tile joins the cell of its nearest site, and
## the whole cell is nudged outward from the slab's centre so the fracture reads
## as an explosion frozen mid-burst. Every ~3 seconds it re-seeds with new sites
## and shatters again. A readout names the current cell count.

@export var grid_res: int = 34
@export var site_count: int = 9
@export var slab: float = 0.8
@export var explode: float = 0.16
@export var reshatter_interval: float = 3.0

const DEVICE_H: float = 0.45
var _cell: float = 0.0
var _sites: Array[Vector2] = []
var _site_colors: Array[Color] = []
var _container: Node3D
var _field_mi: MultiMeshInstance3D
var _readout: Label3D
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_cell = slab / float(grid_res)
	# housing — a low fracture stage
	add_child(_box(Vector3(0.0, DEVICE_H * 0.5, 0.0), Vector3(1.0, DEVICE_H, 1.0), _matte_mat(Color(0.17, 0.17, 0.2))))
	add_child(_box(Vector3(0.0, DEVICE_H + 0.02, 0.0), Vector3(1.02, 0.04, 1.02), _steel_mat(Color(0.3, 0.32, 0.36))))
	_readout = _billboard_label("cells: 0", Vector3(0.0, 1.1, 0.0), 30, Color(1.0, 0.7, 0.5))
	add_child(_readout)

	_container = Node3D.new()
	_container.position = Vector3(0.0, DEVICE_H + 0.08, 0.0)
	add_child(_container)
	_shatter()


func _scatter_sites() -> void:
	_sites.clear()
	_site_colors.clear()
	var half: float = slab * 0.5
	var margin: float = slab * 0.06
	for i in range(site_count):
		_sites.append(Vector2(_rng.randf_range(-half + margin, half - margin), _rng.randf_range(-half + margin, half - margin)))
		_site_colors.append(Color.from_hsv(_rng.randf(), 0.6, 0.95))


func _nearest_site(p: Vector2) -> int:
	var best: int = 0
	var best_d: float = INF
	for i in range(_sites.size()):
		var d: float = p.distance_squared_to(_sites[i])
		if d < best_d:
			best_d = d
			best = i
	return best


func _field(n: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.16 if emissive else 0.0
	mi.material_override = mat
	return mi


func _shatter() -> void:
	_scatter_sites()
	if _field_mi != null:
		_container.remove_child(_field_mi)
		_field_mi.queue_free()
		_field_mi = null
	var n: int = grid_res * grid_res
	_field_mi = _field(n)
	var mm: MultiMesh = _field_mi.multimesh
	var box := mm.mesh as BoxMesh
	box.size = Vector3(_cell * 0.95, 0.05, _cell * 0.95)
	var half: float = slab * 0.5
	for gy in range(grid_res):
		for gx in range(grid_res):
			var idx: int = gy * grid_res + gx
			var px: float = -half + (float(gx) + 0.5) * _cell
			var pz: float = -half + (float(gy) + 0.5) * _cell
			var owner: int = _nearest_site(Vector2(px, pz))
			# nudge the whole cell outward from its site so chunks pull apart
			var site: Vector2 = _sites[owner]
			var dir: Vector2 = site  # explode away from slab centre, grouped per cell
			var push: Vector2 = dir.normalized() * explode if dir.length() > 0.001 else Vector2.ZERO
			var pos := Vector3(px + push.x, 0.0, pz + push.y)
			mm.set_instance_transform(idx, Transform3D(Basis(), pos))
			mm.set_instance_color(idx, _site_colors[owner])
	_container.add_child(_field_mi)
	if _readout != null:
		_readout.text = "cells: %d" % site_count


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < reshatter_interval:
		return
	_accum = 0.0
	_shatter()
