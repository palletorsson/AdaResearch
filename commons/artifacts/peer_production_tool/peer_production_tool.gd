extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PeerProductionTool

## @identity
## name: Peer Production Tool — The Many Over the One
## concept: Collective knowledge / the commons
## tier: applied
## lineage: post-crisis design after the foundations crisis. Peer production (Benkler) is
##   how the commons actually gets made: no central author, no command hierarchy — many
##   self-selected peers each contribute a small piece, and the pieces accrete into a
##   shared artifact larger than any one of them could build. Linux, Wikipedia, OpenStreetMap:
##   the many, not the one.
## essence: a ~1 m device. Around its rim sit many peer-nodes; each fires a small
##   contribution packet inward that lands on a growing central artifact (a stack of
##   accreted facets). An "EDITS: N  CONTRIBUTORS: M" readout climbs as the work piles up.
##   When the artifact fills, it is "released" (cleared) and the commons starts the next
##   version — the count of contributors keeps growing across versions.
## truth: the many over the one. Value is produced by countless small peer contributions
##   accreting into a shared whole — distributed authorship, no centre.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var contrib_teal: Color = Color(0.35, 0.88, 0.80)   # warm constructive accent
@export var peer_count: int = 12
@export var max_facets: int = 60
@export var add_period: float = 0.16                        # seconds between contributions

var _t: float = 0.0
var _peers: Array = []           # {marker:MeshInstance3D, ang:float}
var _packets: Array = []         # {mesh:MeshInstance3D, from:Vector3, to:Vector3, life:float}
var _facets: MultiMeshInstance3D # the accreting shared artifact (one MultiMesh)
var _placed: int = 0
var _edits: int = 0
var _contributors: int = 0
var _seen_peers: Array = []      # which peer indices have contributed this version
var _readout: Label3D
var _accum: float = 0.0
var _origin := Vector3(0.0, 0.95, 0.0)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(true)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("peer_count"):
		peer_count = int(config["peer_count"])
	if config.has("max_facets"):
		max_facets = int(config["max_facets"])
	if config.has("add_period"):
		add_period = float(config["add_period"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _facet_field() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = max_facets
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mi.material_override = mat
	return mi


func _build() -> void:
	_peers = []
	_packets = []
	_placed = 0
	_edits = 0
	_contributors = 0
	_seen_peers = []
	_accum = 0.0

	# --- compact device body (~1 m) ---
	var body_mat: StandardMaterial3D = _matte_mat(slate, 0.85, 0.15)
	add_child(_box(Vector3(0.0, 0.4, 0.0), Vector3(1.0, 0.12, 0.7), body_mat))
	var post_mat: StandardMaterial3D = _steel_mat(Color(0.34, 0.36, 0.42))
	add_child(_cylinder(Vector3(0.0, 0.66, 0.0), 0.05, 0.5, post_mat))
	# rim ring where the peers sit
	add_child(_torus(_origin, 0.42, 0.006, _glow_mat(wire_purple, 1.0)))
	# a small pedestal under the shared artifact
	add_child(_cylinder(_origin + Vector3(0.0, -0.04, 0.0), 0.08, 0.04, _glow_mat(contrib_teal, 1.2)))

	# --- the accreting shared artifact (one MultiMesh) ---
	_facets = _facet_field()
	add_child(_facets)
	_reset_artifact()

	# --- peer-nodes around the rim ---
	var pi: int = 0
	while pi < peer_count:
		var ang: float = float(pi) / float(peer_count) * TAU
		var ppos: Vector3 = _origin + Vector3(cos(ang) * 0.42, 0.0, sin(ang) * 0.42)
		var marker: MeshInstance3D = _sphere(ppos, 0.03, _glow_mat(cool_white, 1.2))
		add_child(marker)
		_peers.append({"marker": marker, "ang": ang})
		_seen_peers.append(false)
		pi += 1

	# --- readout ---
	_readout = _billboard_label("PEER PRODUCTION\nEDITS: 0  CONTRIBUTORS: 0", _origin + Vector3(0.0, 0.85, 0.0), 22, contrib_teal)
	add_child(_readout)
	add_child(_billboard_label("the many over the one", _origin + Vector3(0.0, 0.62, 0.0), 14, wire_purple))


func _reset_artifact() -> void:
	_placed = 0
	var i: int = 0
	while i < _seen_peers.size():
		_seen_peers[i] = false
		i += 1
	var mm: MultiMesh = _facets.multimesh
	var k: int = 0
	while k < mm.instance_count:
		mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)), _origin))
		mm.set_instance_color(k, Color(0, 0, 0, 0))
		k += 1


func _place_facet(peer_idx: int) -> void:
	if _placed >= max_facets:
		return
	var mm: MultiMesh = _facets.multimesh
	# accrete upward in a loose helix — pieces from all sides piling into one shared whole
	var layer: int = _placed
	var ang: float = float(layer) * 2.399963
	var rad: float = 0.07 * (1.0 - float(layer) / float(max_facets) * 0.5)
	var y: float = 0.02 + float(layer) * (0.34 / float(max_facets))
	var pos: Vector3 = _origin + Vector3(cos(ang) * rad, y, sin(ang) * rad)
	var s: float = 0.05
	mm.set_instance_transform(_placed, Transform3D(Basis().rotated(Vector3.UP, ang).scaled(Vector3(s, s * 0.6, s)), pos))
	# colour: cool purple base shading toward the warm teal accent as it accretes
	var f: float = float(_placed) / float(max_facets)
	mm.set_instance_color(_placed, wire_purple.lerp(contrib_teal, f))
	_placed += 1
	_edits += 1
	# count distinct contributors this version
	if peer_idx >= 0 and peer_idx < _seen_peers.size() and not bool(_seen_peers[peer_idx]):
		_seen_peers[peer_idx] = true
		_contributors += 1


func _spawn_packet(from: Vector3) -> void:
	var pkt: MeshInstance3D = _sphere(from, 0.018, _glow_mat(contrib_teal, 2.2))
	add_child(pkt)
	_packets.append({"mesh": pkt, "from": from, "to": _origin + Vector3(0.0, 0.02 + float(_placed) * (0.34 / float(max_facets)), 0.0), "life": 0.0})


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# gentle device idle
	if is_instance_valid(_facets):
		_facets.rotation.y = sin(_t * 0.3) * 0.06

	# --- on a timer, a random peer fires a contribution packet inward ---
	_accum += delta
	if _accum >= add_period:
		_accum = 0.0
		if _placed >= max_facets:
			_reset_artifact()
		elif _peers.size() > 0:
			var idx: int = _rng.randi() % _peers.size()
			var peer: Dictionary = _peers[idx]
			var mk: MeshInstance3D = peer["marker"]
			if is_instance_valid(mk):
				_spawn_packet(mk.position)
				# flash the contributing peer
				var pm: StandardMaterial3D = mk.material_override as StandardMaterial3D
				if pm != null:
					pm.emission_energy_multiplier = 3.0 if emissive else 0.4
			# stash which peer this packet belongs to on the last packet
			if _packets.size() > 0:
				(_packets[_packets.size() - 1] as Dictionary)["peer"] = idx

	# --- advance packets; when they land, accrete a facet + bump the readout ---
	var i: int = _packets.size() - 1
	while i >= 0:
		var pk: Dictionary = _packets[i]
		pk["life"] = float(pk["life"]) + delta * 4.0
		var life: float = float(pk["life"])
		var m: MeshInstance3D = pk["mesh"]
		if life >= 1.0:
			var who: int = int(pk.get("peer", -1))
			_place_facet(who)
			if is_instance_valid(m):
				m.queue_free()
			_packets.remove_at(i)
			if _readout != null:
				_readout.text = "PEER PRODUCTION\nEDITS: %d  CONTRIBUTORS: %d" % [_edits, _contributors]
		else:
			if is_instance_valid(m):
				m.position = (Vector3(pk["from"])).lerp(Vector3(pk["to"]), life)
		i -= 1

	# cool the peer markers back down between contributions
	var p: int = 0
	while p < _peers.size():
		var peer2: Dictionary = _peers[p]
		var mk2: MeshInstance3D = peer2["marker"]
		if is_instance_valid(mk2):
			var pm2: StandardMaterial3D = mk2.material_override as StandardMaterial3D
			if pm2 != null:
				var target: float = 1.2 if emissive else 0.0
				pm2.emission_energy_multiplier = lerpf(pm2.emission_energy_multiplier, target, delta * 4.0)
		p += 1
