extends Node3D

# Vowel Instrument (Phase 3: Embodied Control)
# Maps spatial input (Hand relative to Head) to Vowel Formants.

@export var vowel_synth_path: NodePath
@export var head_path: NodePath
@export var hand_path: NodePath

# Interaction Settings
@export var range_y: float = 0.5  # Max vertical range (Jaw Openness)
@export var range_z: float = 0.5  # Max forward range (Tongue Advancement)
@export var min_f1: float = 200.0  # Closed (High) - /i/ /u/
@export var max_f1: float = 900.0  # Open (Low) - /a/
@export var min_f2: float = 700.0  # Back - /u/ /o/
@export var max_f2: float = 2500.0 # Front - /i/ /e/

@onready var vowel_synth = get_node_or_null(vowel_synth_path)
@onready var head = get_node_or_null(head_path)
@onready var hand = get_node_or_null(hand_path) # User must assign

var is_xr: bool = false
var xr_controller: XRController3D

func _ready():
	if hand_path and not hand:
		hand = get_node(hand_path)
	
	if hand is XRController3D:
		is_xr = true
		xr_controller = hand
		print("Vowel Instrument: Attached to XR Controller")

func _process(delta):
	if not vowel_synth or not head or not hand:
		return
		
	# 1. Calculate Relative Position (Hand in Head Space)
	# We want hand position relative to head orientation? Or just global offset?
	# Global offset is easier for "Body Schema".
	# Head-relative is better for "Mouth" metaphor.
	
	var relative_pos = head.global_transform.basis.inverse() * (hand.global_position - head.global_position)
	
	# Y Axis: Jaw Openness
	# Hand roughly at mouth level (0) -> Closed. Lower (-Y) -> Open.
	var jaw_openness = remap(relative_pos.y, 0.0, -range_y, 0.0, 1.0)
	jaw_openness = clamp(jaw_openness, 0.0, 1.0)
	
	# Z Axis: Tongue Advancement
	# Hand near mouth (0) -> Back. Hand Forward (-Z in Godot?) -> Front.
	# Godot -Z is forward.
	var tongue_advancement = remap(-relative_pos.z, 0.0, range_z, 0.0, 1.0)
	tongue_advancement = clamp(tongue_advancement, 0.0, 1.0)
	
	# 2. Map to Formants
	# F1 (Jaw): Closed = Low F1. Open = High F1.
	var target_f1 = lerp(min_f1, max_f1, jaw_openness)
	
	# F2 (Tongue): Back = Low F2. Front = High F2.
	var target_f2 = lerp(min_f2, max_f2, tongue_advancement)
	
	# F3: Usually static or tracks F2 weakly.
	var target_f3 = 2500.0 + (tongue_advancement * 500.0)
	
	# 3. Apply to Synth
	# We access variables directly for speed, or via tween (but process is immediate here)
	vowel_synth.f1 = lerp(vowel_synth.f1, target_f1, delta * 15.0)
	vowel_synth.f2 = lerp(vowel_synth.f2, target_f2, delta * 15.0)
	vowel_synth.f3 = lerp(vowel_synth.f3, target_f3, delta * 15.0)
	
	# 4. Intensity (Trigger/Grip)
	var pressure = 0.0
	if is_xr:
		pressure = xr_controller.get_float("trigger") # Primary trigger
	else:
		# Mouse fallback
		pressure = 1.0 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 0.0
		
	# Update envelope
	vowel_synth.target_intensity = pressure
	if pressure > 0.01 and not vowel_synth.is_speaking:
		vowel_synth.is_speaking = true
	elif pressure < 0.01 and vowel_synth.is_speaking:
		vowel_synth.is_speaking = false
