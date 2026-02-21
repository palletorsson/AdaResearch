# StickTool.gd
# A simple wooden stick the player can grab in VR.
# Hold it near a PlasmaCritter → plasma attaches to the tip, becomes a torch.
# The stick is the mediator between player and plasma — the relational bridge.
#
# Extends XRToolsPickable so XR Tools' FunctionPickup can detect and grab it.
# XRToolsPickable provides: pick_up(), let_go(), can_pick_up(), is_picked_up()
extends XRToolsPickable
class_name StickTool

# ── Configuration ──────────────────────────────────────────────────────────
@export var stick_length: float = 0.8
@export var stick_radius: float = 0.02
@export var stick_color: Color = Color(0.35, 0.22, 0.1)  # Dark wood
@export var tip_glow_when_ready: bool = true

# ── State ──────────────────────────────────────────────────────────────────
var attached_plasma: PlasmaCritter = null
var is_held: bool = false

# ── Visual nodes ───────────────────────────────────────────────────────────
var _mesh: MeshInstance3D = null
var _tip: Marker3D = null
var _tip_indicator: MeshInstance3D = null
var _collision_shape: CollisionShape3D = null

# ── Signals ────────────────────────────────────────────────────────────────
signal plasma_attached(plasma: PlasmaCritter)
signal plasma_detached()

# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	super()

	_build_stick()
	_setup_physics()

	add_to_group("stick")
	add_to_group("tool")

	# Connect XRToolsPickable signals for held state tracking
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

	print("[StickTool] Ready at %s" % global_position)

func _process(_delta: float) -> void:
	# Subtle glow at tip when no plasma is attached (inviting interaction)
	if tip_glow_when_ready and _tip_indicator:
		_tip_indicator.visible = attached_plasma == null

# ═══════════════════════════════════════════════════════════════════════════
# STICK IDENTITY (called by PlasmaCritter to detect sticks)
# ═══════════════════════════════════════════════════════════════════════════

func is_stick() -> bool:
	return true

func receive_plasma(plasma: PlasmaCritter) -> void:
	if attached_plasma != null:
		return  # Already carrying plasma

	attached_plasma = plasma

	# Listen for plasma depletion
	if plasma.has_signal("plasma_depleted"):
		if not plasma.plasma_depleted.is_connected(_on_plasma_depleted):
			plasma.plasma_depleted.connect(_on_plasma_depleted)

	plasma_attached.emit(plasma)
	print("[StickTool] Plasma attached: %s" % PlasmaCritter.Form.keys()[plasma.current_form])

func release_plasma() -> void:
	if attached_plasma == null:
		return

	var old_plasma: PlasmaCritter = attached_plasma
	attached_plasma = null

	if is_instance_valid(old_plasma) and old_plasma.has_signal("plasma_depleted"):
		if old_plasma.plasma_depleted.is_connected(_on_plasma_depleted):
			old_plasma.plasma_depleted.disconnect(_on_plasma_depleted)

	plasma_detached.emit()
	print("[StickTool] Plasma released")

func _on_plasma_depleted() -> void:
	release_plasma()

# ═══════════════════════════════════════════════════════════════════════════
# VISUAL CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════════

func _build_stick() -> void:
	# Stick mesh — wooden cylinder
	_mesh = MeshInstance3D.new()
	_mesh.name = "StickMesh"
	var cyl := CylinderMesh.new()
	cyl.top_radius = stick_radius * 0.8  # Slightly tapered
	cyl.bottom_radius = stick_radius
	cyl.height = stick_length
	_mesh.mesh = cyl

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = stick_color
	wood_mat.roughness = 0.85
	wood_mat.metallic = 0.0
	_mesh.material_override = wood_mat
	add_child(_mesh)

	# Tip marker — where plasma attaches
	_tip = Marker3D.new()
	_tip.name = "Tip"
	_tip.position = Vector3(0, stick_length * 0.5, 0)  # Top of stick
	add_child(_tip)

	# Tip glow indicator (small sphere, subtle)
	_tip_indicator = MeshInstance3D.new()
	_tip_indicator.name = "TipGlow"
	var tip_sphere := SphereMesh.new()
	tip_sphere.radius = 0.025
	tip_sphere.height = 0.05
	_tip_indicator.mesh = tip_sphere

	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = Color(0.8, 0.6, 0.3, 0.5)
	tip_mat.emission_enabled = true
	tip_mat.emission = Color(1.0, 0.7, 0.3)
	tip_mat.emission_energy_multiplier = 0.8
	tip_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_tip_indicator.material_override = tip_mat
	_tip.add_child(_tip_indicator)

func _setup_physics() -> void:
	# Physics properties
	mass = 0.3
	gravity_scale = 1.0
	linear_damp = 1.0
	angular_damp = 2.0

	# Collision shape — capsule matching the stick
	_collision_shape = CollisionShape3D.new()
	_collision_shape.name = "StickCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = stick_radius * 2.5  # Slightly larger for easier grabbing
	capsule.height = stick_length
	_collision_shape.shape = capsule
	add_child(_collision_shape)

	# Collision layers: Layer 3 (pickable) so XR Tools FunctionPickup detects it
	collision_layer = 0b0000_0000_0000_0000_0000_0000_0000_0100  # Layer 3
	collision_mask = 1  # Collide with world

# ═══════════════════════════════════════════════════════════════════════════
# XR-TOOLS PICKABLE CALLBACKS
# XRToolsPickable emits picked_up/dropped signals — we listen for them.
# ═══════════════════════════════════════════════════════════════════════════

func _on_picked_up(_pickable) -> void:
	is_held = true
	print("[StickTool] Picked up")

func _on_dropped(_pickable) -> void:
	is_held = false
	print("[StickTool] Dropped")

# ═══════════════════════════════════════════════════════════════════════════
# GRID INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)

func configure(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	if config_data.has("length"):
		stick_length = _cfg_float(config_data["length"], stick_length)
	if config_data.has("radius"):
		stick_radius = _cfg_float(config_data["radius"], stick_radius)

func _cfg_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var text: String = str(value).strip_edges()
	if text.is_valid_float():
		return float(text)
	return fallback
