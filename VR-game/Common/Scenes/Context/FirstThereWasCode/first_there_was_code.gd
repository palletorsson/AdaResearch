extends Node3D
class_name FirstThereWasCode

# Configuration
@export var magenta_color: Color = Color(1.0, 0.0, 1.0)  # Neon magenta color
@export var background_color: Color = Color(0.4, 0.1, 0.4)  # Dark purple background
@export var progression_speed: float = 0.05  # Speed of typing effect

# Nodes
var environment: WorldEnvironment
@onready var player_camera = $"../../XROrigin3D/XRCamera3D/"
var grid: MeshInstance3D
@onready var terminal_text = $Label3D
var cube_scene = preload("res://adaresearch/Common/Scenes/Context/Cubes/cube_scene.tscn")
var progression_timer: Timer
var current_progression_stage: int = 0

# Typing effect variables
var terminal_lines = [
	"_ THERE WERE ALREAD \n    THE FLIPPED MONOLITE                                  ",
	" ",
	"_ THERE WAS  \n    CODE                  ",
	" ",
	"_ THERE WAS A  \n    SPACE SYSTEMS                ",
	"_",
	" ",
	"_ AND THERE WAS \n  THE GRID       ",
	"_",
	" ",
	"_ THERE WAS AN EXIT      ",
	"_",
	" ",
	"_ THERE WAS \n    INFO BOARD -->                ",
	"_",
	" ",
	"_ THERE WAS \n    ADA RESEARCH                                                                        ",
	"_",
	" "
]
var current_line_index: int = 0
var current_char_index: int = 0
var current_text: String = ""

func _ready():
	# Setup environment
	setup_environment()
	
	# Create initial elements
	setup_initial_elements()
	
	# Create progression timer
	setup_progression_timer()

func setup_progression_timer():
	progression_timer = Timer.new()
	add_child(progression_timer)
	progression_timer.wait_time = progression_speed
	progression_timer.one_shot = false
	progression_timer.connect("timeout", on_progression_timer_timeout)
	progression_timer.start()

func on_progression_timer_timeout():
	match current_progression_stage:
		0:  # Typing effect
			if current_line_index < terminal_lines.size():
				type_next_char()
			else:
				# All text typed
				current_progression_stage += 1
				progression_timer.stop()
				terminal_text.text = ""  # Clear final text if needed

func type_next_char():
	var current_line = terminal_lines[current_line_index]
	
	# Add next character
	if current_char_index < current_line.length():
		current_text += current_line[current_char_index]
		terminal_text.text = current_text
		current_char_index += 1
	else:
		# Move to next line
		current_line_index += 1
		current_char_index = 0
		current_text = ""

func setup_environment():
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = background_color
	env.ambient_light_color = Color(0.5, 0.3, 0.5)
	env.ambient_light_energy = 0.5
	
	environment = WorldEnvironment.new()
	environment.environment = env
	add_child(environment)

func setup_initial_elements():
	# Create terminal text display
	terminal_text.text = ""
	terminal_text.font_size = 36
	terminal_text.modulate = magenta_color
	terminal_text.visible = true  # Make visible from the start
