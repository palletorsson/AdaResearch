class_name InventoryInstancer
extends Node3D
## COPIES AS ONE MULTIMESH (Palle, 2026-10-30: "keep the copies multi mesh, if we add like 10 boxes of the same
## type"). The first copy of a prefab pays its draw calls; every further copy of the same prefab with the same
## config is an INSTANCE of the first's merged mesh (MeshMerge), drawn by one MultiMeshInstance3D per key, so ten
## crates cost the draws of one. Each copy keeps its own body, colliders and transform - its own meshes are put
## on layer 0 and the instance follows the copy every physics frame (a plank that falls still falls). A copy
## that leaves the tree leaves the multimesh. Keys: item id + its config, so a pink ball and a cyan ball are two
## multimeshes. Not for things that animate their own meshes (items.json "instance": false - the clock's digits).

const MergeLib = preload("res://commons/artifacts/mesh_merge.gd")

var _groups: Dictionary = {}   # key -> {mmi: MultiMeshInstance3D, mesh: ArrayMesh, copies: Array[Node3D], roots: Array[Node3D]}

## `copy` is the node the hand placed (a carrier or a pickable); `art` the artifact root whose meshes are the
## thing (the carrier's child, or the pickable itself). Returns true when the copy is now instanced.
func register(copy: Node3D, art: Node3D, key: String) -> bool:
	if not is_instance_valid(copy) or not is_instance_valid(art):return false
	var g: Dictionary = _groups.get(key, {})
	if g.is_empty():
		# the first copy's meshes become the shared mesh: the artifact's own "Merged" if it merges itself (the
		# crate), else merged here once; then its own meshes are hidden like the others'
		var merged: MeshInstance3D = art.find_child("Merged", true, false) as MeshInstance3D
		if merged == null:merged = MergeLib.merge(art)
		if merged == null:return false
		var mmi := MultiMeshInstance3D.new();mmi.name = "Instances_" + key.validate_node_name()
		var mm := MultiMesh.new();mm.transform_format = MultiMesh.TRANSFORM_3D;mm.mesh = merged.mesh;mmi.multimesh = mm
		add_child(mmi);mmi.top_level = true;mmi.global_transform = Transform3D.IDENTITY
		g = {"mmi": mmi, "mesh": merged.mesh, "copies": [], "roots": []};_groups[key] = g
	_hide_meshes(art)
	g.copies.append(copy);g.roots.append(art)
	copy.tree_exiting.connect(_on_copy_leaving.bind(key, copy), CONNECT_ONE_SHOT)
	_resize(key)
	return true

func count(key: String) -> int:
	var g: Dictionary = _groups.get(key, {})
	return (g.copies as Array).size() if not g.is_empty() else 0

func groups() -> int:return _groups.size()

func _on_copy_leaving(key: String, copy: Node3D) -> void:
	var g: Dictionary = _groups.get(key, {})
	if g.is_empty():return
	var i: int = (g.copies as Array).find(copy)
	if i >= 0:(g.copies as Array).remove_at(i);(g.roots as Array).remove_at(i)
	if (g.copies as Array).is_empty():
		(g.mmi as Node).queue_free();_groups.erase(key)
	else:_resize(key)

func _resize(key: String) -> void:
	var g: Dictionary = _groups[key];var mm: MultiMesh = (g.mmi as MultiMeshInstance3D).multimesh
	mm.instance_count = (g.copies as Array).size()
	_follow(key)

## A copy's meshes are hidden, not removed: the thing keeps its shape for pickups, AABBs and probes.
static func _hide_meshes(art: Node) -> void:
	var stack: Array = [art]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():stack.append(c)
		if n is MeshInstance3D:(n as MeshInstance3D).layers = 0

func _physics_process(_delta: float) -> void:
	for key in _groups:_follow(key)

func _follow(key: String) -> void:
	var g: Dictionary = _groups[key];var mm: MultiMesh = (g.mmi as MultiMeshInstance3D).multimesh
	var roots: Array = g.roots
	for i in roots.size():
		var r: Node3D = roots[i]
		if is_instance_valid(r) and r.is_inside_tree():mm.set_instance_transform(i, r.global_transform)
