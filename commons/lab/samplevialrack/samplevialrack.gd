# samplevialrack.gd
# Sample vial rack demonstrating phase relationships
# Each vial pulses with phase offset - wave propagation visualization
extends Node3D

class_name LabSampleVialRack


# @identity
# essence: glow[i](t) = lerp(min, max, 0.5 + 0.5*sin(frequency*t*TAU + phase[i]))
# desire: Watch a rack of sample vials pulse with phase-offset luminescence like a slow wave
# critical_parameter: wave_frequency — controls the collective pulsing rate across all vials
# triggers: phase_mode switches between linear, radial, and random phase distribution across vials
# emerges: a visible traveling wave across the rack — phase offset makes the wave apparent
# needs: VR observation [has], phase mode selection [missing]
# relationships: depends on sine-driven emission modulation; contrasts with chladni_plate (continuous glow vs discrete particles); unlocks phase wave visualization
# truth: A row of oscillators with progressive phase offset is a traveling wave made of light.

@export_group("Wave Settings")
@export var wave_frequency: float = 0.5  # Hz
@export var phase_mode: int = 0  # 0=linear, 1=radial, 2=random
@export var glow_min: float = 0.2
@export var glow_max: float = 2.0

@export_group("DNA")
## AXIS — WHAT THE GLASS ADMITS ABOUT ITSELF.
##
## Sample glass is specified to be invisible: you are meant to read the sample, never the
## tube. It never manages that. There is a rim, a meniscus, a ring where the level stood,
## a number on the side. How much of that this rack shows is an argument about whether an
## instrument can be neutral — and a rack of numbered vials is the case where the argument
## is sharpest, because a labelled sample is evidence and an unlabelled one is stock.
##
##   none      the discipline's own picture of itself — clean vials, the sample legible
##             straight through, nothing recording a hand. The legacy build, exactly.
##   bench     mid-run — marker tape rings where the levels are being watched, a pipette
##             laid across the holder bar, a spare stopper set down on the base.
##   residue   the glass keeps the record — crust in every bottom, a tide ring at the old
##             level, drips down the outside, an etched band gone opaque, and a dried ring
##             on the base where a vial was stood down wet.
##   exhibit   accessioned — a seal over every stopper, a numbered tag wired to the end of
##             the rack, a tick per vial along an accession strip. The labels have become
##             the readable part and the samples have stopped mattering.
##
## Shared word for word with [[GlassRack]] and [[chemicalapparatus]] — one bench, one
## vocabulary. Named `admission` and not `witness` because [[lab_room]] already owns
## `witness` for its aperture (pane | none | port | sash), and config keys are one flat
## global namespace.
@export var admission: String = "none"
const ADMISSIONS: PackedStringArray = ["none", "bench", "residue", "exhibit"]

## AXIS — WHAT THE RACK DOES WITH THE PART OF THE WAVE A STILL CANNOT SHOW.
##
## The taught claim is that six oscillators with progressive phase offset ARE a traveling
## wave. The rack makes that claim in the time domain only: the glow pulses, the phases
## march, and a photograph of it shows six vials at one arbitrary instant with fill levels
## that are literally random. The wave lives entirely in the animation, and anyone who
## stops moving loses it. This axis decides what survives the stopping.
##
##   none      nothing survives — fill levels are randf(), the wave exists only in time.
##             The legacy build, and the honest name for it. (`wave_frequency` is the
##             declared critical_parameter and it is a RATE; it is deliberately NOT an
##             axis here, because a rate cannot be photographed.)
##   level     the wave is written into matter — each vial is filled to the height its own
##             phase dictates, so the meniscus line across the rack IS the waveform, and a
##             datum rule with a tick per vial makes it readable as one. The glow still
##             pulses exactly as before; the still now agrees with the animation.
##   chart     the wave is represented instead of embodied — a plotted card stands behind
##             the rack carrying the curve the phase distribution describes, with a dot on
##             it above each vial. The apparatus and its diagram in the same frame, which
##             is a different claim from `level`: one says the instrument records, the
##             other says a drawing is needed because it does not.
##
## `level` reads the SAME phase_offsets the animation reads, so it also makes phase_mode
## visible in a still for the first time: linear draws a ramp, radial draws a V, random
## draws noise. Nothing about the maths changes — only whether it leaves a mark.
##
## NAMED `inscription` AND NOT `trace`: [[spring_demo]] already declares `trace` for the
## same family of claim with its own value set (off | phase | wave), and two artifacts
## answering one config key with different vocabularies is how a sweep sets a word the
## code does not recognise and publishes identical tiles as a finding.
@export var inscription: String = "none"
const INSCRIPTIONS: PackedStringArray = ["none", "level", "chart"]

@export_group("Samples")
@export var num_vials: int = 6
@export var sample_colors: Array[Color] = [
	Color(0.0, 1.0, 1.0),   # Cyan
	Color(1.0, 1.0, 0.0),   # Yellow
	Color(1.0, 0.0, 1.0),   # Magenta
	Color(0.0, 1.0, 0.5),   # Mint
	Color(1.0, 0.3, 0.0),   # Orange
	Color(0.5, 0.0, 1.0),   # Purple
]

## Internal
var time: float = 0.0
var vial_meshes: Array[MeshInstance3D] = []
var liquid_meshes: Array[MeshInstance3D] = []
var phase_offsets: Array[float] = []
var rack_label: MeshInstance3D

func _ready() -> void:
	_read_dna_meta()
	_calculate_phases()
	_build_rack()
	# DNA dressing, appended after the rack exists so every node index and transform
	# above is untouched. Both axes at "none" add nothing at all and return immediately.
	_dress_inscription()
	_dress_admission()

func _process(delta: float) -> void:
	time += delta
	
	# Update each vial's glow based on sine wave with phase offset
	for i in range(liquid_meshes.size()):
		var liquid = liquid_meshes[i]
		if liquid and liquid.material_override:
			var phase = phase_offsets[i] if i < phase_offsets.size() else 0.0
			var wave = sin(time * wave_frequency * TAU + phase)
			var normalized = (wave + 1.0) / 2.0  # 0 to 1
			var glow = lerp(glow_min, glow_max, normalized)
			liquid.material_override.emission_energy_multiplier = glow
			
			# Subtle scale pulse
			var scale_factor = 0.9 + 0.2 * normalized
			liquid.scale.y = scale_factor

func _calculate_phases() -> void:
	phase_offsets.clear()
	
	match phase_mode:
		0:  # Linear - wave travels left to right
			for i in range(num_vials):
				phase_offsets.append(float(i) * TAU / float(num_vials))
		1:  # Radial - wave expands from center
			var center = float(num_vials - 1) / 2.0
			for i in range(num_vials):
				var dist = abs(float(i) - center)
				phase_offsets.append(dist * PI / center if center > 0 else 0.0)
		2:  # Random phases
			for i in range(num_vials):
				phase_offsets.append(randf() * TAU)

func _build_rack() -> void:
	for child in get_children():
		child.queue_free()
	vial_meshes.clear()
	liquid_meshes.clear()
	
	# Rack base
	var base = MeshInstance3D.new()
	base.name = "RackBase"
	var base_mesh = BoxMesh.new()
	var rack_width = 0.02 + num_vials * 0.022
	base_mesh.size = Vector3(rack_width, 0.015, 0.05)
	base.mesh = base_mesh
	base.position = Vector3(0, 0.0075, 0)
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.7, 0.75, 0.8)
	base_mat.metallic = 0.4
	base_mat.roughness = 0.5
	base.material_override = base_mat
	add_child(base)
	
	# Top holder bar
	var holder = MeshInstance3D.new()
	holder.name = "Holder"
	var holder_mesh = BoxMesh.new()
	holder_mesh.size = Vector3(rack_width, 0.008, 0.03)
	holder.mesh = holder_mesh
	holder.position = Vector3(0, 0.045, 0)
	holder.material_override = base_mat
	add_child(holder)
	
	# Support posts
	for x_mult in [-1, 1]:
		var post = MeshInstance3D.new()
		var post_mesh = BoxMesh.new()
		post_mesh.size = Vector3(0.006, 0.04, 0.006)
		post.mesh = post_mesh
		post.position = Vector3(x_mult * (rack_width / 2.0 - 0.005), 0.03, 0.015)
		post.material_override = base_mat
		add_child(post)
	
	# Create vials
	var spacing = 0.022
	var start_x = -spacing * (num_vials - 1) / 2.0
	
	for i in range(num_vials):
		var vial_x = start_x + i * spacing
		var color = sample_colors[i % sample_colors.size()]
		_create_vial(Vector3(vial_x, 0.015, 0), i, color)
	
	# Label
	rack_label = MeshInstance3D.new()
	rack_label.name = "Label"
	var label_mesh = BoxMesh.new()
	label_mesh.size = Vector3(rack_width * 0.8, 0.008, 0.002)
	rack_label.mesh = label_mesh
	rack_label.position = Vector3(0, 0.005, 0.026)
	var label_mat = StandardMaterial3D.new()
	label_mat.albedo_color = Color(0.1, 0.4, 0.8)
	label_mat.emission_enabled = true
	label_mat.emission = Color(0.1, 0.3, 0.6)
	label_mat.emission_energy_multiplier = 0.5
	rack_label.material_override = label_mat
	add_child(rack_label)

func _create_vial(pos: Vector3, index: int, color: Color) -> void:
	# Glass vial
	var vial = MeshInstance3D.new()
	vial.name = "Vial_%d" % index
	var vial_mesh = CylinderMesh.new()
	vial_mesh.top_radius = 0.007
	vial_mesh.bottom_radius = 0.007
	vial_mesh.height = 0.055
	vial_mesh.radial_segments = 12
	vial.mesh = vial_mesh
	vial.position = pos + Vector3(0, 0.0275, 0)
	var vial_mat = StandardMaterial3D.new()
	vial_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.3)
	vial_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vial_mat.roughness = 0.0
	vial_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	vial.material_override = vial_mat
	add_child(vial)
	vial_meshes.append(vial)
	
	# Rubber stopper
	var stopper = MeshInstance3D.new()
	var stopper_mesh = CylinderMesh.new()
	stopper_mesh.top_radius = 0.008
	stopper_mesh.bottom_radius = 0.007
	stopper_mesh.height = 0.008
	stopper.mesh = stopper_mesh
	stopper.position = pos + Vector3(0, 0.059, 0)
	var stopper_mat = StandardMaterial3D.new()
	stopper_mat.albedo_color = Color(0.3, 0.1, 0.1)
	stopper_mat.roughness = 0.9
	stopper.material_override = stopper_mat
	add_child(stopper)
	
	# Liquid sample
	var liquid = MeshInstance3D.new()
	liquid.name = "Liquid_%d" % index
	var liquid_mesh = CylinderMesh.new()
	liquid_mesh.top_radius = 0.005
	liquid_mesh.bottom_radius = 0.005
	var fill_height = 0.02 + randf() * 0.02  # Random fill level
	# INSCRIPTION = level: the phase this vial carries, written into the liquid itself, so the
	# meniscus line across the rack is the waveform. randf() is still consumed above so
	# the RNG stream is identical on every other value of the axis.
	if inscription == "level":
		var ph: float = phase_offsets[index] if index < phase_offsets.size() else 0.0
		fill_height = 0.014 + 0.030 * (0.5 + 0.5 * sin(ph))
	liquid_mesh.height = fill_height
	liquid.mesh = liquid_mesh
	liquid.position = pos + Vector3(0, 0.005 + fill_height / 2.0, 0)
	var liquid_mat = StandardMaterial3D.new()
	liquid_mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
	liquid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_mat.emission_enabled = true
	liquid_mat.emission = color
	liquid_mat.emission_energy_multiplier = glow_min
	liquid.material_override = liquid_mat
	add_child(liquid)
	liquid_meshes.append(liquid)

## Public API
func set_wave_frequency(freq: float) -> void:
	wave_frequency = freq

func set_phase_mode(mode: int) -> void:
	phase_mode = mode
	_calculate_phases()

func trigger_wave_pulse() -> void:
	# Reset time to create a clean wave from the start
	time = 0.0

func get_phase_at_vial(index: int) -> float:
	if index >= 0 and index < phase_offsets.size():
		return phase_offsets[index]
	return 0.0

# =============================================================================
# DNA — admission (what the glass admits) + inscription (what survives the stopping)
# =============================================================================
# Everything below is APPENDED. It runs after _build_rack(), adds at most two
# children named "Inscription" and "Admission", and touches nothing that already exists.
# Both axes at "none" return before their child is created, so the legacy rack is
# reproduced node for node. The pulse maths in _process is not read here at all.

const ADMISSION_ROOT := "Admission"
const INSCRIPTION_ROOT := "Inscription"
const VIAL_SPACING := 0.022


func _read_dna_meta() -> void:
	## The grid stamps config_<key> metadata BEFORE add_child, so this is readable from
	## _ready(). An unknown word keeps the default rather than blanking the axis.
	if has_meta("config_admission"):
		admission = _pick_admission(str(get_meta("config_admission")))
	if has_meta("config_inscription"):
		inscription = _pick_inscription(str(get_meta("config_inscription")))


func _pick_admission(raw: String) -> String:
	var w: String = raw.strip_edges().to_lower()
	return w if ADMISSIONS.has(w) else admission


func _pick_inscription(raw: String) -> String:
	var t: String = raw.strip_edges().to_lower()
	return t if INSCRIPTIONS.has(t) else inscription


## Additive: only `admission` and `inscription` do anything here. A token carrying anything else
## leaves the rack exactly as it was built.
func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("inscription"):
		var before: String = inscription
		inscription = _pick_inscription(str(config_data["inscription"]))
		rebuild = inscription != before
	if config_data.has("admission"):
		admission = _pick_admission(str(config_data["admission"]))
	if rebuild:
		# `level` lives in the liquid heights, which are decided at build time.
		_calculate_phases()
		_build_rack()
	if config_data.has("inscription") or config_data.has("admission"):
		_dress_inscription()
		_dress_admission()


func _rack_width() -> float:
	return 0.02 + float(num_vials) * VIAL_SPACING


func _vial_x(i: int) -> float:
	return -VIAL_SPACING * float(num_vials - 1) / 2.0 + VIAL_SPACING * float(i)


## Phase at a continuous position across the rack, interpolated between the vials'
## own offsets so a chart drawn from it describes whatever phase_mode is set.
func _phase_at(t: float) -> float:
	if phase_offsets.is_empty():
		return 0.0
	var f: float = clampf(t, 0.0, 1.0) * float(phase_offsets.size() - 1)
	var i0: int = int(floor(f))
	var i1: int = mini(i0 + 1, phase_offsets.size() - 1)
	return lerpf(float(phase_offsets[i0]), float(phase_offsets[i1]), f - float(i0))


# ── INSCRIPTION ─────────────────────────────────────────────────────────────────────

func _dress_inscription() -> void:
	var old: Node = get_node_or_null(INSCRIPTION_ROOT)
	if old:
		remove_child(old)
		old.queue_free()
	if inscription == "none":
		return

	var root := Node3D.new()
	root.name = INSCRIPTION_ROOT
	add_child(root)

	match inscription:
		"level":
			_inscription_level(root)
		"chart":
			_inscription_chart(root)
		_:
			pass


## LEVEL — the fill heights already carry the phase (see _create_vial). This adds the
## apparatus that makes them READABLE as a waveform rather than as six random fills: a
## datum rule across the rack at mid-level and a tick standing off each meniscus.
func _inscription_level(root: Node3D) -> void:
	var rule: StandardMaterial3D = _dna_mat(Color(0.90, 0.90, 0.86), 0.85, 0.0)
	var mark: StandardMaterial3D = _dna_mat(Color(0.10, 0.10, 0.13), 0.8, 0.0)
	var w: float = _rack_width()

	# The datum: one horizontal rule at the middle of the fill range, standing proud of
	# the vials so the meniscus line can be read against it.
	_dna_box(root, Vector3(0, 0.049, 0.0108), Vector3(w * 0.94, 0.0012, 0.0012), rule)

	for i in range(liquid_meshes.size()):
		var lm: MeshInstance3D = liquid_meshes[i]
		if lm == null or lm.mesh == null:
			continue
		var cm := lm.mesh as CylinderMesh
		if cm == null:
			continue
		var top: float = lm.position.y + cm.height * 0.5
		# a tick at this vial's meniscus, and the riser joining it to the datum
		_dna_box(root, Vector3(_vial_x(i), top, 0.0108), Vector3(0.016, 0.0016, 0.0016), mark)
		var span: float = absf(0.049 - top)
		if span > 0.0008:
			_dna_box(root, Vector3(_vial_x(i), (top + 0.049) * 0.5, 0.0108),
				Vector3(0.0012, span, 0.0012), rule)


## CHART — the wave drawn instead of held. A plotted card rises off the back of the rack
## carrying the curve the phase distribution describes, with a dot above each vial.
func _inscription_chart(root: Node3D) -> void:
	var board: StandardMaterial3D = _dna_mat(Color(0.90, 0.89, 0.83), 0.88, 0.0)
	var mark: StandardMaterial3D = _dna_mat(Color(0.10, 0.10, 0.13), 0.8, 0.0)
	var post: StandardMaterial3D = _dna_mat(Color(0.62, 0.65, 0.70), 0.5, 0.6)
	var w: float = _rack_width()
	var cz: float = -0.030
	var cy: float = 0.062
	var ch: float = 0.072

	for side in range(2):
		var sx: float = (-1.0 + 2.0 * float(side)) * (w * 0.5 - 0.004)
		_dna_cyl(root, Vector3(sx, 0.048, cz + 0.004), 0.0022, 0.086, post)
	_dna_box(root, Vector3(0, cy, cz), Vector3(w + 0.010, ch, 0.0018), board)
	# the zero axis
	_dna_box(root, Vector3(0, cy, cz + 0.0016), Vector3(w * 0.94, 0.0012, 0.0012), mark)

	# the curve, plotted from the rack's own phase offsets
	var steps: int = 40
	for k in range(steps):
		var t: float = float(k) / float(steps - 1)
		var px: float = lerpf(-w * 0.47, w * 0.47, t)
		var py: float = cy + sin(_phase_at(t)) * ch * 0.34
		_dna_box(root, Vector3(px, py, cz + 0.0018), Vector3(0.0032, 0.0022, 0.0012), mark)

	# one dot per vial, directly above it
	for i in range(num_vials):
		var t2: float = 0.0 if num_vials < 2 else float(i) / float(num_vials - 1)
		var dy: float = cy + sin(_phase_at(t2)) * ch * 0.34
		_dna_box(root, Vector3(_vial_x(i), dy, cz + 0.0026), Vector3(0.0062, 0.0062, 0.0014), mark)
		_dna_box(root, Vector3(_vial_x(i), cy - ch * 0.44, cz + 0.0018),
			Vector3(0.0014, 0.0080, 0.0012), mark)


# ── ADMISSION ───────────────────────────────────────────────────────────────────

func _dress_admission() -> void:
	var old: Node = get_node_or_null(ADMISSION_ROOT)
	if old:
		remove_child(old)
		old.queue_free()
	if admission == "none":
		return

	var root := Node3D.new()
	root.name = ADMISSION_ROOT
	add_child(root)

	match admission:
		"bench":
			_admission_bench(root)
		"residue":
			_admission_residue(root)
		"exhibit":
			_admission_exhibit(root)
		_:
			pass


## BENCH — mid-run. Marker tape where the levels are being watched, a pipette laid across
## the holder bar, a spare stopper set down, and a scrawl over the rack's own label.
func _admission_bench(root: Node3D) -> void:
	var tape: StandardMaterial3D = _dna_mat(Color(0.94, 0.92, 0.84), 0.88, 0.0)
	var ink: StandardMaterial3D = _dna_mat(Color(0.10, 0.10, 0.13), 0.8, 0.0)
	var rubber: StandardMaterial3D = _dna_mat(Color(0.32, 0.11, 0.11), 0.92, 0.0)
	var w: float = _rack_width()

	for i in range(num_vials):
		if i % 2 == 0:
			_dna_cyl(root, Vector3(_vial_x(i), 0.0530 - 0.004 * float(i % 3), 0.0), 0.0088, 0.0026, tape)

	# a pipette resting across the holder bar
	var pip: MeshInstance3D = _dna_cyl(root, Vector3(0.008, 0.0545, -0.006), 0.0024, w * 0.72, tape)
	pip.rotation_degrees = Vector3(0, 6.0, 90)
	_dna_cyl(root, Vector3(0.008 + w * 0.34, 0.0545, -0.006), 0.0038, 0.010, rubber)

	# a spare stopper set down on the base
	_dna_cyl(root, Vector3(w * 0.5 - 0.010, 0.0190, 0.014), 0.0080, 0.0080, rubber)

	# a scrawl over the rack's own label plate
	for k in range(3):
		_dna_box(root, Vector3(-w * 0.18 + w * 0.22 * float(k), 0.0050, 0.0278),
			Vector3(w * 0.15, 0.0016, 0.0014), ink)


## RESIDUE — the glass keeps the record. Crust in every bottom, a tide ring at the old
## level, drips down the outside, an etched band gone opaque, and a dried ring on the base
## where a vial was stood down wet.
func _admission_residue(root: Node3D) -> void:
	var crust: StandardMaterial3D = _dna_mat(Color(0.22, 0.17, 0.09), 0.97, 0.0)
	var tide: StandardMaterial3D = _dna_mat(Color(0.38, 0.30, 0.16), 0.92, 0.0)
	var frost: StandardMaterial3D = _dna_mat(Color(0.80, 0.82, 0.79), 1.0, 0.0)
	var chalk: StandardMaterial3D = _dna_mat(Color(0.52, 0.48, 0.38), 0.96, 0.0)

	for i in range(num_vials):
		var vx: float = _vial_x(i)
		_dna_cyl(root, Vector3(vx, 0.0218, 0.0), 0.0058, 0.0044, crust)
		var tide_y: float = 0.0300 + 0.0045 * float(i % 3)
		_dna_cyl(root, Vector3(vx, tide_y, 0.0), 0.0082, 0.0018, tide)
		# the etched band: opaque, matte, on the clear upper wall — the vial stops being
		# see-through exactly where you would look to read the level.
		_dna_cyl(root, Vector3(vx, 0.0530, 0.0), 0.0075, 0.0160, frost)
		for d in range(2):
			var a: float = 0.6 + 2.2 * float(d)
			_dna_box(root, Vector3(vx + cos(a) * 0.0074, (0.0180 + tide_y) * 0.5,
				sin(a) * 0.0074), Vector3(0.0016, tide_y - 0.0180, 0.0016), tide)

	# rings on the base where wet vials were stood down
	for k in range(2):
		_dna_cyl(root, Vector3(-_rack_width() * 0.30 + _rack_width() * 0.62 * float(k),
			0.0157, 0.0155), 0.0100, 0.0014, chalk)


## EXHIBIT — accessioned. A seal over every stopper, a tick per vial along an accession
## strip, a numbered tag wired to the end of the rack and a barcoded card standing in
## front of it. The labels have become the readable part.
func _admission_exhibit(root: Node3D) -> void:
	var card: StandardMaterial3D = _dna_mat(Color(0.91, 0.89, 0.81), 0.85, 0.0)
	var ink: StandardMaterial3D = _dna_mat(Color(0.09, 0.09, 0.12), 0.8, 0.0)
	var wire: StandardMaterial3D = _dna_mat(Color(0.58, 0.58, 0.62), 0.4, 0.8)
	var seal: StandardMaterial3D = _dna_mat(Color(0.82, 0.30, 0.14), 0.7, 0.0)
	var w: float = _rack_width()

	for i in range(num_vials):
		_dna_cyl(root, Vector3(_vial_x(i), 0.0745, 0.0), 0.0094, 0.0030, seal)

	# accession strip across the front of the base, one tick per vial
	_dna_box(root, Vector3(0, 0.0128, 0.0268), Vector3(w * 0.92, 0.0070, 0.0018), card)
	for i in range(num_vials):
		_dna_box(root, Vector3(_vial_x(i), 0.0128, 0.0278), Vector3(0.0018, 0.0044, 0.0014), ink)

	# tag on a wire off the +X end of the rack
	_dna_cyl_x(root, Vector3(w * 0.5 + 0.008, 0.0560, 0.004), 0.0009, 0.020, wire)
	_dna_box(root, Vector3(w * 0.5 + 0.026, 0.0470, 0.004), Vector3(0.0260, 0.0170, 0.0016), card)
	for k in range(2):
		_dna_box(root, Vector3(w * 0.5 + 0.026, 0.0470 + 0.0038 - 0.0072 * float(k), 0.0050),
			Vector3(0.0170, 0.0022, 0.0012), ink)

	# a barcoded accession card standing in front of the rack
	var bx0: float = -w * 0.26
	_dna_box(root, Vector3(bx0, 0.0290, 0.0300), Vector3(0.0560, 0.0270, 0.0018), card)
	_dna_box(root, Vector3(bx0, 0.0160, 0.0292), Vector3(0.0560, 0.0030, 0.0080), card)
	for k in range(9):
		var bw: float = 0.0016 if k % 2 == 0 else 0.0032
		_dna_box(root, Vector3(bx0 - 0.0220 + 0.0055 * float(k), 0.0270, 0.0310),
			Vector3(bw, 0.0150, 0.0014), ink)
	_dna_box(root, Vector3(bx0, 0.0378, 0.0310), Vector3(0.0460, 0.0026, 0.0014), ink)


# ── DNA geometry helpers ──────────────────────────────────────────────────────

func _dna_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _dna_box(parent: Node3D, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	parent.add_child(mi)
	return mi


func _dna_cyl(parent: Node3D, center: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = maxf(height, 0.0005)
	mesh.radial_segments = 16
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	parent.add_child(mi)
	return mi


func _dna_cyl_x(parent: Node3D, center: Vector3, radius: float, length: float, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = _dna_cyl(parent, center, radius, length, mat)
	mi.rotation_degrees = Vector3(0, 0, 90)
	return mi
