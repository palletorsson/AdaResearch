extends Node3D
class_name LeadSafetyDoor

# @identity
# essence: a heavy lead-lined radiation safety door — lab / restricted-access vocabulary for "the room behind this is not for everybody, and the wall has been thickened on purpose". A WHITE door slab, unusually THICK because it is shielding (lead, not just steel), set into a near-black charcoal frame that grips it on every edge; a column of warnings runs down the white face top-to-bottom — a yellow ATTENTION triangle, a yellow HAZARD pictogram naming the danger, a black EMPLOYEES ONLY plate; a horizontal lever handle waits on the LEFT, hinges line the RIGHT. The lab's standing confession that some knowledge is kept behind shielding, and the door is the membrane that decides who crosses.
# desire: every shielded room wants its threshold to be UNMISTAKABLE — a single architectural object that says "stop, read, this is a controlled boundary, the room behind me is dangerous and restricted". The door wants to read as a THICK NO that is also a legible one: not a blank wall, but a wall that explains itself in pictograms before it refuses you. Its whole posture is GATEKEEPING-with-a-warning — the thickness is the threat, the signage is the courtesy.
# critical_parameter: hazard_type — the danger the door shields against, which swaps the central pictogram and so re-poses the WHOLE door: "radiation" (the trefoil, the reference — an X-ray suite, an isotope store) / "biohazard" (three interlocking arcs — a containment lab, living danger) / "electrical" (a lightning bolt — a high-voltage room, instant death by current) / "none" (no hazard sign — merely restricted, secret not lethal). Same white slab, four utterly different forbidden rooms: the pictogram is the door's declaration of what KIND of harm waits behind it.
# triggers: _ready() builds the charcoal frame + thick white slab (closed, or pivoted ~90° on its hinge edge) + the ATTENTION sign + the hazard pictogram selected by hazard_type + the EMPLOYEES ONLY plate + the side lever handle + the opposite-edge hinges, all from exports; apply_grid_config rebuilds
# emerges: hazard_type="radiation" + door_open=false = "the reference, the sealed X-ray suite, the trefoil keeping watch"; hazard_type="biohazard" = "a containment lab, the danger is alive"; hazard_type="electrical" = "a substation room, the danger is instantaneous"; hazard_type="none" = "restricted but not lethal — a secret, not a hazard"; door_open=true = "someone authorized has crossed, the thick NO is briefly a YES". The hazard_type + door_open combination tells the player WHAT is forbidden and WHETHER the boundary is currently holding.
# needs: a near-black charcoal frame slightly larger than the slab, gripping every edge [present]; a THICK white shielding slab (lead-deep in Z) set into the frame [present]; a yellow ATTENTION triangle sign high on the face [present]; a yellow hazard pictogram mid-face, swapped by hazard_type [present]; a black EMPLOYEES ONLY plate with white Label3D text low on the face [present]; a horizontal lever handle on the LEFT at mid-height [present]; visible hinges down the RIGHT edge [present]; door BOTTOM at y=0, centred in X/Z, white face toward +Z [present]; optional ~90° swing about the hinge (right) edge when door_open [present]
# relationships: sibling to electrical_panel (both make an invisible hazard decidable at a threshold — the panel says "this circuit is the danger, switch it by hand", the door says "the whole room is the danger, cross it only if cleared"); cousin to fire_hose_box (both are wall-mounted pre-commitments that explain themselves in signage before they act, both posture as readiness/refusal rather than neutral surface); peer to the warning placard and the dosimeter rack (a shielded door with no dosimeter station beside it is half a protocol — restricted-access hardware presumes its companions along the same threshold)
# truth: a lead safety door is not just a thick white slab. It is the lab's MEMBRANE OF CONSEQUENCE — the precise line where ordinary corridor ends and controlled hazard begins, thickened with lead so the danger cannot leak out and stamped with pictograms so the danger cannot be entered by mistake. The hazard_type is the door's whole argument: it tells you, before you touch the handle, exactly which way the room behind it would harm you. The door makes the boundary auditable, and auditability is the only honest form a forbidden room can take.

## A heavy lead-lined radiation safety door.
##
## Built procedurally from DNA exports. Origin is at the door's BOTTOM,
## centred in X and Z — the door bottom sits at y=0, the white front face
## looks toward +Z, the charcoal frame surrounds it. The lever handle is on
## handle_side (default left); hinges run down the OPPOSITE edge. When
## door_open=true the slab (and all its signage) pivots ~90° about that
## hinge vertical edge so the room behind is exposed.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var door_width: float = 0.9
@export var door_height: float = 2.0
@export var door_thickness: float = 0.12

@export_group("Color")
@export var frame_color: Color = Color(0.12, 0.12, 0.14)
@export var door_color: Color = Color(0.90, 0.91, 0.92)
@export var handle_color: Color = Color(0.62, 0.64, 0.67)
@export var hazard_color: Color = Color(0.98, 0.82, 0.10)

@export_group("Hazard")
@export var hazard_type: String = "radiation"   # "radiation" | "biohazard" | "electrical" | "none"
@export var show_attention_sign: bool = true

@export_group("Signage")
@export var restricted_text: String = "EMPLOYEES ONLY"

@export_group("Door")
@export var handle_side: String = "left"        # "left" | "right" (hinges go on the opposite edge)
@export var door_open: bool = false

# ── External helpers ──────────────────────────────────────────────────

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# ── Constants ─────────────────────────────────────────────────────────

const FRAME_MARGIN: float = 0.045       # how far the frame extends beyond the slab (x/y)
const FRAME_DEPTH_EXTRA: float = 0.06   # how much deeper the frame is than the slab (sits BEHIND)
const SLAB_PROUD: float = 0.015         # how far the white slab front stands proud of the frame front
const SIGN_PROUD: float = 0.006         # how far signage sits proud of the white face
const SIGN_PLATE_DEPTH: float = 0.006   # thickness of a sign plate
const ICON_DEPTH: float = 0.004         # thickness of dark icon meshes on a plate
const DOOR_OPEN_DEG: float = 90.0       # how far the door swings when open

const ATTENTION_SIZE: float = 0.30      # side of the yellow ATTENTION square plate
const HAZARD_SIZE: float = 0.34         # side of the yellow hazard pictogram plate
const PLATE_SIZE: Vector2 = Vector2(0.46, 0.13)  # black EMPLOYEES ONLY plate (w, h)

const LEVER_LENGTH: float = 0.20        # horizontal lever bar length
const LEVER_RADIUS: float = 0.016
const LEVER_STEM: float = 0.05          # how far the lever stands off the face
const HINGE_SIZE: Vector3 = Vector3(0.05, 0.10, 0.05)
const HINGE_COUNT: int = 3

const LABEL_PIXEL_SIZE: float = 0.0022
const LABEL_FONT_SIZE: int = 36
const ATTN_PIXEL_SIZE: float = 0.0018
const ATTN_FONT_SIZE: int = 28

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_door()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_door()


func _read_metadata_overrides() -> void:
	if has_meta("config_door_width"):
		door_width = float(str(get_meta("config_door_width")))
	if has_meta("config_door_height"):
		door_height = float(str(get_meta("config_door_height")))
	if has_meta("config_door_thickness"):
		door_thickness = float(str(get_meta("config_door_thickness")))
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_door_color"):
		door_color = _parse_color(str(get_meta("config_door_color")), door_color)
	if has_meta("config_handle_color"):
		handle_color = _parse_color(str(get_meta("config_handle_color")), handle_color)
	if has_meta("config_hazard_color"):
		hazard_color = _parse_color(str(get_meta("config_hazard_color")), hazard_color)
	if has_meta("config_hazard_type"):
		hazard_type = str(get_meta("config_hazard_type"))
	if has_meta("config_show_attention_sign"):
		var av := str(get_meta("config_show_attention_sign")).to_lower()
		show_attention_sign = av in ["true", "1", "yes", "on"]
	if has_meta("config_restricted_text"):
		restricted_text = str(get_meta("config_restricted_text"))
	if has_meta("config_handle_side"):
		handle_side = str(get_meta("config_handle_side")).to_lower()
	if has_meta("config_door_open"):
		var dv := str(get_meta("config_door_open")).to_lower()
		door_open = dv in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_door() -> void:
	_built = true
	_build_frame()
	_build_slab_and_signage()


func _front_z() -> float:
	# Front (white) face of the door slab in this Node's local space.
	return door_thickness * 0.5


func _hinge_on_right() -> bool:
	# Hinges sit on the edge OPPOSITE the handle. Default handle_side="left"
	# → hinges on the right (+X). Any non-"right" handle value keeps hinges right.
	return handle_side != "right"


func _build_frame() -> void:
	# Near-black charcoal jamb surrounding the slab, sitting BEHIND its front face.
	# A single box whose front is recessed SLAB_PROUD behind the white slab front, so
	# the white face is the frontmost (proud) surface — it stays fully lit and the
	# frame never casts a shadow across it. The frame reads as a slim dark border +
	# reveal around the edges (the right jamb is the dark hinge edge at angle). The
	# frame is the fixed jamb; it does NOT swing with the door.
	var root := Node3D.new()
	root.name = "Frame"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.55
	mat.metallic = 0.35

	var fw: float = door_width + FRAME_MARGIN * 2.0
	var fh: float = door_height + FRAME_MARGIN * 2.0
	var fd: float = door_thickness + FRAME_DEPTH_EXTRA
	var cy: float = door_height * 0.5             # frame vertical centre (door bottom at y=0)
	var frame_front: float = _front_z() - SLAB_PROUD   # front recessed behind the white slab

	var back := MeshInstance3D.new()
	back.name = "FrameJamb"
	var bm := BoxMesh.new()
	bm.size = Vector3(fw, fh, fd)
	back.mesh = bm
	back.material_override = mat
	back.position = Vector3(0.0, cy, frame_front - fd * 0.5)
	root.add_child(back)


func _build_slab_and_signage() -> void:
	# The thick white slab plus everything mounted on it (signage, handle, hinges)
	# lives under a single pivot placed on the hinge vertical edge, so door_open
	# rotates the slab and all its furniture together about that edge.
	var pivot := Node3D.new()
	pivot.name = "DoorPivot"
	add_child(pivot)

	var hinge_right: bool = _hinge_on_right()
	var hinge_x: float = (door_width * 0.5) if hinge_right else (-door_width * 0.5)
	# Pivot at the hinge edge, at the slab's mid-depth, door-bottom at y=0.
	pivot.position = Vector3(hinge_x, 0.0, 0.0)
	if door_open:
		# Right-edge hinge swings inward toward -Z by rotating -deg about +Y;
		# left-edge hinge mirrors. Either way the slab opens away from +Z.
		var dir: float = -1.0 if hinge_right else 1.0
		pivot.rotation = Vector3(0.0, deg_to_rad(DOOR_OPEN_DEG * dir), 0.0)

	# Slab centre x in pivot space: the slab spans from the hinge edge inward.
	var slab_cx: float = -door_width * 0.5 if hinge_right else door_width * 0.5

	_build_slab(pivot, slab_cx)
	_build_attention_sign(pivot, slab_cx)
	_build_hazard_sign(pivot, slab_cx)
	_build_restricted_plate(pivot, slab_cx)
	_build_handle(pivot, slab_cx, hinge_right)
	_build_hinges(pivot)


func _build_slab(pivot: Node3D, slab_cx: float) -> void:
	# Thick white shielding slab. Bottom at y=0 → centre at door_height/2.
	var slab := MeshInstance3D.new()
	slab.name = "Slab"
	var dm := BoxMesh.new()
	dm.size = Vector3(door_width, door_height, door_thickness)
	slab.mesh = dm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = door_color
	mat.roughness = 0.6
	mat.metallic = 0.1
	slab.material_override = mat
	slab.position = Vector3(slab_cx, door_height * 0.5, 0.0)
	pivot.add_child(slab)


func _yellow_plate(name_str: String, side: float, cx: float, cy: float) -> MeshInstance3D:
	# A yellow square sign plate proud of the white face, centred at (cx, cy).
	var plate := MeshInstance3D.new()
	plate.name = name_str
	var pm := BoxMesh.new()
	pm.size = Vector3(side, side, SIGN_PLATE_DEPTH)
	plate.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = hazard_color
	mat.roughness = 0.45
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = hazard_color
	mat.emission_energy_multiplier = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	plate.mesh = pm
	plate.material_override = mat
	plate.position = Vector3(cx, cy, _front_z() + SIGN_PROUD + SIGN_PLATE_DEPTH * 0.5)
	return plate


func _dark_material() -> StandardMaterial3D:
	# Dark ink for icons drawn on yellow plates.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.07, 0.08)
	mat.roughness = 0.6
	mat.metallic = 0.0
	return mat


func _icon_z() -> float:
	# Z of dark icons: just proud of the yellow plate front.
	return _front_z() + SIGN_PROUD + SIGN_PLATE_DEPTH + ICON_DEPTH * 0.5


func _build_attention_sign(pivot: Node3D, slab_cx: float) -> void:
	# Yellow square + dark triangle outline + "!" + ATTENTION caption, high on the face.
	if not show_attention_sign:
		return
	var root := Node3D.new()
	root.name = "AttentionSign"
	pivot.add_child(root)

	var cy: float = door_height - 0.42        # high on the slab
	var plate := _yellow_plate("AttentionPlate", ATTENTION_SIZE, slab_cx, cy)
	root.add_child(plate)

	var ink := _dark_material()
	var iz: float = _icon_z()
	# Dark triangle outline as 3 thin bars (apex up). Triangle spans within the plate,
	# sitting in the upper portion to leave room for the ATTENTION caption below.
	var tri_side: float = ATTENTION_SIZE * 0.62
	var tri_cy: float = cy + ATTENTION_SIZE * 0.08
	var bar_t: float = 0.018
	var h: float = tri_side * 0.866             # triangle height
	# Bottom bar.
	var b_bot := MeshInstance3D.new()
	b_bot.name = "TriBottom"
	var bm := BoxMesh.new()
	bm.size = Vector3(tri_side, bar_t, ICON_DEPTH)
	b_bot.mesh = bm
	b_bot.material_override = ink
	b_bot.position = Vector3(slab_cx, tri_cy - h * 0.5, iz)
	root.add_child(b_bot)
	# Two slanted sides meeting at the apex.
	for sx in [1.0, -1.0]:
		var side_bar := MeshInstance3D.new()
		side_bar.name = "TriSide_%d" % int(sx)
		var sm := BoxMesh.new()
		sm.size = Vector3(bar_t, h, ICON_DEPTH)
		side_bar.mesh = sm
		side_bar.material_override = ink
		# Centre of each slanted side, tilted so they meet at the top apex.
		side_bar.position = Vector3(slab_cx - sx * tri_side * 0.25, tri_cy, iz)
		side_bar.rotation = Vector3(0.0, 0.0, deg_to_rad(sx * 30.0))
		root.add_child(side_bar)
	# Exclamation mark inside the triangle: a short vertical bar + a dot.
	var ex_bar := MeshInstance3D.new()
	ex_bar.name = "ExclaimBar"
	var em := BoxMesh.new()
	em.size = Vector3(bar_t * 0.9, h * 0.38, ICON_DEPTH)
	ex_bar.mesh = em
	ex_bar.material_override = ink
	ex_bar.position = Vector3(slab_cx, tri_cy + h * 0.02, iz)
	root.add_child(ex_bar)
	var ex_dot := MeshInstance3D.new()
	ex_dot.name = "ExclaimDot"
	var cm := CylinderMesh.new()
	cm.top_radius = bar_t * 0.6
	cm.bottom_radius = bar_t * 0.6
	cm.height = ICON_DEPTH
	ex_dot.mesh = cm
	ex_dot.material_override = ink
	ex_dot.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	ex_dot.position = Vector3(slab_cx, tri_cy - h * 0.26, iz)
	root.add_child(ex_dot)
	# ATTENTION caption baked onto the plate — paint on the surface, not a floating
	# Label3D (the fire_extinguisher principle, via BakedText.make_label_mesh).
	var cap := BakedText.make_label_mesh(
		"ATTENTION", Color(0.07, 0.07, 0.08),
		Vector2(ATTENTION_SIZE * 0.84, ATTENTION_SIZE * 0.17))
	if cap:
		cap.name = "AttentionCaption"
		cap.position = Vector3(slab_cx, cy - ATTENTION_SIZE * 0.34, iz)
		root.add_child(cap)


func _build_hazard_sign(pivot: Node3D, slab_cx: float) -> void:
	# Yellow plate + a dark pictogram selected by hazard_type, mid-face.
	if hazard_type == "none":
		return
	var root := Node3D.new()
	root.name = "HazardSign"
	pivot.add_child(root)

	var cy: float = door_height * 0.5         # mid-face
	var plate := _yellow_plate("HazardPlate", HAZARD_SIZE, slab_cx, cy)
	root.add_child(plate)

	match hazard_type:
		"radiation":
			_build_trefoil(root, slab_cx, cy)
		"biohazard":
			_build_biohazard(root, slab_cx, cy)
		"electrical":
			_build_lightning(root, slab_cx, cy)
		_:
			# Unknown hazard string → fall back to the radiation trefoil.
			_build_trefoil(root, slab_cx, cy)


func _build_trefoil(root: Node3D, cx: float, cy: float) -> void:
	# Classic radiation trefoil: dark centre disc + three 60°-wide blades at 120°.
	var ink := _dark_material()
	var iz: float = _icon_z()
	# Centre disc.
	var hub := MeshInstance3D.new()
	hub.name = "TrefoilHub"
	var cm := CylinderMesh.new()
	cm.top_radius = HAZARD_SIZE * 0.07
	cm.bottom_radius = HAZARD_SIZE * 0.07
	cm.height = ICON_DEPTH
	hub.mesh = cm
	hub.material_override = ink
	hub.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	hub.position = Vector3(cx, cy, iz)
	root.add_child(hub)
	# Three blades — each a flat PrismMesh wedge pointing outward, at 0/120/240°.
	var blade_r: float = HAZARD_SIZE * 0.30    # how far the blade reaches from centre
	var blade_w: float = HAZARD_SIZE * 0.30    # tangential width at the outer edge
	for k in range(3):
		var ang: float = deg_to_rad(90.0 + 120.0 * float(k))  # apex pointing up first
		var pivot := Node3D.new()
		pivot.name = "TrefoilBladePivot_%d" % k
		pivot.position = Vector3(cx, cy, iz)
		pivot.rotation = Vector3(0.0, 0.0, ang)
		root.add_child(pivot)
		var blade := MeshInstance3D.new()
		blade.name = "TrefoilBlade_%d" % k
		var pm := PrismMesh.new()
		# Prism: tip toward +Y (the narrow apex sits at the centre), base outward.
		pm.size = Vector3(blade_w, blade_r, ICON_DEPTH)
		blade.mesh = pm
		blade.material_override = ink
		# Apex of the prism is at the local origin direction; push the wide base outward.
		blade.position = Vector3(0.0, blade_r * 0.55, 0.0)
		blade.rotation = Vector3(0.0, 0.0, PI)   # flip so the wide base faces outward
		pivot.add_child(blade)


func _build_biohazard(root: Node3D, cx: float, cy: float) -> void:
	# Biohazard: dark centre + three partial rings (torus arcs approximated by full
	# thin tori) arranged at 120°, overlapping toward the centre.
	var ink := _dark_material()
	var iz: float = _icon_z()
	# Centre disc.
	var hub := MeshInstance3D.new()
	hub.name = "BioHub"
	var cm := CylinderMesh.new()
	cm.top_radius = HAZARD_SIZE * 0.06
	cm.bottom_radius = HAZARD_SIZE * 0.06
	cm.height = ICON_DEPTH
	hub.mesh = cm
	hub.material_override = ink
	hub.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	hub.position = Vector3(cx, cy, iz)
	root.add_child(hub)
	# Three interlocking rings, centres pushed out at 120° from the icon centre.
	var ring_r: float = HAZARD_SIZE * 0.13
	var offset: float = HAZARD_SIZE * 0.16
	for k in range(3):
		var ang: float = deg_to_rad(90.0 + 120.0 * float(k))
		var ring := MeshInstance3D.new()
		ring.name = "BioRing_%d" % k
		var tm := TorusMesh.new()
		tm.inner_radius = ring_r - ICON_DEPTH * 0.9
		tm.outer_radius = ring_r + ICON_DEPTH * 0.9
		tm.rings = 6
		tm.ring_segments = 18
		ring.mesh = tm
		ring.material_override = ink
		# TorusMesh lies in X/Z; rotate so its disc faces +Z.
		ring.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		ring.position = Vector3(cx + cos(ang) * offset, cy + sin(ang) * offset, iz)
		root.add_child(ring)


func _build_lightning(root: Node3D, cx: float, cy: float) -> void:
	# Electrical: a dark lightning-bolt zigzag from 3 thin angled boxes.
	var ink := _dark_material()
	var iz: float = _icon_z()
	var seg_len: float = HAZARD_SIZE * 0.34
	var seg_w: float = HAZARD_SIZE * 0.10
	# Three segments forming a Z/lightning shape, top to bottom.
	var defs := [
		{ "pos": Vector2(cx + HAZARD_SIZE * 0.05, cy + HAZARD_SIZE * 0.18), "ang": 28.0 },
		{ "pos": Vector2(cx - HAZARD_SIZE * 0.02, cy), "ang": -32.0 },
		{ "pos": Vector2(cx + HAZARD_SIZE * 0.01, cy - HAZARD_SIZE * 0.18), "ang": 28.0 },
	]
	for i in range(defs.size()):
		var d: Dictionary = defs[i]
		var seg := MeshInstance3D.new()
		seg.name = "BoltSeg_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(seg_w, seg_len, ICON_DEPTH)
		seg.mesh = bm
		seg.material_override = ink
		var p: Vector2 = d["pos"]
		seg.position = Vector3(p.x, p.y, iz)
		seg.rotation = Vector3(0.0, 0.0, deg_to_rad(float(d["ang"])))
		root.add_child(seg)


func _build_restricted_plate(pivot: Node3D, slab_cx: float) -> void:
	# Black plate with white restricted_text, low on the face.
	if restricted_text == "":
		return
	var root := Node3D.new()
	root.name = "RestrictedPlate"
	pivot.add_child(root)

	var cy: float = 0.42                       # low on the slab
	# Black plate + white text baked into ONE textured quad — a single printed patch
	# on the door (BakedText.make_panel_mesh), not a box with a floating Label3D.
	var plate := BakedText.make_panel_mesh(
		restricted_text, Color(0.05, 0.05, 0.06), Color(0.96, 0.96, 0.96),
		Vector2(PLATE_SIZE.x, PLATE_SIZE.y))
	if plate == null:
		return
	plate.name = "Plate"
	plate.position = Vector3(slab_cx, cy, _front_z() + SIGN_PROUD + SIGN_PLATE_DEPTH * 0.5)
	root.add_child(plate)


func _build_handle(pivot: Node3D, slab_cx: float, hinge_right: bool) -> void:
	# Horizontal metal lever bar on the side OPPOSITE the hinges, at mid-height.
	# Hinges right → handle left (-X side of the slab), and vice versa.
	var root := Node3D.new()
	root.name = "Handle"
	pivot.add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = handle_color
	mat.roughness = 0.3
	mat.metallic = 0.85

	# Handle edge x in pivot space (slab spans [slab_cx - w/2, slab_cx + w/2]).
	var edge_sign: float = -1.0 if hinge_right else 1.0
	var handle_x: float = slab_cx + edge_sign * (door_width * 0.5 - 0.10)
	var cy: float = door_height * 0.5         # mid-height
	var face_z: float = _front_z() + LEVER_STEM

	# A short stem standing off the white face, then a horizontal lever bar.
	var stem := MeshInstance3D.new()
	stem.name = "HandleStem"
	var sm := CylinderMesh.new()
	sm.top_radius = LEVER_RADIUS * 0.7
	sm.bottom_radius = LEVER_RADIUS * 0.7
	sm.height = LEVER_STEM
	stem.mesh = sm
	stem.material_override = mat
	# Cylinder default axis +Y; lay along +Z so it pokes out of the face.
	stem.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	stem.position = Vector3(handle_x, cy, _front_z() + LEVER_STEM * 0.5)
	root.add_child(stem)

	# Horizontal lever bar, pointing inward across the slab from the stem.
	var lever := MeshInstance3D.new()
	lever.name = "HandleLever"
	var lm := CylinderMesh.new()
	lm.top_radius = LEVER_RADIUS
	lm.bottom_radius = LEVER_RADIUS
	lm.height = LEVER_LENGTH
	lever.mesh = lm
	lever.material_override = mat
	# Cylinder default axis +Y; lay along X (horizontal).
	lever.rotation = Vector3(0.0, 0.0, PI * 0.5)
	# Bar extends from the stem toward the slab centre.
	lever.position = Vector3(handle_x - edge_sign * LEVER_LENGTH * 0.5, cy, face_z)
	root.add_child(lever)


func _build_hinges(pivot: Node3D) -> void:
	# Visible dark hinges down the hinge vertical edge (the pivot axis, x=0 in
	# pivot space). Distributed along the door height.
	var root := Node3D.new()
	root.name = "Hinges"
	pivot.add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color.lightened(0.08)
	mat.roughness = 0.4
	mat.metallic = 0.8

	var top_y: float = door_height - 0.20
	var bot_y: float = 0.20
	var span: float = top_y - bot_y
	for i in range(HINGE_COUNT):
		var t: float = 0.5 if HINGE_COUNT <= 1 else float(i) / float(HINGE_COUNT - 1)
		var y: float = bot_y + span * t
		var hinge := MeshInstance3D.new()
		hinge.name = "Hinge_%d" % i
		var hm := BoxMesh.new()
		hm.size = HINGE_SIZE
		hinge.mesh = hm
		hinge.material_override = mat
		# Hinge sits at the pivot axis (x=0), proud of the front face.
		hinge.position = Vector3(0.0, y, _front_z() - HINGE_SIZE.z * 0.25)
		root.add_child(hinge)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
