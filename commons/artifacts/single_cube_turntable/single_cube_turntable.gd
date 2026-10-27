extends "res://commons/artifacts/scale_zoetrope/scale_zoetrope.gd"
## One fixed cube sits on the axis of a compact rotating plate. The platform's
## rotation turns its orientation in place; no separate cube animation.

func _ready() -> void:
	open_frame = true;frame_count = 1;orbit_radius = 0.0;plate_radius = .55
	deck_y = 1.05;control_z = 1.72;drop_z = 1.36;fixed_cube_edge = .48
	rpm_limit = 30;motor_rpm = 10;sample_hz = 0
	super._ready()
	part_defaults.DiskAndCrank.bounds = [-.57,0,-.57,2.12,1.85,2.59]
	set_meta("void_preview_kind","Real single-cube turntable, pink hand crank and speed/phase controls. Cube is fixed to the plate; native motor yields to the hand.")

func build_shutter() -> void:
	# Retain the base transmission hook without adding a sampling blind.
	shutter = MeshInstance3D.new();shutter.name = "UnusedSamplingHook"
	drive.add_child(shutter)

func build_controls() -> void:
	controls = Node3D.new();controls.name = "PlaybackControls"
	controls.position = Vector3(1.03,1.98,control_z)
	rod(controls,Vector3(0,-1.94,-.12),Vector3(0,.31,-.12),.04,steel).name = "ControlStand"
	box(controls,Vector3(0,-1.94,-.12),Vector3(.55,.08,.42),steel,true).name = "ControlStandFoot"
	console = load("res://commons/ui/physical_parameter_console.gd").new()
	console.name = "PlaybackConsole";console.title = "ONE CUBE / ONE TURN"
	var parameters: Array[Dictionary] = [{"label":"RPM","continuous":true,"value":motor_rpm/rpm_limit},
		{"label":"ANGLE","continuous":true,"value":0.0}]
	console.parameters = parameters;console.actions = PackedStringArray(["RUN","REVERSE"])
	controls.add_child(console);add_child(controls);MachineFinish.console_finish(console)
	console.parameter_changed.connect(_on_parameter);console.action_pressed.connect(_on_action)
	words(controls,"HAND / PLATE / CUBE",Vector3(0,.41,.018),0)

func _on_parameter(index: int,value: float) -> void:
	if index==0:set_rpm(value*rpm_limit)
	else:
		auto_run = false;wheel.set_angle_degrees(value*360)
		motor_phase = angle_degrees;refresh_controls()

func _on_action(index: int) -> void:
	if index==0:auto_run = not auto_run;motor_phase = angle_degrees
	else:reverse = not reverse
	refresh_controls()

func refresh_controls() -> void:
	if not is_instance_valid(console) or not console.is_node_ready():return
	console.set_parameter(0,motor_rpm/rpm_limit)
	console.set_parameter(1,fposmod(angle_degrees,360)/360)
	console.set_action_selected(0,auto_run);console.set_action_selected(1,reverse)
	var state := "HAND" if hand_active() or manual_cooldown>0 else ("AUTO" if auto_run else "STOP")
	console.set_reading("%s | %.1f RPM | %s\nANGLE %.0f deg | ONE FIXED CUBE"%[state,motor_rpm,"REVERSE" if reverse else "FORWARD",fposmod(angle_degrees,360)])
