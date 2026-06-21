extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CapTheoremBench

## @identity
## name: CAP Theorem Bench — Pick Two
## concept: Paraconsistent engineering
## tier: medium
## lineage: post-crisis engineering takes impossibility results as design material, not
##   defeat. Brewer's CAP theorem says a distributed system cannot simultaneously
##   guarantee Consistency, Availability, and Partition-tolerance — and since networks
##   DO partition, the real choice is which of C or A you sacrifice when they do. The
##   limit is not a wall; it is a dial. The engineer who knows the limit designs around
##   the third.
## essence: a floor-standing triangle bench. Three corner posts — C / A / P — with a
##   glowing edge between each pair. At any moment only TWO corners are lit and the edge
##   between them glows warm: that is the guarantee you currently hold. The lit pair
##   rotates, dramatising that no single configuration gives you all three.
## truth: in a distributed system you pick two; you engineer around the third. The
##   triangle never closes on all three at once — and knowing that is what lets you
##   build something that survives the partition.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var lit_color: Color = Color(0.98, 0.72, 0.32)    # the held guarantee — amber
@export var dim_color: Color = Color(0.28, 0.32, 0.42)    # the sacrificed corner
@export var cycle_time: float = 3.2                        # seconds per rotation step

var _t: float = 0.0
var _active_pair: int = 0                                  # 0=CA, 1=AP, 2=PC
var _node_mats: Array[StandardMaterial3D] = []            # 3 corner glows
var _edge_mats: Array[StandardMaterial3D] = []            # 3 edge glows (CA, AP, PC)
var _corner_pos: Array[Vector3] = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cycle_time"):
		cycle_time = float(config["cycle_time"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_node_mats = []
	_edge_mats = []
	_corner_pos = []

	# --- bench base: a hexagonal slate plinth ~1 m across ---
	var base_mat: StandardMaterial3D = _matte_mat(slate, 0.85)
	add_child(_cylinder(Vector3(0.0, 0.06, 0.0), 0.55, 0.12, base_mat))
	var leg_mat: StandardMaterial3D = _steel_mat(Color(0.30, 0.31, 0.34))
	var li: int = 0
	while li < 3:
		var a: float = float(li) * TAU / 3.0 + 0.5
		add_child(_cylinder(Vector3(cos(a) * 0.38, 0.0, sin(a) * 0.38), 0.03, 0.12, leg_mat))
		li += 1

	# --- triangle: three corner posts at radius 0.42, top of plinth ---
	var labels: Array[String] = ["C", "A", "P"]
	var names: Array[String] = ["Consistency", "Availability", "Partition-tolerance"]
	var ci: int = 0
	while ci < 3:
		var ang: float = float(ci) * TAU / 3.0 - PI / 2.0   # C up, A lower-right, P lower-left
		var p: Vector3 = Vector3(cos(ang) * 0.42, 0.55, sin(ang) * 0.42)
		_corner_pos.append(p)
		# post pillar from plinth up to the node
		add_child(_cylinder(Vector3(p.x, 0.33, p.z), 0.022, 0.42, _steel_mat(Color(0.32, 0.33, 0.37))))
		# the corner node sphere (glow toggled in _process)
		var nm: StandardMaterial3D = _glow_mat(dim_color, 0.6)
		_node_mats.append(nm)
		add_child(_sphere(p, 0.075, nm))
		# wireframe ring around each corner — formal/cool
		add_child(_torus(p, 0.11, 0.006, _glow_mat(wire_purple, 0.6)))
		# corner labels
		add_child(_billboard_label(labels[ci], p + Vector3(0.0, 0.0, 0.0), 44, cool_white))
		add_child(_billboard_label(names[ci], p + Vector3(0.0, -0.17, 0.0), 16, Color(0.72, 0.78, 0.92)))
		ci += 1

	# --- three edges between the corners; edge e connects corner e and corner (e+1)%3 ---
	# edge 0 = C-A, edge 1 = A-P, edge 2 = P-C
	var ei: int = 0
	while ei < 3:
		var a_corner: Vector3 = _corner_pos[ei]
		var b_corner: Vector3 = _corner_pos[(ei + 1) % 3]
		var em: StandardMaterial3D = _glow_mat(dim_color, 0.5)
		_edge_mats.append(em)
		add_child(_cylinder_between(a_corner, b_corner, 0.014, em))
		ei += 1

	# --- title label (medium tier: y ~ 1.5) ---
	add_child(_billboard_label("CAP — PICK TWO", Vector3(0.0, 1.5, 0.0), 28, cool_white))
	add_child(_billboard_label("engineer around the third", Vector3(0.0, 1.38, 0.0), 16, Color(0.78, 0.84, 0.96)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# advance the lit pair on a timer
	var step: int = int(_t / maxf(cycle_time, 0.5)) % 3
	_active_pair = step
	# lit edge: 0 -> C-A(edge0), 1 -> A-P(edge1), 2 -> P-C(edge2)
	# the two corners adjacent to the lit edge are the two guarantees held.
	var lit_a: int = _active_pair
	var lit_b: int = (_active_pair + 1) % 3
	var pulse: float = 1.6 + 0.5 * sin(_t * 4.0)

	var i: int = 0
	while i < 3:
		var on: bool = (i == lit_a) or (i == lit_b)
		if _node_mats.size() > i and _node_mats[i] != null:
			var m: StandardMaterial3D = _node_mats[i]
			if on:
				m.albedo_color = lit_color
				m.emission = lit_color
				m.emission_energy_multiplier = pulse if emissive else pulse * 0.3
			else:
				m.albedo_color = dim_color
				m.emission = dim_color
				m.emission_energy_multiplier = 0.4 if emissive else 0.15
		# edges
		if _edge_mats.size() > i and _edge_mats[i] != null:
			var em: StandardMaterial3D = _edge_mats[i]
			if i == _active_pair:
				em.albedo_color = lit_color
				em.emission = lit_color
				em.emission_energy_multiplier = pulse if emissive else pulse * 0.3
			else:
				em.albedo_color = dim_color
				em.emission = dim_color
				em.emission_energy_multiplier = 0.3 if emissive else 0.1
		i += 1
