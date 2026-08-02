# @identity
# essence: a handheld measurement instrument — a sword-style cylindrical handle with a copper guard, an emissive LCD screen on its top, a precision laser beam from the guard, and a numeric readout that pairs the beam-tip with the number
# desire: make scale legible by hand — turn empty space into a measurable quantity, in a body that reads as a tool, not as a placeholder cube
# critical_parameter: max_range and unit — they set what the tool can see and how it reports
# triggers: _ready() builds handle + copper guard + LCD frame + lit screen panel + raycast + beam mesh + tick-mark ruler + inline hit-point label; _process() casts every frame, updates readouts, reveals ticks up to hit-distance
# emerges: a beam that snaps to surfaces, a hit-dot at the intersection, a glowing green-on-black LCD reading on the handle's top face, a hovering numeric label AT the hit-point, and a tick-mark ruler along the beam
# needs: raycast configurable range [present]; unit selector m/cm [present]; damage mode for laser-hazard repurposing [present]; inline hit-point readout [present]; tick-mark ruler along beam [present]; sword-style cylinder body [present, 2026-05-19]; emissive LCD screen panel [present, 2026-05-19]
# relationships: shares body geometry vocabulary with laser_sword (cylinder handle + copper guard); companion to vectorline (geometric length) and to the science_screen family (in-world numeric readouts); doubles as a hazard via deals_damage flag
# truth: Measurement is a probe with a number attached. The beam without the readout is decoration; the readout without the beam is abstract. The pairing is the primitive — now made explicit in three places: a readout that rides the hit-point, a ruler that lives along the beam, and a screen on the handle that reads like a real instrument's LCD.

extends Node3D

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

@export_category("Measurement Settings")
@export var max_range: float = 50.0
@export var scan_frequency: float = 30.0
@export var unit: String = "m"  # "m", "cm", "units"
@export var decimal_places: int = 2

@export_category("Laser Beam Settings")
@export var show_laser: bool = true
@export var laser_color: Color = Color(1.0, 0.1, 0.1, 0.9)
@export var laser_hit_color: Color = Color(0.1, 1.0, 0.3, 0.9)
@export var laser_thickness: float = 0.003
@export var show_hit_dot: bool = true
@export var hit_dot_size: float = 0.02

@export_category("Damage Settings")
@export var deals_damage: bool = false           ## Enable to make laser hurt the player
@export var damage_amount: float = 1.0           ## 1% damage per hit
@export var damage_cooldown: float = 1.0         ## Seconds between damage ticks

@export_category("Display Settings")
@export var text_color: Color = Color(0.2, 1.0, 0.3, 1.0)
@export var show_target_name: bool = true
## Show a small numeric label at the hit point — tightens the beam ↔ readout pairing
@export var show_inline_readout: bool = true
## Show tick marks along the beam at unit intervals — makes scale legible by hand, not just as a number
@export var show_tick_marks: bool = true
@export var tick_interval_m: float = 1.0   # 1m intervals
@export var tick_size: float = 0.012

@export_category("Body Geometry")
## Build a laser-sword-style cylinder handle + copper guard in code.
## Set false to keep the legacy box-body from grab_laser_measure.tscn.
@export var build_body_in_code: bool = true
@export var handle_length: float = 0.14
@export var handle_radius: float = 0.016
@export var handle_color: Color = Color(0.25, 0.23, 0.20)   # Rams dark, same as laser_sword
@export var guard_radius_scale: float = 1.8                  # copper disc relative to handle radius
@export var guard_color: Color = Color(0.75, 0.38, 0.13)     # copper

@export_category("LCD Screen")
## Build a proper LCD screen panel on the handle (vs raw Label3D).
@export var build_lcd_screen: bool = true
@export var lcd_size: Vector2 = Vector2(0.05, 0.024)         # width × height in metres
@export var lcd_bg_color: Color = Color(0.0, 0.08, 0.04)     # deep dark green like an LCD
@export var lcd_frame_color: Color = Color(0.18, 0.16, 0.13) # dark frame (matches handle)
@export var lcd_text_color: Color = Color(0.4, 1.0, 0.55)    # bright green digits

@export_category("Claim")
## AXIS — WHAT THE INSTRUMENT COMMITS TO when it answers. A measuring tool is the thing
## by which this world claims to know its own dimensions, so the interesting question is
## not how far it reaches or in which unit it prints, but how much it is willing to say.
## Five values, five different claims about whether measurement is perception or
## bookkeeping, and every one of them legible in a single still:
##
##   none       a beam and nothing else. The screen bay is closed with a blind cover, the
##              ruler is not fitted, and nothing is written onto the world at all. The
##              tool points; the number is somebody else's business. Perception.
##   figure     a bare quantity. The bay is refitted as one large window carrying a single
##              numeral — no unit, no target named, no graduation anywhere on the beam.
##              A number belonging to no system.
##   metric     THE LEGACY LINEAGE, byte for byte: number and unit on the fitted screen,
##              the target named under it, unit ticks stepping along the beam, a tag
##              riding the hit point. The quantity belongs to a system, and the system is
##              inscribed on the world.
##   tolerance  the number carries its error. A translucent envelope sleeves the beam for
##              its whole length between two bound lines, every tick becomes a bracketed
##              PAIR straddling its nominal place, and the screen reads with a +/- band.
##              The instrument admits it can be wrong.
##   datum      the reading is booked against a reference. A datum board stands at the
##              emitter carrying the zero every entry is measured FROM, each tick gains a
##              numbered station plate on a stalk off the beam, and the screen becomes a
##              log under a datum header. Bookkeeping.
##
## The RULER is the pivot, the way the lit seam is on [[station_wall]]: it is the only
## thing this artifact writes onto the world outside its own body. The two values that
## withhold it (none, figure) read from across a room; the two that elaborate it
## (tolerance, datum) reward the arm's length a handheld tool is met at anyway.
##
## Nothing here is a rate, a speed or a decay — the evidence for this axis is one frame
## per value, and a frame cannot see scan_frequency.
@export_enum("none", "figure", "metric", "tolerance", "datum") var claim: String = "metric"
const CLAIMS: PackedStringArray = ["none", "figure", "metric", "tolerance", "datum"]
## Envelope half-width as a fraction of reach — what `tolerance` draws as the +/- sleeve.
const CLAIM_BAND: float = 0.004
## A record has a finite page: `datum` books this many stations and leaves the rest of
## the beam unentered.
const CLAIM_STATIONS: int = 16

var _claim_root: Node3D                          # everything the axis ADDS, freed on reapply
var _claim_hidden: Array[MeshInstance3D] = []    # everything the axis MUTES (layers = 0)
var _claim_freed_lcd: bool = false               # `none` freed the readout holder
var _claim_freed_inline: bool = false            # `none`/`figure` freed the hit-point tag

var raycast: RayCast3D
var laser_beam: MeshInstance3D
var laser_material: StandardMaterial3D
var hit_dot: MeshInstance3D
var hit_dot_material: StandardMaterial3D
var body_mesh: MeshInstance3D
# Integrated 2D-in-3D boards (baked text) — replace bare floating Label3D.
var lcd_board: Node3D                   # multi-line readout block ON the LCD screen surface
var _lcd_board_holder: Node3D           # container we can clear/rebuild on text change
var _lcd_cache_key: String = ""         # cache guard — rebuild the LCD board only when the text changes
var inline_board: Node3D                # numeric tag AT the hit point (billboarded)
var _inline_board_holder: Node3D        # container for the inline tag
var _inline_cache_key: String = ""      # cache guard for the inline tag
var tick_root: Node3D                  # parent for tick mesh instances
var _tick_meshes: Array[MeshInstance3D] = []
# New body geometry built in code (laser-sword-style handle)
var _handle_mesh: MeshInstance3D
var _guard_mesh: MeshInstance3D
var _lcd_frame: MeshInstance3D
var _lcd_screen: MeshInstance3D
var scan_timer: float = 0.0

var last_distance: float = 0.0
var last_target: String = ""
var is_measuring: bool = false
var _damage_timer: float = 0.0

func _ready():
	setup_raycast()
	if build_body_in_code:
		setup_body_geometry()    # cylinder handle + copper guard, laser-sword style
	setup_laser_beam()
	setup_hit_dot()
	setup_tick_marks()
	setup_inline_readout()
	if build_lcd_screen:
		setup_lcd_screen()       # proper LCD panel on the handle
	setup_display()
	update_display(0.0, "", false)
	_apply_claim()               # APPENDED LAST — "metric" adds nothing above this line

func setup_raycast():
	raycast = find_child("RayCast3D", true, false)
	if not raycast:
		raycast = RayCast3D.new()
		raycast.name = "MeasureRayCast"
		add_child(raycast)

	raycast.enabled = true
	raycast.target_position = Vector3(0, 0, -max_range)
	raycast.collision_mask = 0xFFFFFFFF
	raycast.collide_with_bodies = true
	raycast.collide_with_areas = false

func setup_laser_beam():
	if not show_laser:
		return

	laser_beam = MeshInstance3D.new()
	laser_beam.name = "LaserBeam"
	add_child(laser_beam)

	var beam_mesh = BoxMesh.new()
	beam_mesh.size = Vector3(laser_thickness, laser_thickness, max_range)
	laser_beam.mesh = beam_mesh
	laser_beam.position = Vector3(0, 0, -max_range / 2)

	laser_material = StandardMaterial3D.new()
	laser_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	laser_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	laser_material.emission_enabled = true
	laser_material.emission = laser_color
	laser_material.emission_energy_multiplier = 2.0
	laser_material.albedo_color = laser_color
	laser_beam.set_surface_override_material(0, laser_material)

func setup_hit_dot():
	if not show_hit_dot:
		return

	hit_dot = MeshInstance3D.new()
	hit_dot.name = "HitDot"
	add_child(hit_dot)

	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = hit_dot_size
	dot_mesh.height = hit_dot_size * 2
	dot_mesh.radial_segments = 8
	dot_mesh.rings = 4
	hit_dot.mesh = dot_mesh
	hit_dot.visible = false

	hit_dot_material = StandardMaterial3D.new()
	hit_dot_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hit_dot_material.emission_enabled = true
	hit_dot_material.emission = laser_hit_color
	hit_dot_material.emission_energy_multiplier = 3.0
	hit_dot_material.albedo_color = laser_hit_color
	hit_dot.set_surface_override_material(0, hit_dot_material)

func setup_body_geometry():
	# Laser-sword-style handle + copper guard, built in code so the artifact
	# reads as a real instrument even outside its grab_stick scene wrapper.
	# Mirrors laser_sword's geometry pattern (cylinder + guard disc).
	# Local axis convention: the beam fires along -Z, so the handle is also
	# along Z with the grip going from +Z (back/butt) to -Z (front/lens-end).

	# Handle — cylinder along Z
	_handle_mesh = MeshInstance3D.new()
	_handle_mesh.name = "Handle"
	var cyl := CylinderMesh.new()
	cyl.height = handle_length
	cyl.top_radius = handle_radius
	cyl.bottom_radius = handle_radius * 1.1   # slight taper toward the butt
	cyl.radial_segments = 16
	_handle_mesh.mesh = cyl
	# CylinderMesh defaults to Y axis — rotate so axis aligns with Z
	_handle_mesh.rotation_degrees = Vector3(90, 0, 0)
	_handle_mesh.position = Vector3(0, 0, 0)
	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = handle_color
	handle_mat.metallic = 0.7
	handle_mat.roughness = 0.3
	_handle_mesh.material_override = handle_mat
	add_child(_handle_mesh)

	# Guard — copper disc at the front of the handle (where beam emits)
	_guard_mesh = MeshInstance3D.new()
	_guard_mesh.name = "Guard"
	var guard_cyl := CylinderMesh.new()
	guard_cyl.height = 0.006
	guard_cyl.top_radius = handle_radius * guard_radius_scale
	guard_cyl.bottom_radius = handle_radius * guard_radius_scale
	guard_cyl.radial_segments = 16
	_guard_mesh.mesh = guard_cyl
	_guard_mesh.rotation_degrees = Vector3(90, 0, 0)
	_guard_mesh.position = Vector3(0, 0, -handle_length / 2.0)   # front of handle
	var guard_mat := StandardMaterial3D.new()
	guard_mat.albedo_color = guard_color
	guard_mat.metallic = 0.6
	guard_mat.roughness = 0.35
	guard_mat.emission_enabled = true
	guard_mat.emission = guard_color
	guard_mat.emission_energy_multiplier = 0.3
	_guard_mesh.material_override = guard_mat
	add_child(_guard_mesh)


func setup_lcd_screen():
	# A small, screen-shaped LCD panel mounted on the handle's "top" surface,
	# facing roughly toward the operator. Frame around a dark-green panel; the
	# consolidated readout board (distance + target as one baked-text block) gets
	# parented to this screen so the text reads as a real digital readout.
	#
	# Local convention: handle is along Z; mount the panel on +Y face (top of
	# the handle when held horizontally), inset slightly along the length.
	var panel_y := handle_radius + 0.001   # just above handle surface

	# Frame — slightly larger than the lit area
	_lcd_frame = MeshInstance3D.new()
	_lcd_frame.name = "LCDFrame"
	var frame_box := BoxMesh.new()
	frame_box.size = Vector3(lcd_size.x + 0.004, 0.002, lcd_size.y + 0.004)
	_lcd_frame.mesh = frame_box
	_lcd_frame.position = Vector3(0, panel_y, 0.015)   # slight offset toward the butt
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = lcd_frame_color
	frame_mat.metallic = 0.5
	frame_mat.roughness = 0.4
	_lcd_frame.material_override = frame_mat
	add_child(_lcd_frame)

	# Lit screen surface — slightly raised from frame top, emissive dark green
	_lcd_screen = MeshInstance3D.new()
	_lcd_screen.name = "LCDScreen"
	var screen_box := BoxMesh.new()
	screen_box.size = Vector3(lcd_size.x, 0.0012, lcd_size.y)
	_lcd_screen.mesh = screen_box
	_lcd_screen.position = Vector3(0, panel_y + 0.0016, 0.015)
	var screen_mat := StandardMaterial3D.new()
	screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen_mat.albedo_color = lcd_bg_color
	screen_mat.emission_enabled = true
	screen_mat.emission = lcd_bg_color
	screen_mat.emission_energy_multiplier = 0.6
	_lcd_screen.material_override = screen_mat
	add_child(_lcd_screen)


func setup_tick_marks():
	# Tick marks along the beam at tick_interval_m intervals.
	# Make scale legible by hand — the desire in @identity.
	if not show_tick_marks:
		return
	tick_root = Node3D.new()
	tick_root.name = "TickMarks"
	add_child(tick_root)
	var tick_mat := StandardMaterial3D.new()
	tick_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tick_mat.emission_enabled = true
	tick_mat.emission = laser_color
	tick_mat.emission_energy_multiplier = 2.5
	tick_mat.albedo_color = laser_color
	# Build a pool of ticks sized to cover max_range
	var n_ticks: int = int(max_range / tick_interval_m)
	for i in range(1, n_ticks + 1):
		var tm := MeshInstance3D.new()
		tm.name = "Tick_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(tick_size, tick_size, 0.002)   # short horizontal strip
		tm.mesh = box
		tm.position = Vector3(0, 0, -i * tick_interval_m)
		tm.set_surface_override_material(0, tick_mat)
		tm.visible = false
		tick_root.add_child(tm)
		_tick_meshes.append(tm)

func setup_inline_readout():
	# Numeric tag at the hit point — the truth says "the pairing is the primitive".
	# Body LCD is the formal readout; this is the inline glance at the probe. Now an
	# integrated 2D-in-3D board (make_tag) instead of a bare floating Label3D: a
	# framed billboarded plate that rides the beam-tip. Its holder rebuilds on text
	# change only (cache-guarded) since the value changes as the laser moves.
	if not show_inline_readout:
		return
	_inline_board_holder = Node3D.new()
	_inline_board_holder.name = "InlineReadout"
	_inline_board_holder.visible = false
	add_child(_inline_board_holder)

func setup_display():
	# ONE consolidated readout board — distance + target name share a single lit
	# surface (make_text_block), so the two readouts can never overlap on the small
	# LCD. Preferred mount: on the code-built LCD screen. Fallback: on the legacy
	# LaserMeasure#Body from grab_laser_measure.tscn.
	if _lcd_screen:
		# A holder parented to the screen, oriented to face +Y (up out of the panel,
		# toward the operator). The board mesh block is rebuilt into it on text change.
		_lcd_board_holder = Node3D.new()
		_lcd_board_holder.name = "LCDReadoutBoard"
		_lcd_screen.add_child(_lcd_board_holder)
		# make_text_block faces +Z; rotate so it faces +Y (out of the screen face),
		# and lift it just above the emissive surface so it reads as printed digits.
		_lcd_board_holder.rotation_degrees = Vector3(-90, 0, 0)
		_lcd_board_holder.position = Vector3(0, 0.0009, 0)
		return
	body_mesh = get_node_or_null("../LaserMeasure#Body")
	if not body_mesh:
		var parent = get_parent()
		if parent:
			body_mesh = parent.get_node_or_null("LaserMeasure#Body")
	if body_mesh:
		# Legacy body — same consolidated board, mounted on the +Z back face facing
		# the user (Body size 0.04 x 0.025 x 0.12, back face at +Z = 0.06 local).
		_lcd_board_holder = Node3D.new()
		_lcd_board_holder.name = "ReadoutBoard"
		body_mesh.add_child(_lcd_board_holder)
		_lcd_board_holder.position = Vector3(0, 0, 0.061)   # just past the back surface, facing +Z

func _process(delta):
	scan_timer += delta
	if _damage_timer > 0.0:
		_damage_timer -= delta

	if scan_timer >= (1.0 / scan_frequency):
		perform_measurement()
		scan_timer = 0.0

func perform_measurement():
	if not raycast:
		return

	raycast.force_raycast_update()

	if raycast.is_colliding():
		var hit_point = raycast.get_collision_point()
		var hit_object = raycast.get_collider()
		var distance = global_position.distance_to(hit_point)

		last_distance = distance
		last_target = _get_display_name(hit_object)
		is_measuring = true

		update_laser_hit(distance)
		update_hit_dot(hit_point)
		update_tick_marks(distance)
		update_inline_readout(hit_point, distance)
		update_display(distance, last_target, true)

		# Damage: any hit triggers damage when enabled (the laser itself is the hazard)
		if deals_damage and _damage_timer <= 0.0:
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("apply_health_damage"):
				# The laser beam touching anything while player holds it = player in danger
				# For static placed lasers: hitting the player body specifically
				if _is_player_body(hit_object):
					gm.apply_health_damage(damage_amount)
					_damage_timer = damage_cooldown
					print("[LaserMeasure] LASER HIT PLAYER! dmg=%.1f target=%s" % [damage_amount, hit_object.name])
	else:
		is_measuring = false
		last_distance = 0.0
		last_target = ""

		update_laser_miss()
		hide_hit_dot()
		hide_inline_readout()
		hide_tick_marks()   # passive ruler when no target
		update_display(0.0, "", false)

func _get_display_name(obj: Node) -> String:
	if not obj:
		return ""

	var name = obj.name
	# Clean up common suffixes
	name = name.replace("StaticBody3D", "").replace("RigidBody3D", "")
	name = name.replace("CollisionShape3D", "").replace("MeshInstance3D", "")
	name = name.strip_edges()

	# Truncate long names
	if name.length() > 12:
		name = name.substr(0, 10) + ".."

	return name

func update_laser_hit(distance: float):
	if not laser_beam or not laser_material:
		return

	var beam_mesh = laser_beam.mesh as BoxMesh
	if beam_mesh:
		beam_mesh.size.z = distance
		laser_beam.position.z = -distance / 2

	laser_material.emission = laser_hit_color
	laser_material.albedo_color = laser_hit_color

func update_laser_miss():
	if not laser_beam or not laser_material:
		return

	var beam_mesh = laser_beam.mesh as BoxMesh
	if beam_mesh:
		beam_mesh.size.z = max_range
		laser_beam.position.z = -max_range / 2

	laser_material.emission = laser_color
	laser_material.albedo_color = laser_color

func update_hit_dot(world_position: Vector3):
	if not hit_dot:
		return

	hit_dot.global_position = world_position
	hit_dot.visible = true

	# Pulse effect
	var pulse = 0.8 + 0.4 * sin(Time.get_ticks_msec() * 0.01)
	hit_dot.scale = Vector3.ONE * pulse

func hide_hit_dot():
	if hit_dot:
		hit_dot.visible = false

func update_tick_marks(distance: float):
	# Show only ticks within current measurement distance.
	# The ticks act as a ruler: ticks visible = "1, 2, 3 metres" legible in space.
	if not show_tick_marks or _tick_meshes.is_empty():
		return
	for i in range(_tick_meshes.size()):
		var tick_distance: float = float(i + 1) * tick_interval_m
		_tick_meshes[i].visible = tick_distance < distance

func hide_tick_marks():
	# When not measuring, show all ticks at low brightness as a passive ruler
	if not show_tick_marks or _tick_meshes.is_empty():
		return
	for tm in _tick_meshes:
		tm.visible = true   # passive ruler when not pointed at anything

func update_inline_readout(world_position: Vector3, distance: float):
	# The numeric tag rides at the hit-point — the readout follows the probe. It is
	# an integrated 2D-in-3D board (make_tag). The board mesh is only rebuilt when the
	# displayed string changes (cache-guarded) — every frame we just move the holder,
	# which is cheap. This keeps the per-frame cost low while the value updates live.
	if not show_inline_readout or not _inline_board_holder:
		return
	_inline_board_holder.global_position = world_position + Vector3(0, 0.08, 0)
	_inline_board_holder.visible = true
	var unit_suffix = unit
	var display_value = distance
	match unit:
		"cm": display_value = distance * 100.0
		"units": unit_suffix = ""
	var txt := "%.*f%s" % [decimal_places, display_value, unit_suffix]
	if txt == _inline_cache_key:
		return   # same text — reuse existing board, no rebuild
	_inline_cache_key = txt
	if inline_board and is_instance_valid(inline_board):
		inline_board.queue_free()
	inline_board = BakedText.make_tag(txt, laser_hit_color, 0.05,
		Color(0.03, 0.06, 0.04), true, laser_hit_color)
	if inline_board:
		_inline_board_holder.add_child(inline_board)

func hide_inline_readout():
	if _inline_board_holder:
		_inline_board_holder.visible = false

func update_display(distance: float, target: String, is_active: bool):
	if not _lcd_board_holder:
		return

	# Pick text colour based on which mount is active. The LCD-screen path uses
	# lcd_text_color (bright lime green) on the dark-green emissive panel — high
	# contrast, reads like a real instrument. The legacy body mount uses text_color.
	var active_color: Color = lcd_text_color if _lcd_screen else text_color

	# Compose the two readouts (distance, target) as lines of ONE board so they
	# share the surface and can never overlap.
	var distance_line: String
	if is_active:
		var display_value = distance
		var unit_suffix = unit
		match unit:
			"cm":
				display_value = distance * 100.0
			"units":
				unit_suffix = "u"
		distance_line = ("%." + str(decimal_places) + "f %s") % [display_value, unit_suffix]
	else:
		# Idle — keep the digits visible, like a real LCD when not measuring.
		distance_line = "--- %s" % unit

	var lines: Array = [distance_line]
	if show_target_name:
		if is_active:
			lines.append(target if target != "" else "---")
		else:
			lines.append("No target")

	# CLAIM — what the instrument commits to IN WRITING. "metric" never enters here, so
	# the default readout is still composed exactly as it was before the axis existed.
	if claim != "metric":
		lines = _claim_readout(distance, is_active)

	# Cache guard — rebuild the board mesh only when the text (or active state) changes.
	var key := "%s|%s|%d" % ["\n".join(PackedStringArray(lines)), active_color, int(is_active)]
	if key == _lcd_cache_key:
		return
	_lcd_cache_key = key

	if lcd_board and is_instance_valid(lcd_board):
		lcd_board.queue_free()

	# Sizing: fit the block inside the LCD surface (lcd_size) when on-screen; use a
	# larger board on the legacy body. Idle text sits slightly dimmed but readable.
	var col: Color = active_color if is_active else active_color.darkened(0.15 if _lcd_screen else 0.5)
	var line_h: float
	var max_w: float
	if _lcd_screen:
		max_w = lcd_size.x * 0.92
		line_h = lcd_size.y * 0.42   # two lines fit within the panel height with a gap
	else:
		max_w = 0.03
		line_h = 0.012
	# One numeral, one window: `figure` gives the whole face to the quantity.
	if claim == "figure" and _lcd_screen:
		line_h = lcd_size.y * 0.72
		max_w = lcd_size.x * 1.02
	lcd_board = BakedText.make_text_block(lines, col, line_h, max_w, line_h * 0.3, true)
	if lcd_board:
		_lcd_board_holder.add_child(lcd_board)

# Public API
func get_distance() -> float:
	return last_distance

func get_target_name() -> String:
	return last_target

func is_hitting() -> bool:
	return is_measuring

func set_unit(new_unit: String):
	unit = new_unit

func set_max_range(new_range: float):
	max_range = new_range
	if raycast:
		raycast.target_position = Vector3(0, 0, -max_range)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("damage"):
		deals_damage = str(config_data["damage"]).to_lower() == "true"
	if config_data.has("damage_amount"):
		damage_amount = float(config_data["damage_amount"])
	if config_data.has("cooldown"):
		damage_cooldown = float(config_data["cooldown"])
	# CLAIM — appended after the damage keys so every one of them behaves as it did.
	if config_data.has("claim"):
		claim = _claim_token(str(config_data["claim"]))
		if is_inside_tree():
			_apply_claim()


func _is_player_body(obj: Node) -> bool:
	if not obj:
		return false
	# Direct checks
	if obj.is_in_group("player") or obj.is_in_group("player_body"):
		return true
	if obj.name.containsn("player") or obj.name.containsn("Player"):
		return true
	# Check collision layer 20 (player body layer = 524288)
	if obj is CollisionObject3D:
		if (obj as CollisionObject3D).collision_layer & 524288 != 0:
			return true
	# Check parent chain
	var node := obj
	while node:
		if node.name == "PlayerBody" or node is XROrigin3D:
			return true
		if node.is_in_group("player"):
			return true
		node = node.get_parent()
	return false


# ── CLAIM ────────────────────────────────────────────────────────────────────────────
# One axis, five commitments, built AFTER everything else so the default value adds
# nothing and removes nothing. Appearance only: the raycast, the collision shapes, the
# grab points, the pickup layer and the damage path are never touched here — this is a
# grabbable tool and the XR interaction system must find it exactly where it left it.


## Normalise a token, keeping the default on a word the code cannot reach. Same guard
## station_wall puts on `upkeep`: an unknown value must fall back, never render blank.
func _claim_token(v: String) -> String:
	var t: String = v.strip_edges().to_lower()
	return t if CLAIMS.has(t) else "metric"


func _apply_claim() -> void:
	# Put back whatever a previous pass moved, THEN dress. On the default path both the
	# restore and the match are empty, so "metric" builds precisely what this artifact
	# built before the axis existed.
	_claim_restore()
	claim = _claim_token(claim)
	match claim:
		"none":
			_claim_none()
		"figure":
			_claim_figure()
		"tolerance":
			_claim_tolerance()
		"datum":
			_claim_datum()
		_:
			pass                                  # "metric" — the legacy lineage


## Undo the previous value. Every branch is guarded by state only a non-default value can
## set, so the first call from _ready() on the default touches nothing at all.
func _claim_restore() -> void:
	var touched: bool = false
	if _claim_root != null and is_instance_valid(_claim_root):
		_claim_root.queue_free()
		touched = true
	_claim_root = null
	if not _claim_hidden.is_empty():
		for mi in _claim_hidden:
			if is_instance_valid(mi):
				mi.layers = 1
		_claim_hidden.clear()
		touched = true
	if _claim_freed_lcd:
		_claim_freed_lcd = false
		setup_display()
		touched = true
	if _claim_freed_inline:
		_claim_freed_inline = false
		setup_inline_readout()
		touched = true
	if touched:
		_lcd_cache_key = ""
		_inline_cache_key = ""


func _claim_hold() -> Node3D:
	if _claim_root == null or not is_instance_valid(_claim_root):
		_claim_root = Node3D.new()
		_claim_root.name = "ClaimDressing"
		add_child(_claim_root)
	return _claim_root


## layers = 0, NEVER visible = false. Godot resolves visibility through the whole subtree,
## so a hidden parent takes its children with it; and the tick meshes have their `visible`
## flag rewritten by update_tick_marks on every scan anyway, which would undo a hide on
## the next frame. The render layer is per-instance and nothing else in this file reads it.
func _claim_mute(mi: MeshInstance3D) -> void:
	if mi == null or not is_instance_valid(mi):
		return
	mi.layers = 0
	_claim_hidden.append(mi)


func _claim_mute_ruler() -> void:
	for tm in _tick_meshes:
		_claim_mute(tm)


## Free the tag that rides the hit point. update_inline_readout and hide_inline_readout
## both return early on a null holder, so the number simply stops being written onto the
## world — no per-frame branch, no cost.
func _claim_drop_inline() -> void:
	if _inline_board_holder != null and is_instance_valid(_inline_board_holder):
		_inline_board_holder.queue_free()
	_inline_board_holder = null
	_claim_freed_inline = true


## NONE — the instrument that answers nothing. The screen bay is closed with a blind cover
## bolted at four corners (a bay with no instrument fitted, not a broken one), the ruler is
## unfitted, and the hit-point tag is gone. What is left is a beam and a hand.
func _claim_none() -> void:
	var hold: Node3D = _claim_hold()
	_claim_mute_ruler()
	_claim_mute(_lcd_frame)
	_claim_mute(_lcd_screen)
	# The readout holder is the only thing update_display writes into; freeing it makes
	# that function return at its first line, so no board can be rebuilt behind the cover.
	if _lcd_board_holder != null and is_instance_valid(_lcd_board_holder):
		_lcd_board_holder.queue_free()
	_lcd_board_holder = null
	lcd_board = null
	_claim_freed_lcd = true
	_claim_drop_inline()
	var panel_y: float = handle_radius + 0.001
	var cw: float = lcd_size.x + 0.006
	var cl: float = lcd_size.y + 0.006
	_claim_box(hold, Vector3(0.0, panel_y + 0.0012, 0.015), Vector3(cw, 0.0035, cl),
		_claim_solid(lcd_frame_color))
	var head: StandardMaterial3D = _claim_solid(lcd_frame_color.lightened(0.28))
	for bx in [-(cw * 0.5 - 0.005), cw * 0.5 - 0.005]:
		for bz in [0.015 - (cl * 0.5 - 0.005), 0.015 + (cl * 0.5 - 0.005)]:
			_claim_box(hold, Vector3(bx, panel_y + 0.0032, bz), Vector3(0.004, 0.002, 0.004), head)


## FIGURE — a quantity and nothing else. The fitted screen is replaced by one window of
## roughly two and a half times its lit area, carrying a single large numeral with no unit
## and no target under it; the beam loses its graduations and the hit point loses its tag.
## Nothing outside the instrument's own face says anything.
func _claim_figure() -> void:
	var hold: Node3D = _claim_hold()
	_claim_mute_ruler()
	_claim_mute(_lcd_frame)
	_claim_mute(_lcd_screen)
	_claim_drop_inline()
	var panel_y: float = handle_radius + 0.001
	var w: float = lcd_size.x * 1.10
	var l: float = lcd_size.y * 2.20
	_claim_box(hold, Vector3(0.0, panel_y, 0.015), Vector3(w + 0.004, 0.002, l + 0.004),
		_claim_solid(lcd_frame_color))
	var lit: StandardMaterial3D = _claim_lit(lcd_bg_color, 0.6)
	_claim_box(hold, Vector3(0.0, panel_y + 0.0016, 0.015), Vector3(w, 0.0012, l), lit)
	_lcd_cache_key = ""


## TOLERANCE — the reading with its doubt attached. A translucent envelope sleeves the beam
## end to end between two lit bound lines, and every tick of the ruler is doubled into a
## bracket straddling its nominal place: the mark stops being a point on a scale and becomes
## the width of the uncertainty about that point.
func _claim_tolerance() -> void:
	var hold: Node3D = _claim_hold()
	var span: float = maxf(max_range, 0.05)
	var half: float = _claim_band()
	var sleeve := StandardMaterial3D.new()
	sleeve.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sleeve.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sleeve.albedo_color = Color(laser_color.r, laser_color.g, laser_color.b, 0.20)
	sleeve.emission_enabled = true
	sleeve.emission = laser_color
	sleeve.emission_energy_multiplier = 0.45
	_claim_box(hold, Vector3(0.0, 0.0, -span * 0.5), Vector3(half * 2.0, half * 2.0, span), sleeve)
	var edge: StandardMaterial3D = _claim_lit(laser_color, 1.4)
	for sy in [-half, half]:
		_claim_box(hold, Vector3(0.0, sy, -span * 0.5),
			Vector3(laser_thickness * 2.0, laser_thickness * 2.0, span), edge)
	var brk: StandardMaterial3D = _claim_lit(laser_hit_color, 1.8)
	for tm in _tick_meshes:
		var z: float = tm.position.z
		for dz in [-half, half]:
			_claim_box(hold, Vector3(0.0, 0.0, z + dz),
				Vector3(tick_size * 1.7, tick_size * 0.5, laser_thickness * 2.0), brk)
	_lcd_cache_key = ""


## DATUM — the reading booked against a reference. A survey board stands at the emitter
## carrying the zero line every entry is measured FROM, so the tool stops answering "how
## far" and starts answering "how far from HERE" while bringing the here with it. Each tick
## the ruler already carries gains a station plate on a stalk. The page is finite: after
## CLAIM_STATIONS entries the beam runs on unbooked.
func _claim_datum() -> void:
	var hold: Node3D = _claim_hold()
	var paper: StandardMaterial3D = _claim_solid(Color(0.88, 0.86, 0.80))
	var ink: StandardMaterial3D = _claim_solid(Color(0.10, 0.10, 0.12))
	var z0: float = -handle_length * 0.5 - 0.006
	var pw: float = handle_radius * 4.4
	var ph: float = handle_radius * 3.0
	var cy: float = handle_radius * 2.4 + ph * 0.5
	_claim_box(hold, Vector3(0.0, cy, z0), Vector3(pw, ph, 0.004), paper)
	_claim_box(hold, Vector3(0.0, cy, z0 - 0.0025), Vector3(pw * 0.86, 0.004, 0.002), ink)
	_claim_box(hold, Vector3(0.0, cy + ph * 0.27, z0 - 0.0025), Vector3(pw * 0.55, 0.003, 0.002), ink)
	_claim_box(hold, Vector3(0.0, cy - ph * 0.30, z0 - 0.0025), Vector3(pw * 0.40, 0.003, 0.002), ink)
	# A post carrying the board down to the barrel, so it reads as fitted, not floating.
	_claim_box(hold, Vector3(0.0, handle_radius * 1.7, z0), Vector3(0.006, handle_radius * 1.6, 0.005),
		_claim_solid(guard_color))
	# The index mark ON the zero — the only lit thing on the board.
	_claim_box(hold, Vector3(0.0, cy - ph * 0.5 - 0.003, z0 + 0.002), Vector3(pw * 0.30, 0.005, 0.006),
		_claim_lit(laser_hit_color, 1.6))
	var n: int = mini(_tick_meshes.size(), CLAIM_STATIONS)
	for i in range(n):
		var z: float = _tick_meshes[i].position.z
		var sy: float = tick_size * 2.6
		_claim_box(hold, Vector3(0.0, sy * 0.5, z), Vector3(0.0022, sy, 0.0022), ink)
		_claim_box(hold, Vector3(0.0, sy + tick_size * 0.9, z),
			Vector3(tick_size * 2.4, tick_size * 1.8, 0.0025), paper)
		_claim_box(hold, Vector3(0.0, sy + tick_size * 0.9, z - 0.0016),
			Vector3(tick_size * 1.5, tick_size * 0.35, 0.0016), ink)
	_lcd_cache_key = ""


## The envelope half-width in metres: a fixed fraction of reach, floored so it is never
## thinner than the beam it sleeves. At the shipped 50 m reach that is a 0.2 m band; on a
## bench-length reach the floor takes over and it stays visible.
func _claim_band() -> float:
	return maxf(maxf(max_range, 0.05) * CLAIM_BAND, laser_thickness * 4.0)


## The lines the screen prints for a non-default claim. Never reached by "metric".
func _claim_readout(distance: float, is_active: bool) -> Array:
	var value: float = distance
	var suffix: String = unit
	match unit:
		"cm":
			value = distance * 100.0
		"units":
			suffix = "u"
	var digits: String = ("%." + str(decimal_places) + "f") % value
	var reading: String = "--- %s" % suffix
	if is_active:
		reading = "%s %s" % [digits, suffix]
	match claim:
		"figure":
			var bare: String = "----"
			if is_active:
				bare = digits
			return [bare]
		"tolerance":
			var band: float = _claim_band()
			if unit == "cm":
				band = band * 100.0
			return [reading, ("+/- %." + str(decimal_places) + "f") % band]
		"datum":
			return ["DATUM 0.00", reading]
	return [reading]


# ── Local builders ───────────────────────────────────────────────────────────────────
func _claim_box(parent: Node3D, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	parent.add_child(mi)
	return mi


func _claim_solid(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.5
	m.roughness = 0.42
	return m


func _claim_lit(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
