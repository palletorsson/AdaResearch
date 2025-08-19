# non_euclidean_spaces.gd - Main controller for non-Euclidean experiments
extends Node3D

# Configuration

@export var enable_debug_visuals: bool = false
@export var portal_transition_speed: float = 0.2

# Nodes for quick access
@onready var player = $"../../XROrigin3D"
var debug_overlay: CanvasLayer
var portal_manager: PortalManager

func _ready():
	# Set up portal manager

	if !portal_manager:
		portal_manager = PortalManager.new()
		portal_manager.name = "PortalManager"
		add_child(portal_manager)
	else: 
		print("no portal manager")
	

	# Set up debug overlays if enabled
	if enable_debug_visuals:
		_setup_debug_overlay()
	
	# Connect signals
	portal_manager.portal_entered.connect(_on_portal_entered)
	portal_manager.portal_exited.connect(_on_portal_exited)
	
	print("Non-Euclidean Space Demo initialized")

func _setup_debug_overlay():
	debug_overlay = CanvasLayer.new()
	debug_overlay.name = "DebugOverlay"
	add_child(debug_overlay)
	
	var debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.position = Vector2(20, 20)
	debug_overlay.add_child(debug_label)

func _on_portal_entered(portal: Portal, body: Node3D):
	if body == player:
		if debug_overlay:
			var label = debug_overlay.get_node("DebugLabel")
			label.text = "Entered portal: " + portal.name

func _on_portal_exited(portal: Portal, body: Node3D):
	if body == player:
		if debug_overlay:
			var label = debug_overlay.get_node("DebugLabel")
			label.text = "Exited portal: " + portal.name

func _process(delta):
	if player and debug_overlay:
		var label = debug_overlay.get_node("DebugLabel")
		label.text += "\nPlayer position: " + str(player.global_position)
