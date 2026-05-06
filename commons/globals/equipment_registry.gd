extends Node

## Global registry for assembled equipment
## Equipment built on assembly lines gets registered here
## Higher-level assemblies query this to find available equipment

# Stored equipment: id → {node, type, available, metadata}
var _equipment: Dictionary = {}

# Signals
signal equipment_registered(id: String, equipment_type: String)
signal equipment_consumed(id: String, equipment_type: String)
signal equipment_released(id: String, equipment_type: String)


func _ready() -> void:
	add_to_group("equipment_registry")
	print("EquipmentRegistry: Initialized")


## Register new equipment (called when assembly line completes a product)
func register(id: String, equipment: Node3D, equipment_type: String, metadata: Dictionary = {}) -> void:
	_equipment[id] = {
		"node": equipment,
		"type": equipment_type,
		"available": true,
		"metadata": metadata
	}

	# Tag the node itself for easy identification
	equipment.set_meta("equipment_id", id)
	equipment.set_meta("equipment_type", equipment_type)
	equipment.add_to_group("registered_equipment")
	equipment.add_to_group("equipment_%s" % equipment_type)

	print("EquipmentRegistry: Registered %s (%s)" % [id, equipment_type])
	equipment_registered.emit(id, equipment_type)


## Get all available equipment of a specific type
func get_available(equipment_type: String) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for id in _equipment:
		var entry = _equipment[id]
		if entry.available and entry.type == equipment_type:
			if is_instance_valid(entry.node):
				result.append(entry.node)
	return result


## Get all available equipment (any type)
func get_all_available() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for id in _equipment:
		var entry = _equipment[id]
		if entry.available and is_instance_valid(entry.node):
			result.append(entry.node)
	return result


## Check if specific equipment type is available
func has_available(equipment_type: String) -> bool:
	return get_available(equipment_type).size() > 0


## Count available equipment of a type
func count_available(equipment_type: String) -> int:
	return get_available(equipment_type).size()


## Consume equipment (mark as used, typically when placed in higher-level assembly)
func consume(id: String) -> Node3D:
	if _equipment.has(id):
		var entry = _equipment[id]
		if entry.available and is_instance_valid(entry.node):
			entry.available = false
			print("EquipmentRegistry: Consumed %s (%s)" % [id, entry.type])
			equipment_consumed.emit(id, entry.type)
			return entry.node
	return null


## Consume equipment by node reference
func consume_node(equipment: Node3D) -> bool:
	var id = equipment.get_meta("equipment_id", "")
	if id != "" and _equipment.has(id):
		_equipment[id].available = false
		equipment_consumed.emit(id, _equipment[id].type)
		return true
	return false


## Release equipment (make available again, e.g., if assembly cancelled)
func release(id: String) -> void:
	if _equipment.has(id):
		_equipment[id].available = true
		print("EquipmentRegistry: Released %s" % id)
		equipment_released.emit(id, _equipment[id].type)


## Unregister equipment (remove completely, e.g., if destroyed)
func unregister(id: String) -> void:
	if _equipment.has(id):
		var entry = _equipment[id]
		if is_instance_valid(entry.node):
			entry.node.remove_from_group("registered_equipment")
			entry.node.remove_from_group("equipment_%s" % entry.type)
		_equipment.erase(id)
		print("EquipmentRegistry: Unregistered %s" % id)


## Get equipment info by ID
func get_info(id: String) -> Dictionary:
	if _equipment.has(id):
		return _equipment[id].duplicate()
	return {}


## Get equipment by ID
func get_equipment(id: String) -> Node3D:
	if _equipment.has(id) and is_instance_valid(_equipment[id].node):
		return _equipment[id].node
	return null


## Clean up invalid entries (nodes that were freed)
func cleanup() -> void:
	var to_remove: Array[String] = []
	for id in _equipment:
		if not is_instance_valid(_equipment[id].node):
			to_remove.append(id)

	for id in to_remove:
		_equipment.erase(id)

	if to_remove.size() > 0:
		print("EquipmentRegistry: Cleaned up %d invalid entries" % to_remove.size())


## Debug: Print all registered equipment
func debug_print() -> void:
	print("=== Equipment Registry ===")
	for id in _equipment:
		var entry = _equipment[id]
		var status = "AVAILABLE" if entry.available else "CONSUMED"
		var valid = "valid" if is_instance_valid(entry.node) else "INVALID"
		print("  %s: %s [%s] (%s)" % [id, entry.type, status, valid])
	print("==========================")
