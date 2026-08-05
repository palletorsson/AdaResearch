# ===========================================================================
# FireworkLauncher.gd - Particle System Firework Display
# Launch rockets that explode into particle sprays with gravity + drag + fading
# Shows particle emission, lifetime, forces on many bodies, emergent patterns
#
# QFEP: Many from one — a single event creates a statistical population.
# ===========================================================================
#
# @identity
# essence: launch → ascend → explode(N particles) → each: v += g, v *= drag, life -= dt, fade. One event becomes sixty trajectories.
# desire: To launch a rocket and watch it bloom — sixty glowing particles inheriting random velocities from a single explosion point, then falling under gravity and drag.
# critical_parameter: shell — the figure the burst throws (sphere | ring | spokes | willow), the pyrotechnic shell type made reachable from a map; burst_force (1.0-8.0) sets how wide it opens
# triggers: Auto-launch every 2.5s, FIRE button → manual launch, preset buttons → color palettes (classic/ocean/garden) and shell types (sphere/ring), burst slider → controls explosion force
# emerges: Ring patterns from constrained emission (horizontal only). Sphere patterns from uniform random direction. Particle trails tracing parabolas. The moment of bloom as maximum expansion.
# needs: VR preset buttons [has], fire button [has], burst force slider [has], auto-launch toggle [has], star trails [added]. Missing: height slider, multi-launch choreography.
# relationships: CPU particle system (contrasts with particle_systems using GPUParticles3D). Lives in ForcesSystems. Each particle is a mini bouncing_ball with drag and lifetime.
# truth: A firework is a population explosion. One event becomes many independent trajectories, each obeying the same law, each taking a different path.
#
# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-05) — shell
#
# The runner refused this as NO TURNABLE KNOBS. Eight exports and every one of
# them a rate, a magnitude or a boolean: particle_count_per_burst, burst_force,
# gravity_strength, drag, particle_lifetime, launch_speed, launch_height,
# trail_enabled. apply_grid_config was a literal `pass`, so no map could reach any
# of them anyway.
#
# The decision that carries the argument was not an export. It was the third
# element of a hard-coded preset row — the string "sphere" on three rows and
# "ring" on the fourth — reachable only by a player walking up and pressing a VR
# button, and bundled together with a colour palette so that asking for a ring
# also meant asking for orange.
#
#   shell   the figure the burst throws
#           sphere · ring · spokes · willow
#
# These are shell types, the pyrotechnician's own taxonomy, and each is a
# different DIRECTION LAW applied to one explosion — which is precisely what this
# artifact is about. The population is identical every time; only the rule that
# hands out velocities changes:
#
#   sphere   uniform random unit vectors. The shipped default and the peony: no
#            preferred direction, so the statistics are isotropic and the figure
#            is a ball. This is what "random" looks like when nothing constrains
#            it.
#   ring     one plane. Emission angle is i/N around the horizontal, so the
#            sixty are not independent at all — they are indexed. The shipped
#            alternative, and the one the RING button has always reached.
#   spokes   eight arms. The same sixty stars quantised onto eight bearings with
#            speed ramped along each, so the population is visibly a lattice
#            rather than a cloud. The palm shell: structure imposed on a burst
#            that could have been isotropic.
#   willow   upper hemisphere, slower stars, heavier stars — 2.4x gravity on each
#            body. The only value that changes a LAW rather than a distribution,
#            and it earns its place: at any fixed instant after detonation the
#            figure is a drooping canopy, because these stars have already lost
#            the argument with gravity that the sphere's are still having.
#
# WHAT THE STILL COULD NOT SEE, and the two repairs that fix it. This artifact
# was photographed for the multi_shots gallery and the frames contain NO FIREWORK
# AT ALL — a launch tube, a base plate and a white VR control panel filling a
# third of the frame. Auto-launch first fires at t = 2.5 s and the capture rig
# settles for 1.1 s, so the shutter has always closed a second and a half before
# anything happens. Both repairs are bench-only and neither is an axis:
#
#   bench_stage = "burst" detonates a shell at the apex inside _ready, integrates
#   it forward by bench_moment seconds in fixed steps, and then FREEZES, so the
#   geometry is already final when the rig's 0.35 s AABB pre-pass measures it and
#   the 1.1 s settle photographs it. It also skips the labels and the control
#   panel, which are identical in every variant and would be the subject the
#   critic measured instead of the burst — the mst_visualization fault.
#
#   burst_seed pins the draws. Sixty particles from an unseeded global randf make
#   four variants into four different fireworks, and any bite number would then
#   be about the generator rather than the shell.
#
# STAR TRAILS ARE A REAL FEATURE, not a bench trick, and they close a gap this
# file's own @identity already claimed: "Particle trails tracing parabolas" has
# been in the emerges line since the artifact was written, and only the ROCKET
# ever had one. A still of a firework is a long exposure — the trail is what a
# photograph of a burst actually contains, and it is the only thing that can show
# a willow's droop as a curve rather than as a lower cloud of dots. star_trails
# defaults to "off" because sixty live ImmediateMesh rebuilds per physics frame
# is a real cost in a room, so no existing placement changes.
#
# DECLINED: particle_count_per_burst, burst_force, gravity_strength, drag and
# particle_lifetime are all how-much and not what-kind. The colour presets are
# which-colour, which is never an argument — and note that the promotion PRISES
# THE SHELL OUT of the preset bundle: the four buttons still set both, so the
# room behaves exactly as before, but a map can now ask for a willow without also
# asking for green.
#
# Usage in map_data.json:
#   "firework_launcher#shell:willow"
# ─────────────────────────────────────────────────────────────────────────────
extends Node3D

class_name FireworkLauncher

## THE AXIS — the figure the burst throws. "sphere" is the shipped default: it is
## the pattern string on three of the four preset rows and the one the artifact
## opens on, and its branch below is the original `else` clause verbatim.
@export_enum("sphere", "ring", "spokes", "willow") var shell: String = "sphere"

## Pins the draws so a variant photographs the same firework twice. -1 keeps the
## global randf stream untouched — a fresh unpredictable burst every launch,
## which is right in a room and useless on a bench — and at -1 no generator is
## constructed at all.
@export var burst_seed: int = -1

## Bench-only. A String enum rather than a bool on purpose: the sweep sets
## exports from a JSON fixture before _ready, and a typed bool silently rejects a
## fixture string. "live" is the shipped artifact. "burst" detonates one shell at
## the apex during _ready, advances it by bench_moment, freezes it, and leaves off
## the labels and the control panel.
@export_enum("live", "burst") var bench_stage: String = "live"

## How far past detonation the frozen frame sits, in seconds. 0.7 is the moment
## of maximum legibility at the default burst_force of 3.0: the stars have opened
## to about 1.3 m and gravity has bent the slower ones without yet collapsing the
## figure. Only read when bench_stage is "burst".
@export var bench_moment: float = 0.7

## Whether each star drags a trail behind it, the way the rocket already does.
## "off" is the shipped behaviour and the default: sixty ImmediateMesh rebuilds
## per physics frame is a real cost, so no placement pays it unless it asks.
@export_enum("off", "on") var star_trails: String = "off"

## Firework parameters
@export var particle_count_per_burst: int = 60
@export var burst_force: float = 3.0:
	set(value):
		burst_force = clampf(value, 1.0, 8.0)
@export var gravity_strength: float = 2.0
@export var drag: float = 0.98
@export var particle_lifetime: float = 3.0

## Launch parameters
@export var launch_speed: float = 4.0
@export var launch_height: float = 1.5

## Visuals
@export var trail_enabled: bool = true

## The allow-list, same spelling and same order as the @export_enum above.
const SHELLS: PackedStringArray = ["sphere", "ring", "spokes", "willow"]

## shell:spokes — how many bearings the sixty stars are quantised onto. Eight
## reads as arms at sixty stars; four reads as a cross and sixteen reads as a
## sphere again.
const SPOKE_ARMS: int = 8

## shell:willow — how much heavier a willow star is than a sphere star. The
## droop, in one number.
const WILLOW_GRAVITY: float = 2.4

## Trail length, in recorded positions. Matches the rocket's own cap.
const TRAIL_POINTS: int = 30

# Internal
var _rockets: Array = []  # Active rockets flying upward
var _particles: Array = []  # Exploded particles falling
var _info_label: Label3D
var _control_panel: Node3D
var _time_since_auto: float = 0.0
var _auto_launch: bool = true

## Non-null only when burst_seed >= 0. At the default the global stream is used,
## call for call, so frame one of an unconfigured placement is unchanged.
var _rng: RandomNumberGenerator = null

## Set by the bench fixture once its shell has been detonated and advanced.
## _physics_process returns on its first line afterwards, so the figure holds.
var _frozen: bool = false

# Presets: [name, colors, spread_pattern]
var _presets := [
	["CLASSIC", [Color(1.0, 0.3, 0.2), Color(1.0, 0.7, 0.1), Color(1.0, 1.0, 0.3)], "sphere"],
	["OCEAN", [Color(0.2, 0.5, 1.0), Color(0.3, 0.8, 0.9), Color(0.5, 1.0, 1.0)], "sphere"],
	["GARDEN", [Color(0.4, 1.0, 0.3), Color(1.0, 0.4, 0.7), Color(0.9, 0.3, 1.0)], "sphere"],
	["RING", [Color(1.0, 0.8, 0.2), Color(1.0, 0.4, 0.1), Color(0.8, 0.2, 0.1)], "ring"],
]
var _current_preset: int = 0


func _ready() -> void:
	if burst_seed >= 0:
		_rng = RandomNumberGenerator.new()
		_rng.seed = burst_seed
	_create_launch_tube()
	if _is_bench():
		# The labels and the control panel are identical in every variant and
		# would be most of the subject the critic measures. Not built at all,
		# rather than hidden, so they cannot inflate the fitted AABB either.
		_bench_detonate()
		return
	_create_labels()
	_create_vr_controls()


## One draw, from the pinned generator when there is one and from the global
## stream otherwise. At burst_seed = -1 this is `randf_range(a, b)` — the same
## call in the same order as before the promotion.
func _rf(a: float, b: float) -> float:
	if _rng != null:
		return _rng.randf_range(a, b)
	return randf_range(a, b)


func _is_bench() -> bool:
	return bench_stage.strip_edges().to_lower() == "burst"


func _trails_on() -> bool:
	return star_trails.strip_edges().to_lower() == "on"


func _shell_name() -> String:
	var v: String = shell.strip_edges().to_lower()
	if SHELLS.has(v):
		return v
	return "sphere"


func _create_launch_tube() -> void:
	# Launch tube visual
	var tube := MeshInstance3D.new()
	tube.name = "LaunchTube"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.06
	cyl.height = 0.2
	tube.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.35)
	mat.metallic = 0.6
	tube.material_override = mat
	tube.position = Vector3(0, 0.1, 0)
	add_child(tube)

	# Base plate
	var base := MeshInstance3D.new()
	base.name = "Base"
	var box := BoxMesh.new()
	box.size = Vector3(0.25, 0.02, 0.25)
	base.mesh = box
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.15, 0.15, 0.18)
	base_mat.metallic = 0.4
	base.material_override = base_mat
	add_child(base)

func _launch_firework() -> void:
	var preset: Array = _presets[_current_preset]
	var colors: Array = preset[1]

	# Create rocket
	var rocket := {
		"pos": Vector3(_rf(-0.05, 0.05), 0.2, _rf(-0.05, 0.05)),
		"vel": Vector3(_rf(-0.3, 0.3), launch_speed, _rf(-0.3, 0.3)),
		"target_height": launch_height + _rf(-0.3, 0.3),
		"colors": colors,
		"pattern": _shell_name(),
		"mesh": null,
		"trail_points": PackedVector3Array(),
		"trail_mesh": null,
	}

	# Rocket visual
	var mesh := MeshInstance3D.new()
	mesh.name = "Rocket"
	var sphere := SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.5)
	mat.emission_energy_multiplier = 3.0
	mesh.material_override = mat
	mesh.position = rocket["pos"]
	add_child(mesh)
	rocket["mesh"] = mesh

	# Trail mesh
	if trail_enabled:
		var trail := MeshInstance3D.new()
		trail.name = "RocketTrail"
		add_child(trail)
		rocket["trail_mesh"] = trail

	_rockets.append(rocket)


## THE AXIS LIVES HERE. Every shell hands out sixty velocities from one point;
## what differs is the rule that hands them out. `sphere` is the original `else`
## clause and `ring` the original `if`, both unchanged, so the two values the
## artifact has always had are the code it has always run.
func _burst_direction(index: int, shell_name: String) -> Dictionary:
	match shell_name:
		"ring":
			# Ring pattern: particles spread in a horizontal ring
			var angle: float = float(index) / float(particle_count_per_burst) * TAU
			return {
				"dir": Vector3(cos(angle), _rf(-0.2, 0.4), sin(angle)),
				"speed_scale": 1.0,
				"grav": 1.0,
			}
		"spokes":
			# Palm: eight bearings, speed ramped along each arm, so the sixty
			# read as a lattice of rays rather than as a cloud.
			var arm: int = index % SPOKE_ARMS
			var per_arm: int = maxi(1, floori(float(particle_count_per_burst) / float(SPOKE_ARMS)))
			var band: int = floori(float(index) / float(SPOKE_ARMS))
			var along: float = float(band) / float(maxi(1, per_arm - 1))
			var bearing: float = float(arm) / float(SPOKE_ARMS) * TAU
			var elev: float = 0.55
			return {
				"dir": Vector3(cos(bearing) * cos(elev), sin(elev), sin(bearing) * cos(elev)),
				"speed_scale": 0.35 + 0.65 * clampf(along, 0.0, 1.0),
				"grav": 1.0,
			}
		"willow":
			# Heavy slow stars thrown upward only: at any fixed instant after
			# detonation they are already falling while a sphere's are not.
			var a: float = _rf(0.0, TAU)
			var e: float = _rf(0.25, 1.1)
			return {
				"dir": Vector3(cos(a) * cos(e), sin(e), sin(a) * cos(e)),
				"speed_scale": 0.75,
				"grav": WILLOW_GRAVITY,
			}
	# Sphere pattern: random directions
	return {
		"dir": Vector3(_rf(-1, 1), _rf(-1, 1), _rf(-1, 1)).normalized(),
		"speed_scale": 1.0,
		"grav": 1.0,
	}


func _explode(rocket: Dictionary) -> void:
	var pos: Vector3 = rocket["pos"]
	var colors: Array = rocket["colors"]
	var pattern: String = rocket["pattern"]
	var trails: bool = _trails_on()

	for i in range(particle_count_per_burst):
		var law: Dictionary = _burst_direction(i, pattern)
		var dir: Vector3 = law["dir"]

		var speed := burst_force * _rf(0.5, 1.0) * float(law["speed_scale"])
		var color: Color = colors[i % colors.size()]
		# Slight color variation
		color = color.lightened(_rf(-0.1, 0.1))

		var particle := {
			"pos": pos,
			"vel": dir * speed,
			"color": color,
			"life": particle_lifetime,
			"max_life": particle_lifetime,
			"grav": float(law["grav"]),
			"mesh": null,
			"trail_points": PackedVector3Array(),
			"trail_mesh": null,
		}

		# Particle visual
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.012
		sphere.height = 0.024
		mesh.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.5
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = mat
		mesh.position = pos
		add_child(mesh)
		particle["mesh"] = mesh

		if trails:
			var trail := MeshInstance3D.new()
			trail.name = "StarTrail"
			add_child(trail)
			particle["trail_mesh"] = trail

		_particles.append(particle)

	# Remove rocket visual
	if rocket["mesh"]:
		(rocket["mesh"] as MeshInstance3D).queue_free()
	if rocket["trail_mesh"]:
		(rocket["trail_mesh"] as MeshInstance3D).queue_free()

func _physics_process(delta: float) -> void:
	if _frozen:
		return

	# Update rockets
	var exploded_indices: Array[int] = []
	for i in range(_rockets.size()):
		var r: Dictionary = _rockets[i]
		r["vel"].y -= gravity_strength * 0.3 * delta  # Light gravity on rockets
		r["pos"] += r["vel"] * delta

		if r["mesh"]:
			(r["mesh"] as MeshInstance3D).position = r["pos"]

		# Track trail
		if trail_enabled and r["trail_mesh"]:
			var rpts: PackedVector3Array = r["trail_points"]
			rpts.append(r["pos"])
			r["trail_points"] = rpts
			_update_trail_mesh(r["trail_mesh"] as MeshInstance3D, rpts, Color(1.0, 0.7, 0.3, 0.5))

		if r["pos"].y >= r["target_height"]:
			exploded_indices.append(i)

	# Explode rockets that reached target
	for i in range(exploded_indices.size() - 1, -1, -1):
		_explode(_rockets[exploded_indices[i]])
		_rockets.remove_at(exploded_indices[i])

	_integrate_particles(delta)

	# Auto-launch
	if _auto_launch:
		_time_since_auto += delta
		if _time_since_auto >= 2.5:
			_time_since_auto = 0.0
			_launch_firework()

	_update_info()


## The population, integrated. Split out of _physics_process so the bench fixture
## can advance the same equations by hand rather than reimplementing them — one
## law, not two that can drift.
func _integrate_particles(delta: float) -> void:
	var trails: bool = _trails_on()
	var dead_indices: Array[int] = []
	for i in range(_particles.size()):
		var p: Dictionary = _particles[i]
		p["vel"].y -= gravity_strength * float(p["grav"]) * delta
		p["vel"] *= drag
		p["pos"] += p["vel"] * delta
		p["life"] -= delta

		if p["mesh"]:
			var mesh: MeshInstance3D = p["mesh"]
			mesh.position = p["pos"]

			# Fade out
			var life_ratio: float = float(p["life"]) / float(p["max_life"])
			var mat := mesh.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color.a = life_ratio
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.emission_energy_multiplier = 2.5 * life_ratio

			# Shrink
			var s: float = life_ratio * 0.8 + 0.2
			mesh.scale = Vector3(s, s, s)

		if trails and p["trail_mesh"]:
			var pts: PackedVector3Array = p["trail_points"]
			pts.append(p["pos"])
			p["trail_points"] = pts
			_update_trail_mesh(p["trail_mesh"] as MeshInstance3D, pts, p["color"])

		if p["life"] <= 0:
			dead_indices.append(i)

	# Clean up dead particles
	for i in range(dead_indices.size() - 1, -1, -1):
		var p: Dictionary = _particles[dead_indices[i]]
		if p["mesh"]:
			(p["mesh"] as MeshInstance3D).queue_free()
		if p["trail_mesh"]:
			(p["trail_mesh"] as MeshInstance3D).queue_free()
		_particles.remove_at(dead_indices[i])


## BENCH ONLY. Detonate one shell at the apex and hand-integrate it to
## bench_moment in fixed steps, all inside _ready, so the figure is already final
## when the capture rig's 0.35 s AABB pre-pass measures it — a burst that arrives
## later would be framed for a launch tube. Then freeze, so the shutter cannot
## catch a different instant for each value.
func _bench_detonate() -> void:
	var rocket := {
		"pos": Vector3(0.0, launch_height, 0.0),
		"colors": (_presets[_current_preset][1] as Array),
		"pattern": _shell_name(),
		"mesh": null,
		"trail_mesh": null,
	}
	_explode(rocket)
	var step: float = 1.0 / 60.0
	var elapsed: float = 0.0
	while elapsed < bench_moment:
		_integrate_particles(step)
		elapsed += step
	_frozen = true

func _update_trail_mesh(mesh: MeshInstance3D, points: PackedVector3Array, color: Color) -> void:
	if points.size() < 2:
		return
	# Keep last TRAIL_POINTS points
	while points.size() > TRAIL_POINTS:
		points.remove_at(0)

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(points.size()):
		var alpha := float(i) / float(points.size()) * 0.6
		im.surface_set_color(Color(color.r, color.g, color.b, alpha))
		im.surface_add_vertex(points[i])
	im.surface_end()
	mesh.mesh = im

	# Built once per trail rather than once per frame: the parameters never vary,
	# and sixty star trails would otherwise allocate sixty materials a tick.
	if mesh.material_override == null:
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat

func _update_info() -> void:
	if not is_instance_valid(_info_label):
		return
	_info_label.text = "FIREWORKS — %s\nParticles: %d  Rockets: %d" % [
		(_presets[_current_preset][0] as String),
		_particles.size(),
		_rockets.size()
	]

func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 14
	_info_label.position = Vector3(0, launch_height + 0.8, 0)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.outline_size = 3
	_info_label.outline_modulate = Color.BLACK
	_info_label.text = "FIREWORK LAUNCHER"
	add_child(_info_label)

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("FIREWORKS", [
		[
			{"type": "button", "label": "CLASSIC"},
			{"type": "button", "label": "OCEAN"},
			{"type": "button", "label": "GARDEN"},
			{"type": "button", "label": "RING"},
		],
		[
			{"type": "button", "label": "FIRE!"},
			{"type": "slider_h", "label": "BURST", "default": 0.5},
		],
	])
	_control_panel.position = Vector3(0, 0.02, 0.3)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	# Preset buttons. They still set BOTH the palette and the shell, so the room
	# behaves exactly as it did — pressing RING still gives a ring. What changed
	# is that a map can now ask for a shell without also asking for a colour.
	for i in 4:
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var idx: int = i
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): _select_preset(idx))

	# Fire button (Btn_4)
	var fire_btn: Node = _control_panel.find_child("Btn_4", true, false)
	if fire_btn:
		var fire_area = fire_btn.get_node_or_null("InteractableAreaButton")
		if fire_area:
			fire_area.button_pressed.connect(func(_b): _launch_firework())

	# Burst slider
	var force_slider: Node = _control_panel.find_child("Param_0", true, false)
	if force_slider and force_slider.has_signal("slider_moved"):
		force_slider.slider_moved.connect(func(_pos):
			if force_slider.has_method("get_normalized_value"):
				burst_force = 1.0 + force_slider.get_normalized_value() * 7.0
		)


## A preset is a palette AND a shell, exactly as it always was. The only change
## is that the shell now lands in an export a map can also write.
func _select_preset(index: int) -> void:
	_current_preset = clampi(index, 0, _presets.size() - 1)
	shell = str(_presets[_current_preset][2])

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE: _launch_firework()
			KEY_1: _select_preset(0)
			KEY_2: _select_preset(1)
			KEY_3: _select_preset(2)
			KEY_4: _select_preset(3)
			KEY_A: _auto_launch = not _auto_launch

func reset() -> void:
	# Clean up all particles and rockets
	for p in _particles:
		if p["mesh"]:
			(p["mesh"] as MeshInstance3D).queue_free()
		if p["trail_mesh"]:
			(p["trail_mesh"] as MeshInstance3D).queue_free()
	_particles.clear()
	for r in _rockets:
		if r["mesh"]:
			(r["mesh"] as MeshInstance3D).queue_free()
		if r["trail_mesh"]:
			(r["trail_mesh"] as MeshInstance3D).queue_free()
	_rockets.clear()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## GUARDED. Config can arrive before _ready (the grid stamps it on the node it is
## about to add) or after. Only a word this file knows, and only one that DIFFERS
## from the one it holds, is taken — and even then nothing is torn down, because
## `shell` is read at detonation and the next burst simply obeys the new one. The
## force_pad fault was rebuilding on any call at all, including calls naming
## nothing it owns. None of the 5 mentions of this token in map_data passes a
## shell key.
##
## burst_seed, bench_stage and bench_moment are deliberately not accepted here:
## all three are consumed in _ready and honouring them afterwards would mean
## re-detonating a burst that is already in the air.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	if config.has("shell"):
		var want: String = str(config["shell"]).strip_edges().to_lower()
		if SHELLS.has(want):
			shell = want
		else:
			push_warning("firework_launcher: unknown shell '%s' — keeping '%s'" % [want, shell])
	if config.has("star_trails"):
		var t: String = str(config["star_trails"]).strip_edges().to_lower()
		if t == "on" or t == "off":
			star_trails = t
