# MovementCapabilityGate.gd
# Gates movement providers (climb, flight) based on CatalystCapabilityManager state.
# Attach to XROrigin3D or place as autoload.
# Climb unlocks at stage 8 (noise), flight at stage 14 (swarmintelligence).

extends Node
class_name MovementCapabilityGate

# Movement provider node names to search for
const FLIGHT_NODE_NAME := "MovementFlight"
const CLIMB_NODE_NAME := "MovementClimb"

# Map ability names (from soft_stages.json) to node names.
# Only abilities defined in soft_stages.json movement_abilities are gated.
# wall_walk is NOT gated — it has no stage entry and stays always available.
const ABILITY_TO_NODE: Dictionary = {
	"flight": FLIGHT_NODE_NAME,
	"climb": CLIMB_NODE_NAME,
}

var _cap_mgr: Node = null
var _gated_providers: Dictionary = {}  # ability_name -> Node reference


func _ready() -> void:
	call_deferred("_initialize")


func _initialize() -> void:
	_cap_mgr = get_node_or_null("/root/CatalystCapabilityManager")
	if not _cap_mgr:
		push_warning("MovementCapabilityGate: CatalystCapabilityManager not found — movement unrestricted")
		return

	# Connect to capability signals
	if _cap_mgr.has_signal("movement_ability_unlocked"):
		_cap_mgr.movement_ability_unlocked.connect(_on_movement_ability_unlocked)

	# Find the XR origin (search up from self, or from scene root)
	var xr_origin: Node = _find_xr_origin()
	if not xr_origin:
		push_warning("MovementCapabilityGate: No XROrigin3D found — movement unrestricted")
		return

	# Find and gate movement providers
	for ability_name in ABILITY_TO_NODE.keys():
		var node_name: String = ABILITY_TO_NODE[ability_name]
		var provider: Node = xr_origin.find_child(node_name, true, false)
		if provider:
			_gated_providers[ability_name] = provider
			var is_unlocked: bool = _cap_mgr.is_movement_available(ability_name)
			_set_provider_enabled(provider, is_unlocked)
			print("MovementCapabilityGate: '%s' (%s) -> %s" % [
				ability_name, provider.name, "ENABLED" if is_unlocked else "DISABLED"
			])
		# else: provider not in scene, that's fine (e.g., climb not added yet)

	print("MovementCapabilityGate: Initialized — %d providers gated, stage %d" % [
		_gated_providers.size(), _cap_mgr.get_current_stage_order()
	])


func _on_movement_ability_unlocked(ability: String) -> void:
	if _gated_providers.has(ability):
		var provider: Node = _gated_providers[ability]
		if is_instance_valid(provider):
			_set_provider_enabled(provider, true)
			print("MovementCapabilityGate: UNLOCKED '%s' (%s)" % [ability, provider.name])

	# Also try to find provider dynamically (may have been added after init)
	elif ABILITY_TO_NODE.has(ability):
		var xr_origin := _find_xr_origin()
		if xr_origin:
			var node_name: String = ABILITY_TO_NODE[ability]
			var provider: Node = xr_origin.find_child(node_name, true, false)
			if provider:
				_gated_providers[ability] = provider
				_set_provider_enabled(provider, true)
				print("MovementCapabilityGate: UNLOCKED '%s' (late-found %s)" % [ability, provider.name])


func _set_provider_enabled(provider: Node, enabled: bool) -> void:
	if provider.has_method("set") and "enabled" in provider:
		provider.set("enabled", enabled)
	elif provider.has_method("set_enabled"):
		provider.set_enabled(enabled)
	else:
		# Fallback: toggle process
		provider.set_process(enabled)
		provider.set_physics_process(enabled)


func _find_xr_origin() -> Node:
	# Method 1: parent is XROrigin3D
	var parent := get_parent()
	while parent:
		if parent is XROrigin3D:
			return parent
		parent = parent.get_parent()

	# Method 2: search from scene root
	var scene := get_tree().current_scene
	if scene:
		var origins = scene.find_children("*", "XROrigin3D", true, false)
		if origins.size() > 0:
			return origins[0]

	# Method 3: xr_origin group
	var group = get_tree().get_nodes_in_group("xr_origin")
	if group.size() > 0:
		return group[0]

	return null


# Debug: force-enable all gated providers
func unlock_all() -> void:
	for ability in _gated_providers:
		var provider = _gated_providers[ability]
		if is_instance_valid(provider):
			_set_provider_enabled(provider, true)
	print("MovementCapabilityGate: All providers force-enabled")


# Debug: force-disable all gated providers
func lock_all() -> void:
	for ability in _gated_providers:
		var provider = _gated_providers[ability]
		if is_instance_valid(provider):
			_set_provider_enabled(provider, false)
	print("MovementCapabilityGate: All providers force-disabled")
