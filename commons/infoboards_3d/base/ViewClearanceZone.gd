# ViewClearanceZone.gd
# Hides a "lid" mesh when player enters the area in front of the InfoBoard screen
extends Area3D

@export var lid_mesh_path: NodePath  # Path to the lid mesh to hide/show
@export var auto_find_lid: bool = true  # Automatically find lid mesh in parent

var lid_mesh: MeshInstance3D = null
var player_in_area: bool = false
var entry_count: int = 0  # Track number of objects in area

func _ready():
	# Connect signals to detect when player enters or exits the area
	# Check if already connected to avoid duplicate connections
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	# Find the lid mesh
	if auto_find_lid:
		_auto_find_lid()
	elif not lid_mesh_path.is_empty():
		lid_mesh = get_node_or_null(lid_mesh_path)

	if lid_mesh:
		print("[ViewClearanceZone] ✅ Initialized - lid mesh: %s (visible: %s)" % [lid_mesh.name, lid_mesh.visible])
		print("[ViewClearanceZone] Collision mask: %d, Layer: %d" % [collision_mask, collision_layer])
	else:
		print("[ViewClearanceZone] ⚠️ No lid mesh found - auto_find_lid: %s" % auto_find_lid)

func _auto_find_lid():
	# Look for a mesh named "Lid" or "ScreenLid" in parent
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is MeshInstance3D and ("lid" in child.name.to_lower() or "cover" in child.name.to_lower()):
				lid_mesh = child
				print("[ViewClearanceZone] Auto-found lid: %s" % child.name)
				return

func _on_area_entered(area: Area3D) -> void:
	print("[ViewClearanceZone] 🔵 Area entered: %s (type: %s)" % [area.name, area.get_class()])

	# Hide lid for ANY area entry (less restrictive for testing)
	entry_count += 1
	_hide_lid()

func _on_area_exited(area: Area3D) -> void:
	print("[ViewClearanceZone] 🔴 Area exited: %s" % area.name)

	entry_count -= 1
	if entry_count <= 0:
		entry_count = 0
		_show_lid()

func _on_body_entered(body: Node3D) -> void:
	print("[ViewClearanceZone] 🟢 Body entered: %s (type: %s)" % [body.name, body.get_class()])

	# Hide lid for ANY body entry (less restrictive for testing)
	entry_count += 1
	_hide_lid()

func _on_body_exited(body: Node3D) -> void:
	print("[ViewClearanceZone] 🟠 Body exited: %s" % body.name)

	entry_count -= 1
	if entry_count <= 0:
		entry_count = 0
		_show_lid()

func _hide_lid():
	if lid_mesh and lid_mesh.visible:
		lid_mesh.visible = false
		print("[ViewClearanceZone] 👁️ LID HIDDEN (entry_count: %d)" % entry_count)

func _show_lid():
	if lid_mesh and not lid_mesh.visible:
		lid_mesh.visible = true
		print("[ViewClearanceZone] 👁️ LID SHOWN (entry_count: %d)" % entry_count)

# Check if this is a player-related area
func _is_player_area(area: Area3D) -> bool:
	if not area:
		return false

	var area_name = area.name.to_lower()
	# Check for common player area names
	return "player" in area_name or "xr" in area_name or "camera" in area_name

# Check if this is a player-related body
func _is_player_body(body: Node3D) -> bool:
	if not body:
		return false

	var body_name = body.name.to_lower()
	# Check for common player body names
	return "player" in body_name or "xrbody" in body_name or "characterbody" in body_name
