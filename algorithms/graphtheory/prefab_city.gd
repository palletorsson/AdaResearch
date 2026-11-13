extends RefCounted
## THE PARTS A WALKABLE CITY IS BUILT FROM (the pass, 2026-11-13)
##
## The graph-theory floors carry works a body walks: lands in water joined by bridges, built from the tower's real
## prefabs (Palle, 2026-11-13). seven_bridges, plank_price and stone_river each carry their own copy of these
## functions; this is the shape lifted out before a fourth copy was made, and room_for_another is its first user.
## The three earlier works were tested as they stand and are not rewritten onto it.
##
##   var city := preload("res://algorithms/graphtheory/prefab_city.gd").new()
##   city.part(holder, "timber_plank_2m", at)          # one of the spatial lab's inputs, through the lab's adapter
##   city.catalogue_part(holder, "work_light", at)     # one of the wider catalogue (commons/void/primitive-prefabs.json)
##   city.water(ground, Rect2(...), dry_rects)         # tiles and a solid a body cannot wade
##
## A holder must be IN THE TREE when parts are added to it: the adapter builds in _ready.
const Prefab := preload("res://commons/modular/lab_input.gd")
const CATALOGUE := "res://commons/void/primitive-prefabs.json"
const WATER := Color("3f77b8")

var parts := 0
var _catalogue := {}


## One of the lab's inputs. `fit` fits the source's own meshes to an envelope and adds a box solid; the part is then
## lifted by half its height so `at` is its foot. `solid` false takes every collider away (a deck let into the floor).
func part(parent: Node3D, token: String, at: Vector3, yaw_degrees: float = 0.0, fit: Vector3 = Vector3.ZERO, solid: bool = true) -> Node3D:
	var made: Node3D = Prefab.new()
	made.set("token", token)
	if fit != Vector3.ZERO:
		made.set("fit_box", fit)
		at.y += fit.y * 0.5
	made.position = at
	made.rotation_degrees.y = yaw_degrees
	parent.add_child(made)
	if not solid: unsolid(made)
	parts += 1
	return made


func unsolid(node: Node) -> void:
	for body in node.find_children("*", "CollisionObject3D", true, false):
		(body as CollisionObject3D).collision_layer = 0
		(body as CollisionObject3D).collision_mask = 0


## One of the wider catalogue: a composite term, or a scene with its catalogue config.
func catalogue_part(parent: Node3D, id: String, at: Vector3, yaw_degrees: float = 0.0) -> Node3D:
	if _catalogue.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
		if data is Dictionary:
			for entry in (data as Dictionary).get("prefabs", []): _catalogue[str(entry.id)] = entry
	var found: Dictionary = _catalogue.get(id, {})
	var path := str(found.get("scene", ""))
	if not path.ends_with(".tscn") or not ResourceLoader.exists(path):
		push_warning("prefab_city: the catalogue has no scene for " + id)
		return null
	var node: Node3D = (load(path) as PackedScene).instantiate()
	var config: Variant = found.get("config")
	if path.ends_with("composite.tscn"): node.set("term", str(found.get("token", "")).trim_prefix("mod_"))
	elif config is Dictionary:
		for key in config: node.set_meta("config_" + str(key), config[key])
	node.position = at
	node.rotation_degrees.y = yaw_degrees
	parent.add_child(node)
	if config is Dictionary and node.has_method("apply_grid_config"): node.apply_grid_config(config)
	node.set_meta("prefab", id)
	node.set_meta("source_scene", path)
	parts += 1
	return node


## A row of one prefab from a to b, each fitted to its share of the length.
func fence(parent: Node3D, a: Vector3, b: Vector3, token: String, unit: float, high: float, deep: float) -> void:
	var length: float = a.distance_to(b)
	if length < 0.7: return
	var n: int = maxi(1, roundi(length / unit))
	var along: Vector3 = (b - a) / float(n)
	var yaw: float = 0.0 if absf(along.x) > absf(along.z) else 90.0
	for k in n:
		part(parent, token, a + along * (float(k) + 0.5), yaw, Vector3(along.length() - 0.04, high, deep))


func flat(colour: Color, rough: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = rough
	return m


func sheet(parent: Node3D, at: Vector3, size: Vector2, colour: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.x, 0.01, size.y)
	mesh.mesh = box
	mesh.material_override = flat(colour)
	mesh.position = at
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh


## A box of a static body: a wall a body cannot pass. Returns the shape, so a gate can switch it off.
func wall(solid: StaticBody3D, at: Vector3, size: Vector3) -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = size
	shape.shape = block
	shape.position = at + Vector3(0, size.y * 0.5, 0)
	solid.add_child(shape)
	return shape


## Water: `basin` cut into cells by the edges of the dry rects (lands, bridge places); every cell that is not dry gets
## a tile and a solid 1.3 m high. Returns {"solid": StaticBody3D, "cells": [{"rect": Rect2, "shape": CollisionShape3D}]}.
func water(parent: Node3D, basin: Rect2, dry: Array, colour: Color = WATER) -> Dictionary:
	var xs := [basin.position.x, basin.end.x]
	var zs := [basin.position.y, basin.end.y]
	for r in dry:
		for v in [(r as Rect2).position.x, (r as Rect2).end.x]:
			if v > basin.position.x and v < basin.end.x and not xs.any(func(a): return absf(a - v) < 0.001): xs.append(v)
		for v in [(r as Rect2).position.y, (r as Rect2).end.y]:
			if v > basin.position.y and v < basin.end.y and not zs.any(func(a): return absf(a - v) < 0.001): zs.append(v)
	xs.sort()
	zs.sort()
	var solid := StaticBody3D.new()
	solid.name = "Water"
	parent.add_child(solid)
	var tiles: Array[Transform3D] = []
	var cells := []
	for j in zs.size() - 1:
		for i in xs.size() - 1:
			var cell := Rect2(float(xs[i]), float(zs[j]), float(xs[i + 1]) - float(xs[i]), float(zs[j + 1]) - float(zs[j]))
			var mid := cell.get_center()
			if dry.any(func(r): return (r as Rect2).has_point(mid)): continue
			tiles.append(Transform3D(Basis().scaled(Vector3(cell.size.x, 0.006, cell.size.y)), Vector3(mid.x, 0.003, mid.y)))
			cells.append({"rect": cell, "shape": wall(solid, Vector3(mid.x, 0, mid.y), Vector3(cell.size.x, 1.3, cell.size.y))})
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	var unit := BoxMesh.new()
	unit.size = Vector3(1, 1, 1)
	many.mesh = unit
	many.instance_count = tiles.size()
	for i in tiles.size(): many.set_instance_transform(i, tiles[i])
	var drawn := MultiMeshInstance3D.new()
	drawn.name = "WaterTiles"
	drawn.multimesh = many
	drawn.material_override = flat(colour, 0.2)
	drawn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(drawn)
	return {"solid": solid, "cells": cells}


## A board on a low stand, leaning back, turned to +z. Returns its Label3D.
func board(parent: Node3D, at: Vector3, wide: float = 3.2, high: float = 1.0) -> Label3D:
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = at
	parent.add_child(stand)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(wide, high, 0.05)
	panel.mesh = face
	panel.material_override = flat(Color(0.11, 0.115, 0.13), 0.85)
	panel.position = Vector3(0, 0.66, 0)
	panel.rotation.x = -0.5
	stand.add_child(panel)
	var text := Label3D.new()
	text.pixel_size = 0.0021
	text.font_size = 30
	text.line_spacing = 2.0
	text.modulate = Color(0.88, 0.94, 1.0)
	text.outline_size = 4
	text.outline_modulate = Color(0, 0, 0, 1)
	text.width = (wide - 0.18) / 0.0021
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.position = Vector3(0, 0.035, 0.03)
	panel.add_child(text)
	return text


## A name over a land, turned to whoever looks.
func sign_post(parent: Node3D, at: Vector3) -> Label3D:
	var post := Label3D.new()
	post.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	post.pixel_size = 0.0032
	post.font_size = 40
	post.outline_size = 8
	post.outline_modulate = Color(0, 0, 0, 1)
	post.position = at
	parent.add_child(post)
	return post


## Words lying on the floor, read from the south.
func floor_words(parent: Node3D, at: Vector3, text: String, size: int = 36, colour: Color = Color(0.95, 0.95, 0.98)) -> Label3D:
	var words := Label3D.new()
	words.text = text
	words.pixel_size = 0.002
	words.font_size = size
	words.modulate = colour
	words.outline_size = 6
	words.outline_modulate = Color(0, 0, 0, 1)
	words.rotation_degrees = Vector3(-90, 0, 0)
	words.position = at
	parent.add_child(words)
	return words
