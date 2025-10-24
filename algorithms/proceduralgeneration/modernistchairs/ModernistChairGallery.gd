# ModernistChairGallery.gd
# Main scene controller for the modernist chair gallery
extends Node3D
class_name ModernistChairGallery

@export var gallery_radius: float = 5.0
@export var regenerate_interval: float = 10.0
@export var auto_regenerate: bool = false

var chair_classes = [
	BauhausCantileverChair,
	BarcelonaPavilionChair,
	OrganicShellChair,
	GridWireChair,
	PrismaticCrystalChair,
	FloatingMembraneChair,
	SpiralHelicalChair,
	ModularBlockChair,
	FlowingRibbonChair,
	LevitatingCushionChair
]

var chair_instances: Array[Node3D] = []
var chair_info_labels: Array[Label3D] = []
var regenerate_timer: Timer

func _ready():
	setup_gallery()
	setup_lighting()
	setup_environment()
	setup_ui()
	
	if auto_regenerate:
		setup_auto_regeneration()

func setup_gallery():
	"""Create and position all 10 chair types in a circular gallery"""
	for i in range(chair_classes.size()):
		var angle = float(i) / chair_classes.size() * TAU
		var position = Vector3(
			cos(angle) * gallery_radius,
			0,
			sin(angle) * gallery_radius
		)
		
		# Create chair instance
		var chair = chair_classes[i].new()
		chair.position = position
		chair.rotation.y = angle + PI  # Face inward toward center
		add_child(chair)
		chair_instances.append(chair)
		
		# Create info label
		var info_label = create_chair_info_label(chair_classes[i], position)
		add_child(info_label)
		chair_info_labels.append(info_label)

func create_chair_info_label(chair_class, position: Vector3) -> Label3D:
	"""Create an informational label for each chair"""
	var label = Label3D.new()
	label.text = get_chair_name(chair_class)
	label.position = position + Vector3(0, 1.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.modulate = Color.WHITE
	return label

func get_chair_name(chair_class) -> String:
	"""Get display name for chair class"""
	match chair_class:
		BauhausCantileverChair:
			return "Bauhaus Cantilever\n(Breuer Style)"
		BarcelonaPavilionChair:
			return "Barcelona Pavilion\n(Mies van der Rohe)"
		OrganicShellChair:
			return "Organic Shell\n(Eames Style)"
		GridWireChair:
			return "Wire Grid\n(Bertoia Style)"
		PrismaticCrystalChair:
			return "Prismatic Crystal\n(Geometric Modern)"
		FloatingMembraneChair:
			return "Floating Membrane\n(Suspension Design)"
		SpiralHelicalChair:
			return "Spiral Helical\n(Mathematical Form)"
		ModularBlockChair:
			return "Modular Block\n(De Stijl/Rietveld)"
		FlowingRibbonChair:
			return "Flowing Ribbon\n(Continuous Surface)"
		LevitatingCushionChair:
			return "Levitating Cushion\n(Anti-Gravity Concept)"
		_:
			return "Unknown Chair"

func setup_lighting():
	"""Create professional gallery lighting"""
	# Main directional light (key light)
	var key_light = DirectionalLight3D.new()
	key_light.position = Vector3(5, 10, 5)
	key_light.rotation = Vector3(deg_to_rad(-30), deg_to_rad(45), 0)
	key_light.light_energy = 0.8
	key_light.shadow_enabled = true
	key_light.shadow_bias = 0.05
	add_child(key_light)
	
	# Fill light (softer, opposite side)
	var fill_light = DirectionalLight3D.new()
	fill_light.position = Vector3(-5, 8, -5)
	fill_light.rotation = Vector3(deg_to_rad(-25), deg_to_rad(-45), 0)
	fill_light.light_energy = 0.4
	fill_light.light_color = Color(0.9, 0.95, 1.0)  # Slightly cool
	add_child(fill_light)
	
	# Rim light (edge definition)
	var rim_light = DirectionalLight3D.new()
	rim_light.position = Vector3(0, 12, -8)
	rim_light.rotation = Vector3(deg_to_rad(-60), 0, 0)
	rim_light.light_energy = 0.3
	rim_light.light_color = Color(1.0, 0.9, 0.8)  # Slightly warm
	add_child(rim_light)
	
	# Ambient spotlight for center
	var spot_light = SpotLight3D.new()
	spot_light.position = Vector3(0, 8, 0)
	spot_light.rotation = Vector3(deg_to_rad(-90), 0, 0)
	spot_light.light_energy = 0.5
	spot_light.spot_range = 15.0
	spot_light.spot_angle = 45.0
	add_child(spot_light)

func setup_environment():
	"""Create gallery environment"""
	# Gallery floor
	var floor = MeshInstance3D.new()
	floor.mesh = CylinderMesh.new()
	floor.mesh.top_radius = gallery_radius * 1.5
	floor.mesh.bottom_radius = gallery_radius * 1.5
	floor.mesh.height = 0.1
	floor.position = Vector3(0, -0.05, 0)
	
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.9, 0.9, 0.9, 1.0)
	floor_material.roughness = 0.8
	floor_material.metallic = 0.1
	floor.material_override = floor_material
	add_child(floor)
	
	# Central pedestal
	var pedestal = MeshInstance3D.new()
	pedestal.mesh = CylinderMesh.new()
	pedestal.mesh.top_radius = 0.5
	pedestal.mesh.bottom_radius = 0.6
	pedestal.mesh.height = 0.3
	pedestal.position = Vector3(0, 0.15, 0)
	
	var pedestal_material = StandardMaterial3D.new()
	pedestal_material.albedo_color = Color(0.2, 0.2, 0.2, 1.0)
	pedestal_material.roughness = 0.3
	pedestal_material.metallic = 0.8
	pedestal.material_override = pedestal_material
	add_child(pedestal)
	
	# Information panel on pedestal
	var info_panel = Label3D.new()
	info_panel.text = "MODERNIST CHAIR COLLECTION\nProcedural Design Gallery\n\n10 Algorithmic Interpretations\nof Iconic 20th Century Furniture"
	info_panel.position = Vector3(0, 0.5, 0)
	info_panel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_panel.font_size = 16
	info_panel.modulate = Color.WHITE
	add_child(info_panel)

func setup_ui():
	"""Create user interface controls"""
	var ui_canvas = CanvasLayer.new()
	add_child(ui_canvas)
	
	var control_panel = Control.new()
	control_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	control_panel.position = Vector2(-250, 20)
	control_panel.size = Vector2(230, 200)
	ui_canvas.add_child(control_panel)
	
	var background = Panel.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.modulate = Color(0, 0, 0, 0.7)
	control_panel.add_child(background)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	control_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Gallery Controls"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	# Regenerate all button
	var regenerate_button = Button.new()
	regenerate_button.text = "Regenerate All Chairs"
	regenerate_button.pressed.connect(_on_regenerate_all)
	vbox.add_child(regenerate_button)
	
	# Auto-regenerate toggle
	var auto_toggle = CheckBox.new()
	auto_toggle.text = "Auto Regenerate"
	auto_toggle.button_pressed = auto_regenerate
	auto_toggle.toggled.connect(_on_auto_regenerate_toggled)
	vbox.add_child(auto_toggle)
	
	# Gallery radius slider
	var radius_label = Label.new()
	radius_label.text = "Gallery Radius"
	vbox.add_child(radius_label)
	
	var radius_slider = HSlider.new()
	radius_slider.min_value = 3.0
	radius_slider.max_value = 10.0
	radius_slider.value = gallery_radius
	radius_slider.step = 0.5
	radius_slider.value_changed.connect(_on_radius_changed)
	vbox.add_child(radius_slider)

func setup_auto_regeneration():
	"""Setup automatic chair regeneration timer"""
	regenerate_timer = Timer.new()
	regenerate_timer.wait_time = regenerate_interval
	regenerate_timer.autostart = true
	regenerate_timer.timeout.connect(_on_regenerate_timer_timeout)
	add_child(regenerate_timer)

func _on_regenerate_all():
	"""Regenerate all chairs with random parameters"""
	for chair in chair_instances:
		if chair.has_method("regenerate_with_parameters"):
			var random_params = generate_random_parameters()
			chair.regenerate_with_parameters(random_params)

func _on_auto_regenerate_toggled(pressed: bool):
	"""Toggle auto-regeneration"""
	auto_regenerate = pressed
	if auto_regenerate and not regenerate_timer:
		setup_auto_regeneration()
	elif regenerate_timer:
		regenerate_timer.paused = not auto_regenerate

func _on_radius_changed(value: float):
	"""Change gallery radius"""
	gallery_radius = value
	reposition_chairs()

func _on_regenerate_timer_timeout():
	"""Auto-regeneration timer callback"""
	if auto_regenerate:
		_on_regenerate_all()

func reposition_chairs():
	"""Reposition chairs in a circle with new radius"""
	for i in range(chair_instances.size()):
		var angle = float(i) / chair_instances.size() * TAU
		var position = Vector3(
			cos(angle) * gallery_radius,
			0,
			sin(angle) * gallery_radius
		)
		
		chair_instances[i].position = position
		chair_instances[i].rotation.y = angle + PI
		chair_info_labels[i].position = position + Vector3(0, 1.2, 0)

func generate_random_parameters() -> Dictionary:
	"""Generate random parameters for chair variation"""
	return {
		"scale_factor": randf_range(0.8, 1.2),
		"material_variation": randf_range(0.0, 0.2),
		"geometric_variation": randf_range(0.0, 0.3)
	}

func _input(event):
	"""Handle input for gallery interaction"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				_on_regenerate_all()
			KEY_T:
				auto_regenerate = not auto_regenerate
				_on_auto_regenerate_toggled(auto_regenerate)
			KEY_ESCAPE:
				get_tree().quit()
































