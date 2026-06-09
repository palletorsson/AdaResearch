# @identity
# essence: mode(curriculum_progress) -> hand_force(type) -- a held tool that evolves through the curriculum
# desire: an evolving hand force tracking player progression, from slow cubes to swarm intelligence
# critical_parameter: current_mode_index / unlocked_modes -- curriculum stage determines the tool's current power
# triggers: XRToolsPickable grab/release; mode cycling through unlocked abilities; curriculum progression unlocks
# emerges: the tool that grows with the learner -- same object, different capability at each understanding stage
# needs: XRToolsPickable [has]; mode system [has]; fire cooldown [has]; curriculum tracking [has]
# relationships: companion to loving_triangle (tool + atom pair); embodies Q-FEP progression across all sequences
# truth: the catalyst does not change the world -- it changes what the holder can do in the world.

# BecomingCatalyst.gd
# The Becoming Catalyst — an evolving hand force that grows with the curriculum.
# Not a weapon of destruction but a tool of transformation, becoming, and
# boundary dissolution.  Each Lab sequence unlocks a new expressive mode.
#
# Pickup behavior: the crystal shrinks into the hand and is absorbed.
# The hand permanently gains its power — trigger fires projectiles.
# The crystal is consumed. The hand is free to grab other things.
#
# QFEP arc: from order (primitives) through entropy (randomness) to the
# edge of chaos (fractals, L-systems) and collective emergence (swarm).
extends XRToolsPickable
class_name BecomingCatalyst

# ── Mode Definitions ──────────────────────────────────────────────────────
# Each entry maps a mode_id to its metadata and factory script.
const MODE_DEFS: Array[Dictionary] = [
	{"id": "voxel_editor",   "order": 0,  "name": "Voxel Editor",   "sequence": "",                   "script": "res://commons/hazards/becoming_catalyst/modes/mode_voxel_editor.gd"},
	{"id": "wedge_placer",   "order": 0,  "name": "Wedge Placer",  "sequence": "",                   "script": "res://commons/hazards/becoming_catalyst/modes/mode_wedge_placer.gd"},
	{"id": "artifact_edit",  "order": 0,  "name": "Edit",           "sequence": "",                   "script": ""},
	{"id": "lab_edit",       "order": 0,  "name": "Lab",            "sequence": "",                   "script": ""},
	{"id": "biome_brush",    "order": 0,  "name": "Biome Brush",    "sequence": "",                   "script": "res://commons/hazards/becoming_catalyst/modes/mode_biome_brush.gd"},
	{"id": "modifier",       "order": 0,  "name": "Modifier",       "sequence": "",                   "script": "res://commons/hazards/becoming_catalyst/modes/mode_modifier.gd"},
	# ADDITIVE: in-headset editing of the utilities layer (spawn/teleporter/ramp/door/…).
	# No factory script — dispatched inline in _physics_process (mirrors the biome block).
	{"id": "utility_edit",   "order": 0,  "name": "Utility",        "sequence": "",                   "script": ""},
	{"id": "primitives",     "order": 1,  "name": "Primitives",     "sequence": "primitives",         "script": "res://commons/hazards/becoming_catalyst/modes/mode_primitives.gd"},
	{"id": "transformation", "order": 2,  "name": "Transformation", "sequence": "transformation",     "script": "res://commons/hazards/becoming_catalyst/modes/mode_transformation.gd"},
	{"id": "chromatic",      "order": 3,  "name": "Chromatic",      "sequence": "color",              "script": "res://commons/hazards/becoming_catalyst/modes/mode_chromatic.gd"},
	{"id": "forces",         "order": 4,  "name": "Forces",         "sequence": "forces",             "script": "res://commons/hazards/becoming_catalyst/modes/mode_forces.gd"},
	{"id": "waveform",       "order": 6,  "name": "Waveform",       "sequence": "wavefunctions",      "script": "res://commons/hazards/becoming_catalyst/modes/mode_waveform.gd"},
	{"id": "chaos",          "order": 7,  "name": "Chaos",          "sequence": "randomness",         "script": "res://commons/hazards/becoming_catalyst/modes/mode_chaos.gd"},
	{"id": "fractal",        "order": 10, "name": "Fractal",        "sequence": "fractals",           "script": "res://commons/hazards/becoming_catalyst/modes/mode_fractal.gd"},
	{"id": "cellular",       "order": 9,  "name": "Cellular",       "sequence": "cellularautomata",   "script": "res://commons/hazards/becoming_catalyst/modes/mode_cellular.gd"},
	{"id": "branching",      "order": 11, "name": "Branching",      "sequence": "lsystems",           "script": "res://commons/hazards/becoming_catalyst/modes/mode_branching.gd"},
	{"id": "swarm",          "order": 14, "name": "Swarm",          "sequence": "swarmintelligence",  "script": "res://commons/hazards/becoming_catalyst/modes/mode_swarm.gd"},
]

# ── State ─────────────────────────────────────────────────────────────────
var unlocked_modes: Array[String] = ["voxel_editor", "wedge_placer", "artifact_edit", "lab_edit", "biome_brush", "modifier", "utility_edit", "off"]
var current_mode_index: int = 0
var fire_cooldown: float = 0.0
var is_held: bool = false
var _absorbed: bool = false
var controller: XRController3D = null
var _pickup_controller_name: String = ""  # Remember which controller picked us up

# Mode switching debounce
var _stick_debounce: float = 0.0
const STICK_THRESHOLD := 0.7
const STICK_COOLDOWN := 0.5  # Short cooldown — smooth lerp handles the visual transition

# Voxel editing (tool mode)
var _voxel_controller: VoxelEditController = null
var _voxel_active: bool = false
# Biome Brush (tool mode) — paints biome density on the floor; B saves paint_layers.
# preload (NOT the global class_name) so the type resolves regardless of the
# script-class cache load order at runtime — the class_name isn't yet registered
# when this script parses on a fresh game load.
const BiomeBrushControllerClass = preload("res://commons/hazards/becoming_catalyst/BiomeBrushController.gd")
var _biome_brush: BiomeBrushControllerClass = null
# Left-hand Tilt-Brush-style menu (viewport_2d_in_3d) — choose element + brush size.
const BiomeMenuViewport = preload("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
const BiomeMenuUIScene = preload("res://commons/hazards/becoming_catalyst/biome_brush_menu_ui.tscn")
var _biome_menu: Node = null         # viewport_2d_in_3d on the off hand
var _biome_menu_ui: Control = null   # the 2D menu Control inside it
var _voxel_data_component: Node = null  # holds current map name, for B-to-save

# ── Unified Tabbed Editor Panel (ADDITIVE — step 3 of the VR editor) ──────────
# A SECOND left-wrist viewport_2d_in_3d holding TabbedEditorPanel: GRID · ARTIFACT
# · MODIFIER · BIOME tabs. Tapping a tab drives the bracelet mode (no rotation);
# tool buttons set live edit state; the GRID tab paints small (<=4x4) strokes
# through the existing voxel controller + GridOps. Mounted ALONGSIDE the biome
# menu — neither replaces the other. See doc/VR_EDITING_SYSTEM.md.
const EditorPanelViewport = preload("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
const EditorPanelUIScene = preload("res://commons/hazards/becoming_catalyst/tabbed_editor_panel.tscn")
const GridOpsLib = preload("res://commons/modifiers/grid_ops.gd")
var _editor_panel: Node = null          # viewport_2d_in_3d on the off hand
var _editor_panel_ui: Control = null    # the TabbedEditorPanel Control inside it
# Re-entrancy guard: when the GRID tab's tool buttons (structure vs paint) flip
# the bracelet mode, the resulting _sync_editor_panel_tab() can re-fire the
# panel's tab_changed → _on_editor_tab_changed and fight the mode we just set.
# Set true around our own mode flips so the tab-changed handler no-ops.
var _editor_tab_routing: bool = false
# Live GRID tool state driven by the panel. Defaults are chosen so the GRID tab
# is a no-op-vs-original until the player touches the panel: op "add" + brush 1
# means the first trigger goes straight to the legacy single-cube _handle_voxel_add.
var _active_grid_op: String = "add"
var _active_brush_size: int = 1
var _active_grid_level: int = 3
# Live MODIFIER colour driven by the panel's palette (used by colorize).
var _active_modifier_color: Color = Color(0.88, 0.54, 0.16)
# True once the panel has supplied a colour — only then does colorize override
# the original cycling MODIFIER_PALETTE (keeps non-panel behaviour byte-identical).
var _modifier_color_from_panel: bool = false
# Voxel activation retry (grid may not be ready on map transition)
var _voxel_activate_retries: int = 0
const VOXEL_MAX_RETRIES := 10
const VOXEL_RETRY_DELAY := 0.3  # seconds between retries
# B-save POSTs the edited structure to the PC encyclopedia, which writes it into
# the repo's map_data.json. On the headset this reaches the PC over
# `adb reverse tcp:3003 tcp:3003`.
const MAP_SAVE_URL := "http://localhost:3003/api/game/save-layers"

# Head raycast (Minecraft style) — look where you want to place
var _xr_camera: XRCamera3D = null
var _xr_origin: XROrigin3D = null

# Wedge placement — placed prisms stored for removal
var _placed_wedges: Array[Dictionary] = []  # {node, grid_x, grid_z, direction}
var _wedge_ghost: MeshInstance3D = null
var _wedge_ghost_dir: float = 0.0  # Y rotation in degrees

# Modifier mode (additive) — each touch appends one op to this non-destructive
# stack (the map_data.json `modifiers` array shape). Trigger cycles colorize ->
# random_colors -> normalize/clear; B saves the stack to disk; grip undoes (pop).
# See commons/modifiers/modifier_stack.gd + doc/BRACELET_GARDEN_MODIFIERS.md.
const ModifierStackLib = preload("res://commons/modifiers/modifier_stack.gd")
var _modifier_stack: Array = []
var _modifier_op_index: int = 0  # 0=colorize, 1=random_colors, 2=normalize/clear
const MODIFIER_OPS: Array[String] = ["colorize", "random_colors", "normalize"]
const MODIFIER_PALETTE: Array = [
	"#e08a2a", "#3aa0e0", "#7ad06a", "#e05a8a", "#d0c23a", "#9a6ae0", "#e0e0e0",
]
var _modifier_palette_index: int = 0

# ── Utility Edit mode (ADDITIVE) ──────────────────────────────────────────
# Edits the utilities layer (map_data.layers.utilities[row][col]="<code>") in VR,
# mirroring the desktop GridEditorDesktop3D utility CRUD. Reuses the shared voxel
# controller's targeted cell (target_cell) for the (x,z) to edit, and the live
# GridUtilitiesComponent (_place_utility / utility_objects) for zero-drift spawn.
# Tracked in-memory so B can rebuild + POST the whole utilities layer.
var _vr_util_code: String = "s"            # active utility type (panel sets it)
var _vr_util_op: String = "ADD"            # active op: ADD / MOVE / ROTATE / REMOVE
var _vr_utilities_comp: Node = null        # cached GridUtilitiesComponent (live spawn path)
var _vr_utilities: Array = []              # in-memory utilities layer (rows[z][x]="<code>")
var _vr_utilities_seeded_map: String = ""  # map name _vr_utilities was seeded from ("" = never)
var _vr_util_trigger_was_down: bool = false  # debounce: one trigger pull = one op
var _vr_util_move_picked: bool = false     # MOVE: have we picked a cell yet?
var _vr_util_move_token: String = ""       # MOVE: the held utility token
var _vr_util_move_from: Vector2i = Vector2i(-1, -1)  # MOVE: source cell (row, col)
var _vr_util_ghost: MeshInstance3D = null  # simple cell ghost in utility_edit mode

# Artifact Edit mode — laser-grab existing artifacts and move/rotate/snap them
var _edit_target: Node3D = null        # artifact under the laser (not grabbed)
var _edit_grabbed: Node3D = null       # artifact currently being moved
var _edit_grab_offset: Transform3D = Transform3D.IDENTITY  # controller→artifact at grab
var _edit_trigger_was_down: bool = false
var _edit_highlight: MeshInstance3D = null
var _edit_is_lab: bool = false  # lab_edit mode → surface-magnetism for lab props
var _lab_surfaces: Array = []   # cached other-prop tops (room-local) for table-stacking
var _held_aabb: AABB = AABB()   # the grabbed prop's own AABB (prop-local), for flush offset
const LAB_SNAP_DIST := 0.25     # m: within this of a surface, the prop sticks flush
const LAB_SAVE_URL := "http://localhost:3003/api/labs/save"
const EDIT_MAX_RANGE := 8.0
const EDIT_RAY_RADIUS := 0.6  # how close to the laser line an artifact must be
const EDIT_HOLD_DISTANCE := 1.5  # how far in front of the hand a grabbed artifact floats
const EDIT_MAX_Y_LEVEL := 6  # artifacts can float up to this grid level when dropped in air

# Tip marker — where projectiles spawn
var _tip: Marker3D = null
var _mode_label: Label3D = null
var _mode_label_timer: float = 0.0
var _collision_shape: CollisionShape3D = null

# Held glow
var _held_glow: OmniLight3D = null
var _pickup_tween: Tween = null

# ── Signals ───────────────────────────────────────────────────────────────
signal mode_changed(mode_id: String)
signal mode_unlocked(mode_id: String)
signal projectile_fired(mode_id: String, position: Vector3)

# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	super()

	_setup_physics()
	_build_tip()
	_build_mode_label()
	_load_unlocked_modes()

	add_to_group("catalyst")
	add_to_group("tool")

	# XRToolsPickable signals
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

	# Glow light (visible only when held)
	_held_glow = OmniLight3D.new()
	_held_glow.name = "HeldGlow"
	_held_glow.light_color = Color(0.7, 0.7, 1.0)
	_held_glow.light_energy = 0.0
	_held_glow.omni_range = 0.8
	_held_glow.omni_attenuation = 2.0
	add_child(_held_glow)

	# Build initial visual
	_rebuild_visual()

	# Try to connect to progression managers
	call_deferred("_connect_progression_signals")

	print("[Catalyst] Ready — modes: %s" % [unlocked_modes])

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	_stick_debounce = maxf(0.0, _stick_debounce - delta)

	# Mode label — always visible when held, shows current mode + index.
	# top_level label lives in world space; keep it hovering above the hand.
	if is_held and _mode_label:
		if is_instance_valid(controller):
			_mode_label.global_position = controller.global_position + Vector3(0.0, 0.18, 0.0)
		if _mode_label_timer > 0.0:
			_mode_label_timer -= delta
			# After the flash period, show a dimmer persistent label
			if _mode_label_timer <= 0.0:
				var mode_def := _get_current_mode_def()
				_mode_label.text = mode_def.get("name", "")
				_mode_label.modulate = CatalystVisual.get_mode_color(mode_def.get("id", "")).darkened(0.3)
				_mode_label.modulate.a = 0.6  # Dimmer but still visible
		_mode_label.visible = true
	elif _mode_label:
		_mode_label.visible = false

	# Hand glow pulse — the absorbed power breathes
	if is_held and _held_glow:
		var pulse := 1.5 + sin(Time.get_ticks_msec() / 400.0) * 0.5
		_held_glow.light_energy = pulse

	# Update cardinal neighbor targeting (shared by voxel + wedge modes)
	_update_voxel_raycast()

	# ADDITIVE: keep the unified tabbed editor panel shown/hidden per mode. Runs
	# alongside the biome menu's own show/hide below — neither overrides the other.
	_update_editor_panel_visibility()

	# Update mode-specific ghost preview
	var _cur_mode_id := ""
	if current_mode_index >= 0 and current_mode_index < unlocked_modes.size():
		_cur_mode_id = unlocked_modes[current_mode_index]
	if _cur_mode_id == "wedge_placer":
		_update_wedge_ghost()
		# Hide voxel ghosts when in wedge mode
		if _voxel_controller:
			if _voxel_controller._ghost_add:
				_voxel_controller._ghost_add.visible = false
			if _voxel_controller._ghost_remove:
				_voxel_controller._ghost_remove.visible = false
	else:
		if _wedge_ghost:
			_wedge_ghost.visible = false

	# Artifact Edit / Lab modes — laser-grab artifacts, move, snap on release.
	# artifact_edit → grid (map) artifacts; lab_edit → lab props (net 0.1m snap).
	if is_held and (_cur_mode_id == "artifact_edit" or _cur_mode_id == "lab_edit"):
		_edit_is_lab = (_cur_mode_id == "lab_edit")
		_update_edit_mode(delta)
	elif _edit_target != null or _edit_grabbed != null or (_edit_highlight and _edit_highlight.visible):
		_end_edit_mode()

	# Biome Brush — point at the floor, trigger paints / grip erases the active
	# element's density; on release the biome rebuilds live. B saves paint_layers.
	if is_held and _cur_mode_id == "biome_brush":
		_ensure_biome_brush()
		# ONE INTERFACE: when the unified editor panel is present it owns the biome
		# UI (its BIOME tab), so don't build or show the separate biome menu. The
		# biome brush itself (painting below) is untouched — only the 2nd panel is
		# suppressed. Without the unified panel, the legacy wrist menu still shows.
		if _editor_panel and is_instance_valid(_editor_panel):
			if _biome_menu and is_instance_valid(_biome_menu):
				_biome_menu.visible = false
		else:
			_ensure_biome_menu()
			if _biome_menu:
				_biome_menu.visible = true
		if controller:
			var b_origin: Vector3 = controller.global_position
			var b_fwd: Vector3 = -controller.global_transform.basis.z
			var b_paint: bool = controller.is_button_pressed("trigger_click")
			var b_erase: bool = controller.is_button_pressed("grip_click")
			_biome_brush.update(b_origin, b_fwd, b_paint, b_erase)
		# Hide voxel ghosts while painting biome.
		if _voxel_controller:
			if _voxel_controller._ghost_add:
				_voxel_controller._ghost_add.visible = false
			if _voxel_controller._ghost_remove:
				_voxel_controller._ghost_remove.visible = false
	elif _biome_brush:
		_biome_brush.set_idle()
		if _biome_menu:
			_biome_menu.visible = false

	# Utility Edit — point at a cell (shared voxel target_cell), trigger applies the
	# active op (ADD/REMOVE/ROTATE/MOVE) on the utilities layer. Mirrors the desktop
	# utility CRUD; debounced so one trigger pull = one op. B saves the layer.
	if is_held and _cur_mode_id == "utility_edit":
		_update_utility_edit()
	elif _vr_util_ghost and is_instance_valid(_vr_util_ghost):
		_vr_util_ghost.visible = false

	# Mode switching disabled on controller thumbstick — use the bracelet instead

# ═════════════════════════════════════════════════════════════════════════
# FIRING
# ═════════════════════════════════════════════════════════════════════════

## Called by XRToolsFunctionPickup when the trigger is pressed while held.
## Pre-absorption: do nothing — the catalyst must absorb first before firing.
## Post-absorption: never called because let_go() releases from FunctionPickup.
func action() -> void:
	super()

## Controller button handler.
## Mode switching is done by the OTHER hand grabbing and rotating the bracelet hinge.
## This handler only deals with firing/voxel actions on the catalyst hand.
##
## A/X = fire projectile OR add cube (voxel mode)
## B/Y = remove cube (voxel mode only)
## Trigger = add cube (voxel mode) — in other modes trigger is XRTools grab
## Grip = NOT used here — grip is for the OTHER hand grabbing the bracelet
##
func _on_controller_button(button_name: String) -> void:
	var mode_def := _get_current_mode_def()
	var mode_id: String = mode_def.get("id", "") if not mode_def.is_empty() else ""

	# Biome Brush intercepts its buttons before the firing/voxel dispatch:
	# trigger/grip painting is POLLED in _process; Ax cycles the element; By saves.
	# (The early return prevents trigger_click from falling through to _fire().)
	if mode_id == "biome_brush":
		match button_name:
			"ax_button":
				if _biome_brush:
					_biome_brush.cycle_element()
					if _biome_menu_ui and _biome_menu_ui.has_method("set_selected_element"):
						_biome_menu_ui.set_selected_element(_biome_brush.active_element())
					_flash_label("BRUSH: " + _biome_brush.active_element().to_upper(), Color(0.6, 0.95, 0.7))
			"by_button":
				_save_biome()
		return

	# Modifier mode intercepts its buttons before the firing/voxel dispatch
	# (additive — mirrors the biome_brush early-return so trigger never falls
	# through to _fire()). trigger = apply the active op on the targeted cell;
	# Ax = cycle the op (colorize/random/clear); grip = undo (pop); By = save.
	if mode_id == "modifier":
		match button_name:
			"trigger_click":
				if not _is_hand_busy():
					_handle_modifier_apply()
			"ax_button":
				_cycle_modifier_op()
			"grip_click":
				_handle_modifier_undo()
			"by_button":
				_save_modifiers()
		return

	# Utility Edit mode intercepts its buttons before the firing/voxel dispatch
	# (additive — mirrors the biome_brush / modifier early-returns so trigger never
	# falls through to _fire()). trigger = apply the active op (POLLED + debounced in
	# _update_utility_edit, so the event itself is a no-op here); Ax = cycle the op;
	# grip = cancel an in-flight MOVE; By = save the utilities layer.
	if mode_id == "utility_edit":
		match button_name:
			"ax_button":
				_cycle_vr_utility_op()
			"grip_click":
				if _vr_util_move_picked:
					_cancel_vr_utility_move()
					_flash_label("MOVE CANCELLED", Color(1.0, 0.8, 0.4))
			"by_button":
				_save_utilities()
		return

	match button_name:
		"ax_button", "trigger_click":
			match mode_id:
				"voxel_editor":
					# ADDITIVE: route through the panel-driven stroke dispatcher.
					# It falls back to the original single-cube _handle_voxel_add()
					# whenever no panel op is in play (brush 1 + "add").
					_handle_grid_stroke(true)
				"wedge_placer":
					_handle_wedge_add()
				"artifact_edit", "lab_edit":
					pass  # grab/move handled by polling in _update_edit_mode
				_:
					if not _is_hand_busy():
						_fire()
		"grip_click":
			match mode_id:
				"voxel_editor":
					# ADDITIVE: panel-driven remove stroke (brush footprint); falls
					# back to the original single-cube _handle_voxel_remove().
					_handle_grid_stroke(false)
				"wedge_placer":
					_handle_wedge_remove()
		"by_button":
			# B = save the edited grid back to the repo's map_data.json.
			print("[Catalyst] B (by_button) pressed — mode=%s" % mode_id)
			match mode_id:
				"voxel_editor", "wedge_placer", "artifact_edit":
					_save_map()
				"lab_edit":
					_save_lab()
				_:
					_flash_label("B SAVES IN EDIT/VOXEL MODE", Color(1.0, 0.8, 0.3))


## Voxel mode: trigger/AX = ADD cube on the cardinal neighbor you're facing.
func _handle_voxel_add() -> void:
	if not _voxel_controller or not _voxel_controller.has_target:
		return
	_voxel_controller.try_add()
	fire_cooldown = 0.15
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.2, 0.0)


## Voxel mode: grip = REMOVE cube.
func _handle_voxel_remove() -> void:
	if not _voxel_controller:
		return
	_voxel_controller.try_remove()
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.3, 0.0)


## ADDITIVE — panel-driven GRID stroke. `is_primary` true = trigger/AX (add side),
## false = grip (remove side). Brushes a small <=4x4 footprint through GridOps.
##
## Preserves the ORIGINAL single-cube behaviour: when the active op is plain
## add/remove AND the brush is 1x1, this just delegates to _handle_voxel_add /
## _handle_voxel_remove (no behavioural change vs. before this panel existed).
##
## For larger brushes and the height ops (fill/raise/randomize/ground/checker/
## frame/ring/smooth) it builds a height-model over the footprint, runs the pure
## GridOps stroke, and writes each resulting height back via set_height_at —
## which is safe because GridStructureComponent rebuilds its MultiMesh from the
## layout on every set (instance_count is reallocated, not a fixed buffer).
func _handle_grid_stroke(is_primary: bool) -> void:
	if not _voxel_controller or not _voxel_controller.has_target:
		# Nothing targeted — keep the original no-op contract.
		return
	var brush: int = clampi(_active_brush_size, 1, 4)

	# ── GRIP side: ALWAYS remove (legacy contract). At brush 1 this delegates to
	# the original single-cube _handle_voxel_remove, byte-identical to before. At
	# brush >1 it removes across the footprint. The panel op never changes what
	# grip does — grip is the eraser.
	if not is_primary:
		if brush <= 1:
			_handle_voxel_remove()
			return
		_grid_footprint_stack("remove", brush)
		return

	# ── TRIGGER side: drive by the active panel op ──
	var op_name := _active_grid_op

	# Plain add at brush 1 → original single-cube placement (legacy feel preserved).
	if op_name == "add" and brush <= 1:
		_handle_voxel_add()
		return
	# Explicit remove/erase op on the trigger → footprint remove (or single cube).
	if op_name == "remove" or op_name == "erase":
		if brush <= 1:
			_handle_voxel_remove()
		else:
			_grid_footprint_stack("remove", brush)
		return
	# Footprint add.
	if op_name == "add":
		_grid_footprint_stack("add", brush)
		return

	# ── Height ops (fill/raise/randomize/ground/checker/frame/ring/smooth) ──
	var structure: GridStructureComponent = _voxel_controller.structure_component
	if structure == null:
		# Can't reach the heightfield — degrade to a plain add so the button isn't dead.
		_handle_voxel_add()
		return
	var grid_op_name := op_name
	match op_name:
		"fill": grid_op_name = "fill"
		"raise": grid_op_name = "raise"
		"randomize": grid_op_name = "randomize"
		"ground": grid_op_name = "ground_plane"
		"checker": grid_op_name = "checker"
		"frame": grid_op_name = "frame"
		"ring": grid_op_name = "ring"
		"smooth": grid_op_name = "smooth"
		_:
			# Unknown op — degrade to a plain add rather than do nothing.
			_grid_footprint_stack("add", brush)
			return
	# Centre the footprint on the cube being faced (target_cell). GridOps cell
	# model is Vector2i(row, col) = (grid z, grid x).
	var tc: Vector3i = _voxel_controller.target_cell
	if tc.x < 0 or tc.z < 0:
		return
	var center := Vector2i(tc.z, tc.x)
	var cells: Array = GridOpsLib.brush_cells(center, brush)
	# Build a height-model over the footprint from the CURRENT layout.
	var base: Dictionary = {}
	for rc in cells:
		var hz: int = int(rc[0])
		var hx: int = int(rc[1])
		base[Vector2i(hz, hx)] = structure.get_height_at(hx, hz)
	var params: Dictionary = {"value": clampi(_active_grid_level, 0, GridOpsLib.MAX_H)}
	var op_seed: int = Time.get_ticks_msec()
	var result: Dictionary = GridOpsLib.stroke(base, grid_op_name, center, brush, params, op_seed)
	# Write each resulting height back. set_height_at rebuilds the MultiMesh.
	for k in result.keys():
		structure.set_height_at(int(k.y), int(k.x), int(result[k]))
	fire_cooldown = 0.15
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.06, 0.3, 0.0)
	_flash_label("%s %dx%d" % [op_name.to_upper(), brush, brush], Color(0.45, 0.75, 1.0))


## ADDITIVE — apply a plain add/remove stack op across the brush footprint via
## the existing VoxelEditController. Drives each cell with set_target_direct +
## try_add/try_remove (the same primitives the single-cube path uses), then
## restores live targeting. Footprint is centred on the faced cell (add → the
## empty add_cell so new cubes appear in front of you; remove → target_cell).
func _grid_footprint_stack(kind: String, brush: int) -> void:
	if _voxel_controller == null or not _voxel_controller.has_target:
		return
	var center_cell: Vector3i = _voxel_controller.add_cell if kind == "add" else _voxel_controller.target_cell
	if center_cell.x < 0 or center_cell.z < 0:
		return
	# GridOps cell model is Vector2i(row, col) = (grid z, grid x).
	var center := Vector2i(center_cell.z, center_cell.x)
	var cells: Array = GridOpsLib.brush_cells(center, clampi(brush, 1, 4))
	var saved_target: Vector3i = _voxel_controller.target_cell
	var saved_add: Vector3i = _voxel_controller.add_cell
	for rc in cells:
		var cz: int = int(rc[0])
		var cx: int = int(rc[1])
		_voxel_controller.set_target_direct(Vector3i(cx, 0, cz), Vector3i(cx, 0, cz))
		if kind == "add":
			_voxel_controller.try_add()
		else:
			_voxel_controller.try_remove()
	# Restore the live target so ghosts/raycast stay coherent until next frame.
	_voxel_controller.set_target_direct(saved_target, saved_add)
	fire_cooldown = 0.15
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.05, 0.25, 0.0)
	_flash_label("%s %dx%d" % [kind.to_upper(), brush, brush], Color(0.45, 0.75, 1.0))


# ═════════════════════════════════════════════════════════════════════════
# MODIFIER MODE — colorize / random / clear grid cells (additive)
# Each touch records one op on a non-destructive stack (the map_data.json
# `modifiers` array shape) and applies it live via the ModifierStack. B saves
# the stack to disk; on load GridSystem re-applies it. Reaches the targeted cell
# through the shared voxel controller's target_cell (the top cube being faced).
# ═════════════════════════════════════════════════════════════════════════

## Ax = cycle the active op: colorize -> random_colors -> normalize(clear).
func _cycle_modifier_op() -> void:
	_modifier_op_index = (_modifier_op_index + 1) % MODIFIER_OPS.size()
	var op_name: String = MODIFIER_OPS[_modifier_op_index]
	var col := Color(0.6, 0.95, 0.7)
	match op_name:
		"colorize": col = Color(0.9, 0.7, 0.3)
		"random_colors": col = Color(0.5, 0.8, 1.0)
		"normalize": col = Color(0.8, 0.8, 0.85)
	_flash_label("MOD: " + op_name.to_upper(), col)
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.15, 0.0)


## The cell currently targeted by the shared voxel controller, as a modifier
## cell Vector2i(row, col) = (grid z, grid x). Returns Vector2i(-1,-1) if no
## valid target / no controller.
func _modifier_target_cell() -> Vector2i:
	if not _voxel_controller or not _voxel_controller.has_target:
		return Vector2i(-1, -1)
	var tc: Vector3i = _voxel_controller.target_cell
	if tc.x < 0 or tc.z < 0:
		return Vector2i(-1, -1)
	return Vector2i(tc.z, tc.x)  # (row, col)


## trigger = apply the active op to the targeted cell. Builds one op dict, appends
## it to the stack, and tints the cell live by recomputing its colour through the
## pure ModifierStack over a single-cell base.
func _handle_modifier_apply() -> void:
	var cell: Vector2i = _modifier_target_cell()
	if cell.x < 0 or cell.y < 0:
		_flash_label("AIM AT A CELL", Color(1.0, 0.7, 0.3))
		return
	var op_name: String = MODIFIER_OPS[_modifier_op_index]
	var op: Dictionary = {}
	match op_name:
		"colorize":
			# ADDITIVE: if the panel chose a swatch, use it; otherwise keep the
			# original cycling palette behaviour untouched.
			var hex: String = ""
			if _modifier_color_from_panel:
				hex = "#" + _active_modifier_color.to_html(false)
			else:
				hex = String(MODIFIER_PALETTE[_modifier_palette_index])
				_modifier_palette_index = (_modifier_palette_index + 1) % MODIFIER_PALETTE.size()
			op = {
				"op": "colorize",
				"target": {"cells": [[cell.x, cell.y]]},
				"params": {"color": hex},
			}
		"random_colors":
			op = {
				"op": "random_colors",
				"target": {"cells": [[cell.x, cell.y]]},
				"params": {"palette": "spectrum"},
				"seed": _modifier_stack.size(),
			}
		"normalize":
			op = {
				"op": "normalize",
				"target": {"cells": [[cell.x, cell.y]]},
				"params": {},
			}
	_modifier_stack.append(op)
	_apply_modifier_cell_live(cell)
	_flash_label("MOD %s  (%d)" % [op_name.to_upper(), _modifier_stack.size()], Color(0.6, 0.95, 0.7))
	fire_cooldown = 0.15
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.2, 0.0)


## grip = undo: pop the last op, then re-apply the whole stack's colours to every
## cell it ever touched (popped cells fall back to the structure's base tint).
func _handle_modifier_undo() -> void:
	if _modifier_stack.is_empty():
		_flash_label("NOTHING TO UNDO", Color(1.0, 0.6, 0.3))
		return
	_modifier_stack.pop_back()
	_reapply_modifier_stack_to_grid()
	_flash_label("UNDO  (%d)" % _modifier_stack.size(), Color(1.0, 0.8, 0.4))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.3, 0.0)


## Recompute one cell's colour from the full stack and push it to the grid.
func _apply_modifier_cell_live(cell: Vector2i) -> void:
	var structure := _get_edit_structure()
	if structure == null:
		return
	var base: Dictionary = {cell: {"height": 1, "color": ModifierStackLib.DEFAULT_COLOR}}
	var result: Dictionary = ModifierStackLib.apply(base, _modifier_stack)
	var out: Dictionary = result.get(cell, {})
	var col: Color = out.get("color", ModifierStackLib.DEFAULT_COLOR)
	if structure.has_method("set_cell_color"):
		structure.set_cell_color(cell, col)


## Re-apply the entire stack's colours to every cell any op has touched. Used by
## undo so popped cells revert. Cells that resolve to the default tint are reset
## to that default (the structure's neutral grey) rather than left stale.
func _reapply_modifier_stack_to_grid() -> void:
	var structure := _get_edit_structure()
	if structure == null or not structure.has_method("set_cell_color"):
		return
	# Gather every cell referenced by any op in the stack (their `target.cells`).
	var touched: Dictionary = {}  # Vector2i -> true
	for op in _modifier_stack:
		if typeof(op) != TYPE_DICTIONARY:
			continue
		var target = op.get("target", null)
		if typeof(target) == TYPE_DICTIONARY and target.has("cells"):
			for rc in target["cells"]:
				if typeof(rc) == TYPE_ARRAY and rc.size() >= 2:
					touched[Vector2i(int(rc[0]), int(rc[1]))] = true
	if touched.is_empty():
		return
	# Build a base over exactly those cells and run the (possibly shortened) stack.
	var base: Dictionary = {}
	for k in touched.keys():
		base[k] = {"height": 1, "color": ModifierStackLib.DEFAULT_COLOR}
	var result: Dictionary = ModifierStackLib.apply(base, _modifier_stack)
	for k in touched.keys():
		var out: Dictionary = result.get(k, {})
		var col: Color = out.get("color", ModifierStackLib.DEFAULT_COLOR)
		structure.set_cell_color(k, col)


## B button = SAVE the edited grid back to the repo's map_data.json.
## Writes only the structure layer (the cubes you placed/removed); utilities,
## interactables, lighting and settings are preserved untouched. Edit the map
## inside VR, press B, and the change lands on disk in the repo.
func _save_map() -> void:
	print("[Catalyst] _save_map() called")
	# Map name from the live grid data — works in voxel mode AND edit mode.
	var data := _get_grid_data_component()
	var map_name := ""
	if data and data.has_method("get_current_map_name"):
		map_name = data.get_current_map_name()
	if map_name == "":
		push_warning("[Catalyst] B-save aborted — no current map name")
		_flash_label("NO MAP NAME", Color(1.0, 0.4, 0.3))
		return
	# Structure layer only when we're actually voxel-editing cubes. In Edit mode
	# (artifacts) there's no voxel controller — we save placements only, leaving
	# the structure layer on disk untouched.
	var layout: Array = []
	if _voxel_controller and _voxel_controller.structure_component:
		var structure: GridStructureComponent = _voxel_controller.structure_component
		# Local write — editor only; res:// is read-only on a packaged/Quest build.
		if not OS.has_feature("android"):
			VoxelSaveManager.save(map_name, structure)
		layout = structure.get_editable_layout()
	var placements := _collect_vr_placements()
	if layout.is_empty() and placements.is_empty():
		_flash_label("NOTHING TO SAVE", Color(1.0, 0.5, 0.2))
		return
	# HTTP POST to the PC — works on the headset over `adb reverse tcp:3003 tcp:3003`.
	_save_map_over_http(map_name, layout, placements)
	_flash_label("SAVING  " + map_name + " ...", Color(0.6, 0.85, 1.0))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.12, 0.4, 0.0)

## The live GridDataComponent — the one voxel mode cached, or a fresh lookup.
func _get_grid_data_component() -> Node:
	if _voxel_data_component and is_instance_valid(_voxel_data_component):
		return _voxel_data_component
	return _find_node_by_name(get_tree().root, "GridDataComponent")


## Flash a transient message on the held tool's mode label, then revert.
func _flash_label(text: String, color: Color) -> void:
	if not _mode_label:
		return
	_mode_label.text = text
	_mode_label.modulate = color
	_mode_label.modulate.a = 1.0
	_mode_label.visible = true
	_mode_label_timer = 2.0


## POST the edited structure to the PC's encyclopedia so it lands in the repo's
## map_data.json (preserving the other layers). On the headset this reaches the
## PC over `adb reverse tcp:3003 tcp:3003`.
## Collect artifacts placed/moved in VR (group "vr_placed_artifact") into a list
## of {x, z, token} cell placements that the save endpoint overlays onto the
## map's interactables layer. When an artifact has MOVED since it was last
## saved (or since it spawned, for existing artifacts), we first emit a CLEAR
## for its old cell so it doesn't leave a duplicate behind. Clears are emitted
## before sets so a clear can never wipe a freshly-set cell.
func _collect_vr_placements() -> Array:
	var clears: Array = []
	var sets: Array = []
	var structure := _get_edit_structure()
	var total_size: float = 1.0
	if structure:
		total_size = structure.cube_size + structure.gutter
	for node in get_tree().get_nodes_in_group("vr_placed_artifact"):
		if not is_instance_valid(node):
			continue
		var lookup := String(node.get_meta("artifact_lookup_name", ""))
		var cell: Vector2i = node.get_meta("grid_cell", Vector2i(-1, -1))
		if lookup == "" or cell.x < 0 or cell.y < 0:
			continue
		var rot := int(round(float(node.get_meta("grid_rotation_y", 0.0))))
		# Free-height drops: encode the vertical offset from the column top as the
		# token's y_position param, so the artifact reloads at the same level.
		var y_token := ""
		if structure and node.has_meta("grid_y_level"):
			var y_level: int = int(node.get_meta("grid_y_level", 0))
			var base: int = structure.find_highest_y_at(cell.x, cell.y)
			var y_off: float = float(y_level - base) * total_size
			if absf(y_off) > 0.001:
				y_token = String.num(y_off, 3).rstrip("0").rstrip(".")
		var token := lookup
		if y_token != "":
			token = "%s:%d:%s" % [lookup, rot, y_token]  # lookup:yaw:y_offset
		elif rot != 0:
			token = "%s:%d" % [lookup, rot]
		# Clear the previous cell if this artifact moved.
		var saved: Vector2i = node.get_meta("vr_saved_cell", Vector2i(-1, -1))
		if saved.x >= 0 and saved.y >= 0 and saved != cell:
			clears.append({"x": saved.x, "z": saved.y, "token": " "})
		sets.append({"x": cell.x, "z": cell.y, "token": token})
		# Remember where it now lives, so the next move can clear this cell.
		node.set_meta("vr_saved_cell", cell)
	return clears + sets


## POST the edited layers to the PC's save-layers endpoint. ADDITIVE 4th arg:
## `modifiers` — when non-empty it's sent as the top-level `modifiers` field so
## the modifier op-stack persists over the SAME adb-reverse tunnel as structure
## and placements (route.ts merges it non-destructively). Existing callers that
## omit `modifiers` behave exactly as before.
func _save_map_over_http(map_name: String, layout: Array, placements: Array = [], modifiers: Array = []) -> void:
	print("[Catalyst] POSTing '%s' (%d rows, %d placed artifacts, %d modifiers) -> %s" % [map_name, layout.size(), placements.size(), modifiers.size(), MAP_SAVE_URL])
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_map_save_completed.bind(http))
	var headers := PackedStringArray(["Content-Type: application/json"])
	var payload := {"mapName": map_name}
	if not layout.is_empty():
		payload["layers"] = {"structure": layout}
	if not placements.is_empty():
		payload["interactablePlacements"] = placements
	if not modifiers.is_empty():
		payload["modifiers"] = modifiers
	http.set_meta("map_name", map_name)
	var err := http.request(MAP_SAVE_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		http.queue_free()
		_flash_label("POST FAILED: %s" % error_string(err), Color(1.0, 0.3, 0.3))


func _on_map_save_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest) -> void:
	var mn := String(http.get_meta("map_name", ""))
	http.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		print("[Catalyst] B-save: '%s' written on the PC (HTTP %d)" % [mn, response_code])
		_flash_label("SAVED -> PC  " + mn, Color(0.4, 1.0, 0.6))
		if controller:
			controller.trigger_haptic_pulse("haptic", 0.0, 0.2, 0.6, 0.0)
	else:
		var hint := ""
		if result == HTTPRequest.RESULT_CANT_CONNECT:
			hint = "  (adb reverse tcp:3003 tcp:3003)"
		_flash_label("SAVE FAILED %d/%d%s" % [result, response_code, hint], Color(1.0, 0.35, 0.35))
		push_warning("[Catalyst] map save HTTP failed result=%d code=%d" % [result, response_code])

# ═══════════════════════════════════════════════════════════════════════════
# MODIFIER SAVE — write only the `modifiers` key into map_data.json (additive)
# ═══════════════════════════════════════════════════════════════════════════

## B (modifier / GRID-paint mode) = persist the modifier op-stack into the repo's
## map_data.json. Now POSTs the `modifiers` array over the SAME adb-reverse tunnel
## as structure + placements (/api/game/save-layers), which read-merges ONLY the
## top-level `modifiers` key — every other key is preserved. This works on the
## Quest (where res:// is read-only) exactly like the structure / biome saves.
func _save_modifiers() -> void:
	var data := _get_grid_data_component()
	var map_name := ""
	if data and data.has_method("get_current_map_name"):
		map_name = data.get_current_map_name()
	if map_name == "":
		_flash_label("NO MAP NAME", Color(1.0, 0.4, 0.3))
		return
	if _modifier_stack.is_empty():
		_flash_label("NOTHING TO SAVE", Color(1.0, 0.5, 0.2))
		return

	# Primary path: POST the stack to the PC (works on headset over adb reverse).
	# No structure/placements here — only the modifiers field, so the endpoint
	# touches just the `modifiers` key and leaves the rest of map_data.json intact.
	_save_map_over_http(map_name, [], [], _modifier_stack.duplicate(true))
	_flash_label("SAVING MODIFIERS  %s ..." % map_name, Color(0.6, 0.85, 1.0))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.12, 0.4, 0.0)


## Resolve a map name to its map_data.json path (mirrors GridDataComponent).
func _map_data_path_for(a_map_name: String) -> String:
	var maps_path := "res://commons/maps/"
	if a_map_name == "Lab":
		return maps_path + "Lab/map_data.json"
	if a_map_name.begins_with("Lab/"):
		return maps_path + "Lab/" + a_map_name.substr(4) + ".json"
	return maps_path + a_map_name + "/map_data.json"

# ═══════════════════════════════════════════════════════════════════════════
# BIOME BRUSH SAVE — POST paint_layers to the PC, same tunnel as map saves
# ═══════════════════════════════════════════════════════════════════════════

## B (biome_brush mode) = save the painted density fields to the repo's
## map_data.json `paint_layers[]` via /api/game/save-layers (merged by element,
## non-destructive). res:// is read-only on Quest, so it POSTs over the tunnel.
func _save_biome() -> void:
	if _biome_brush == null or not _biome_brush.has_strokes():
		_flash_label("NOTHING PAINTED", Color(1.0, 0.5, 0.2))
		return
	var data := _get_grid_data_component()
	var map_name := ""
	if data and data.has_method("get_current_map_name"):
		map_name = data.get_current_map_name()
	if map_name == "":
		_flash_label("NO MAP NAME", Color(1.0, 0.4, 0.3))
		return
	_save_biome_over_http(map_name, _biome_brush.paint_layers_payload())
	_flash_label("SAVING BIOME  " + map_name + " ...", Color(0.6, 0.85, 1.0))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.12, 0.4, 0.0)


func _save_biome_over_http(map_name: String, paint_layers: Array) -> void:
	print("[Catalyst] POSTing biome '%s' (%d paint layers) -> %s" % [map_name, paint_layers.size(), MAP_SAVE_URL])
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_map_save_completed.bind(http))  # reuse SAVED→PC flash
	var headers := PackedStringArray(["Content-Type: application/json"])
	var payload := {"mapName": map_name, "paintLayers": paint_layers}
	http.set_meta("map_name", map_name)
	var err := http.request(MAP_SAVE_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		http.queue_free()
		_flash_label("POST FAILED: %s" % error_string(err), Color(1.0, 0.3, 0.3))


# ═══════════════════════════════════════════════════════════════════════════
# BIOME BRUSH MENU — Tilt-Brush-style panel on the off hand (element + size)
# ═══════════════════════════════════════════════════════════════════════════

## The off-hand XRController3D (the one NOT holding the catalyst).
func _get_left_controller() -> XRController3D:
	if controller == null:
		return null
	var origin := controller.get_parent()
	if origin == null:
		return null
	for c in origin.get_children():
		if c is XRController3D and c != controller:
			return c as XRController3D
	return null


## The RIGHT-hand XRController3D. Mirrors _get_left_controller (walks the same
## XROrigin children) but resolves the right hand explicitly: first by the
## tracker StringName ("right_hand"), then by a node-name hint ("RightHand" /
## "Right" / "right"). Falls back to "any controller that isn't the catalyst's
## own" so the editor panel still mounts even on rigs that don't label hands.
## Additive — does not touch the left-hand lookup the biome menu relies on.
func _get_right_controller() -> XRController3D:
	if controller == null:
		return null
	var origin := controller.get_parent()
	if origin == null:
		return null
	var fallback: XRController3D = null
	for c in origin.get_children():
		if not (c is XRController3D):
			continue
		var xc := c as XRController3D
		# Tracker is the authoritative signal (StringName "right_hand").
		if String(xc.tracker) == "right_hand":
			return xc
		# Node-name hint as a secondary cue.
		var nm := String(xc.name).to_lower()
		if nm.find("right") != -1:
			return xc
		# Remember any non-catalyst controller as a last resort.
		if xc != controller:
			fallback = xc
	# If the catalyst is itself the right hand, mount on it (still a valid wrist).
	if String(controller.tracker) == "right_hand" or String(controller.name).to_lower().find("right") != -1:
		return controller
	return fallback


## Build the left-hand menu viewport once, on first biome_brush use.
func _ensure_biome_menu() -> void:
	if _biome_menu and is_instance_valid(_biome_menu):
		return
	var left := _get_left_controller()
	if left == null:
		return
	var vp = BiomeMenuViewport.instantiate()
	vp.name = "BiomeBrushMenu"
	vp.scene = BiomeMenuUIScene
	vp.screen_size = Vector2(0.22, 0.18)
	vp.viewport_size = Vector2(500, 420)
	# Tilted up off the wrist, toward the face — glanceable like Tilt Brush.
	vp.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-45)), Vector3(0.0, 0.05, -0.11))
	left.add_child(vp)
	_biome_menu = vp
	call_deferred("_connect_biome_menu", vp)


func _connect_biome_menu(vp: Node) -> void:
	for i in range(15):
		await get_tree().process_frame
		_biome_menu_ui = vp.get_scene_instance() if vp.has_method("get_scene_instance") else null
		if _biome_menu_ui:
			break
	if _biome_menu_ui == null:
		return
	if _biome_menu_ui.has_signal("element_selected") and not _biome_menu_ui.element_selected.is_connected(_on_biome_menu_element):
		_biome_menu_ui.element_selected.connect(_on_biome_menu_element)
	if _biome_menu_ui.has_signal("size_changed") and not _biome_menu_ui.size_changed.is_connected(_on_biome_menu_size):
		_biome_menu_ui.size_changed.connect(_on_biome_menu_size)
	if _biome_menu_ui.has_signal("pressure_changed") and not _biome_menu_ui.pressure_changed.is_connected(_on_biome_menu_pressure):
		_biome_menu_ui.pressure_changed.connect(_on_biome_menu_pressure)
	if _biome_menu_ui.has_signal("artifact_toggle_requested") and not _biome_menu_ui.artifact_toggle_requested.is_connected(_on_biome_menu_artifact):
		_biome_menu_ui.artifact_toggle_requested.connect(_on_biome_menu_artifact)
	print("[Catalyst] Biome menu connected")


## Create the biome brush on demand (idempotent) so the panel's BIOME tab can set the
## element/size/pressure BEFORE the first hold (the physics paint loop uses the same path).
## Without this, picking "tree" in the panel before pointing+holding was silently dropped
## and you'd paint the default element — reading as "can't edit the biome".
func _ensure_biome_brush() -> void:
	if _biome_brush == null:
		_biome_brush = BiomeBrushControllerClass.new()
		_biome_brush.name = "BiomeBrushCtrl"
		add_child(_biome_brush)
		_biome_brush.setup()
	elif ("_grid" in _biome_brush) and _biome_brush._grid == null and _biome_brush.has_method("setup"):
		_biome_brush.setup()   # an earlier setup ran before the map was ready — re-find the grid


func _on_biome_menu_element(element_name: String) -> void:
	_ensure_biome_brush()
	if _biome_brush:
		_biome_brush.set_element(element_name)
		if _biome_menu_ui and _biome_menu_ui.has_method("refresh_artifact_marks"):
			_biome_menu_ui.refresh_artifact_marks(_biome_brush.active_artifacts())
	_flash_label("BRUSH: " + element_name.to_upper(), Color(0.6, 0.95, 0.7))


func _on_biome_menu_artifact(artifact_name: String) -> void:
	if not _biome_brush:
		return
	var lst: Array = _biome_brush.toggle_artifact(artifact_name)
	if _biome_menu_ui and _biome_menu_ui.has_method("refresh_artifact_marks"):
		_biome_menu_ui.refresh_artifact_marks(lst)
	_flash_label("ARTIFACT: " + artifact_name, Color(0.85, 0.6, 0.95))


func _on_biome_menu_size(radius: int) -> void:
	_ensure_biome_brush()
	if _biome_brush:
		_biome_brush.set_radius(radius)


func _on_biome_menu_pressure(strength: float) -> void:
	_ensure_biome_brush()
	if _biome_brush:
		_biome_brush.set_strength(strength)


# ═══════════════════════════════════════════════════════════════════════════
# UNIFIED TABBED EDITOR PANEL (ADDITIVE) — left-wrist GRID/ARTIFACT/MODIFIER/BIOME
# Mirrors _ensure_biome_menu/_connect_biome_menu but mounts the TabbedEditorPanel
# on the left controller and wires its signals to the existing dispatch paths.
# Nothing here removes or alters the biome menu — both can coexist on the wrist.
# ═══════════════════════════════════════════════════════════════════════════

## Build the right-wrist tabbed editor viewport once, on first edit-mode use.
## The panel now mounts on the RIGHT controller (the biome menu stays on the
## left). Only the controller reference changed; the offset/scene are unchanged.
func _ensure_editor_panel() -> void:
	if _editor_panel and is_instance_valid(_editor_panel):
		return
	var right := _get_right_controller()
	if right == null:
		return
	var vp = EditorPanelViewport.instantiate()
	vp.name = "TabbedEditorPanelVP"
	vp.scene = EditorPanelUIScene
	vp.screen_size = Vector2(0.24, 0.22)
	vp.viewport_size = Vector2(540, 500)
	# Mirror the wrist offset to the right hand (x flipped) so it sits glanceable
	# above the right wrist, the way the biome menu sits above the left.
	vp.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-45)), Vector3(-0.14, 0.04, -0.11))
	right.add_child(vp)
	_editor_panel = vp
	call_deferred("_connect_editor_panel", vp)


## Wire every panel signal to a handler. Guarded: each connect checks has_signal
## and is_connected first, so a re-connect is a no-op.
func _connect_editor_panel(vp: Node) -> void:
	for i in range(15):
		await get_tree().process_frame
		_editor_panel_ui = vp.get_scene_instance() if vp.has_method("get_scene_instance") else null
		if _editor_panel_ui:
			break
	if _editor_panel_ui == null:
		return
	var ui := _editor_panel_ui
	if ui.has_signal("tab_changed") and not ui.tab_changed.is_connected(_on_editor_tab_changed):
		ui.tab_changed.connect(_on_editor_tab_changed)
	if ui.has_signal("grid_op_selected") and not ui.grid_op_selected.is_connected(_on_editor_grid_op):
		ui.grid_op_selected.connect(_on_editor_grid_op)
	if ui.has_signal("brush_size_changed") and not ui.brush_size_changed.is_connected(_on_editor_brush_size):
		ui.brush_size_changed.connect(_on_editor_brush_size)
	if ui.has_signal("level_changed") and not ui.level_changed.is_connected(_on_editor_level):
		ui.level_changed.connect(_on_editor_level)
	if ui.has_signal("modifier_op_selected") and not ui.modifier_op_selected.is_connected(_on_editor_modifier_op):
		ui.modifier_op_selected.connect(_on_editor_modifier_op)
	if ui.has_signal("color_selected") and not ui.color_selected.is_connected(_on_editor_color):
		ui.color_selected.connect(_on_editor_color)
	# BIOME tab reuses the existing biome handlers — just connect, no new logic.
	if ui.has_signal("element_selected") and not ui.element_selected.is_connected(_on_biome_menu_element):
		ui.element_selected.connect(_on_biome_menu_element)
	if ui.has_signal("size_changed") and not ui.size_changed.is_connected(_on_biome_menu_size):
		ui.size_changed.connect(_on_biome_menu_size)
	if ui.has_signal("pressure_changed") and not ui.pressure_changed.is_connected(_on_biome_menu_pressure):
		ui.pressure_changed.connect(_on_biome_menu_pressure)
	if ui.has_signal("artifact_action") and not ui.artifact_action.is_connected(_on_editor_artifact_action):
		ui.artifact_action.connect(_on_editor_artifact_action)
	# UTILITY tab — pick the active utility type + op (the host applies them on a
	# trigger press at the targeted cell). Guarded like every other connect above.
	if ui.has_signal("utility_type_changed") and not ui.utility_type_changed.is_connected(_on_editor_utility_type):
		ui.utility_type_changed.connect(_on_editor_utility_type)
	if ui.has_signal("utility_op_selected") and not ui.utility_op_selected.is_connected(_on_editor_utility_op):
		ui.utility_op_selected.connect(_on_editor_utility_op)
	# Sync the panel's active tab to whatever mode we're already in.
	_sync_editor_panel_tab()
	print("[Catalyst] Tabbed editor panel connected")


## Show the panel whenever an edit mode is active; hide in off/projectile modes.
## Called alongside the biome-menu show/hide so both stay in step.
func _update_editor_panel_visibility() -> void:
	var mode_def := _get_current_mode_def()
	var mode_id: String = mode_def.get("id", "") if not mode_def.is_empty() else ""
	var edit_modes: Array = ["voxel_editor", "wedge_placer", "artifact_edit", "lab_edit", "modifier", "biome_brush", "utility_edit"]
	if is_held and mode_id in edit_modes:
		_ensure_editor_panel()
		if _editor_panel:
			_editor_panel.visible = true
			# ONE INTERFACE: the panel's BIOME tab is now the biome UI. While the
			# unified panel is up, keep the SEPARATE biome menu hidden (handlers
			# stay wired — only the second 2D panel is suppressed). Additive.
			if _editor_panel.visible and _biome_menu and is_instance_valid(_biome_menu):
				_biome_menu.visible = false
	elif _editor_panel:
		_editor_panel.visible = false


## Push the current mode onto the panel's tab row (guarded, additive). The 3-tab
## panel folds structure + paint into GRID, so BOTH voxel_editor and modifier
## modes map to GRID; only the tabbed modes map to a tab, others leave it as-is.
func _sync_editor_panel_tab() -> void:
	if _editor_panel_ui == null or not is_instance_valid(_editor_panel_ui):
		return
	if not _editor_panel_ui.has_method("set_active_tab"):
		return
	var mode_def := _get_current_mode_def()
	var mode_id: String = mode_def.get("id", "") if not mode_def.is_empty() else ""
	var tab_id := ""
	match mode_id:
		"voxel_editor": tab_id = "GRID"
		"modifier": tab_id = "GRID"  # paint lives in the GRID tab now
		"artifact_edit": tab_id = "ARTIFACTS"
		"utility_edit": tab_id = "UTILITY"
		"biome_brush": tab_id = "BIOME"
	if tab_id != "":
		_editor_panel_ui.set_active_tab(tab_id)


## tab_changed → switch the bracelet mode via the EXISTING set_mode_index path.
## 3-tab panel: GRID folds structure + paint, so it lands on voxel_editor by
## default (PAINT ops re-route to "modifier" in _on_editor_modifier_op).
func _on_editor_tab_changed(tab_id: String) -> void:
	# Ignore tab_changed echoes triggered by our own grid-op mode routing —
	# the GRID tab maps to BOTH voxel_editor and modifier, so a re-sync to GRID
	# must not yank us back to voxel_editor mid-paint.
	if _editor_tab_routing:
		return
	var target_mode := ""
	match tab_id.to_upper():
		"GRID": target_mode = "voxel_editor"
		"ARTIFACTS": target_mode = "artifact_edit"
		"UTILITY": target_mode = "utility_edit"
		"BIOME": target_mode = "biome_brush"
	if target_mode == "":
		return
	var idx: int = unlocked_modes.find(target_mode)
	if idx < 0:
		_flash_label("MODE LOCKED: " + tab_id, Color(1.0, 0.6, 0.3))
		return
	if idx != current_mode_index:
		set_mode_index(idx)


## Flip the bracelet to `mode_id` via the EXISTING set_mode_index path, with the
## tab-routing guard raised so the resulting tab re-sync doesn't echo back into
## _on_editor_tab_changed and undo the switch. No-op if already in that mode or
## the mode isn't unlocked. Returns true if we are (now) in the requested mode.
func _route_bracelet_mode(mode_id: String) -> bool:
	var cur_def := _get_current_mode_def()
	var cur_id: String = cur_def.get("id", "") if not cur_def.is_empty() else ""
	if cur_id == mode_id:
		return true
	var idx: int = unlocked_modes.find(mode_id)
	if idx < 0:
		return false
	_editor_tab_routing = true
	set_mode_index(idx)
	_editor_tab_routing = false
	return true


## grid_op_selected (a STRUCTURE op) → make sure we're in voxel_editor mode so
## the next trigger runs the structure stroke, then remember the live op.
func _on_editor_grid_op(op: String) -> void:
	_route_bracelet_mode("voxel_editor")
	_active_grid_op = op
	_flash_label("GRID: " + op.to_upper(), Color(0.45, 0.75, 1.0))


## brush_size_changed → cap to 1..4 (local strokes only).
func _on_editor_brush_size(size: int) -> void:
	_active_brush_size = clampi(size, 1, 4)


## level_changed → target height for fill/raise/checker/etc.
func _on_editor_level(level: int) -> void:
	_active_grid_level = clampi(level, 0, GridOpsLib.MAX_H)


## modifier_op_selected (a PAINT op from the GRID tab) → switch the bracelet into
## "modifier" mode so painting works without leaving the GRID tab, then map the
## panel's op names onto the existing MODIFIER_OPS and sync _modifier_op_index.
##   panel "colorize" -> "colorize"; "random" -> "random_colors"; "clear" -> "normalize".
func _on_editor_modifier_op(op: String) -> void:
	_route_bracelet_mode("modifier")
	var mapped := op
	match op:
		"random": mapped = "random_colors"
		"clear": mapped = "normalize"
	var idx: int = MODIFIER_OPS.find(mapped)
	if idx >= 0:
		_modifier_op_index = idx
		_flash_label("MOD: " + mapped.to_upper(), Color(0.7, 0.55, 1.0))


## color_selected → live colour for the modifier colorize op.
func _on_editor_color(color: Color) -> void:
	_active_modifier_color = color
	_modifier_color_from_panel = true


## artifact_action — the panel's PREV/NEXT/PLACE buttons. The catalyst has no
## artifact-palette browser yet, so these are guarded stubs that flash a hint.
## (Wire to a real palette browser in a follow-up.)
func _on_editor_artifact_action(action: String) -> void:
	_flash_label("ARTIFACT " + action, Color(0.95, 0.7, 0.35))


# ═══════════════════════════════════════════════════════════════════════════
# UTILITY EDIT MODE (ADDITIVE) — edit the utilities layer in VR
# Mirrors the desktop GridEditorDesktop3D utility CRUD. Point at a cell (the
# shared voxel controller's target_cell), pick a TYPE + OP on the panel's UTILITY
# tab, and pull the trigger to apply: ADD places the type, REMOVE clears it,
# ROTATE bumps its facing +90°, MOVE picks-then-places. Spawns live through the
# real GridUtilitiesComponent (_place_utility / utility_objects) for zero drift,
# and tracks every edit in _vr_utilities so B can save the whole layer.
# ═══════════════════════════════════════════════════════════════════════════

## utility_type_changed → remember the active utility code (panel sends the bare
## code, e.g. "s"/"t"/"wp"). Switches the bracelet into utility_edit so the next
## trigger edits the utilities layer (mirrors _on_editor_grid_op's mode route).
func _on_editor_utility_type(code: String) -> void:
	_route_bracelet_mode("utility_edit")
	var c := code.strip_edges()
	if c != "":
		_vr_util_code = c
	_flash_label("UTIL: " + _util_friendly_code(_vr_util_code), Color(0.85, 0.5, 0.95))


## utility_op_selected → remember the active op (ADD/MOVE/ROTATE/REMOVE). Defaults
## to ADD for any unknown value. Switching op cancels an in-flight MOVE pick.
func _on_editor_utility_op(op: String) -> void:
	_route_bracelet_mode("utility_edit")
	var up := op.strip_edges().to_upper()
	if up != "ADD" and up != "MOVE" and up != "ROTATE" and up != "REMOVE":
		up = "ADD"
	if up != "MOVE":
		_cancel_vr_utility_move()
	_vr_util_op = up
	_flash_label("UTIL OP: " + up, Color(0.85, 0.5, 0.95))


## Ax convenience — cycle the active op ADD → MOVE → ROTATE → REMOVE without the
## panel. Cancels an in-flight MOVE when leaving it. Mirrors _on_editor_utility_op.
func _cycle_vr_utility_op() -> void:
	var ops: Array = ["ADD", "MOVE", "ROTATE", "REMOVE"]
	var idx: int = ops.find(_vr_util_op)
	if idx < 0:
		idx = 0
	idx = (idx + 1) % ops.size()
	var up: String = str(ops[idx])
	if up != "MOVE":
		_cancel_vr_utility_move()
	_vr_util_op = up
	_flash_label("UTIL OP: " + up, Color(0.85, 0.5, 0.95))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.15, 0.0)


## Per-frame utility_edit driver. Shows a ghost at the targeted cell and, on a
## trigger press-edge, applies the active op once (debounced). Reuses the shared
## voxel controller's target_cell — already updated every frame by
## _update_voxel_raycast (voxel mode is active in utility_edit, see set_mode_index).
func _update_utility_edit() -> void:
	if not is_instance_valid(controller):
		return
	# Resolve the faced cell from the shared voxel controller (Vector3i x,y,z).
	var col := -1
	var row := -1
	if _voxel_controller and _voxel_controller.has_target:
		var tc: Vector3i = _voxel_controller.target_cell
		if tc.x >= 0 and tc.z >= 0:
			col = tc.x
			row = tc.z
	_update_vr_utility_ghost(col, row)
	# Hide the voxel add/remove ghosts — the utility ghost is the preview here.
	if _voxel_controller:
		if _voxel_controller._ghost_add:
			_voxel_controller._ghost_add.visible = false
		if _voxel_controller._ghost_remove:
			_voxel_controller._ghost_remove.visible = false
	# Debounced trigger: one pull = one op.
	var trig_down: bool = controller.is_button_pressed("trigger_click")
	if trig_down and not _vr_util_trigger_was_down:
		if col >= 0 and row >= 0:
			_apply_vr_utility_op(col, row)
		else:
			_flash_label("AIM AT A CELL", Color(1.0, 0.7, 0.3))
	_vr_util_trigger_was_down = trig_down


## Apply the active op at column (x=col, z=row). Mirrors _utility_left_click on
## desktop. Every branch keeps _vr_utilities (the in-memory layer) in sync so the
## B-save reconstructs the correct whole layer.
func _apply_vr_utility_op(col: int, row: int) -> void:
	_ensure_vr_utilities_seeded()
	match _vr_util_op:
		"ADD": _vr_utility_add(col, row)
		"REMOVE": _vr_utility_remove(col, row)
		"ROTATE": _vr_utility_rotate(col, row)
		"MOVE": _vr_utility_move_click(col, row)
		_: _vr_utility_add(col, row)


## ADD: clear any occupant, write the type into the layer, and spawn it live.
func _vr_utility_add(col: int, row: int) -> void:
	if not _vr_util_cell_valid(row, col):
		return
	if _vr_util_code.strip_edges() == "":
		_flash_label("PICK A UTILITY TYPE", Color(1.0, 0.7, 0.3))
		return
	_vr_despawn_utility_at(col, row)
	_vr_utilities[row][col] = _vr_util_code
	var ok := _vr_spawn_utility(col, row, _vr_util_code)
	if ok:
		_flash_label("PLACED %s (%d,%d)" % [_util_friendly_code(_vr_util_code), row, col], Color(0.4, 1.0, 0.6))
	else:
		_flash_label("PLACED %s (data only)" % _util_friendly_code(_vr_util_code), Color(0.7, 0.9, 0.6))
	fire_cooldown = 0.15
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.05, 0.25, 0.0)


## REMOVE: clear the cell's data and despawn its live object.
func _vr_utility_remove(col: int, row: int) -> void:
	if not _vr_util_cell_valid(row, col):
		return
	var tok := str(_vr_utilities[row][col]).strip_edges()
	if tok == "" or tok == " ":
		_flash_label("CELL (%d,%d) EMPTY" % [row, col], Color(1.0, 0.7, 0.3))
		return
	_vr_despawn_utility_at(col, row)
	_vr_utilities[row][col] = " "
	_flash_label("CLEARED (%d,%d)" % [row, col], Color(1.0, 0.8, 0.4))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.3, 0.0)


## ROTATE: bump the cell's facing +90° on its token, rewrite the layer, respawn.
func _vr_utility_rotate(col: int, row: int) -> void:
	if not _vr_util_cell_valid(row, col):
		return
	var tok := str(_vr_utilities[row][col]).strip_edges()
	if tok == "" or tok == " ":
		_flash_label("NOTHING TO ROTATE", Color(1.0, 0.7, 0.3))
		return
	var rotated := _vr_bump_rotation_token(tok)
	_vr_despawn_utility_at(col, row)
	_vr_utilities[row][col] = rotated
	_vr_spawn_utility(col, row, rotated)
	_flash_label("ROTATED (%d,%d)" % [row, col], Color(0.6, 0.85, 1.0))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.05, 0.25, 0.0)


## MOVE: pick-then-place. First trigger on an occupied cell lifts it; the next
## trigger drops it on the targeted cell (mirrors desktop _utility_move_click).
func _vr_utility_move_click(col: int, row: int) -> void:
	if not _vr_util_move_picked:
		_vr_utility_pick_up(col, row)
	else:
		_vr_utility_drop(col, row)


func _vr_utility_pick_up(col: int, row: int) -> void:
	if not _vr_util_cell_valid(row, col):
		return
	var tok := str(_vr_utilities[row][col]).strip_edges()
	if tok == "" or tok == " ":
		_flash_label("MOVE — (%d,%d) EMPTY" % [row, col], Color(1.0, 0.7, 0.3))
		return
	_vr_despawn_utility_at(col, row)
	_vr_utilities[row][col] = " "
	_vr_util_move_token = tok
	_vr_util_move_from = Vector2i(row, col)
	_vr_util_move_picked = true
	_flash_label("MOVE — PICKED (%d,%d)" % [row, col], Color(0.85, 0.6, 0.95))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.06, 0.3, 0.0)


func _vr_utility_drop(col: int, row: int) -> void:
	if not _vr_util_cell_valid(row, col):
		return
	_vr_despawn_utility_at(col, row)
	_vr_utilities[row][col] = _vr_util_move_token
	var moved := _vr_util_move_token
	_vr_spawn_utility(col, row, _vr_util_move_token)
	_vr_util_move_picked = false
	_vr_util_move_token = ""
	_vr_util_move_from = Vector2i(-1, -1)
	_flash_label("MOVE — %s → (%d,%d)" % [_util_friendly_code(moved), row, col], Color(0.4, 1.0, 0.6))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.1, 0.4, 0.0)


## Abort an in-flight MOVE pick, restoring the picked utility to its source cell.
func _cancel_vr_utility_move() -> void:
	if not _vr_util_move_picked:
		return
	var row := _vr_util_move_from.x
	var col := _vr_util_move_from.y
	if row >= 0 and col >= 0 and _vr_util_cell_valid(row, col):
		_vr_utilities[row][col] = _vr_util_move_token
		_vr_spawn_utility(col, row, _vr_util_move_token)
	_vr_util_move_picked = false
	_vr_util_move_token = ""
	_vr_util_move_from = Vector2i(-1, -1)


## Spawn one utility at column (x=col, z=row) via the live GridUtilitiesComponent's
## _place_utility — the SAME path the desktop _spawn_utility uses (zero drift).
## Returns false if the component is absent / synthetic / the code has no scene.
func _vr_spawn_utility(col: int, row: int, token: String) -> bool:
	var comp := _get_vr_utilities_comp()
	if comp == null:
		return false
	if not ("parent_node" in comp) or comp.parent_node == null:
		return false
	if not comp.has_method("_place_utility"):
		return false
	var parsed: Dictionary = UtilityRegistry.parse_utility_cell(token)
	var code := str(parsed.get("type", "")).strip_edges()
	if code == "" or code == " ":
		return false
	if not UtilityRegistry.is_valid_utility_type(code):
		return false
	if UtilityRegistry.get_utility_scene_path(code) == "":
		return false  # authorial / param-only codes: data write stands, no live spawn
	var params: Array = parsed.get("parameters", [])
	var y_pos := 0
	var structure := _get_edit_structure()
	if structure and structure.has_method("find_highest_y_at"):
		y_pos = structure.find_highest_y_at(col, row)
	var total_size: float = 1.0
	if structure:
		total_size = structure.cube_size + structure.gutter
	elif "gutter" in comp:
		total_size = 1.0 + float(comp.gutter)
	comp._place_utility(col, y_pos, row, code, params, {}, total_size)
	return true


## Despawn any spawned utility object(s) at column (x=col, z=row). The component
## keys utility_objects by Vector3i(x,y,z); y is unknown, so scan the column.
func _vr_despawn_utility_at(col: int, row: int) -> void:
	var comp := _get_vr_utilities_comp()
	if comp == null or not ("utility_objects" in comp):
		return
	var objs: Dictionary = comp.utility_objects
	var to_free: Array = []
	for key in objs.keys():
		if key is Vector3i and key.x == col and key.z == row:
			to_free.append(key)
	for key in to_free:
		var node = objs[key]
		if is_instance_valid(node):
			node.queue_free()
		objs.erase(key)


## Bump a rotation (degrees) param on a utility token by +90°, wrapping 0..270.
## Mirrors the desktop _bump_rotation_token exactly: a trailing pure-integer param
## is the rotation slot; otherwise append ":90". PackedStringArray from split(":").
func _vr_bump_rotation_token(tok: String) -> String:
	var parts: PackedStringArray = tok.split(":")
	if parts.size() == 0:
		return tok
	var base := str(parts[0])
	if parts.size() >= 2 and str(parts[parts.size() - 1]).is_valid_int():
		var deg := int(str(parts[parts.size() - 1]))
		deg = wrapi(deg + 90, 0, 360)
		parts[parts.size() - 1] = str(deg)
		return ":".join(parts)
	var out := base
	for i in range(1, parts.size()):
		out += ":" + str(parts[i])
	out += ":90"
	return out


## The live GridUtilitiesComponent — cached, or a fresh lookup by node name.
func _get_vr_utilities_comp() -> Node:
	if _vr_utilities_comp and is_instance_valid(_vr_utilities_comp):
		return _vr_utilities_comp
	# Prefer the GridSystem accessor; fall back to a tree search by name.
	var gs := _find_node_by_name(get_tree().root, "GridSystem")
	if gs and gs.has_method("get_utilities_component"):
		var c = gs.get_utilities_component()
		if c != null:
			_vr_utilities_comp = c
			return _vr_utilities_comp
	var n := _find_node_by_name(get_tree().root, "GridUtilitiesComponent")
	if n != null:
		_vr_utilities_comp = n
	return _vr_utilities_comp


## True when (row, col) is inside the in-memory utilities layer.
func _vr_util_cell_valid(row: int, col: int) -> bool:
	if row < 0 or row >= _vr_utilities.size():
		return false
	var r: Array = _vr_utilities[row]
	return col >= 0 and col < r.size()


## Friendly label for a utility code (registry name when known, else the code).
func _util_friendly_code(code: String) -> String:
	var base := code
	if ":" in base:
		base = base.split(":")[0]
	if UtilityRegistry.is_valid_utility_type(base):
		return UtilityRegistry.get_utility_name(base)
	return code


## Seed _vr_utilities from the loaded map, so the B-save sends the WHOLE layer
## (existing utilities + this session's edits). Re-seeds when the current map name
## changes (map transition) so edits never leak across maps. Primary source is the
## live component's cached layout (what actually spawned); falls back to the data
## component's utility layout, then to a blank grid sized to the structure.
func _ensure_vr_utilities_seeded() -> void:
	# Current map name — re-seed if it changed (or first use).
	var cur_map := ""
	var dc := _get_grid_data_component()
	if dc and dc.has_method("get_current_map_name"):
		cur_map = dc.get_current_map_name()
	if _vr_utilities_seeded_map == cur_map and not _vr_utilities.is_empty():
		return
	# A map transition invalidates any in-flight MOVE pick + cached component.
	_vr_util_move_picked = false
	_vr_util_move_token = ""
	_vr_util_move_from = Vector2i(-1, -1)
	_vr_utilities_comp = null
	var rows: Array = []
	# 1) live component's cached layout (the truth of what's rendered)
	var comp := _get_vr_utilities_comp()
	if comp and ("_cached_utility_layout" in comp):
		var cached = comp._cached_utility_layout
		if cached is Array and (cached as Array).size() > 0:
			rows = _dup_util_rows(cached)
	# 2) data component's utility layout_data
	if rows.is_empty():
		var data := _get_grid_data_component()
		if data and data.has_method("get_utility_data"):
			var ud = data.get_utility_data()
			if ud != null and ("layout_data" in ud) and ud.layout_data is Array:
				rows = _dup_util_rows(ud.layout_data)
	# 3) blank grid sized to the structure (last resort)
	if rows.is_empty():
		var structure := _get_edit_structure()
		var w := 8
		var d := 8
		if structure and structure.has_method("get_grid_dimensions"):
			var dims: Vector3i = structure.get_grid_dimensions()
			w = maxi(1, dims.x)
			d = maxi(1, dims.z)
		for z in range(d):
			var blank: Array = []
			for x in range(w):
				blank.append(" ")
			rows.append(blank)
	_vr_utilities = rows
	_vr_utilities_seeded_map = cur_map


## Deep-ish copy of a utilities layout, normalising every cell to a String so the
## save payload is clean text (the source may hold StringName / mixed types).
func _dup_util_rows(src: Array) -> Array:
	var out: Array = []
	for row in src:
		var r: Array = []
		if row is Array:
			for cell in row:
				var s := str(cell)
				if s == "":
					s = " "
				r.append(s)
		out.append(r)
	return out


## Build / update a simple translucent ghost cube at the targeted cell so the
## player sees where the next utility op will land. Mirrors the wedge ghost shape.
func _update_vr_utility_ghost(col: int, row: int) -> void:
	var structure := _get_edit_structure()
	if structure == null or col < 0 or row < 0:
		if _vr_util_ghost and is_instance_valid(_vr_util_ghost):
			_vr_util_ghost.visible = false
		return
	var total_size: float = structure.cube_size + structure.gutter
	var grid_origin := _grid_origin_of(structure)
	var y_level: int = structure.find_highest_y_at(col, row)
	if _vr_util_ghost == null:
		_vr_util_ghost = MeshInstance3D.new()
		_vr_util_ghost.name = "UtilityGhost"
		_vr_util_ghost.top_level = true
		var bm := BoxMesh.new()
		bm.size = Vector3.ONE * (total_size * 0.92)
		_vr_util_ghost.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.5, 0.95, 0.16)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(0.85, 0.5, 0.95)
		mat.emission_energy_multiplier = 0.4
		mat.no_depth_test = true
		_vr_util_ghost.material_override = mat
		add_child(_vr_util_ghost)
	_vr_util_ghost.visible = true
	_vr_util_ghost.global_position = grid_origin + Vector3(
		float(col) * total_size,
		float(y_level) * total_size,
		float(row) * total_size
	)


## B (utility_edit mode) = save the whole utilities layer back to the repo's
## map_data.json via /api/game/save-layers (layers.utilities = whole-layer replace).
## Reconstructs the layer from the seeded-from-map + live-edited _vr_utilities array,
## then POSTs over the SAME adb-reverse tunnel as the structure / biome / modifier saves.
func _save_utilities() -> void:
	_ensure_vr_utilities_seeded()
	var data := _get_grid_data_component()
	var map_name := ""
	if data and data.has_method("get_current_map_name"):
		map_name = data.get_current_map_name()
	if map_name == "":
		_flash_label("NO MAP NAME", Color(1.0, 0.4, 0.3))
		return
	if _vr_utilities.is_empty():
		_flash_label("NOTHING TO SAVE", Color(1.0, 0.5, 0.2))
		return
	_save_utilities_over_http(map_name, _vr_utilities)
	_flash_label("SAVING UTILITIES  " + map_name + " ...", Color(0.6, 0.85, 1.0))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.12, 0.4, 0.0)


## POST the utilities layer to /api/game/save-layers as a whole-layer replace.
## Same HTTPRequest pattern + SAVED→PC flash as _save_map_over_http / _save_biome_over_http.
func _save_utilities_over_http(map_name: String, rows: Array) -> void:
	print("[Catalyst] POSTing utilities '%s' (%d rows) -> %s" % [map_name, rows.size(), MAP_SAVE_URL])
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_map_save_completed.bind(http))  # reuse SAVED→PC flash
	var headers := PackedStringArray(["Content-Type: application/json"])
	var payload := {"mapName": map_name, "layers": {"utilities": rows}}
	http.set_meta("map_name", map_name)
	var err := http.request(MAP_SAVE_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		http.queue_free()
		_flash_label("POST FAILED: %s" % error_string(err), Color(1.0, 0.3, 0.3))


# ═══════════════════════════════════════════════════════════════════════════
# WEDGE PLACEMENT — PrismMesh slopes on the grid
# ═══════════════════════════════════════════════════════════════════════════

## Wedge mode: trigger/AX = place wedge on the cardinal neighbor, sloping toward you.
func _handle_wedge_add() -> void:
	if not _voxel_controller or not _voxel_controller.has_target:
		return
	if not _voxel_controller.structure_component:
		return

	var ac := _voxel_controller.add_cell
	var structure: GridStructureComponent = _voxel_controller.structure_component
	var total_size: float = structure.cube_size + structure.gutter

	# Grid origin
	var grid_origin := Vector3.ZERO
	var grid_parent := structure.get_parent()
	if grid_parent is Node3D:
		grid_origin = (grid_parent as Node3D).global_position

	# Check if there's already a wedge at this XZ
	for w in _placed_wedges:
		if w["grid_x"] == ac.x and w["grid_z"] == ac.z:
			return  # Already occupied

	# Load the walkable prism scene (has StaticBody3D + ConcavePolygonShape3D)
	var wp_scene := load("res://commons/scenes/mapobjects/walkableprism.tscn")
	if wp_scene == null:
		push_error("[Catalyst] Failed to load walkableprism.tscn")
		return
	var wedge: Node3D = wp_scene.instantiate()
	wedge.name = "Wedge_%d_%d" % [ac.x, ac.z]

	# Scale to fit one grid cell (scene default is 2x1x1, we need total_size)
	var scene_width := 2.0  # Default PrismMesh width in the scene
	var scale_factor := total_size / scene_width
	wedge.scale = Vector3(scale_factor, total_size, scale_factor)

	# Position at grid cell
	var world_pos := grid_origin + Vector3(
		float(ac.x) * total_size,
		float(ac.y) * total_size,
		float(ac.z) * total_size
	)
	wedge.global_position = world_pos

	# Rotate so the slope faces the player's look direction
	wedge.rotation_degrees.y = _wedge_ghost_dir

	# Add to scene
	get_tree().current_scene.add_child(wedge)
	_placed_wedges.append({
		"node": wedge,
		"grid_x": ac.x,
		"grid_z": ac.z,
		"direction": _wedge_ghost_dir,
	})

	fire_cooldown = 0.2
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.2, 0.0)
	print("[Catalyst] Wedge placed at (%d, %d) dir=%.0f" % [ac.x, ac.z, _wedge_ghost_dir])


## Wedge mode: grip = remove the wedge at the target neighbor.
func _handle_wedge_remove() -> void:
	if not _voxel_controller or not _voxel_controller.has_target:
		return
	var tc := _voxel_controller.add_cell  # Same cell as where we'd place

	for i in range(_placed_wedges.size() - 1, -1, -1):
		var w: Dictionary = _placed_wedges[i]
		if w["grid_x"] == tc.x and w["grid_z"] == tc.z:
			if is_instance_valid(w["node"]):
				(w["node"] as Node).queue_free()
			_placed_wedges.remove_at(i)
			if controller:
				controller.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.3, 0.0)
			print("[Catalyst] Wedge removed at (%d, %d)" % [tc.x, tc.z])
			return


## Build or update the wedge ghost preview.
func _update_wedge_ghost() -> void:
	if not _voxel_active or not _voxel_controller or not _voxel_controller.has_target:
		if _wedge_ghost:
			_wedge_ghost.visible = false
		return
	if not _voxel_controller.structure_component:
		return

	var structure: GridStructureComponent = _voxel_controller.structure_component
	var total_size: float = structure.cube_size + structure.gutter
	var ac := _voxel_controller.add_cell

	# Grid origin
	var grid_origin := Vector3.ZERO
	var grid_parent := structure.get_parent()
	if grid_parent is Node3D:
		grid_origin = (grid_parent as Node3D).global_position

	# Create ghost on first use
	if not _wedge_ghost:
		_wedge_ghost = MeshInstance3D.new()
		_wedge_ghost.name = "WedgeGhost"
		_wedge_ghost.top_level = true
		var prism := PrismMesh.new()
		prism.size = Vector3(total_size * 0.96, total_size * 0.96, total_size * 0.96)
		prism.left_to_right = 0.0
		_wedge_ghost.mesh = prism
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.55, 0.2, 0.15)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.no_depth_test = true
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(0.85, 0.55, 0.2)
		mat.emission_energy_multiplier = 0.3
		_wedge_ghost.material_override = mat
		add_child(_wedge_ghost)

	_wedge_ghost.visible = true
	_wedge_ghost.global_position = grid_origin + Vector3(
		float(ac.x) * total_size,
		float(ac.y) * total_size,
		float(ac.z) * total_size
	)

	# Compute wedge direction from look direction
	var look_dir := Vector3.ZERO
	if _xr_camera and is_instance_valid(_xr_camera):
		look_dir = -_xr_camera.global_transform.basis.z
	elif controller:
		look_dir = -controller.global_transform.basis.z
	var flat := Vector2(look_dir.x, look_dir.z)
	if flat.length() > 0.01:
		# Snap to 4 cardinal directions (0, 90, 180, 270)
		var angle_rad := atan2(flat.x, flat.y)
		var snapped := roundf(angle_rad / (PI * 0.5)) * 90.0
		_wedge_ghost_dir = snapped
	_wedge_ghost.rotation_degrees.y = _wedge_ghost_dir


## Check if FunctionPickup on this controller is currently holding a pickable.
func _is_hand_busy() -> bool:
	if not is_instance_valid(controller):
		return false
	for child in controller.get_children():
		if child is XRToolsFunctionPickup:
			if is_instance_valid(child.picked_up_object):
				return true
	return false

func _fire() -> void:
	if not is_held or fire_cooldown > 0.0:
		return

	var mode_def := _get_current_mode_def()
	if mode_def.is_empty():
		return

	# ── Tool modes: voxel cubes and wedge prisms ──
	if mode_def["id"] == "voxel_editor":
		_handle_voxel_add()
		return
	if mode_def["id"] == "wedge_placer":
		_handle_wedge_add()
		return

	# ── Standard projectile modes ──
	# Fire where the controller points (local -Z, same axis as FunctionPointer ray)
	var spawn_pos: Vector3
	var fire_dir: Vector3
	if controller:
		fire_dir = -controller.global_transform.basis.z
		spawn_pos = controller.global_position + fire_dir * 0.15
	else:
		fire_dir = -global_transform.basis.z
		spawn_pos = global_position

	# Load the mode script and call its factory
	var mode_script: GDScript = load(mode_def["script"])
	if mode_script == null:
		push_warning("[Catalyst] Could not load mode script: %s" % mode_def["script"])
		return

	var projectile: CatalystProjectile = mode_script.create_projectile(spawn_pos, fire_dir)
	if projectile == null:
		return

	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_pos

	fire_cooldown = mode_script.FIRE_RATE if "FIRE_RATE" in mode_script else 0.4
	projectile_fired.emit(mode_def["id"], spawn_pos)

	# Haptic kick
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.35, 0.0)

# ═════════════════════════════════════════════════════════════════════════
# MODE SWITCHING
# ═════════════════════════════════════════════════════════════════════════

# ═════════════════════════════════════════════════════════════════════════
# VOXEL EDITING — Tool mode for adding/removing grid cubes
# ═════════════════════════════════════════════════════════════════════════

func _activate_voxel_mode() -> void:
	if _voxel_active:
		return
	# Find GridStructureComponent in scene
	var structure := _find_node_by_name(get_tree().root, "GridStructureComponent")
	if not structure or not (structure is GridStructureComponent):
		# Grid not ready yet (common after map transitions — grid needs ~3 frames)
		if _voxel_activate_retries < VOXEL_MAX_RETRIES:
			_voxel_activate_retries += 1
			print("[Catalyst] Grid not ready, retry %d/%d in %.1fs" % [_voxel_activate_retries, VOXEL_MAX_RETRIES, VOXEL_RETRY_DELAY])
			get_tree().create_timer(VOXEL_RETRY_DELAY).timeout.connect(_activate_voxel_mode)
			return
		print("[Catalyst] No GridStructureComponent found after %d retries — voxel mode unavailable" % VOXEL_MAX_RETRIES)
		return
	# Check if grid data is actually loaded (not just the node existing)
	var data := _find_node_by_name(get_tree().root, "GridDataComponent")
	if not data or not data.has_method("is_data_loaded") or not data.is_data_loaded():
		if _voxel_activate_retries < VOXEL_MAX_RETRIES:
			_voxel_activate_retries += 1
			print("[Catalyst] Grid data not loaded yet, retry %d/%d" % [_voxel_activate_retries, VOXEL_MAX_RETRIES])
			get_tree().create_timer(VOXEL_RETRY_DELAY).timeout.connect(_activate_voxel_mode)
			return
		print("[Catalyst] Grid data not available after %d retries" % VOXEL_MAX_RETRIES)
		return
	_voxel_activate_retries = 0
	_voxel_data_component = data  # remember it so B can save back to the right map
	if data.has_method("get_structure_data"):
		(structure as GridStructureComponent).enable_editing(data.get_structure_data())
	_voxel_controller = VoxelEditController.new()
	_voxel_controller.name = "CatalystVoxelEdit"
	_voxel_controller.structure_component = structure as GridStructureComponent
	_voxel_controller.cube_size = (structure as GridStructureComponent).cube_size
	add_child(_voxel_controller)
	_voxel_active = true

	# Find XR nodes for head raycast (Minecraft style)
	_xr_camera = null
	_xr_origin = null
	if controller:
		var node = controller.get_parent()
		while node:
			if node is XROrigin3D:
				_xr_origin = node
				break
			node = node.get_parent()
		if _xr_origin:
			for child in _xr_origin.get_children():
				if child is XRCamera3D:
					_xr_camera = child
					break
	if _xr_camera:
		print("[Catalyst] Head raycast active — using %s" % _xr_camera.get_path())
	else:
		push_warning("[Catalyst] No XRCamera3D found — falling back to controller ray")
	print("[Catalyst] Voxel editor activated")


func _deactivate_voxel_mode() -> void:
	if not _voxel_active:
		return
	if _voxel_controller and is_instance_valid(_voxel_controller):
		_voxel_controller.queue_free()
	_voxel_controller = null
	_xr_camera = null
	_xr_origin = null
	_voxel_active = false


func _update_voxel_raycast() -> void:
	if not _voxel_active or not _voxel_controller:
		return
	if not _voxel_controller.structure_component:
		return

	var structure: GridStructureComponent = _voxel_controller.structure_component
	var total_size: float = structure.cube_size + structure.gutter

	# Get player grid position (feet level), accounting for grid world offset
	if not _xr_origin or not is_instance_valid(_xr_origin):
		_voxel_controller.clear_target()
		return
	var grid_origin := Vector3.ZERO
	var grid_parent := structure.get_parent()
	if grid_parent is Node3D:
		grid_origin = (grid_parent as Node3D).global_position
	var local_pos: Vector3 = _xr_origin.global_position - grid_origin
	var player_grid: Vector3i = structure.world_to_grid(local_pos)

	# Get look direction from head (or controller fallback), projected onto XZ
	var look_dir := Vector3.ZERO
	if _xr_camera and is_instance_valid(_xr_camera):
		look_dir = -_xr_camera.global_transform.basis.z
	elif controller:
		look_dir = -controller.global_transform.basis.z
	else:
		_voxel_controller.clear_target()
		return

	# Project onto XZ plane and pick the dominant cardinal direction
	# Reach = 2 cells out (skip the cell right next to you for better visibility)
	var flat := Vector2(look_dir.x, look_dir.z)
	if flat.length() < 0.01:
		_voxel_controller.clear_target()
		return

	const REACH := 2  # How many cells out to place/remove
	var offset := Vector3i.ZERO
	if absf(flat.x) > absf(flat.y):
		offset = Vector3i(REACH, 0, 0) if flat.x > 0 else Vector3i(-REACH, 0, 0)
	else:
		offset = Vector3i(0, 0, REACH) if flat.y > 0 else Vector3i(0, 0, -REACH)

	var neighbor_x: int = player_grid.x + offset.x
	var neighbor_z: int = player_grid.z + offset.z
	var height: int = structure.get_height_at(neighbor_x, neighbor_z)

	# Target cell: top cube of the neighbor column (for removal)
	var target := Vector3i(neighbor_x, maxi(height - 1, 0), neighbor_z)
	# Add cell: on top of the neighbor column (for placement)
	var add := Vector3i(neighbor_x, height, neighbor_z)

	_voxel_controller.set_target_direct(target, add)


# ═════════════════════════════════════════════════════════════════════════
# ARTIFACT EDIT MODE — laser gravity-gun for existing map artifacts
# Point the catalyst at an artifact, hold trigger to grab it (it floats in
# front of the hand and follows your aim + twist), release to snap it onto the
# grid (cell on top of the structure, upright, yaw to 90°). Artifacts keep all
# their normal interactivity — nothing about them changes outside Edit mode.
# ═════════════════════════════════════════════════════════════════════════

func _update_edit_mode(_delta: float) -> void:
	if not is_instance_valid(controller):
		return
	var ray_dir: Vector3 = -controller.global_transform.basis.z
	if ray_dir.length() < 0.001:
		return
	ray_dir = ray_dir.normalized()
	var ray_origin: Vector3 = controller.global_position
	var trig_down: bool = controller.is_button_pressed("trigger_click")

	if is_instance_valid(_edit_grabbed):
		# Move: rigid follow. Lab props also magnetise — when near a wall/floor/
		# ceiling/prop-top they stick flush; otherwise they move freely.
		_edit_grabbed.global_transform = controller.global_transform * _edit_grab_offset
		if _edit_is_lab:
			_apply_lab_magnetism(_edit_grabbed)
		_show_edit_highlight(_edit_grabbed)
		if _edit_trigger_was_down and not trig_down:
			_edit_release()
	else:
		_edit_target = _find_edit_target(ray_origin, ray_dir)
		if _edit_target:
			_show_edit_highlight(_edit_target)
		else:
			_hide_edit_highlight()
		if trig_down and not _edit_trigger_was_down and _edit_target:
			_edit_grab()
	_edit_trigger_was_down = trig_down

## Nearest editable artifact to the laser line (no collider needed).
func _find_edit_target(ray_origin: Vector3, ray_dir: Vector3) -> Node3D:
	var best: Node3D = null
	var best_score: float = INF
	var group_name := "vr_lab_prop" if _edit_is_lab else "vr_editable_artifact"
	for n in get_tree().get_nodes_in_group(group_name):
		if not (n is Node3D) or not is_instance_valid(n):
			continue
		var node := n as Node3D
		var to_obj: Vector3 = node.global_position - ray_origin
		var along: float = to_obj.dot(ray_dir)
		if along < 0.2 or along > EDIT_MAX_RANGE:
			continue
		var closest: Vector3 = ray_origin + ray_dir * along
		var perp: float = node.global_position.distance_to(closest)
		if perp > EDIT_RAY_RADIUS:
			continue
		var score: float = perp + along * 0.05
		if score < best_score:
			best_score = score
			best = node
	return best

func _edit_grab() -> void:
	if not is_instance_valid(_edit_target):
		return
	_edit_grabbed = _edit_target
	# Reel it to a comfortable hold distance in front of the hand, keeping its
	# current orientation + scale relative to the controller.
	var rel: Transform3D = controller.global_transform.affine_inverse() * _edit_grabbed.global_transform
	rel.origin = Vector3(0.0, 0.0, -EDIT_HOLD_DISTANCE)
	_edit_grab_offset = rel
	if _edit_is_lab:
		_cache_lab_surfaces(_edit_grabbed)  # snapshot other props' tops for stacking
		_held_aabb = _local_aabb(_edit_grabbed)  # its own size, for flush-to-wall
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.4, 0.0)
	print("[Catalyst] Edit grab: %s" % String(_edit_grabbed.get_meta("artifact_lookup_name", "?")))

func _edit_release() -> void:
	var node := _edit_grabbed
	_edit_grabbed = null
	if not is_instance_valid(node):
		return
	if _edit_is_lab:
		_edit_release_lab(node)
		return
	var structure := _get_edit_structure()
	if structure == null:
		print("[Catalyst] Edit release: no grid — left in place")
		return
	var total_size: float = structure.cube_size + structure.gutter
	var grid_origin := _grid_origin_of(structure)
	var dims := structure.get_grid_dimensions()
	var local: Vector3 = (node.global_position - grid_origin) / total_size
	var x: int = clampi(int(round(local.x)), 0, maxi(dims.x - 1, 0))
	var z: int = clampi(int(round(local.z)), 0, maxi(dims.z - 1, 0))
	# Respect the height you dropped it at: snap Y to the nearest integer level.
	# Dropped low it lands on the surface; lifted, it stays floating at that level.
	var y_level: int = clampi(int(round(local.y)), 0, maxi(dims.y - 1, EDIT_MAX_Y_LEVEL))
	# snap rotation: upright, yaw to nearest 90°
	var yaw_deg: float = rad_to_deg(node.global_rotation.y)
	var snapped_yaw: float = round(yaw_deg / 90.0) * 90.0
	node.global_rotation = Vector3(0.0, deg_to_rad(snapped_yaw), 0.0)
	node.global_position = grid_origin + Vector3(x, y_level, z) * total_size
	node.set_meta("grid_cell", Vector2i(x, z))
	node.set_meta("grid_y_level", y_level)
	node.set_meta("grid_rotation_y", fposmod(snapped_yaw, 360.0))
	if not node.is_in_group("vr_placed_artifact"):
		node.add_to_group("vr_placed_artifact")  # now it'll save with B
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.15, 0.5, 0.0)
	_flash_label("MOVED  %s" % String(node.get_meta("artifact_lookup_name", "")), Color(0.4, 1.0, 0.6))
	print("[Catalyst] Edit drop -> cell (%d,%d) y=%d yaw=%d" % [x, z, y_level, int(snapped_yaw)])

func _end_edit_mode() -> void:
	if is_instance_valid(_edit_grabbed):
		_edit_release()
	_edit_grabbed = null
	_edit_target = null
	_edit_trigger_was_down = false
	_hide_edit_highlight()

func _get_edit_structure() -> GridStructureComponent:
	if _voxel_controller and _voxel_controller.structure_component:
		return _voxel_controller.structure_component
	var n := _find_node_by_name(get_tree().root, "GridStructureComponent")
	if n is GridStructureComponent:
		return n as GridStructureComponent
	return null

func _grid_origin_of(structure: GridStructureComponent) -> Vector3:
	var p := structure.get_parent()
	if p is Node3D:
		return (p as Node3D).global_position
	return Vector3.ZERO

func _show_edit_highlight(node: Node3D) -> void:
	if _edit_highlight == null:
		_build_edit_highlight()
	var size: float = 1.0
	var structure := _get_edit_structure()
	if structure:
		size = structure.cube_size + structure.gutter
	_edit_highlight.scale = Vector3.ONE * size
	_edit_highlight.global_position = node.global_position
	_edit_highlight.visible = true

func _hide_edit_highlight() -> void:
	if _edit_highlight:
		_edit_highlight.visible = false

func _build_edit_highlight() -> void:
	_edit_highlight = MeshInstance3D.new()
	_edit_highlight.name = "EditHighlight"
	_edit_highlight.top_level = true  # world space — ignore the shrunk catalyst
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * 0.95
	_edit_highlight.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 1.0, 0.6, 0.18)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.4, 1.0, 0.6)
	mat.emission_energy_multiplier = 0.6
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	_edit_highlight.material_override = mat
	_edit_highlight.visible = false
	add_child(_edit_highlight)

# ── Lab net editing — props stick to their face, snap in-plane to 0.1m ───────

func _edit_release_lab(node: Node3D) -> void:
	if not is_instance_valid(node):
		return
	_apply_lab_magnetism(node)  # final stick to whatever surface it's near
	node.rotation = Vector3(0.0, node.rotation.y, 0.0)  # keep upright, preserve yaw
	if not node.is_in_group("vr_lab_moved"):
		node.add_to_group("vr_lab_moved")  # B will save it
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.12, 0.5, 0.0)
	var stuck := bool(node.get_meta("lab_stuck", false))
	var suffix: String = "  (stuck)" if stuck else "  (free)"
	_flash_label("MOVED  %s%s" % [String(node.get_meta("lab_lookup", "")), suffix], Color(0.4, 1.0, 0.6))
	print("[Catalyst] Lab move: %s local=%s stuck=%s" % [String(node.get_meta("lab_prop_id", "")), str(node.position), str(stuck)])

## Surface magnetism: a held lab prop moves freely, but within LAB_SNAP_DIST of a
## wall / floor / ceiling (or the top of another prop) it sticks flush to that
## surface, gridded to 0.1m along it. Pull it away to un-stick. Works in the
## lab_room's local frame (prop positions are room-local).
func _apply_lab_magnetism(node: Node3D) -> void:
	var dims_v: Vector3 = node.get_meta("lab_room_dims", Vector3(8.0, 7.0, 4.5))
	var rw: float = dims_v.x
	var rd: float = dims_v.y
	var rh: float = dims_v.z
	var p: Vector3 = node.position

	# Nearest wall within snap distance (the wall to align + sit flush against).
	var wd: Array = [absf(p.x - rw / 2.0), absf(p.x + rw / 2.0), absf(p.z - rd / 2.0), absf(p.z + rd / 2.0)]
	var wcoord: Array = [rw / 2.0, -rw / 2.0, rd / 2.0, -rd / 2.0]
	var wyaw: Array = [270.0, 90.0, 0.0, 180.0]  # face INTO the room (front to viewer; +Z-forward)
	var wisx: Array = [true, true, false, false]
	var bw := -1
	var bd: float = LAB_SNAP_DIST + 0.001
	for i in 4:
		if wd[i] < bd:
			bd = wd[i]
			bw = i

	if bw >= 0:
		# stick to the wall, ALIGN the facing to it, and offset so it sits flush.
		var np: Vector3 = p
		if p.y <= LAB_SNAP_DIST:
			np.y = 0.0  # a wall prop near the floor also stands on it
		elif p.y >= rh - LAB_SNAP_DIST:
			np.y = rh
		if wisx[bw]:
			np.x = wcoord[bw]
		else:
			np.z = wcoord[bw]
		node.position = np
		# align: face the room. An artifact may declare wall_facing_offset_deg if
		# its front is the opposite of the +Z convention (e.g. wall_placard = 180).
		var face_off: float = 0.0
		var fo = node.get("wall_facing_offset_deg")
		if fo != null:
			face_off = float(fo)
		node.rotation = Vector3(0.0, deg_to_rad(wyaw[bw] + face_off), 0.0)
		# Flush: push the prop's wall-side edge exactly onto the wall plane.
		var ab: AABB = node.transform * _held_aabb
		if wisx[bw]:
			if wcoord[bw] > 0.0:
				node.position.x += wcoord[bw] - (ab.position.x + ab.size.x)
			else:
				node.position.x += wcoord[bw] - ab.position.x
			node.position.z = _snap01(node.position.z)  # grid along the wall
		else:
			if wcoord[bw] > 0.0:
				node.position.z += wcoord[bw] - (ab.position.z + ab.size.z)
			else:
				node.position.z += wcoord[bw] - ab.position.z
			node.position.x = _snap01(node.position.x)
		node.position.y = _snap01(node.position.y)
		_clamp_prop_to_room(node, rw, rd, rh)
		node.set_meta("lab_stuck", true)
		return

	# No wall — floor / ceiling / table for the vertical axis (free rotation kept).
	var s: Vector3 = p
	var stuck := false
	if p.y <= LAB_SNAP_DIST:
		s.y = 0.0
		stuck = true
	elif p.y >= rh - LAB_SNAP_DIST:
		s.y = rh
		stuck = true
	for surf in _lab_surfaces:
		if absf(p.x - surf["cx"]) <= surf["hx"] + 0.1 and absf(p.z - surf["cz"]) <= surf["hz"] + 0.1:
			if absf(p.y - surf["top"]) <= LAB_SNAP_DIST and p.y >= surf["top"] - 0.05:
				s.y = surf["top"]
				stuck = true
				break
	node.position = s
	# floor flush — push the prop's bottom onto the floor (base-origin → no change)
	if stuck and is_zero_approx(s.y):
		var ab2: AABB = node.transform * _held_aabb
		node.position.y += -ab2.position.y
	if stuck:
		node.position.x = _snap01(node.position.x)
		node.position.y = _snap01(node.position.y)
		node.position.z = _snap01(node.position.z)
	_clamp_prop_to_room(node, rw, rd, rh)
	node.set_meta("lab_stuck", stuck)

## Keep the prop's body inside the room — never let any part cross a wall, the
## floor, or the ceiling. Uses its AABB; pushes it back in if an edge pokes out.
## Guarantees an artifact always sits on the room side of every plane.
func _clamp_prop_to_room(node: Node3D, rw: float, rd: float, rh: float) -> void:
	var ab: AABB = node.transform * _held_aabb
	if ab.size.length() <= 0.0001:
		return
	var lo: Vector3 = ab.position
	var hi: Vector3 = ab.position + ab.size
	var push := Vector3.ZERO
	if lo.x < -rw / 2.0:
		push.x = -rw / 2.0 - lo.x
	elif hi.x > rw / 2.0:
		push.x = rw / 2.0 - hi.x
	if lo.z < -rd / 2.0:
		push.z = -rd / 2.0 - lo.z
	elif hi.z > rd / 2.0:
		push.z = rd / 2.0 - hi.z
	if lo.y < 0.0:
		push.y = -lo.y
	elif hi.y > rh:
		push.y = rh - hi.y
	node.position += push

## AABB of a node's visible meshes in the node's OWN local frame (constant; cached
## on grab). node.transform * this gives the room-local AABB (exact for the 90°-
## multiple facing yaws we use), which drives the flush-to-wall offset.
func _local_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is VisualInstance3D:
			var vi := n as VisualInstance3D
			var a: AABB = vi.get_aabb()
			if a.size.length() > 0.0001:
				var t := Transform3D.IDENTITY
				var cur: Node = n
				while cur != null and cur != root:
					if cur is Node3D:
						t = (cur as Node3D).transform * t
					cur = cur.get_parent()
				for i in 8:
					var c: Vector3 = a.position
					if i & 1:
						c.x += a.size.x
					if i & 2:
						c.y += a.size.y
					if i & 4:
						c.z += a.size.z
					var lc: Vector3 = t * c
					if first:
						result = AABB(lc, Vector3.ZERO)
						first = false
					else:
						result = result.expand(lc)
		for ch in n.get_children():
			stack.append(ch)
	return result

## Snapshot the OTHER lab props' tops + footprints (room-local) so the held prop
## can stick on them (tables). Assumes the lab_room is axis-aligned in the world.
func _cache_lab_surfaces(grabbed: Node3D) -> void:
	_lab_surfaces.clear()
	var room := grabbed.get_parent()
	if not (room is Node3D):
		return
	var room_origin: Vector3 = (room as Node3D).global_position
	for n in get_tree().get_nodes_in_group("vr_lab_prop"):
		if n == grabbed or not is_instance_valid(n) or not (n is Node3D):
			continue
		var g := _global_aabb(n as Node3D)
		if g.size.y <= 0.001:
			continue
		_lab_surfaces.append({
			"cx": g.position.x + g.size.x * 0.5 - room_origin.x,
			"cz": g.position.z + g.size.z * 0.5 - room_origin.z,
			"hx": g.size.x * 0.5,
			"hz": g.size.z * 0.5,
			"top": g.position.y + g.size.y - room_origin.y,
		})

## World-space AABB of a node's visible meshes.
func _global_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is VisualInstance3D:
			var vi := n as VisualInstance3D
			var a: AABB = vi.get_aabb()
			if a.size.length() > 0.0001:
				var gt: Transform3D = vi.global_transform
				for i in 8:
					var c: Vector3 = a.position
					if i & 1:
						c.x += a.size.x
					if i & 2:
						c.y += a.size.y
					if i & 4:
						c.z += a.size.z
					var wc: Vector3 = gt * c
					if first:
						result = AABB(wc, Vector3.ZERO)
						first = false
					else:
						result = result.expand(wc)
		for ch in n.get_children():
			stack.append(ch)
	return result

func _snap01(v: float) -> float:
	return round(v / 0.1) * 0.1

## B in Lab mode: POST the moved lab props back to their lab JSON (by id), over
## adb reverse, so the change lands in commons/labs/<name>.lab.json.
func _save_lab() -> void:
	print("[Catalyst] _save_lab() called")
	var updates: Array = []
	var lab_name := ""
	for node in get_tree().get_nodes_in_group("vr_lab_moved"):
		if not is_instance_valid(node):
			continue
		var pid := String(node.get_meta("lab_prop_id", ""))
		if pid == "":
			continue
		if lab_name == "":
			var jp := String(node.get_meta("lab_json_path", ""))
			lab_name = jp.get_file().trim_suffix(".json").trim_suffix(".lab")
		var pos: Vector3 = node.position
		updates.append({
			"id": pid,
			"position": [pos.x, pos.y, pos.z],
			"rotation_y": rad_to_deg(node.rotation.y),
		})
	if lab_name == "" or updates.is_empty():
		_flash_label("NO LAB EDITS", Color(1.0, 0.5, 0.2))
		return
	_save_lab_over_http(lab_name, updates)
	_flash_label("SAVING LAB  " + lab_name + " ...", Color(0.6, 0.85, 1.0))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.12, 0.4, 0.0)

func _save_lab_over_http(lab_name: String, updates: Array) -> void:
	print("[Catalyst] POSTing lab '%s' (%d prop updates) -> %s" % [lab_name, updates.size(), LAB_SAVE_URL])
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_lab_save_completed.bind(http))
	var headers := PackedStringArray(["Content-Type: application/json"])
	var payload := {"name": lab_name, "propUpdates": updates}
	http.set_meta("lab_name", lab_name)
	var err := http.request(LAB_SAVE_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		http.queue_free()
		_flash_label("POST FAILED: %s" % error_string(err), Color(1.0, 0.3, 0.3))

func _on_lab_save_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest) -> void:
	var ln := String(http.get_meta("lab_name", ""))
	http.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		_flash_label("LAB SAVED -> PC  " + ln, Color(0.4, 1.0, 0.6))
		if controller:
			controller.trigger_haptic_pulse("haptic", 0.0, 0.2, 0.6, 0.0)
	else:
		var hint := ""
		if result == HTTPRequest.RESULT_CANT_CONNECT:
			hint = "  (adb reverse tcp:3003 tcp:3003)"
		_flash_label("LAB SAVE FAILED %d/%d%s" % [result, response_code, hint], Color(1.0, 0.35, 0.35))
		push_warning("[Catalyst] lab save HTTP failed result=%d code=%d" % [result, response_code])


func _voxel_save() -> void:
	if not _voxel_controller or not _voxel_controller.structure_component:
		return
	var data := _find_node_by_name(get_tree().root, "GridDataComponent")
	var map_name: String = ""
	if data and data.has_method("get_current_map_name"):
		map_name = data.get_current_map_name()
	if map_name.is_empty():
		return
	VoxelSaveManager.save(map_name, _voxel_controller.structure_component)
	print("[Catalyst] 💾 Saved: %s" % map_name)
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.15, 0.5, 0.0)


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found:
			return found
	return null


func _check_mode_switch() -> void:
	# Mode switching is done by the OTHER hand rotating the bracelet hinge.
	# No thumbstick or grip-click mode switching on the catalyst hand.
	pass

func _switch_mode(direction: int) -> void:
	var new_index := (current_mode_index + direction) % unlocked_modes.size()
	if new_index < 0:
		new_index = unlocked_modes.size() - 1
	if new_index == current_mode_index:
		return

	current_mode_index = new_index
	var mode_id := unlocked_modes[current_mode_index]

	_show_mode_label()
	mode_changed.emit(mode_id)

	# Activate/deactivate grid editing based on mode (voxel + wedge + modifier +
	# utility_edit share the same voxel controller — it supplies the targeted cell)
	if mode_id in ["voxel_editor", "wedge_placer", "modifier", "utility_edit"]:
		_activate_voxel_mode()
	else:
		_deactivate_voxel_mode()

	# Keep bracelet in sync with thumbstick switching
	var cap_mgr = get_node_or_null("/root/CatalystCapabilityManager")
	if cap_mgr and cap_mgr.has_method("get_bracelet"):
		var bracelet = cap_mgr.get_bracelet()
		if bracelet and bracelet.has_method("sync_to_mode"):
			bracelet.sync_to_mode(current_mode_index)

	# Haptic tick
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.15, 0.0)

	# ADDITIVE: keep the tabbed editor panel's tab in step with this mode.
	_sync_editor_panel_tab()

	print("[Catalyst] Switched to mode: %s" % mode_id)

## Set mode by absolute index (called by capacity bracelet).
func set_mode_index(index: int) -> void:
	if index < 0 or index >= unlocked_modes.size() or index == current_mode_index:
		return
	current_mode_index = index
	var mode_id := unlocked_modes[current_mode_index]
	_show_mode_label()
	_rebuild_visual()
	mode_changed.emit(mode_id)

	# Activate/deactivate grid editing (voxel + wedge + modifier + utility_edit share the controller)
	if mode_id in ["voxel_editor", "wedge_placer", "modifier", "utility_edit"]:
		_activate_voxel_mode()
	else:
		_deactivate_voxel_mode()

	# Don't call bracelet.sync_to_mode here — the bracelet initiated this change
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.15, 0.0)
	# ADDITIVE: keep the tabbed editor panel's tab in step with this mode.
	_sync_editor_panel_tab()
	print("[Catalyst] Set mode to: %s" % mode_id)

func _show_mode_label() -> void:
	if not _mode_label:
		return
	var mode_def := _get_current_mode_def()
	var mode_name: String = mode_def.get("name", "???")
	var index_display: String = "%d/%d" % [current_mode_index + 1, unlocked_modes.size()]
	_mode_label.text = "%s  %s" % [index_display, mode_name]
	_mode_label.modulate = CatalystVisual.get_mode_color(mode_def.get("id", ""))
	_mode_label.visible = true
	_mode_label_timer = 4.0  # Visible longer so player can read it

func _get_current_mode_def() -> Dictionary:
	if current_mode_index < 0 or current_mode_index >= unlocked_modes.size():
		return {}
	var mode_id := unlocked_modes[current_mode_index]
	for def in MODE_DEFS:
		if def["id"] == mode_id:
			return def
	return {}

# ═════════════════════════════════════════════════════════════════════════
# PROGRESSION — MODE UNLOCKING
# ═════════════════════════════════════════════════════════════════════════

func _connect_progression_signals() -> void:
	# Try LabManager first (has is_sequence_completed)
	var lab_mgr := _find_lab_manager()
	if lab_mgr and lab_mgr.has_method("is_sequence_completed"):
		# Check already-completed sequences
		for mode_def in MODE_DEFS:
			if lab_mgr.is_sequence_completed(mode_def["sequence"]):
				_unlock_mode(mode_def["id"], false)

	# Listen for future completions from AdaSceneManager
	var scene_mgr := get_node_or_null("/root/AdaSceneManager")
	if scene_mgr and scene_mgr.has_signal("sequence_completed"):
		if not scene_mgr.sequence_completed.is_connected(_on_sequence_completed):
			scene_mgr.sequence_completed.connect(_on_sequence_completed)
			print("[Catalyst] Connected to AdaSceneManager.sequence_completed")

	# Also try MapProgressionManager
	var map_prog := get_node_or_null("/root/MapProgressionManager")
	if map_prog and map_prog.has_signal("sequence_completed"):
		if not map_prog.sequence_completed.is_connected(_on_map_progression_sequence_completed):
			map_prog.sequence_completed.connect(_on_map_progression_sequence_completed)
			print("[Catalyst] Connected to MapProgressionManager.sequence_completed")

func _on_sequence_completed(sequence_name: String, _completion_data: Dictionary) -> void:
	for mode_def in MODE_DEFS:
		if mode_def["sequence"] == sequence_name:
			_unlock_mode(mode_def["id"], true)

func _on_map_progression_sequence_completed(sequence_name: String) -> void:
	for mode_def in MODE_DEFS:
		if mode_def["sequence"] == sequence_name:
			_unlock_mode(mode_def["id"], true)

func _unlock_mode(mode_id: String, notify: bool = true) -> void:
	if mode_id in unlocked_modes:
		return
	unlocked_modes.append(mode_id)
	_save_unlocked_modes()
	_rebuild_visual()
	if notify:
		mode_unlocked.emit(mode_id)
		print("[Catalyst] 🌀 Unlocked mode: %s" % mode_id)

func unlock_all_modes() -> void:
	"""Debug: unlock everything."""
	for mode_def in MODE_DEFS:
		_unlock_mode(mode_def["id"], false)
	_rebuild_visual()
	print("[Catalyst] All modes unlocked")

func _find_lab_manager() -> Node:
	# LabManager could be autoload or in scene tree
	var mgr := get_node_or_null("/root/LabManager")
	if mgr:
		return mgr
	# Search scene tree
	var tree := get_tree()
	if tree:
		for node in tree.get_nodes_in_group("lab_manager"):
			return node
	return null

# ═════════════════════════════════════════════════════════════════════════
# SAVE / LOAD
# ═════════════════════════════════════════════════════════════════════════

func _save_unlocked_modes() -> void:
	pass  # Fresh start every session — modes unlock during gameplay

func _load_unlocked_modes() -> void:
	# Fresh start: only voxel_editor, modes unlock during gameplay
	current_mode_index = 0

# ═════════════════════════════════════════════════════════════════════════
# VISUAL CONSTRUCTION
# ═════════════════════════════════════════════════════════════════════════

func _rebuild_visual() -> void:
	CatalystVisual.build_crystal(self, unlocked_modes)

func _setup_physics() -> void:
	mass = 0.25
	gravity_scale = 1.0
	linear_damp = 1.0
	angular_damp = 2.0

	# Configure the CollisionShape3D inherited from pickable.tscn
	_collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _collision_shape:
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.06
		capsule.height = 0.22
		_collision_shape.shape = capsule
	else:
		# Fallback: create one if not instanced from pickable.tscn
		_collision_shape = CollisionShape3D.new()
		_collision_shape.name = "CollisionShape3D"
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.06
		capsule.height = 0.22
		_collision_shape.shape = capsule
		add_child(_collision_shape)

func _build_tip() -> void:
	_tip = Marker3D.new()
	_tip.name = "Tip"
	_tip.position = Vector3(0, 0.12, 0)  # Top of crystal
	add_child(_tip)

func _build_mode_label() -> void:
	_mode_label = Label3D.new()
	_mode_label.name = "ModeLabel"
	_mode_label.position = Vector3(0, 0.2, 0)
	_mode_label.pixel_size = 0.002
	_mode_label.font_size = 32
	_mode_label.outline_size = 4
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mode_label.no_depth_test = true
	_mode_label.visible = false
	# When held, the catalyst is shrunk to scale 0.01 ("absorbed into hand") so
	# the body is invisible. A normal child label would shrink with it to 1/100th
	# and never be seen. top_level makes the label ignore the parent transform; we
	# place it in world space above the controller each frame (see _physics_process).
	_mode_label.top_level = true
	_mode_label.pixel_size = 0.0012
	add_child(_mode_label)

# ═════════════════════════════════════════════════════════════════════════
# XR-TOOLS PICKABLE CALLBACKS
# ═════════════════════════════════════════════════════════════════════════

func _on_picked_up(_pickable) -> void:
	is_held = true

	# Find controller — walk up from the holder node
	controller = _find_xr_controller()
	if controller:
		_pickup_controller_name = controller.name
		print("[Catalyst] Picked up — controller: '%s' (path: %s)" % [controller.name, controller.get_path()])
		if not controller.button_pressed.is_connected(_on_controller_button):
			controller.button_pressed.connect(_on_controller_button)
	else:
		print("[Catalyst] WARNING: Could not find XRController3D in pickup hierarchy")

	# Shrink into hand, then absorb permanently
	if _pickup_tween and _pickup_tween.is_running():
		_pickup_tween.kill()
	_pickup_tween = create_tween()
	_pickup_tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.35) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	_pickup_tween.tween_callback(_absorb_into_hand)

	# Haptic pulse — absorbing the crystal
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.15, 0.4, 0.0)

## Remove any previously absorbed catalyst on the given controller.
func _replace_existing_catalyst(ctrl: XRController3D) -> void:
	if not is_instance_valid(ctrl):
		return
	var existing := get_tree().get_nodes_in_group("catalyst")
	for cat in existing:
		if cat == self:
			continue
		if not is_instance_valid(cat):
			continue
		if cat.get("_absorbed") and cat.get("controller") == ctrl:
			# Disconnect old catalyst's button handler
			if ctrl.button_pressed.is_connected(cat._on_controller_button):
				ctrl.button_pressed.disconnect(cat._on_controller_button)
			cat.queue_free()
			print("[Catalyst] Replaced previous catalyst on '%s'" % ctrl.name)

## Crystal is consumed — reparent to controller, release FunctionPickup hold.
func _absorb_into_hand() -> void:
	_absorbed = true

	# If controller reference was lost, try to recover — prefer the SAME hand
	if not is_instance_valid(controller):
		print("[Catalyst] Controller lost since pickup, recovering...")
		# Method A: Walk up from current holder (most reliable)
		var holder = get_picked_up_by()
		if holder:
			var node = holder
			while node:
				if node is XRController3D:
					controller = node
					print("[Catalyst] Recovered controller from holder chain: '%s'" % controller.name)
					break
				node = node.get_parent()
		# Method B: Find controller by saved name
		if not is_instance_valid(controller) and not _pickup_controller_name.is_empty():
			controller = _find_controller_by_name(_pickup_controller_name)
			if controller:
				print("[Catalyst] Recovered controller by saved name: '%s'" % controller.name)
		# Method C: General fallback
		if not is_instance_valid(controller):
			controller = _find_xr_controller()
			if controller:
				print("[Catalyst] Fallback controller: '%s'" % controller.name)

	# Remove any previous catalyst on this controller — only one at a time
	_replace_existing_catalyst(controller)

	# Remember controller before let_go triggers _on_dropped
	var ctrl := controller

	# Release from FunctionPickup so the hand is free to grab other things
	var holder = get_picked_up_by()
	if holder and is_picked_up():
		let_go(holder, Vector3.ZERO, Vector3.ZERO)

	# Restore state that _on_dropped cleared
	controller = ctrl
	is_held = true

	# Kill physics — we're a ghost node now
	freeze = true
	collision_layer = 0
	collision_mask = 0
	if _collision_shape:
		_collision_shape.disabled = true

	# Reconnect trigger (let_go → _on_dropped may have disconnected it)
	if controller and not controller.button_pressed.is_connected(_on_controller_button):
		controller.button_pressed.connect(_on_controller_button)

	# Reparent to the controller so we follow the hand
	call_deferred("_deferred_reparent")

	# Hand glow
	if _held_glow:
		var mode_color := CatalystVisual.get_mode_color(unlocked_modes[current_mode_index])
		_held_glow.light_color = mode_color
		_held_glow.light_energy = 1.5

	# Activate voxel mode if it's the current mode (default on start)
	if unlocked_modes[current_mode_index] == "voxel_editor":
		call_deferred("_activate_voxel_mode")

## Auto-absorb onto a controller without pickup animation.
## Used by CatalystCapabilityManager to restore catalyst after scene transitions.
func auto_absorb(ctrl: XRController3D) -> void:
	# Remove any previous catalyst on this controller — only one at a time
	_replace_existing_catalyst(ctrl)

	_absorbed = true
	is_held = true
	controller = ctrl
	_pickup_controller_name = ctrl.name

	# Kill physics
	freeze = true
	collision_layer = 0
	collision_mask = 0
	if _collision_shape:
		_collision_shape.disabled = true

	# Connect trigger
	if not controller.button_pressed.is_connected(_on_controller_button):
		controller.button_pressed.connect(_on_controller_button)

	# Reparent to controller — tiny and invisible
	var old_parent := get_parent()
	if old_parent:
		old_parent.remove_child(self)
	controller.add_child(self)
	position = Vector3.ZERO
	scale = Vector3(0.01, 0.01, 0.01)
	# Don't set visible=false — ghost cubes are descendants and Godot hides
	# all children of invisible nodes even with top_level=true.
	# The 0.01 scale already makes the catalyst effectively invisible.

	# Hand glow
	if _held_glow and current_mode_index < unlocked_modes.size():
		var mode_color := CatalystVisual.get_mode_color(unlocked_modes[current_mode_index])
		_held_glow.light_color = mode_color
		_held_glow.light_energy = 1.5

	# Activate voxel mode if it's the current mode (same as regular pickup)
	if unlocked_modes[current_mode_index] == "voxel_editor":
		call_deferred("_activate_voxel_mode")

	print("[Catalyst] Auto-absorbed onto '%s' with %d modes: %s" % [
		controller.name, unlocked_modes.size(), unlocked_modes])

func _deferred_reparent() -> void:
	if not is_instance_valid(controller):
		print("[Catalyst] _deferred_reparent: controller INVALID, aborting")
		return
	print("[Catalyst] _deferred_reparent: reparenting to controller '%s' (path: %s, global_pos: %s)" % [
		controller.name, controller.get_path(), controller.global_position])
	var old_parent := get_parent()
	if old_parent:
		old_parent.remove_child(self)
	controller.add_child(self)
	position = Vector3.ZERO
	scale = Vector3(0.01, 0.01, 0.01)

	# Notify the capability manager to spawn the bracelet on this controller
	var cap_mgr = get_node_or_null("/root/CatalystCapabilityManager")
	if cap_mgr and cap_mgr.has_method("spawn_bracelet_on_controller"):
		print("[Catalyst] Requesting bracelet spawn on controller '%s'" % controller.name)
		cap_mgr.spawn_bracelet_on_controller(controller)
	else:
		print("[Catalyst] WARNING: CatalystCapabilityManager not found or missing spawn method")

func _on_dropped(_pickable) -> void:
	if _absorbed:
		# let_go() fired this during absorption — ignore it
		return

	is_held = false
	if controller and controller.button_pressed.is_connected(_on_controller_button):
		controller.button_pressed.disconnect(_on_controller_button)
	controller = null

	if _held_glow:
		_held_glow.light_energy = 0.0
	if _mode_label:
		_mode_label.visible = false

# ═════════════════════════════════════════════════════════════════════════
# CONTROLLER FINDING
# ═════════════════════════════════════════════════════════════════════════

func _find_xr_controller() -> XRController3D:
	# Method 1: Walk up from the holder (FunctionPickup → ... → XRController3D)
	var pickup_node = get_picked_up_by()
	if pickup_node:
		var node = pickup_node
		while node:
			if node is XRController3D:
				return node
			node = node.get_parent()

	# Method 2: Walk up from self (pickable may already be reparented under controller)
	var node = get_parent()
	while node:
		if node is XRController3D:
			return node
		node = node.get_parent()

	# Method 3: Search the scene tree for any XRController3D
	for child in get_tree().root.get_children():
		var found := _find_controller_recursive(child)
		if found:
			return found

	return null

func _find_controller_recursive(node: Node) -> XRController3D:
	if node is XRController3D:
		return node
	for child in node.get_children():
		var found := _find_controller_recursive(child)
		if found:
			return found
	return null

## Find a specific controller by name (recursive search).
func _find_controller_by_name(ctrl_name: String) -> XRController3D:
	for child in get_tree().root.get_children():
		var found := _find_named_controller_recursive(child, ctrl_name)
		if found:
			return found
	return null

func _find_named_controller_recursive(node: Node, ctrl_name: String) -> XRController3D:
	if node is XRController3D and node.name == ctrl_name:
		return node
	for child in node.get_children():
		var found := _find_named_controller_recursive(child, ctrl_name)
		if found:
			return found
	return null

# ═════════════════════════════════════════════════════════════════════════
# GRID INTEGRATION
# ═════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)

func configure(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	# Debug: unlock all modes
	if config_data.has("all_modes"):
		unlock_all_modes()
	# Unlock a specific mode
	if config_data.has("start_mode"):
		_unlock_mode(str(config_data["start_mode"]))
	# Unlock up to a specific mode by order
	if config_data.has("unlock_to"):
		var target_order := int(config_data["unlock_to"])
		for mode_def in MODE_DEFS:
			if mode_def["order"] <= target_order:
				_unlock_mode(mode_def["id"], false)
	# Unlock only the SHOOTING modes (skip voxel_editor + wedge_placer
	# which are at order 0 and consume A/X for placement). Used by the
	# catalyst test maps so the bracelet starts on a projectile mode.
	# CRITICAL: also REMOVE the seeded voxel/wedge/off modes from
	# unlocked_modes — otherwise the bracelet still gets them in its
	# rotation and shows voxel as the active gem at index 0.
	if config_data.has("shooting_only"):
		unlocked_modes = unlocked_modes.filter(
			func(id: String) -> bool:
				return id not in ["voxel_editor", "wedge_placer", "off"]
		)
		for mode_def in MODE_DEFS:
			if int(mode_def.get("order", 0)) >= 1:
				_unlock_mode(mode_def["id"], false)
		# Reset index since the array shifted under us.
		current_mode_index = 0
	# Set the active mode index to point at a specific mode_id, AFTER
	# any unlocks above. This is what controls which mode A/X fires in.
	if config_data.has("active_mode"):
		var target_id: String = str(config_data["active_mode"])
		var idx: int = unlocked_modes.find(target_id)
		if idx >= 0:
			current_mode_index = idx
