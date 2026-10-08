extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PeerProductionTool

## @identity
## name: Peer Production Tool — What Survives the Arrival?
## concept: contributions, provenance and revision
## essence: generated peers send packets into an authored helix; source identity
##   survives landing. The visitor can inspect, dispute and revise one existing piece.
## truth: participation counts and a coherent shape do not establish knowledge.
## This is an automated geometric model, not a networked collaborative editor.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var contrib_teal: Color = Color(0.35, 0.88, 0.80)   # warm constructive accent
@export var peer_count: int = 12
@export var max_facets: int = 60
@export var interactive: bool = false
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
var _owned: Array[Node] = []
var _records: Array[Dictionary] = []
var _ever_seen: Dictionary = {}
var _version_sources: int = 0
var _version: int = 1
var _revisions: int = 0
var _last_version: Array[Dictionary] = [] # one bounded previous version, not a saved archive
var _paused: bool = false
var _show_sources: bool = false
var _selected: int = -1
var _controls: Node3D
var _detail: Label3D
var _trace: Node3D
var _marks: Node3D



func _ready() -> void:
	_rng.randomize()
	_rebuild()
	set_process(true)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = str(config["emissive"]).to_lower() in ["true", "1"]
	if config.has("interactive"):
		interactive = str(config["interactive"]).to_lower() in ["true", "1"]
	if config.has("peer_count"):
		peer_count = clampi(int(config["peer_count"]), 1, 24)
	if config.has("max_facets"):
		max_facets = clampi(int(config["max_facets"]), 1, 120)
	if config.has("add_period"):
		add_period = clampf(float(config["add_period"]), .08, 10.0)
	if is_node_ready():
		_rebuild()


func _rebuild() -> void:
	for child in _owned:
		if is_instance_valid(child):
			remove_child(child)
			child.queue_free()
	_owned.clear()
	var external: Array[Node] = get_children()
	_controls = null
	_detail = null
	_trace = null
	_marks = null
	_build()
	for child in get_children():
		if child not in external:
			_owned.append(child)


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
	mat.emission_enabled = not interactive and emissive
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if interactive else BaseMaterial3D.SHADING_MODE_PER_PIXEL
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
	_t = 0.0
	_records.clear()
	_ever_seen.clear()
	_version_sources = 0
	_version = 1
	_revisions = 0
	_last_version.clear()
	_paused = false
	_show_sources = false
	_selected = -1

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
	_clear_form()

	# --- peer-nodes around the rim ---
	var pi: int = 0
	while pi < peer_count:
		var ang: float = float(pi) / float(peer_count) * TAU
		var ppos: Vector3 = _origin + Vector3(cos(ang), 0.0, sin(ang)) * (.85 if interactive else .42)
		var marker: MeshInstance3D = _sphere(ppos, 0.03, _glow_mat(_source_colour(pi), 1.2))
		add_child(marker)
		_peers.append({"marker": marker, "ang": ang})
		_seen_peers.append(false)
		if interactive:
			var nameplate := _fixed_label("P%d" % (pi+1), ppos+Vector3(0,.09,0), 28, .0018)
			add_child(nameplate)
		pi += 1

	# Dynamic labels avoid an ever-growing baked texture cache.
	_readout = _fixed_label("", Vector3(-1.25,1.4,.2), 30, .0016)
	add_child(_readout)
	if interactive:
		_build_workbench()
	else:
		_readout.position = _origin+Vector3(0,.85,0)
	_update_readout()


func _clear_form() -> void:
	# Finish neither old packets nor old disputes in a new version.
	for packet in _packets:
		var mesh: Node = packet.mesh
		if is_instance_valid(mesh):
			mesh.queue_free()
	_packets.clear()
	_placed = 0
	_selected = -1
	_version_sources = 0
	_records.clear()
	_seen_peers.fill(false)
	_accum = 0.0
	_facets.multimesh.visible_instance_count = 0


func _reset_artifact() -> void:
	_last_version = _records.duplicate(true)
	_version += 1
	_clear_form()
	_refresh_marks()
	_update_readout()


func _source_colour(peer: int) -> Color:
	return Color.from_hsv(float(peer) / float(maxi(peer_count,1)), .65, .95)


func _fixed_label(text: String, pos: Vector3, font: int, pixel: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = font
	label.pixel_size = pixel
	label.modulate = cool_white
	label.outline_size = 4
	label.no_depth_test = false
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return label


func _place_facet(peer_idx: int) -> void:
	if _placed >= max_facets or peer_idx < 0 or peer_idx >= peer_count:
		return
	var mm: MultiMesh = _facets.multimesh
	# accrete upward in a loose helix — pieces from all sides piling into one shared whole
	var layer: int = _placed
	var ang: float = float(layer) * 2.399963
	var rad: float = (.22 if interactive else .07) * (1.0 - float(layer) / float(max_facets) * 0.5)
	var y: float = 0.02 + float(layer) * ((1.0 if interactive else .34) / float(max_facets))
	var pos: Vector3 = _origin + Vector3(cos(ang) * rad, y, sin(ang) * rad)
	var s: float = .19 if interactive else .05
	var pose := Transform3D(Basis().rotated(Vector3.UP, ang).scaled(Vector3(s, s * 0.6, s)), pos)
	mm.set_instance_transform(_placed, pose)
	_records.append({"source":peer_idx,"original":pose,"previous":pose,"current":pose,"disputed":false,"revision":0,"revised_by":""})
	# colour: cool purple base shading toward the warm teal accent as it accretes
	var f: float = float(_placed) / float(max_facets)
	mm.set_instance_color(_placed, _source_colour(peer_idx) if _show_sources else wire_purple.lerp(contrib_teal, f))
	_placed += 1
	_edits += 1
	# count distinct contributors this version
	if peer_idx >= 0 and peer_idx < _seen_peers.size() and not bool(_seen_peers[peer_idx]):
		_seen_peers[peer_idx] = true
		_contributors += 1
		_version_sources += 1
	_ever_seen[peer_idx] = true
	mm.visible_instance_count = _placed
	if _selected < 0:
		_selected = 0
	_update_readout()
	_refresh_marks()


func _spawn_packet(from: Vector3, peer_idx: int) -> void:
	var pkt: MeshInstance3D = _sphere(from, 0.018, _glow_mat(_source_colour(peer_idx), 1.0))
	add_child(pkt)
	_packets.append({"mesh": pkt, "from": from, "to": _origin + Vector3(0.0, 0.02 + float(_placed) * ((1.0 if interactive else .34) / float(max_facets)), 0.0), "life": 0.0, "peer":peer_idx})


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _paused:
		return
	_t += delta

	# gentle device idle
	if is_instance_valid(_facets) and not interactive:
		_facets.rotation.y = sin(_t * 0.3) * 0.06

	# --- on a timer, a random peer fires a contribution packet inward ---
	_accum += delta
	if _accum >= add_period:
		_accum = 0.0
		if _placed >= max_facets:
			if interactive:
				_paused = true
				_update_readout()
			else:
				_reset_artifact()
		elif _peers.size() > 0:
			var idx: int = _rng.randi() % _peers.size()
			var peer: Dictionary = _peers[idx]
			var mk: MeshInstance3D = peer["marker"]
			if is_instance_valid(mk):
				_spawn_packet(mk.position, idx)
				# flash the contributing peer
				var pm: StandardMaterial3D = mk.material_override as StandardMaterial3D
				if pm != null:
					pm.emission_energy_multiplier = 3.0 if emissive else 0.4

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


func _build_workbench() -> void:
	# A floor-standing table; small legacy placements retain their old geometry.
	var mat := _matte_mat(slate)
	add_child(_cylinder(Vector3(0,.85,0),.98,.09,mat))
	add_child(_cylinder(Vector3(0,.41,0),.15,.82,mat))
	add_child(_torus(_origin,.85,.008,_glow_mat(wire_purple,.2)))
	for x in [-1.25,1.25]:
		add_child(_box(Vector3(x,1.4,.17),Vector3(1.02,.62,.045),mat))
		add_child(_cylinder(Vector3(x,.55,.16),.055,1.1,mat))
	_detail = _fixed_label("",Vector3(1.25,1.4,.2),30,.0016)
	add_child(_detail)
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_controls = rack.create_panel("COMMON WORK",[
		[{"type":"button","label":"FLOW"},{"type":"button","label":"COLOUR"},{"type":"button","label":"PIECE"}],
		[{"type":"button","label":"DISPUTE"},{"type":"button","label":"REVISE"},{"type":"button","label":"VERSION"}]
	])
	_controls.position = Vector3(0,1.02,1.12)
	_controls.rotation_degrees.x = -25
	_controls.scale = Vector3.ONE*1.6
	add_child(_controls)
	add_child(_cylinder(Vector3(0,.5,1.02),.085,1.0,mat))
	for i in range(6):
		_controls.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.connect(_operate.bind(i))
	_trace = Node3D.new()
	add_child(_trace)
	_marks = Node3D.new()
	add_child(_marks)


func _operate(_body: Variant, choice: int) -> void:
	match choice:
		0: _paused = not _paused
		1:
			_show_sources = not _show_sources
			for i in range(_placed):
				_facets.multimesh.set_instance_color(i, _source_colour(int(_records[i].source)) if _show_sources else wire_purple.lerp(contrib_teal,float(i)/float(max_facets)))
		2:
			_paused = true
			if _placed > 0: _selected = (_selected+1)%_placed
		3:
			_paused = true
			if _selected >= 0:
				_records[_selected].disputed = not bool(_records[_selected].disputed)
		4:
			_paused = true
			if _selected >= 0:
				var record: Dictionary = _records[_selected]
				record.previous = record.current
				record.revision = int(record.revision)+1
				record.revised_by = "VISITOR"
				var pose: Transform3D = record.original
				pose.basis = pose.basis.rotated(Vector3.UP, float(record.revision)*PI/6.0).scaled(Vector3(1,1.5 if int(record.revision)%2 else 1.0,1))
				record.current = pose
				_facets.multimesh.set_instance_transform(_selected,pose)
				_revisions += 1
		5:
			_reset_artifact()
			_paused = true
	_refresh_marks()
	_update_readout()


func _refresh_marks() -> void:
	if not is_instance_valid(_marks): return
	for holder in [_marks,_trace]:
		for child in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for i in range(_placed):
		if i != _selected and not bool(_records[i].disputed): continue
		var record: Dictionary = _records[i]
		var pose: Transform3D = record.current
		var colour := Color(1,.3,.25) if bool(record.disputed) else Color.WHITE
		for axis in range(3):
			for a in [-.56,.56]:
				for b in [-.56,.56]:
					var start := Vector3.ZERO
					start[axis] = -.56
					start[(axis+1)%3] = a
					start[(axis+2)%3] = b
					var end := start
					end[axis] = .56
					start = pose * start
					end = pose * end
					transforms.append(Transform3D(_basis_y_to(end-start) * Basis.from_scale(Vector3(.004,start.distance_to(end),.004)),(start+end)*.5))
					colours.append(colour)
		if i == _selected:
			var peer: int = record.source
			_trace.add_child(_cylinder_between(pose.origin,_peers[peer].marker.position,.006,_glow_mat(_source_colour(peer),.2)))
	if transforms.is_empty(): return
	# One draw call for every disputed/selected frame, bounded by max_facets.
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.0
	cylinder.bottom_radius = 1.0
	cylinder.height = 1.0
	cylinder.radial_segments = 6
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = cylinder
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i,transforms[i])
		mm.set_instance_color(i,colours[i])
	var frame := MultiMeshInstance3D.new()
	frame.multimesh = mm
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	frame.material_override = material
	_marks.add_child(frame)


func _update_readout() -> void:
	if not is_instance_valid(_readout): return
	_readout.text = "VERSION %d | PIECES %d/%d\nSOURCES %d/%d | EVER %d\nADDITIONS %d\nPARTICIPATIONS %d | REVISIONS %d\n%s | COLOUR: %s" % [
		_version,_placed,max_facets,_version_sources,peer_count,_ever_seen.size(),_edits,_contributors,_revisions,
		"HELD" if _paused else "FLOWING","SOURCE" if _show_sources else "ORDER"]
	if is_instance_valid(_detail):
		if _selected < 0:
			_detail.text = "NO PIECE SELECTED\nFLOW to receive arrivals\nPIECE holds and selects\nLast version: %d pieces" % _last_version.size()
		else:
			var r: Dictionary = _records[_selected]
			_detail.text = "PIECE %d | SOURCE P%d\n%s | REVISION %d\n%s\n%s" % [
				_selected+1,int(r.source)+1,"DISPUTED" if bool(r.disputed) else "UNMARKED",int(r.revision),
				"Revised by VISITOR" if int(r.revision)>0 else "Arrival accepted automatically",
				"SOURCE KEPT / POSE CHANGED" if int(r.revision)>0 else "SOURCE KEPT / ORIGINAL POSE"]
