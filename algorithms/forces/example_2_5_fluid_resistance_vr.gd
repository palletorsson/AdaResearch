# ===========================================================================
# NOC Example 2.5: Fluid Resistance
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing -> GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================
#
# @identity
# essence: F_drag = -C * |v|^2 * v-hat. Drag opposes motion and scales with speed squared. Heavier objects fall faster through the same fluid.
# desire: To drop five balls of different masses into a blue fluid and watch the heavy ones punch through while the light ones float — mass as privilege in a resistive medium.
# critical_parameter: drag_coefficient — higher C means thicker fluid. It determines terminal velocity and how quickly the fluid swallows kinetic energy.
# triggers: VR sliders → adjust drag/gravity/depth in real time, Space → scatter movers sideways, R → reset, drag arrows appear when movers enter fluid
# emerges: Terminal velocity — each mover reaches a speed where gravity and drag balance. Heavier movers reach higher terminal velocity. The cyan drag arrows grow with speed.
# needs: VR rack panel with three sliders [has], drag arrow visualization [has], auto-reset timer [has]. Missing: density comparison overlay.
# relationships: Force decomposition like normal_force_demo. Lives in ForcesFoundations. Feeds into particle_systems (particles with drag). Contrasts with force_fields (area-based vs velocity-based forces).
# truth: Drag is the medium's memory of your velocity. The faster you move, the harder the world pushes back.

extends Node3D

## STAGE-2 DNA PROMOTION (2026-07-29).
##
## The three sliders on the rack turn the LAW (drag, gravity, depth). Nothing could turn
## the EXPERIMENT. Two things were hard-coded that carry the whole argument:
##
##   mass_spread  the bodies dropped into the fluid   ladder · uniform · extreme
##   medium       what the fluid IS                   basin · layered · ambient
##
## mass_spread is the demo's own claim, made falsifiable. "Heavier objects fall faster
## through the same fluid" is only visible against a control: `uniform` drops five
## IDENTICAL bodies, so they descend together and the separation you saw before is
## proved to have been mass, not the medium. `extreme` splits the five into two castes
## and states the same claim in its harshest reading — mass as privilege.
##
## medium asks whether resistance is a place you enter or a condition you are in.
## `basin` is a box with a surface: there is a before and an after, and the drag arrows
## switch on at the boundary. `layered` gives the fluid an inside — the lower half is
## denser, so terminal velocity stops being a property of the object and becomes a
## property of where in the medium the object is. `ambient` removes the boundary: no
## surface, no entry, drag everywhere from the first frame, nothing to fall INTO.
##
## mass_spread=ladder, medium=basin is the pre-promotion behaviour EXACTLY — same five
## masses, same spawn points, same single box, same material — and it is the default, so
## the 6 existing placements are unchanged.
##
## Usage in map_data.json:
##   "example_2_5_fluid_resistance_vr#mass_spread:uniform"
##   "example_2_5_fluid_resistance_vr#medium:layered#mass_spread:extreme"

## The bodies dropped into the fluid. ladder = the graded 0.6..2.6 ramp (legacy
## default); uniform = five identical bodies, the control that proves mass did it;
## extreme = three light and two heavy, two castes in one medium.
@export_enum("ladder", "uniform", "extreme") var mass_spread: String = "ladder"
## What the fluid is. basin = one box with a surface to cross (legacy default);
## layered = a denser lower half, so depth changes the law; ambient = no boundary at
## all, drag everywhere, nothing to enter.
@export_enum("basin", "layered", "ambient") var medium: String = "basin"

const DEFAULT_GRAVITY := 0.9
const DEFAULT_DRAG_COEFF := 0.8
const DEFAULT_FLUID_DEPTH := 0.45
const ARROW_LENGTH_SCALE := 0.6
const MIN_ARROW_LENGTH := 0.08
const MAX_ARROW_LENGTH := 0.9

# The three mass populations. Same length and same spawn points in every case, so only
# the masses differ — which is the point of having a control at all.
const MASS_LADDER := [0.6, 1.0, 1.4, 2.0, 2.6]
const MASS_UNIFORM := [1.4, 1.4, 1.4, 1.4, 1.4]
const MASS_EXTREME := [0.4, 0.5, 0.6, 2.8, 3.4]
# How much thicker the lower half of a layered medium is.
const LAYER_DENSITY := 2.5

var movers: Array[Mover] = []
var mover_labels: Dictionary = {}
var drag_visuals: Dictionary = {}
var mover_initial_positions: Dictionary = {}

var gravity_strength: float = DEFAULT_GRAVITY
var drag_coefficient: float = DEFAULT_DRAG_COEFF
var fluid_depth: float = DEFAULT_FLUID_DEPTH
var fluid_surface_y: float = -0.05

# UI — Ada rack panel
var _panel: ForcesRackPanel
var _drag_slider: Node3D
var _gravity_slider: Node3D
var _depth_slider: Node3D

var fluid_volume: MeshInstance3D
var fluid_volume_lower: MeshInstance3D
var auto_reset_timer: Timer
var _built: bool = false

# Where the five bodies are released. Identical across every mass_spread, so the only
# difference between the populations is what they weigh.
var spawn_positions: Array = [
	Vector3(-0.3, 0.35, 0.0),
	Vector3(-0.15, 0.38, 0.0),
	Vector3(0.0, 0.4, 0.0),
	Vector3(0.15, 0.42, 0.0),
	Vector3(0.3, 0.44, 0.0)
]

func _ready() -> void:
	_read_grid_config_meta()

	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	create_fluid_volume()
	_create_panel()
	spawn_movers()
	setup_auto_reset()
	_built = true
	print("Example 2.5: Fluid resistance")

# --- DNA (stage 2) -----------------------------------------------------------

## THE ONLY PATH THAT REACHES THIS SCRIPT FROM A MAP.
##
## This scene's root is an UNSCRIPTED Node3D — the whole NOC forces family is shaped
## root -> FishTank -> Demo, and this script sits on the grandchild. The grid calls
## apply_grid_config() on the ROOT, which has no such method, so that call never arrives
## here. What the grid DOES do unconditionally is write every #key:value token onto the
## root as `config_<key>` metadata, and it does so BEFORE the scene enters the tree —
## so the metadata is already in place when this _ready() runs. Walk up and read it.
##
## Costs nothing when no token is present: the exports keep their defaults and not a
## single existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_mass_spread"):
			mass_spread = str(node.get_meta("config_mass_spread"))
		if node.has_meta("config_medium"):
			medium = str(node.get_meta("config_medium"))
		node = node.get_parent()

## The masses this placement drops. See MASS_LADDER / MASS_UNIFORM / MASS_EXTREME.
func _masses() -> Array:
	if mass_spread == "uniform":
		return MASS_UNIFORM
	if mass_spread == "extreme":
		return MASS_EXTREME
	return MASS_LADDER

## Drag is not one number once the medium has an inside. In a layered medium the lower
## half resists more, so the same body has two terminal velocities depending on depth.
func _drag_coefficient_at(world_position: Vector3) -> float:
	if medium == "layered" and world_position.y < fluid_surface_y - fluid_depth * 0.5:
		return drag_coefficient * LAYER_DENSITY
	return drag_coefficient

func setup_auto_reset() -> void:
	auto_reset_timer = Timer.new()
	auto_reset_timer.wait_time = 20.0
	auto_reset_timer.autostart = true
	auto_reset_timer.timeout.connect(reset_scene)
	add_child(auto_reset_timer)

func _process(_delta: float) -> void:
	pass  # Slider labels auto-update

func _physics_process(_delta: float) -> void:
	for mover in movers:
		if not is_instance_valid(mover):
			continue

		var gravity_force: Vector3 = Vector3(0, -gravity_strength * mover.mass, 0)
		mover.apply_force(gravity_force)

		var drag_force: Vector3 = compute_drag_force(mover)
		mover.apply_force(drag_force)

		update_drag_visual(mover, drag_force)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_scene()
			KEY_SPACE:
				spread_movers()

## The visible box. In a basin it IS the fluid; in a layered medium it is the thin half.
func _upper_size() -> Vector3:
	if medium == "layered":
		return Vector3(0.9, fluid_depth * 0.5, 0.9)
	return Vector3(0.9, fluid_depth, 0.9)

func _upper_position() -> Vector3:
	if medium == "layered":
		return Vector3(0, fluid_surface_y - fluid_depth * 0.25, 0)
	return Vector3(0, fluid_surface_y - fluid_depth * 0.5, 0)

func _surface_label_text() -> String:
	if medium == "ambient":
		return "No surface — medium everywhere"
	if medium == "layered":
		return "Fluid surface (dense below)"
	return "Fluid surface"

## Ada accent_blue tinted translucent fluid. alpha/energy are the only things that
## differ between a layer and the whole basin.
func _fluid_material(alpha: float, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.55, 0.95, alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.6
	material.metallic = 0.0
	material.emission_enabled = true
	material.emission = Color(0.20, 0.55, 0.95)
	material.emission_energy_multiplier = energy
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func create_fluid_volume() -> void:
	if medium != "ambient":
		fluid_volume = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = _upper_size()
		fluid_volume.mesh = mesh
		fluid_volume.position = _upper_position()
		fluid_volume.material_override = _fluid_material(0.20, 0.25)
		add_child(fluid_volume)

	if medium == "layered":
		# The dense half. Same water, twice the resistance — depth becomes a law.
		fluid_volume_lower = MeshInstance3D.new()
		var lower_mesh: BoxMesh = BoxMesh.new()
		lower_mesh.size = Vector3(0.9, fluid_depth * 0.5, 0.9)
		fluid_volume_lower.mesh = lower_mesh
		fluid_volume_lower.position = Vector3(0, fluid_surface_y - fluid_depth * 0.75, 0)
		fluid_volume_lower.material_override = _fluid_material(0.45, 0.5)
		add_child(fluid_volume_lower)

	# Surface label — clean, non-billboard
	var surface_label := Label3D.new()
	surface_label.name = "FluidSurfaceLabel"
	surface_label.text = _surface_label_text()
	surface_label.font_size = 14
	surface_label.pixel_size = 0.001
	surface_label.modulate = Color(0.20, 0.55, 0.95, 1.0)
	surface_label.outline_size = 0
	surface_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	surface_label.position = Vector3(0, fluid_surface_y + 0.02, -0.38)
	add_child(surface_label)

func _create_panel() -> void:
	_panel = ForcesRackPanel.new()
	_panel.setup("2.5  Fluid Resistance", 3, 3)
	_panel.set_instructions("[SPACE] Scatter movers  [R] Reset")

	_drag_slider = _panel.add_slider("Drag", 0.05, 1.5, drag_coefficient, 0.01)
	_drag_slider.slider_moved.connect(_on_drag_slider_moved)

	_gravity_slider = _panel.add_slider("Gravity", 0.3, 2.0, gravity_strength, 0.05)
	_gravity_slider.slider_moved.connect(_on_gravity_slider_moved)

	_depth_slider = _panel.add_slider("Depth", 0.15, 0.9, fluid_depth, 0.02)
	_depth_slider.slider_moved.connect(_on_depth_slider_moved)

	# Position panel to the left, at chest height, angled toward viewer
	_panel.position = Vector3(-0.55, 0.35, 0.15)
	_panel.rotation_degrees = Vector3(0, 30, 0)
	add_child(_panel)

func spawn_movers() -> void:
	clear_existing_movers()

	var masses: Array = _masses()

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(spawn_positions.size()):
		var spawn_point: Vector3 = spawn_positions[i]
		var mover := Mover.new()
		mover.mass = float(masses[i])
		mover.position_v = spawn_point
		mover.velocity = Vector3.ZERO
		mover.acceleration = Vector3.ZERO
		mover.bounce_damping = 0.4
		add_child(mover)
		mover.set_size(0.03 + mover.mass * 0.01)

		var random_color := Color(
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.4, 0.7),
			rng.randf_range(0.8, 1.0)
		)
		mover.set_color(random_color)

		movers.append(mover)
		mover_initial_positions[mover] = spawn_point

		var arrow := create_drag_arrow()
		mover.add_child(arrow)
		drag_visuals[mover] = arrow

func clear_existing_movers() -> void:
	for mover in movers:
		if is_instance_valid(mover):
			mover.queue_free()
	movers.clear()
	mover_labels.clear()
	drag_visuals.clear()
	mover_initial_positions.clear()


func create_drag_arrow() -> Node3D:
	var arrow_root := Node3D.new()
	arrow_root.name = "DragArrow"
	arrow_root.visible = false

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var shaft_mesh: CylinderMesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.005
	shaft_mesh.bottom_radius = 0.005
	shaft_mesh.height = 1.0
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0, -0.5)
	shaft.rotation_degrees = Vector3(90, 0, 0)
	shaft.material_override = _create_drag_arrow_material()
	arrow_root.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh: CylinderMesh = CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.02
	head_mesh.height = 0.08
	head.mesh = head_mesh
	head.position = Vector3(0, 0, -1.0)
	head.rotation_degrees = Vector3(90, 0, 0)
	head.material_override = _create_drag_arrow_material()
	arrow_root.add_child(head)

	return arrow_root

func _create_drag_arrow_material() -> StandardMaterial3D:
	# Use Ada accent_cyan for drag arrows
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.00, 0.78, 0.85, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.00, 0.78, 0.85)
	mat.emission_energy_multiplier = 0.4
	return mat

func compute_drag_force(mover: Mover) -> Vector3:
	if not is_instance_valid(mover):
		return Vector3.ZERO

	var in_fluid = is_inside_fluid(mover.position_v)
	if not in_fluid:
		return Vector3.ZERO

	var speed: float = mover.velocity.length()
	if speed < 0.01:
		return Vector3.ZERO

	var drag_mag: float = _drag_coefficient_at(mover.position_v) * speed * speed
	var drag_force = -mover.velocity.normalized() * drag_mag

	return drag_force

func is_inside_fluid(position: Vector3) -> bool:
	if medium == "ambient":
		# No boundary: there is no outside to be in. Drag from the first frame.
		return true
	var bottom: float = fluid_surface_y - fluid_depth
	return position.y <= fluid_surface_y and position.y >= bottom

func update_drag_visual(mover: Mover, drag_force: Vector3) -> void:
	var arrow: Node3D = drag_visuals.get(mover, null)
	if not arrow or not is_instance_valid(arrow):
		return

	var magnitude: float = drag_force.length()
	if magnitude < 0.01:
		arrow.visible = false
		return

	arrow.visible = true
	var length: float = clamp(magnitude * ARROW_LENGTH_SCALE, MIN_ARROW_LENGTH, MAX_ARROW_LENGTH)

	var shaft: Node = arrow.get_node("Shaft") if arrow.has_node("Shaft") else null
	var head: Node = arrow.get_node("Head") if arrow.has_node("Head") else null

	if shaft and shaft is MeshInstance3D:
		shaft.scale = Vector3(1, 1, length)
		shaft.position = Vector3(0, 0, -length * 0.5)

	if head and head is MeshInstance3D:
		head.position = Vector3(0, 0, -length)
		head.scale = Vector3(1, 1, clamp(length * 0.4, 0.3, 0.9))

	var direction: Vector3 = -drag_force.normalized()
	var up_vector := Vector3.UP
	if abs(direction.dot(up_vector)) > 0.95:
		up_vector = Vector3.RIGHT
	var basis := Basis().looking_at(direction, up_vector)
	arrow.transform = Transform3D(basis, Vector3.ZERO)

func update_fluid_volume() -> void:
	if is_instance_valid(fluid_volume):
		var mesh: Mesh = fluid_volume.mesh
		if mesh is BoxMesh:
			(mesh as BoxMesh).size = _upper_size()
		fluid_volume.position = _upper_position()

	if is_instance_valid(fluid_volume_lower):
		var lower_mesh: Mesh = fluid_volume_lower.mesh
		if lower_mesh is BoxMesh:
			(lower_mesh as BoxMesh).size = Vector3(0.9, fluid_depth * 0.5, 0.9)
		fluid_volume_lower.position = Vector3(0, fluid_surface_y - fluid_depth * 0.75, 0)

	var surface_label := get_node("FluidSurfaceLabel") if has_node("FluidSurfaceLabel") else null
	if surface_label and surface_label is Label3D:
		(surface_label as Label3D).position = Vector3(0, fluid_surface_y + 0.02, -0.38)

func reset_scene() -> void:
	drag_coefficient = DEFAULT_DRAG_COEFF
	gravity_strength = DEFAULT_GRAVITY
	fluid_depth = DEFAULT_FLUID_DEPTH
	if _panel:
		_panel.set_slider_value(0, drag_coefficient)
		_panel.set_slider_value(1, gravity_strength)
		_panel.set_slider_value(2, fluid_depth)
	spawn_movers()
	update_fluid_volume()

func spread_movers() -> void:
	var rng := RandomNumberGenerator.new()
	for mover in movers:
		if not is_instance_valid(mover):
			continue
		mover.velocity += Vector3(rng.randf_range(-0.2, 0.2), 0.0, rng.randf_range(-0.2, 0.2))

func _on_drag_slider_moved(_position) -> void:
	drag_coefficient = _panel.get_slider_value(0)

func _on_gravity_slider_moved(_position) -> void:
	gravity_strength = _panel.get_slider_value(1)
	for mover in movers:
		if is_instance_valid(mover):
			mover.velocity = Vector3.ZERO

func _on_depth_slider_moved(_position) -> void:
	fluid_depth = _panel.get_slider_value(2)
	update_fluid_volume()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Config from map_data.json tokens: #mass_spread:uniform#medium:layered
##
## GUARDED. Rebuilds only what actually CHANGED, and only after _ready has built once.
## An unguarded respawn here would re-drop the movers of every shipped placement — and
## rebuilding the medium mid-flight would strand them outside their own fluid.
func apply_grid_config(config: Dictionary) -> void:
	var respawn: bool = false
	var remake_medium: bool = false

	if config.has("mass_spread"):
		var want_spread: String = str(config["mass_spread"])
		if want_spread != mass_spread:
			mass_spread = want_spread
			respawn = true

	if config.has("medium"):
		var want_medium: String = str(config["medium"])
		if want_medium != medium:
			medium = want_medium
			remake_medium = true

	if not _built:
		return
	if remake_medium:
		_rebuild_medium()
	if respawn:
		spawn_movers()

func _rebuild_medium() -> void:
	if is_instance_valid(fluid_volume):
		remove_child(fluid_volume)
		fluid_volume.queue_free()
	fluid_volume = null

	if is_instance_valid(fluid_volume_lower):
		remove_child(fluid_volume_lower)
		fluid_volume_lower.queue_free()
	fluid_volume_lower = null

	if has_node("FluidSurfaceLabel"):
		var old_label: Node = get_node("FluidSurfaceLabel")
		remove_child(old_label)
		old_label.queue_free()

	create_fluid_volume()
