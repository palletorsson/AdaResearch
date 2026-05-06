# GlassSegmentPorts.gd
# Standardized port system for glass pipe segments
# All segments must have consistent connection points
extends RefCounted
class_name GlassSegmentPorts

## Port definition structure
## Every segment gets this metadata attached via set_meta("ports", {...})
##
## Standard port format:
## {
##     "in": {
##         "position": Vector3,    # Local position of input connection
##         "direction": Vector3,   # Direction the port faces (normalized)
##         "radius": float         # Connection radius for alignment
##     },
##     "out": {                    # Or "out1", "out2" for multi-output
##         "position": Vector3,
##         "direction": Vector3,
##         "radius": float
##     }
## }
##
## Terminal segments (cap, drip, beaker) have is_terminal=true and no "out" port

const PORT_IN = "in"
const PORT_OUT = "out"

# =============================================================================
# PORT CREATION HELPERS
# =============================================================================

static func create_port(position: Vector3, direction: Vector3, radius: float) -> Dictionary:
	return {
		"position": position,
		"direction": direction.normalized(),
		"radius": radius
	}

static func create_standard_ports(tube_radius: float, length: float) -> Dictionary:
	## Standard in/out for straight segments
	return {
		PORT_IN: create_port(Vector3.ZERO, Vector3.BACK, tube_radius),
		PORT_OUT: create_port(Vector3(0, 0, length), Vector3.FORWARD, tube_radius)
	}

static func create_terminal_port(tube_radius: float) -> Dictionary:
	## For segments that only have input (cap, drip, beaker)
	return {
		PORT_IN: create_port(Vector3.ZERO, Vector3.BACK, tube_radius)
	}

# =============================================================================
# APPLY PORTS TO SEGMENT
# =============================================================================

static func apply_ports(segment: Node3D, ports: Dictionary, is_terminal: bool = false) -> void:
	segment.set_meta("ports", ports)
	segment.set_meta("is_terminal", is_terminal)

static func apply_standard_ports(segment: Node3D, tube_radius: float, length: float) -> void:
	apply_ports(segment, create_standard_ports(tube_radius, length), false)

static func apply_terminal_port(segment: Node3D, tube_radius: float) -> void:
	apply_ports(segment, create_terminal_port(tube_radius), true)

# =============================================================================
# PORT QUERY
# =============================================================================

static func get_ports(segment: Node3D) -> Dictionary:
	if segment.has_meta("ports"):
		return segment.get_meta("ports")
	return {}

static func get_port(segment: Node3D, port_name: String) -> Dictionary:
	var ports = get_ports(segment)
	return ports.get(port_name, {})

static func is_terminal(segment: Node3D) -> bool:
	if segment.has_meta("is_terminal"):
		return segment.get_meta("is_terminal")
	return false

static func get_out_port_names(segment: Node3D) -> Array[String]:
	## Returns all output port names (out, out1, out2, left, right, etc.)
	var result: Array[String] = []
	var ports = get_ports(segment)
	for key in ports.keys():
		if key != PORT_IN:
			result.append(key)
	return result

# =============================================================================
# CONNECTION VALIDATION
# =============================================================================

static func can_connect(from_segment: Node3D, from_port: String, 
						to_segment: Node3D, to_port: String,
						tolerance: float = 0.1) -> Dictionary:
	## Check if two ports can connect
	## Returns { "valid": bool, "error": String, "radius_diff": float }
	
	var from_p = get_port(from_segment, from_port)
	var to_p = get_port(to_segment, to_port)
	
	if from_p.is_empty():
		return {"valid": false, "error": "Source port '%s' not found" % from_port}
	if to_p.is_empty():
		return {"valid": false, "error": "Target port '%s' not found" % to_port}
	
	var radius_diff = abs(from_p.radius - to_p.radius)
	if radius_diff > tolerance:
		return {
			"valid": false, 
			"error": "Radius mismatch: %.3f vs %.3f" % [from_p.radius, to_p.radius],
			"radius_diff": radius_diff
		}
	
	return {"valid": true, "error": "", "radius_diff": radius_diff}

# =============================================================================
# DEBUG VISUALIZATION
# =============================================================================

static func create_port_visualization(segment: Node3D, port_name: String, color: Color = Color.GREEN) -> MeshInstance3D:
	## Creates a small sphere at port location for debugging
	var port = get_port(segment, port_name)
	if port.is_empty():
		return null
	
	var viz = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = port.radius * 1.5
	sphere.height = port.radius * 3
	viz.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.5
	viz.material_override = mat
	
	viz.position = port.position
	viz.name = "PortViz_%s" % port_name
	
	return viz

static func visualize_all_ports(segment: Node3D) -> Node3D:
	## Creates visualization for all ports on a segment
	var viz_root = Node3D.new()
	viz_root.name = "PortVisualizations"
	
	var ports = get_ports(segment)
	for port_name in ports.keys():
		var color = Color.RED if port_name == PORT_IN else Color.GREEN
		var viz = create_port_visualization(segment, port_name, color)
		if viz:
			viz_root.add_child(viz)
	
	return viz_root
