# Portal.gd
extends Area3D

var a: int
var b: int
@export var link_mesh_path: NodePath
var link_len: float = 1.0

func set_link_nodes(na:int, nb:int) -> void:
	a = na; b = nb

func set_link_length(d:float) -> void:
	link_len = d
	if link_mesh_path != NodePath():
		var m := get_node_or_null(link_mesh_path)
		if m and m is MeshInstance3D:
			m.scale = Vector3(d, m.scale.y, m.scale.z)

func _ready() -> void:
	body_entered.connect(_on_enter)

func _on_enter(body: Node) -> void:
	# Simple bidirectional teleport: if body is near a, send toward b (and vice versa)
	if !"GraphSpace" in get_tree().get_nodes_in_group("GraphSpace"): pass
	var space := get_parent() as Node3D
	if body is CharacterBody3D:
		var space_script := space as GraphSpace
		if space_script == null: return
		var pa = space_script.nodes[a].pos
		var pb = space_script.nodes[b].pos
		var to = (body.global_transform.origin.distance_to(pa) < body.global_transform.origin.distance_to(pb)) if pb else pa
		body.global_transform.origin = to + Vector3(0, 1.2, 0)
