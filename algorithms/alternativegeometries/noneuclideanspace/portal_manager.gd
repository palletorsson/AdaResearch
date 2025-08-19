# portal_manager.gd
class_name PortalManager
extends Node3D

signal portal_entered(portal, body)
signal portal_exited(portal, body)
signal teleport_complete(portal, body)

var active_portals = []
var teleporting = false

func _ready():
	# Find all portals in the scene
	_find_portals()

func _find_portals():
	active_portals.clear()
	for portal in get_tree().get_nodes_in_group("portals"):
		register_portal(portal)

func register_portal(portal: Portal):
	if !active_portals.has(portal):
		active_portals.append(portal)
		portal.body_entered.connect(_on_portal_body_entered.bind(portal))
		portal.body_exited.connect(_on_portal_body_exited.bind(portal))
		print("Registered portal: " + portal.name)

func unregister_portal(portal: Portal):
	if active_portals.has(portal):
		active_portals.erase(portal)
		portal.body_entered.disconnect(_on_portal_body_entered)
		portal.body_exited.disconnect(_on_portal_body_exited)

func _on_portal_body_entered(body: Node3D, portal: Portal):
	portal_entered.emit(portal, body)
	
	# If this is the player and we're not already teleporting, handle it
	if body is XROrigin3D and !teleporting:
		var target_portal = portal.linked_portal
		if target_portal:
			_handle_teleport(body, portal, target_portal)

func _on_portal_body_exited(body: Node3D, portal: Portal):
	portal_exited.emit(portal, body)

func _handle_teleport(body: XROrigin3D, source_portal: Portal, target_portal: Portal):
	teleporting = true
	
	# Calculate the relative position and orientation
	var relative_pos = source_portal.global_transform.inverse() * body.global_transform
	var target_transform = target_portal.global_transform * relative_pos
	
	# Apply scale correction if the portals have different scales
	if source_portal.scale != target_portal.scale:
		var scale_factor = target_portal.scale / source_portal.scale
		target_transform.origin *= scale_factor
	
	# Teleport the player
	body.global_transform = target_transform
	
	# Emit signal and reset teleporting flag
	teleport_complete.emit(target_portal, body)
	teleporting = false
