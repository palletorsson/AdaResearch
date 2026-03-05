extends Node3D
class_name GeneticTreeSculptor

## Interactive DNA-to-tree workbench. Eight sliders control tree genes,
## live preview regenerates via TreeMorphology. The designed DNA is stored
## globally so the branching catalyst can plant copies in the world.

const SliderScene := preload("res://commons/interactables/slider_horizontal.tscn")
const ButtonScene := preload("res://commons/interactables/push_button.tscn")

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
	# Sliders in two columns behind the tree preview
	for i in GENE_SLIDERS.size():
		var def: Array = GENE_SLIDERS[i]
		var gene_name: String = def[0]
		var label: String = def[1]
		var default_val: float = def[2]

		var slider: Node3D = SliderScene.instantiate()
		add_child(slider)

		# Layout: 2 columns, 4 rows, behind the tree (positive Z)
		var col := i % 2
		var row := i / 2
		var x_offset := -0.6 + col * 1.2
		var z_offset := 1.2 + row * 0.35
		slider.position = Vector3(x_offset, 0.85 + row * 0.0, z_offset)
		slider.rotation_degrees.y = 180.0

		slider.set_param_name(label)
		slider.set_normalized_value(default_val)
		slider.slider_moved.connect(_on_slider_moved.bind(gene_name))
		_sliders[gene_name] = slider

	# Randomize button
	var rand_btn: Node3D = ButtonScene.instantiate()
	add_child(rand_btn)
	rand_btn.position = Vector3(-0.6, 0.85, 2.7)
	rand_btn.rotation_degrees.y = 180.0
	var rand_area = rand_btn.get_node_or_null("InteractableAreaButton")
	if rand_area:
		rand_area.button_pressed.connect(_on_randomize)
	_label_button(rand_btn, "Random")

	# Export button — stores DNA for catalyst use
	var export_btn: Node3D = ButtonScene.instantiate()
	add_child(export_btn)
	export_btn.position = Vector3(0.6, 0.85, 2.7)
	export_btn.rotation_degrees.y = 180.0
	var export_area = export_btn.get_node_or_null("InteractableAreaButton")
	if export_area:
		export_area.button_pressed.connect(_on_export_dna)
	_label_button(export_btn, "Plant")

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

func _label_button(btn: Node3D, text: String) -> void:
	var lbl := btn.get_node_or_null("Frame/LabelName")
	if lbl == null:
		lbl = btn.get_node_or_null("Label3D")
	if lbl and lbl is Label3D:
		lbl.text = text

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
