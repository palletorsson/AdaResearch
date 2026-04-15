extends Node3D
class_name GeneticTreeSculptor

# @identity
# essence: 8 sliders → CritterDNA → TreeMorphology.build() — design a tree's genome, watch it grow live
# desire: To sculpt a tree by tweaking its DNA — depth, forks, angle, taper, leaves, tropism, twist, arrangement
# critical_parameter: branch_angle (15-90°) — the single gene that most visibly transforms the tree's character
# triggers: Any slider move → debounced rebuild in 0.3s; Randomize → new genome; Plant → exports DNA for world placement
# emerges: The player becomes a breeder — intuition about which genes produce which forms develops through play
# needs: VR sliders [has, 8 sliders], push buttons [has, Random + Plant], Label3D [has via slider labels]
# relationships: Central to LSystems_Living. Uses CritterDNA and TreeMorphology systems. Bridges to evolution concepts.
# truth: A tree is eight numbers — change them and you are doing what evolution does, but with intention.

## Interactive DNA-to-tree workbench. Eight sliders control tree genes,
## live preview regenerates via TreeMorphology. The designed DNA is stored
## globally so the branching catalyst can plant copies in the world.

# --- slider definitions: [gene_name, label, default_normalized] ---
const GENE_SLIDERS: Array[Array] = [
	["segments",    "Depth",      0.4],   # generations 2-5
	["symmetry",    "Forks",      0.33],  # fork count 2-5
	["branch_angle","Angle",      0.2],   # 15-90°
	["branch_decay","Taper",      0.55],  # 0.3-0.9
	["leaf_density","Leaves",     0.5],   # 0-1
	["part_curve",  "Tropism",    0.35],  # gravity droop 0-1
	["part_twist",  "Twist",      0.5],   # -45 to 45 (0.5 = 0)
	["phyllotaxis", "Arrange",    0.0],   # spiral/opposite/whorled
]

var _dna: CritterDNA
var _mapper: CritterTraitMapper
var _tree_root: Node3D
var _sliders: Dictionary = {}   # gene_name → slider_instance
var _control_panel: Node3D
var _rebuild_queued := false
var _rebuild_timer := 0.0
const REBUILD_COOLDOWN := 0.3   # debounce slider scrubbing

func _ready() -> void:
	_dna = CritterDNA.random_kingdom(0)  # kingdom 0 = tree
	_mapper = CritterTraitMapper.new()
	_build_ui()
	_sync_sliders_from_dna()
	_rebuild_tree()

func _process(delta: float) -> void:
	if _rebuild_queued:
		_rebuild_timer -= delta
		if _rebuild_timer <= 0.0:
			_rebuild_queued = false
			_rebuild_tree()

# ── UI construction ──────────────────────────────────────────────

func _build_ui() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")

	# Build rows: 2 columns of 4 sliders each, then a button row
	var row1 := []
	var row2 := []
	for i in GENE_SLIDERS.size():
		var def: Array = GENE_SLIDERS[i]
		var entry := {"type": "slider_h", "label": def[1], "default": def[2]}
		if i < 4:
			row1.append(entry)
		else:
			row2.append(entry)

	_control_panel = RackTpl.create_panel("GENETIC TREE", [
		row1,
		row2,
		[
			{"type": "button", "label": "RANDOM"},
			{"type": "button", "label": "PLANT"},
		],
	])
	_control_panel.position = Vector3(0, 0.85, 1.2)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	# Wire up sliders
	for i in GENE_SLIDERS.size():
		var gene_name: String = GENE_SLIDERS[i][0]
		var slider = _control_panel.find_child("Param_%d" % i, true, false)
		if slider:
			_sliders[gene_name] = slider
			slider.slider_moved.connect(_on_slider_moved.bind(gene_name))

	# Wire up buttons
	var rand_btn = _control_panel.find_child("Btn_0", true, false)
	if rand_btn:
		var area = rand_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_randomize())

	var export_btn = _control_panel.find_child("Btn_1", true, false)
	if export_btn:
		var area = export_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_export_dna())

	# Pedestal for tree preview
	var pedestal := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.6
	cyl.height = 0.05
	pedestal.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.35)
	mat.roughness = 0.8
	pedestal.material_override = mat
	add_child(pedestal)
	pedestal.position = Vector3(0.0, 0.0, 0.0)

# ── Slider → DNA ─────────────────────────────────────────────────

func _on_slider_moved(_value: float, gene_name: String) -> void:
	_apply_slider_to_dna(gene_name)
	_rebuild_queued = true
	_rebuild_timer = REBUILD_COOLDOWN

func _apply_slider_to_dna(gene_name: String) -> void:
	var slider: Node3D = _sliders[gene_name]
	var n: float = slider.get_normalized_value()
	match gene_name:
		"segments":
			_dna.segments = lerpf(2.0, 10.0, n)
		"symmetry":
			_dna.symmetry = lerpf(1.0, 8.0, n)
		"branch_angle":
			_dna.branch_angle = lerpf(15.0, 90.0, n)
		"branch_decay":
			_dna.branch_decay = lerpf(0.3, 0.9, n)
		"leaf_density":
			_dna.leaf_density = n
		"part_curve":
			_dna.part_curve = n
		"part_twist":
			_dna.part_twist = lerpf(-45.0, 45.0, n)
		"phyllotaxis":
			_dna.phyllotaxis = n

func _sync_sliders_from_dna() -> void:
	for gene_name in _sliders:
		var slider: Node3D = _sliders[gene_name]
		var n: float = 0.5
		match gene_name:
			"segments":
				n = inverse_lerp(2.0, 10.0, _dna.segments)
			"symmetry":
				n = inverse_lerp(1.0, 8.0, _dna.symmetry)
			"branch_angle":
				n = inverse_lerp(15.0, 90.0, _dna.branch_angle)
			"branch_decay":
				n = inverse_lerp(0.3, 0.9, _dna.branch_decay)
			"leaf_density":
				n = _dna.leaf_density
			"part_curve":
				n = _dna.part_curve
			"part_twist":
				n = inverse_lerp(-45.0, 45.0, _dna.part_twist)
			"phyllotaxis":
				n = _dna.phyllotaxis
		slider.set_normalized_value(clampf(n, 0.0, 1.0))

# ── Tree building ────────────────────────────────────────────────

func _rebuild_tree() -> void:
	if _tree_root:
		_tree_root.queue_free()
		_tree_root = null

	_tree_root = Node3D.new()
	add_child(_tree_root)
	_tree_root.position = Vector3(0.0, 0.05, 0.0)

	TreeMorphology.build(_dna, _tree_root, _mapper, 2)

# ── Actions ──────────────────────────────────────────────────────

func _on_randomize() -> void:
	_dna = CritterDNA.random_kingdom(0)
	_sync_sliders_from_dna()
	_rebuild_tree()

func _on_export_dna() -> void:
	# Store designed DNA globally so the branching catalyst can read it
	Engine.set_meta("sculptor_tree_dna", _dna)
	# Visual feedback: brief flash
	if _tree_root:
		var tween := create_tween()
		tween.tween_property(_tree_root, "scale", Vector3(1.1, 1.1, 1.1), 0.15)
		tween.tween_property(_tree_root, "scale", Vector3.ONE, 0.15)

# ── Grid system integration ──────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("dna_seed"):
		_dna = CritterDNA.random_kingdom(0, int(config_data["dna_seed"]))
		_sync_sliders_from_dna()
		_rebuild_tree()
