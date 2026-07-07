extends Node3D
class_name TechCrate

# @identity
# essence: a sleek high-tech cargo container — military supply-crate vocabulary built into a single beveled-edge block: dark graphite metal body with all four front corners shaved, a sealed inset lid cap on top, armored reinforcement caps at the four vertical edges, one or two RECESSED front panels (pockets sunk into the face, framed by a thin raised border), a vent CUT INTO each pocket (an X of crossed slats, a circular fan grille, or horizontal louvers — always at the pocket's back plane, never proud), a scatter of small emissive orange/green LED dots along the lower edge, two latch tabs on the top front edge, and a recessed grip pocket on each side. It is the lab's confession that the equipment did not grow here — it was crated, shipped, and dropped in. But where the wooden crate smells of the supply chain, the tech crate smells of the FACTORY: machined, sealed, climate-controlled, serial-numbered. It is the room saying "this arrived in a hardened case".
# desire: every lab pretends its instruments are native to the bench. The tech crate breaks that pretence with the opposite tone from the wooden crate — not rustic transit but ENGINEERED CONTAINMENT. It wants to read as a thing that protected something fragile and expensive across a logistics network: the recessed panels and machined vents say "this surface was designed, not nailed"; the LEDs say "this case has power, a state, maybe a lock"; the beveled silhouette says "this corner was cut on purpose, to survive being stacked and dropped". Even sealed and at rest it implies a payload not yet revealed.
# critical_parameter: body_color + vent_style + bevel decide the whole register. body_color swings the tone between GRAPHITE-BLACK sci-fi hardware (dark, cold, expensive) and MILITARY-TAN field gear (sandy, rugged, expendable). vent_style swaps the machined-hardware read: an X-vent reads as a rugged crossed-slat cover, a fan-grille reads as ACTIVE COOLING (something inside runs warm), louvers read as passive ventilation. bevel sets how armored the silhouette is — a deep bevel reads as a drop-rated hardened case, a faint bevel as a plain sealed box. The RECESSED vents are what make it read as machined hardware rather than a painted wooden box.
# triggers: _ready() sweeps the beveled front silhouette into a single solid body mesh via MeshFactory.extrude_profile_z, then lays the inset lid cap + corner caps + recessed panel pockets + recessed vents + LEDs + latch tabs + side grips from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single tech crate reads as A RECENT, EXPENSIVE DELIVERY — the experiment runs on shipped-in hardware. A STACK reads as a FORWARD OPERATING LAB / DEPLOYMENT — the space is provisioned, not grown. Glowing LEDs read as POWERED / ARMED / SEALED; dark LEDs as DEPLETED / OPENED. A fan-grille vent reads as LIVE EQUIPMENT INSIDE; an X-vent or louvers as DORMANT STORAGE. The crate is a temporal-and-economic marker: instruments cost money, travel in hardened cases, and arrive from a manufacturer somewhere off-stage.
# needs: a single beveled-edge body mesh (all four front corners cut) [present]; a sealed inset lid cap on top [present]; armored reinforcement caps at the four vertical edges [present]; one-or-two RECESSED front panel pockets with raised border frames [present]; a vent CUT INTO each pocket at its back plane — X / fan-grille / louver [present]; small emissive orange/green LED accents along the front lower edge [present]; two latch tabs on the top front edge [present]; a recessed grip pocket on each ±X end face [present]
# relationships: peer to crate (both are OBJECTS-IN-TRANSIT, contents not yet unpacked — but the wooden crate is rustic supply-chain transit while the tech crate is engineered hardened containment); cousin to futuristic_fuse_box (both are MACHINED-METAL UTILITY MASSES with a graphite skin and a saturated accent that announces state before it is read); sibling to fire_extinguisher (both wear emissive/saturated accents tuned to be RECOGNISED BEFORE THEY ARE INTERPRETED).
# truth: the tech crate is the physical confession that the lab's instruments are bought, not born — that the most fragile and expensive parts of the experiment travelled here inside a hardened, sealed, machined case, protected by recessed panels and ventilated by engineered grilles. The bevel is not styling; it is the corner cut so the case survives the drop. The LEDs are not decoration; they are the case admitting it has a state. Every tech crate is a small monument to the engineering of containment — proof that what matters most is shipped in armour, and that the room is a node in a supply network of machined cases.

## A sleek high-tech / sci-fi cargo crate (military supply-crate vocabulary).
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of the
## crate (floor-stack friendly). Width runs along X, height along Y, depth
## along Z. The flat FRONT face is +Z (at z = crate_depth/2) — this is where
## the recessed panels + vents + LEDs live. The body is ONE beveled-edge mesh
## swept by MeshFactory (commons/artifacts/shared): the front silhouette has
## all four corners shaved at 45° so the block reads as an armored hardened
## case rather than a plain box.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var crate_width: float = 1.2
@export var crate_height: float = 0.55
@export var crate_depth: float = 0.6
## How much each of the four front corners is shaved at 45° — the armored bevel.
@export var bevel: float = 0.07

@export_group("Panels & Vents")
## Number of recessed panels on the front face (1 or 2).
@export var panel_count: int = 2
## Vent cut into each panel pocket: "x" (crossed slats), "fan" (circular
## grille), or "louver" (horizontal slats). Always recessed at the pocket back.
@export var vent_style: String = "x"

@export_group("Hardware")
## Small emissive LED dots along the front lower edge + latch tabs on top.
@export var show_leds: bool = true
## Recessed grip pocket on each ±X end face.
@export var show_handles: bool = true

@export_group("Material")
## Dark graphite metal body. Push toward tan (e.g. 0.55,0.48,0.34) for field gear.
@export var body_color: Color = Color(0.13, 0.14, 0.16)
## Darker recess-pocket metal (the sunk panel floor).
@export var panel_color: Color = Color(0.09, 0.10, 0.12)
## Sealed lid-cap metal on the top face.
@export var lid_color: Color = Color(0.10, 0.11, 0.13)
## Emissive accent — orange (0.95,0.5,0.1) or green (0.3,0.9,0.4) for LEDs/latches.
@export var accent_color: Color = Color(0.95, 0.50, 0.10)
## Apply the animated sci-fi ShaderMaterials (worn-metal body + rim glow,
## scrolling vent-panel scanline, pulsing LEDs). Off = flat StandardMaterial.
@export var use_shader: bool = false

# ── Constants ─────────────────────────────────────────────────────────

## The mesh factory that sweeps the beveled silhouette into a real solid.
const MF := preload("res://commons/artifacts/shared/mesh_factory.gd")
const METAL_SHADER := preload("res://commons/artifacts/tech_crate/tech_crate_metal.gdshader")
const PANEL_SHADER := preload("res://commons/artifacts/tech_crate/tech_crate_panel.gdshader")
const PULSE_SHADER := preload("res://commons/artifacts/tech_crate/tech_crate_pulse.gdshader")

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_crate_width"):
		crate_width = float(str(get_meta("config_crate_width")))
	if has_meta("config_crate_height"):
		crate_height = float(str(get_meta("config_crate_height")))
	if has_meta("config_crate_depth"):
		crate_depth = float(str(get_meta("config_crate_depth")))
	if has_meta("config_bevel"):
		bevel = float(str(get_meta("config_bevel")))
	if has_meta("config_panel_count"):
		panel_count = int(str(get_meta("config_panel_count")))
	if has_meta("config_vent_style"):
		vent_style = str(get_meta("config_vent_style")).to_lower()
	if has_meta("config_use_shader"):
		use_shader = str(get_meta("config_use_shader")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_show_leds"):
		var sl: String = str(get_meta("config_show_leds")).to_lower()
		show_leds = sl == "true" or sl == "1" or sl == "yes" or sl == "on"
	if has_meta("config_show_handles"):
		var sh: String = str(get_meta("config_show_handles")).to_lower()
		show_handles = sh == "true" or sh == "1" or sh == "yes" or sh == "on"
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"):
		panel_color = _parse_color(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_lid_color"):
		lid_color = _parse_color(str(get_meta("config_lid_color")), lid_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	var bv: float = clampf(bevel, 0.0, minf(crate_width, crate_height) * 0.45)
	var hw: float = crate_width * 0.5
	var hd: float = crate_depth * 0.5
	var front_z: float = hd                 # +Z face of the swept solid

	# ── 1. Body — ONE beveled-edge solid (MeshFactory) ───────────────
	# The front silhouette (all four corners cut at 45°) is swept along the
	# depth into a single solid. Front face is +Z at z = crate_depth/2.
	var outline := MF.bevel_rect_outline(crate_width, crate_height, bv)
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = MF.extrude_profile_z(outline, crate_depth)
	body.material_override = _metal_mat(body_color, 0.5, 0.6)
	# Swept solid lights via forced-outward normals — keep it solid from any side.
	if not use_shader:
		body.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	add_child(body)

	# ── 2. Sealed inset lid cap on the top face ──────────────────────
	_build_lid_cap(hw, hd, bv)

	# ── 3. Armored corner reinforcement caps at the four vertical edges
	_build_corner_caps(hw, hd, bv)

	# ── 4. Recessed front panel pockets (with vents cut into each) ───
	_build_front_panels(hw, front_z, bv)

	# ── 5. LED accents + latch tabs ──────────────────────────────────
	if show_leds:
		_build_leds(hw, front_z)
		_build_latch_tabs(hw, front_z)

	# ── 6. Recessed side grips ───────────────────────────────────────
	if show_handles:
		_build_side_grips(hw)


# A slightly-inset sealed box sitting on the TOP face — reads as a beveled lid.
func _build_lid_cap(hw: float, hd: float, bv: float) -> void:
	var lid := MeshInstance3D.new()
	lid.name = "LidCap"
	var lm := BoxMesh.new()
	var lid_h: float = 0.04
	# A touch smaller in X/Z than the body top so it reads as inset.
	lm.size = Vector3((crate_width - bv * 2.0) * 0.94,
		lid_h, (crate_depth - bv * 2.0) * 0.92)
	lid.mesh = lm
	# Faint emissive "solar" tint so the sealed lid catches the eye subtly.
	var lid_mat: Material
	if use_shader:
		lid_mat = _metal_mat(lid_color, 0.45, 0.65)
	else:
		var sm := _make_metal_mat(lid_color, 0.45, 0.65)
		sm.emission_enabled = true
		sm.emission = lid_color.lightened(0.25)
		sm.emission_energy = 0.12
		lid_mat = sm
	lid.material_override = lid_mat
	# Sit just above the body top edge (the bevel reaches crate_height - bv).
	lid.position = Vector3(0.0, crate_height - bv + lid_h * 0.35, 0.0)
	add_child(lid)


# Four short dark trim caps at the vertical edges — armored corners, a touch proud.
func _build_corner_caps(hw: float, hd: float, bv: float) -> void:
	var cap_mat: Material = _metal_mat(panel_color.lightened(0.04), 0.45, 0.7)
	var cap_w: float = maxf(0.05, bv * 1.4)
	var cap_h: float = crate_height - bv * 1.4
	var cap_d: float = 0.05
	var proud: float = 0.012
	# X inset so the cap straddles the bevelled corner; pushed slightly proud.
	var cx: float = hw - bv * 0.5
	var cz: float = hd - bv * 0.5
	for sx in [1.0, -1.0]:
		for sz in [1.0, -1.0]:
			var cap := MeshInstance3D.new()
			cap.name = "CornerCap"
			var cm := BoxMesh.new()
			cm.size = Vector3(cap_w, cap_h, cap_d)
			cap.mesh = cm
			cap.material_override = cap_mat
			cap.position = Vector3(sx * (cx + proud * 0.0),
				crate_height * 0.5, sz * (cz + proud))
			add_child(cap)
			# A short Z-running trim too, so the corner reads wrapped.
			var cap2 := MeshInstance3D.new()
			cap2.name = "CornerCapZ"
			var cm2 := BoxMesh.new()
			cm2.size = Vector3(cap_d, cap_h, cap_w)
			cap2.mesh = cm2
			cap2.material_override = cap_mat
			cap2.position = Vector3(sx * (cx + proud),
				crate_height * 0.5, sz * cz)
			add_child(cap2)


# Build panel_count RECESSED pockets on the +Z face. Each pocket is an inset
# darker box whose FRONT sits ~0.02 BEHIND the body front face, framed by a
# thin raised border (4 thin boxes flush with the body face). The vent is then
# CUT INTO the pocket at its back plane — see _build_vent_in_pocket.
func _build_front_panels(hw: float, front_z: float, bv: float) -> void:
	var count: int = clampi(panel_count, 1, 2)
	var usable_w: float = crate_width - bv * 2.0
	var panel_w: float = (usable_w / float(count)) * 0.74
	var panel_h: float = (crate_height - bv * 2.0) * 0.66
	var panel_y: float = crate_height * 0.52

	# A solid swept body can't hold a real CSG cavity, so the recess is read
	# RELATIVELY: a dark floor plate flush on the body face + a clearly raised
	# border frame around it + the vent nestled in the resulting well. The vent
	# sits just proud of the floor but well BELOW the border, so it reads as
	# machined detail down in the panel, not a beam floating on the surface.
	# LIGHT panel floor so the DARK recessed vent reads on it (matches the
	# reference: a dark X / grille shape sunk into a lit panel face). The
	# raised border is the dark body tone, framing the lit floor.
	var floor_mat: Material = _panel_mat(Color(0.26, 0.27, 0.30))
	var border_mat: Material = _metal_mat(body_color.lightened(0.04), 0.45, 0.65)
	var border_t: float = 0.022
	var vent_z: float = front_z + 0.003          # grille-bar centre plane

	for i in range(count):
		var cx: float = 0.0
		if count == 2:
			cx = -usable_w * 0.25 + usable_w * 0.5 * float(i)

		# Dark floor plate, front face ~flush with the body face (visible).
		var floor := MeshInstance3D.new()
		floor.name = "PanelFloor_%d" % i
		var fm := BoxMesh.new()
		fm.size = Vector3(panel_w, panel_h, 0.03)
		floor.mesh = fm
		floor.material_override = floor_mat
		floor.position = Vector3(cx, panel_y, front_z - 0.014)
		add_child(floor)

		# Raised border frame (stands proud → the floor reads sunk below it).
		var half_w: float = panel_w * 0.5
		var half_h: float = panel_h * 0.5
		for sy in [1.0, -1.0]:
			var bar := MeshInstance3D.new()
			bar.name = "PanelBorderH"
			var bm := BoxMesh.new()
			bm.size = Vector3(panel_w + border_t * 2.0, border_t, 0.045)
			bar.mesh = bm
			bar.material_override = border_mat
			bar.position = Vector3(cx, panel_y + sy * (half_h + border_t * 0.5), front_z + 0.006)
			add_child(bar)
		for sx in [1.0, -1.0]:
			var bar2 := MeshInstance3D.new()
			bar2.name = "PanelBorderV"
			var bm2 := BoxMesh.new()
			bm2.size = Vector3(border_t, panel_h, 0.045)
			bar2.mesh = bm2
			bar2.material_override = border_mat
			bar2.position = Vector3(cx + sx * (half_w + border_t * 0.5), panel_y, front_z + 0.006)
			add_child(bar2)

		_build_vent_in_pocket(cx, panel_y, panel_w, panel_h, vent_z)


# Vent nestled in the panel well: lighter machined-grey grille bars sitting just
# proud of the dark floor but below the raised border, so the X / fan / louver
# reads as detail DOWN IN the recessed panel — never a beam floating on top.
func _build_vent_in_pocket(cx: float, cy: float, panel_w: float, panel_h: float, vent_z: float) -> void:
	# Dark grille so the vent reads as cut/sunk into the lit panel floor.
	var vent_mat := _make_metal_mat(Color(0.04, 0.045, 0.055), 0.5, 0.6)
	var style: String = vent_style if vent_style != "" else "x"

	if style == "fan":
		var r: float = minf(panel_w, panel_h) * 0.40
		for ri in range(3):
			var rad: float = r * (0.34 + 0.22 * float(ri))
			var ring := MeshInstance3D.new()
			ring.name = "VentFanRing_%d" % ri
			var tm := TorusMesh.new()
			tm.inner_radius = rad - 0.007
			tm.outer_radius = rad
			ring.mesh = tm
			ring.material_override = vent_mat
			ring.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
			ring.position = Vector3(cx, cy, vent_z)
			add_child(ring)
		for k in range(4):
			var spoke := MeshInstance3D.new()
			spoke.name = "VentFanSpoke_%d" % k
			var spm := BoxMesh.new()
			spm.size = Vector3(r * 1.9, 0.012, 0.014)
			spoke.mesh = spm
			spoke.material_override = vent_mat
			spoke.rotation = Vector3(0.0, 0.0, deg_to_rad(45.0 * float(k)))
			spoke.position = Vector3(cx, cy, vent_z - 0.003)
			add_child(spoke)
		var hub := MeshInstance3D.new()
		hub.name = "VentFanHub"
		var hm := CylinderMesh.new()
		hm.top_radius = r * 0.16
		hm.bottom_radius = r * 0.16
		hm.height = 0.02
		hm.radial_segments = 12
		hub.mesh = hm
		hub.material_override = vent_mat
		hub.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
		hub.position = Vector3(cx, cy, vent_z + 0.004)
		add_child(hub)

	elif style == "louver":
		var slat_n: int = 5
		var slat_w: float = panel_w * 0.78
		var span_h: float = panel_h * 0.74
		for i in range(slat_n):
			var slat := MeshInstance3D.new()
			slat.name = "VentLouver_%d" % i
			var sm := BoxMesh.new()
			sm.size = Vector3(slat_w, 0.026, 0.02)
			slat.mesh = sm
			slat.material_override = vent_mat
			var ty: float = -span_h * 0.5 + span_h * (float(i) + 0.5) / float(slat_n)
			slat.rotation = Vector3(deg_to_rad(20.0), 0.0, 0.0)
			slat.position = Vector3(cx, cy + ty, vent_z)
			add_child(slat)

	else:
		var diag: float = sqrt(panel_w * panel_w + panel_h * panel_h) * 0.82
		for ang in [45.0, -45.0]:
			var slat := MeshInstance3D.new()
			slat.name = "VentXSlat_%.0f" % ang
			var sm := BoxMesh.new()
			sm.size = Vector3(diag, 0.055, 0.018)
			slat.mesh = sm
			slat.material_override = vent_mat
			slat.rotation = Vector3(0.0, 0.0, deg_to_rad(ang))
			slat.position = Vector3(cx, cy, vent_z)
			add_child(slat)


func _build_leds(hw: float, front_z: float) -> void:
	var led_mat: Material = _led_mat(accent_color)
	var led_r: float = 0.012
	var led_y: float = crate_height * 0.16
	var n: int = 4
	var span: float = crate_width * 0.62
	for i in range(n):
		var led := MeshInstance3D.new()
		led.name = "LED_%d" % i
		var lm := CylinderMesh.new()
		lm.top_radius = led_r
		lm.bottom_radius = led_r
		lm.height = 0.01
		lm.radial_segments = 10
		led.mesh = lm
		led.material_override = led_mat
		led.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)   # face +Z
		var lx: float = -span * 0.5 + span * float(i) / float(n - 1)
		led.position = Vector3(lx, led_y, front_z + 0.006)
		add_child(led)


# Two small orange latch tabs on the top front edge.
func _build_latch_tabs(hw: float, front_z: float) -> void:
	var tab_mat: Material = _led_mat(accent_color)
	var tab_w: float = 0.07
	var tab_h: float = 0.05
	var tab_y: float = crate_height * 0.86
	for sx in [1.0, -1.0]:
		var tab := MeshInstance3D.new()
		tab.name = "LatchTab"
		var tm := BoxMesh.new()
		tm.size = Vector3(tab_w, tab_h, 0.03)
		tab.mesh = tm
		tab.material_override = tab_mat
		tab.position = Vector3(sx * crate_width * 0.3, tab_y, front_z + 0.012)
		add_child(tab)


# A recessed grip pocket (dark inset box) centred on each ±X end face.
func _build_side_grips(hw: float) -> void:
	var grip_mat := _make_metal_mat(Color(0.05, 0.055, 0.065), 0.45, 0.6)
	var grip_h: float = 0.06
	var grip_d: float = crate_depth * 0.42
	var grip_inset: float = 0.04             # box centre set INTO the side face
	for sx in [1.0, -1.0]:
		var grip := MeshInstance3D.new()
		grip.name = "SideGrip"
		var gm := BoxMesh.new()
		gm.size = Vector3(0.05, grip_h, grip_d)
		grip.mesh = gm
		grip.material_override = grip_mat
		# Centre pushed inward so the dark box reads as a sunk grip.
		grip.position = Vector3(sx * (hw - grip_inset), crate_height * 0.52, 0.0)
		add_child(grip)


func _metal_mat(c: Color, rough: float, metal: float) -> Material:
	if not use_shader:
		return _make_metal_mat(c, rough, metal)
	var m := ShaderMaterial.new()
	m.shader = METAL_SHADER
	m.set_shader_parameter("body_color", c)
	m.set_shader_parameter("metallic_amt", metal)
	m.set_shader_parameter("roughness_amt", rough)
	m.set_shader_parameter("rim_color", accent_color)
	m.set_shader_parameter("rim_strength", 0.0)
	m.set_shader_parameter("grime", 0.18)
	return m


func _panel_mat(floor_c: Color) -> Material:
	if not use_shader:
		return _make_metal_mat(floor_c, 0.5, 0.55)
	var m := ShaderMaterial.new()
	m.shader = PANEL_SHADER
	m.set_shader_parameter("floor_color", floor_c)
	m.set_shader_parameter("accent_color", accent_color)
	m.set_shader_parameter("scan_speed", 0.5)
	m.set_shader_parameter("grid_scale", 7.0)
	return m


func _led_mat(c: Color) -> Material:
	if use_shader:
		var m := ShaderMaterial.new()
		m.shader = PULSE_SHADER
		m.set_shader_parameter("led_color", c)
		m.set_shader_parameter("pulse_speed", 2.2)
		m.set_shader_parameter("base_glow", 1.0)
		m.set_shader_parameter("pulse_amp", 1.7)
		return m
	var sm := StandardMaterial3D.new()
	sm.albedo_color = c
	sm.emission_enabled = true
	sm.emission = c
	sm.emission_energy_multiplier = 2.2
	sm.roughness = 0.3
	sm.metallic = 0.0
	return sm


func _make_metal_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m
