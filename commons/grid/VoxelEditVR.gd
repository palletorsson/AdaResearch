# VoxelEditVR.gd — VR voxel editing component
#
# Attach to an XRController3D to enable voxel editing in VR.
# Point at grid surfaces, trigger to add cubes, grip to remove.
#
# Toggle: call enable() / disable() from VR staging or a menu.
#
# Usage in vrStaging.gd:
#   var voxel_vr := VoxelEditVR.new()
#   right_controller.add_child(voxel_vr)
#   voxel_vr.enable()

class_name VoxelEditVR
extends Node3D

var _controller: XRController3D = null
var _edit_controller: VoxelEditController = null
var _structure: GridStructureComponent = null
var _map_name: String = ""
var _active: bool = false
var _ray_visual: MeshInstance3D = null
var _label: Label3D = null


func _ready() -> void:
	# Find parent controller
	_controller = get_parent() as XRController3D
	if not _controller:
		push_warning("[VoxelEditVR] Must be child of XRController3D")
		return

	# Build ray visual
	_ray_visual = MeshInstance3D.new()
	_ray_visual.name = "EditRay"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.002
	cyl.bottom_radius = 0.002
	cyl.height = 15.0
	_ray_visual.mesh = cyl
	_ray_visual.position = Vector3(0, 0, -7.5)
	_ray_visual.rotation.x = PI * 0.5
	var ray_mat := StandardMaterial3D.new()
	ray_mat.albedo_color = Color(0.3, 0.8, 1.0, 0.4)
	ray_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ray_visual.material_override = ray_mat
	_ray_visual.visible = false
	add_child(_ray_visual)

	# HUD label
	_label = Label3D.new()
	_label.name = "VoxelLabel"
	_label.text = ""
	_label.font_size = 20
	_label.position = Vector3(0, 0.04, -0.08)
	_label.rotation.x = -PI * 0.3
	_label.visible = false
	add_child(_label)

	# Connect controller buttons
	if _controller.has_signal("button_pressed"):
		_controller.button_pressed.connect(_on_button)


func enable() -> void:
	# Find grid structure
	_structure = _find_node(get_tree().root, "GridStructureComponent") as GridStructureComponent
	if not _structure:
		push_warning("[VoxelEditVR] No GridStructureComponent found")
		return

	# Find map name
	var data_comp = _find_node(get_tree().root, "GridDataComponent")
	if data_comp and data_comp.has_method("get_current_map_name"):
		_map_name = data_comp.get_current_map_name()
	if data_comp and data_comp.has_method("get_structure_data"):
		_structure.enable_editing(data_comp.get_structure_data())

	# Create controller
	if not _edit_controller:
		_edit_controller = VoxelEditController.new()
		_edit_controller.name = "VoxelEditCtrl"
		_edit_controller.structure_component = _structure
		_edit_controller.cube_size = _structure.cube_size
		add_child(_edit_controller)

	_active = true
	_ray_visual.visible = true
	_label.visible = true
	_label.text = "VOXEL EDIT\nTrigger=Add Grip=Remove"
	print("[VoxelEditVR] Enabled")


func disable() -> void:
	_active = false
	if _ray_visual: _ray_visual.visible = false
	if _label: _label.visible = false
	print("[VoxelEditVR] Disabled")


func is_active() -> bool:
	return _active


func _on_button(button_name: String) -> void:
	if not _active or not _edit_controller:
		return
	match button_name:
		"trigger_click":
			_edit_controller.try_add()
		"grip_click":
			_edit_controller.try_remove()
		"ax_button":
			_save()
		"by_button":
			_edit_controller.undo()


func _process(_delta: float) -> void:
	if not _active or not _controller or not _edit_controller:
		return
	var origin: Vector3 = _controller.global_position
	var forward: Vector3 = -_controller.global_transform.basis.z
	_edit_controller.update_target_from_ray(origin, forward)

	if _label and _edit_controller.has_target:
		var tc := _edit_controller.target_cell
		_label.text = "(%d,%d,%d)\nTrigger=Add Grip=Remove" % [tc.x, tc.y, tc.z]


func _save() -> void:
	if not _structure or _map_name.is_empty():
		return
	VoxelSaveManager.save(_map_name, _structure)
	if _label:
		_label.text = "SAVED!"


func _find_node(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_node(child, node_name)
		if found:
			return found
	return null
