extends Node3D

@onready var label: Label3D = $StartButton/Label3D
@export var xr_origin_path: NodePath = NodePath("../../XROrigin3D")

var _xr_origin: Node3D

func _ready():
	_xr_origin = get_node_or_null(xr_origin_path)
	if not _xr_origin:
		_xr_origin = _find_xr_origin()
	
	if not _xr_origin:
		label.text = "Waiting for Player..."

func _process(_delta):
	if _xr_origin:
		var pos = _xr_origin.global_position
		label.text = "(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]
	elif Engine.get_process_frames() % 60 == 0:
		# Retry finding player
		_xr_origin = _find_xr_origin()

func _find_xr_origin() -> Node3D:
	"""Try to find XROrigin3D in the scene tree"""
	var root = get_tree().root
	if root:
		for child in root.get_children():
			var found = _search_for_xr_origin(child)
			if found:
				return found
	return null

func _search_for_xr_origin(node: Node) -> Node3D:
	"""Recursively search for XROrigin3D"""
	if node.name == "XROrigin3D" or node.is_class("XROrigin3D"):
		return node as Node3D
	for child in node.get_children():
		var found = _search_for_xr_origin(child)
		if found:
			return found
	return null
