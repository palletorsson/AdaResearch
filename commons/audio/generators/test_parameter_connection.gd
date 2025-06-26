# test_parameter_connection.gd
# Simple test to verify parameter controls are working

extends Control

var parameter_controls: ParameterControlsComponent

func _ready():
	print("🧪 Testing parameter controls...")
	
	# Setup basic UI
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# Create parameter controls
	parameter_controls = ParameterControlsComponent.new()
	vbox.add_child(parameter_controls)
	
	# Connect signals
	parameter_controls.parameter_changed.connect(_on_param_changed)
	
	# Create test parameters
	var test_params = {
		"frequency": {"value": 440.0, "min": 20.0, "max": 2000.0, "step": 1.0},
		"amplitude": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01}
	}
	
	# Create controls
	parameter_controls.create_parameter_controls("test_sound", test_params)
	
	print("✅ Test setup complete")

func _on_param_changed(param_name: String, value):
	print("✨ TEST: Parameter %s changed to %s" % [param_name, value]) 