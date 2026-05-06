extends Node
class_name SynthCableManager

## Manages all synth cables and routes audio/parameter connections
## Acts as the "brain" of the modular synth rack

signal parameter_routed(from_param: String, to_param: String)
signal parameter_unrouted(from_param: String, to_param: String)
signal connection_made(cable: SynthCable, output_jack: SynthJack, input_jack: SynthJack)
signal connection_broken(cable: SynthCable)

# All registered jacks
var output_jacks: Dictionary = {}  # parameter_name -> SynthJack
var input_jacks: Dictionary = {}   # parameter_name -> Array[SynthJack] (multiple inputs can exist)

# Active cables
var cables: Array[SynthCable] = []

# Parameter routing: output -> inputs
var routes: Dictionary = {}  # output_param -> Array[input_param]

# Cable color palette (for auto-assigning colors)
const CABLE_COLORS = [
	Color(0.9, 0.2, 0.2),   # Red
	Color(0.2, 0.7, 0.9),   # Cyan
	Color(0.9, 0.6, 0.1),   # Orange
	Color(0.2, 0.9, 0.3),   # Green
	Color(0.9, 0.2, 0.8),   # Pink
	Color(0.4, 0.3, 0.9),   # Purple
	Color(0.9, 0.9, 0.2),   # Yellow
	Color(0.5, 0.5, 0.5),   # Gray
]

var _next_color_index: int = 0

# Touch-to-patch state
var _pending_jack: SynthJack = null         # First jack touched, waiting for second
var _pending_highlight: OmniLight3D = null   # Visual feedback for pending selection
var _all_jacks: Array = []                   # All registered jacks (for touch detection)
const TOUCH_PATCH_ENABLED: bool = true
const TOUCH_TIMEOUT: float = 5.0             # Seconds before pending selection clears
var _pending_timer: float = 0.0


func _ready():
	pass


func _process(delta: float) -> void:
	# Clear pending jack after timeout
	if _pending_jack and _pending_timer > 0:
		_pending_timer -= delta
		if _pending_timer <= 0:
			_clear_pending_jack()


## Register a jack with the manager
func register_jack(jack: SynthJack):
	var param = jack.parameter_name
	
	if jack.is_output():
		output_jacks[param] = jack
		if not routes.has(param):
			routes[param] = []
		print("SynthCableManager: Registered output jack '%s'" % param)
	else:
		if not input_jacks.has(param):
			input_jacks[param] = []
		input_jacks[param].append(jack)
		print("SynthCableManager: Registered input jack '%s'" % param)
	
	# Connect jack signals
	jack.cable_connected.connect(_on_jack_connected.bind(jack))
	jack.cable_disconnected.connect(_on_jack_disconnected.bind(jack))

	# Touch-to-patch: listen for hand/finger entering jack area
	_all_jacks.append(jack)
	if TOUCH_PATCH_ENABLED:
		_setup_touch_detection(jack)


## Unregister a jack
func unregister_jack(jack: SynthJack):
	var param = jack.parameter_name
	
	if jack.is_output():
		output_jacks.erase(param)
		routes.erase(param)
	else:
		if input_jacks.has(param):
			input_jacks[param].erase(jack)


## Register a cable with the manager
func register_cable(cable: SynthCable):
	if cable in cables:
		return
	
	cables.append(cable)
	cable.connection_changed.connect(_on_cable_connection_changed.bind(cable))
	
	# Assign a color
	cable.set_cable_color(_get_next_color())
	
	print("SynthCableManager: Registered cable (total: %d)" % cables.size())


## Create a new cable
func spawn_cable(spawn_position: Vector3 = Vector3.ZERO) -> SynthCable:
	var cable = SynthCable.new()
	cable.position = spawn_position
	add_child(cable)
	register_cable(cable)
	return cable


## Remove a cable
func remove_cable(cable: SynthCable):
	cables.erase(cable)
	cable.queue_free()


func _on_jack_connected(cable: Node3D, plug: Node3D, jack: SynthJack):
	# Connection will be evaluated when cable reports both ends connected
	pass


func _on_jack_disconnected(cable: Node3D, plug: Node3D, jack: SynthJack):
	# Check if this breaks a route
	if cable is SynthCable:
		_evaluate_cable_connection(cable)


func _on_cable_connection_changed(output_jack: SynthJack, input_jack: SynthJack, cable: SynthCable):
	if output_jack and input_jack:
		# New connection made
		var out_param = output_jack.parameter_name
		var in_param = input_jack.parameter_name
		
		# Add route
		if not routes.has(out_param):
			routes[out_param] = []
		if in_param not in routes[out_param]:
			routes[out_param].append(in_param)
			parameter_routed.emit(out_param, in_param)
			connection_made.emit(cable, output_jack, input_jack)
			print("SynthCableManager: Routed %s → %s" % [out_param, in_param])
	else:
		# Connection broken - find and remove the route
		_remove_cable_route(cable)


func _evaluate_cable_connection(cable: SynthCable):
	var output_jack = cable.get_output_jack()
	var input_jack = cable.get_input_jack()
	
	if output_jack and input_jack:
		# Still connected
		return
	
	# Remove any routes this cable had
	_remove_cable_route(cable)


func _remove_cable_route(cable: SynthCable):
	# Find what this cable was routing
	# Since cable might be partially disconnected, we need to check all routes
	for out_param in routes.keys():
		var in_params = routes[out_param]
		for in_param in in_params:
			# Check if this cable was the one providing this route
			if _cable_was_routing(cable, out_param, in_param):
				routes[out_param].erase(in_param)
				parameter_unrouted.emit(out_param, in_param)
				connection_broken.emit(cable)
				print("SynthCableManager: Unrouted %s → %s" % [out_param, in_param])


func _cable_was_routing(cable: SynthCable, out_param: String, in_param: String) -> bool:
	# Check if this cable's jacks match the parameters
	var out_jack = cable.get_output_jack()
	var in_jack = cable.get_input_jack()
	
	if out_jack and out_jack.parameter_name == out_param:
		if in_jack and in_jack.parameter_name == in_param:
			return true
	return false


func _get_next_color() -> Color:
	var color = CABLE_COLORS[_next_color_index % CABLE_COLORS.size()]
	_next_color_index += 1
	return color


## Get all parameters routed from an output
func get_routes_from(output_param: String) -> Array:
	return routes.get(output_param, [])


## Get all outputs routing to an input
func get_routes_to(input_param: String) -> Array:
	var result = []
	for out_param in routes.keys():
		if input_param in routes[out_param]:
			result.append(out_param)
	return result


## Check if a route exists
func has_route(from_param: String, to_param: String) -> bool:
	if not routes.has(from_param):
		return false
	return to_param in routes[from_param]


## Get current parameter value through routing
## Applies jack level attenuation from both output and input jacks
func get_routed_value(target_param: String, values: Dictionary) -> float:
	# Find what routes to this parameter
	var sources = get_routes_to(target_param)

	if sources.is_empty():
		# No routing — apply input jack level to direct value
		var base_val: float = values.get(target_param, 0.0)
		var in_level: float = _get_jack_level(target_param, false)
		return base_val * in_level

	# Mix routed sources, applying output jack levels
	var total = 0.0
	for source_param in sources:
		var source_val: float = values.get(source_param, 0.0)
		var out_level: float = _get_jack_level(source_param, true)
		total += source_val * out_level

	# Apply input jack level to the mixed result
	var in_level: float = _get_jack_level(target_param, false)
	var mixed: float = total / sources.size() if sources.size() > 0 else 0.0
	return mixed * in_level


## Look up a jack's level by parameter name
func _get_jack_level(param: String, is_output: bool) -> float:
	if is_output:
		if output_jacks.has(param):
			return output_jacks[param].level
	else:
		if input_jacks.has(param):
			for jack in input_jacks[param]:
				return jack.level  # Use first matching input jack's level
	return 1.0  # Default: full level if jack not found


## Auto-connect jacks by matching parameter names
## Useful for initial setup
func auto_connect_matching():
	for out_param in output_jacks.keys():
		if input_jacks.has(out_param):
			var out_jack = output_jacks[out_param]
			var in_jack_array = input_jacks[out_param]
			if in_jack_array.size() > 0:
				var in_jack = in_jack_array[0]
				
				# Create cable connecting them
				var cable = spawn_cable()
				cable.plug_a.snap_to_jack(out_jack)
				cable.plug_b.snap_to_jack(in_jack)
				
				print("SynthCableManager: Auto-connected %s" % out_param)


## Get cable count
func get_cable_count() -> int:
	return cables.size()


## Clear all cables
func clear_all_cables():
	for cable in cables.duplicate():
		remove_cable(cable)
	routes.clear()


## --- Touch-to-Patch System ---
## Poke an output jack, then poke an input jack → cable auto-spawns.
## Poke a connected jack → disconnects its cable.

func _setup_touch_detection(jack: SynthJack) -> void:
	# Create a separate Area3D for touch detection (larger than plug snap area)
	var touch_area := Area3D.new()
	touch_area.name = "TouchArea"
	touch_area.collision_layer = 0
	touch_area.collision_mask = 262144  # XR hand layer

	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = jack.socket_radius * 4.0  # Generous touch target
	col.shape = sphere
	touch_area.add_child(col)
	jack.add_child(touch_area)

	touch_area.body_entered.connect(_on_touch_body_entered.bind(jack))


func _on_touch_body_entered(body: Node3D, jack: SynthJack) -> void:
	if not TOUCH_PATCH_ENABLED:
		return

	# Ignore if body is a cable plug (physical patching handles that)
	if body.has_method("is_synth_plug"):
		return

	# Check if body is an XR hand/controller
	# XR hands and controllers typically have specific names or are on the XR layer
	if not _is_xr_hand(body):
		return

	# If this jack is already connected and we're not in pending state, disconnect it
	if jack.is_connected and not _pending_jack:
		_touch_disconnect(jack)
		return

	# If no pending jack, set this as first selection
	if not _pending_jack:
		_set_pending_jack(jack)
		return

	# If same jack touched again, cancel
	if _pending_jack == jack:
		_clear_pending_jack()
		return

	# Second jack touched — try to connect
	_touch_connect(_pending_jack, jack)


func _is_xr_hand(body: Node3D) -> bool:
	# Check various ways an XR hand/controller can be identified
	var name_lower: String = body.name.to_lower()
	if "hand" in name_lower or "controller" in name_lower or "finger" in name_lower:
		return true
	# Check parent names too
	var parent = body.get_parent()
	if parent:
		var pname: String = parent.name.to_lower()
		if "hand" in pname or "controller" in pname or "player" in pname:
			return true
	# Check collision layer — XR hands use layer 262144 (bit 18)
	if body is PhysicsBody3D:
		if body.collision_layer & 262144:
			return true
	return false


func _set_pending_jack(jack: SynthJack) -> void:
	_pending_jack = jack
	_pending_timer = TOUCH_TIMEOUT

	# Visual feedback: bright glow on the selected jack
	_pending_highlight = OmniLight3D.new()
	_pending_highlight.name = "PendingGlow"
	_pending_highlight.light_color = Color(0.3, 0.9, 1.0) if jack.is_output() else Color(1.0, 0.6, 0.2)
	_pending_highlight.light_energy = 2.0
	_pending_highlight.omni_range = 0.06
	_pending_highlight.omni_attenuation = 2.0
	jack.add_child(_pending_highlight)

	print("TouchPatch: Selected %s jack '%s' — touch another jack to connect" % [
		"output" if jack.is_output() else "input", jack.parameter_name])


func _clear_pending_jack() -> void:
	if _pending_highlight and is_instance_valid(_pending_highlight):
		_pending_highlight.queue_free()
	_pending_highlight = null
	_pending_jack = null
	_pending_timer = 0.0


func _touch_connect(jack_a: SynthJack, jack_b: SynthJack) -> void:
	# Determine output and input
	var out_jack: SynthJack = null
	var in_jack: SynthJack = null

	if jack_a.is_output() and jack_b.is_input():
		out_jack = jack_a
		in_jack = jack_b
	elif jack_a.is_input() and jack_b.is_output():
		out_jack = jack_b
		in_jack = jack_a
	else:
		# Same type — can't connect output→output or input→input
		print("TouchPatch: Can't connect two %s jacks" % ("output" if jack_a.is_output() else "input"))
		_clear_pending_jack()
		return

	# Spawn cable and connect both plugs
	var midpoint: Vector3 = (out_jack.global_position + in_jack.global_position) * 0.5
	var cable := spawn_cable(midpoint)
	cable.plug_a.snap_to_jack(out_jack)
	cable.plug_b.snap_to_jack(in_jack)

	print("TouchPatch: Connected %s → %s" % [out_jack.parameter_name, in_jack.parameter_name])
	_clear_pending_jack()


func _touch_disconnect(jack: SynthJack) -> void:
	# Find the cable connected to this jack and remove it
	for cable in cables:
		var out_j = cable.get_output_jack()
		var in_j = cable.get_input_jack()
		if out_j == jack or in_j == jack:
			# Disconnect both plugs
			if out_j:
				out_j.force_disconnect()
			if in_j:
				in_j.force_disconnect()
			remove_cable(cable)
			print("TouchPatch: Disconnected cable from '%s'" % jack.parameter_name)
			return
