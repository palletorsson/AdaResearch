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


func _ready():
	pass


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
## This can be used by the audio system to get routed values
func get_routed_value(target_param: String, values: Dictionary) -> float:
	# Find what routes to this parameter
	var sources = get_routes_to(target_param)
	
	if sources.is_empty():
		# No routing, return the direct value
		return values.get(target_param, 0.0)
	
	# If multiple sources, mix them (could be sum, average, max, etc.)
	var total = 0.0
	for source_param in sources:
		total += values.get(source_param, 0.0)
	
	# Return average of all sources (could be configurable)
	return total / sources.size() if sources.size() > 0 else 0.0


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
