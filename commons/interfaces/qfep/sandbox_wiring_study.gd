extends Node3D
## Connect one existing reactor to exactly two local handles.
## This is a causal-wiring experiment, not a new entropy model.
const InterfacePresets = preload("res://commons/ui/interface_presets.gd")
var receiver: Node3D
var lambda_source: Node3D
var phi_source: Node3D
var connected: bool = false
var panel: Node3D
var readout: Label
var buttons: Array[Node3D] = []
var wires: Array[MeshInstance3D] = []
var wire_material: StandardMaterial3D
var _refresh_time := 0.0

func _ready() -> void:
	receiver = get_parent()
	panel = InterfacePresets.build("machine", "WHERE THE CONTROL REACHES", 1.0)
	# Map places the core 1.3m high; the console sits at 1.0m, in front.
	panel.position = Vector3(0, -0.3, 3.4)
	add_child(panel)
	readout = panel.add_readout("")
	buttons = [panel.add_button("CONNECT / CUT"), panel.add_button("REPEAT")]
	buttons[0].get_node("InteractableAreaButton").button_pressed.connect(func(_body): toggle_connection())
	buttons[1].get_node("InteractableAreaButton").button_pressed.connect(func(_body): repeat_response())
	wire_material = StandardMaterial3D.new()
	wire_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(2):
		var line := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius=0.009
		cylinder.bottom_radius=0.009
		cylinder.radial_segments=8
		line.mesh=cylinder
		line.material_override=wire_material
		add_child(line)
		wires.append(line)
	call_deferred("discover_sources")
	_refresh()

func discover_sources() -> bool:
	_detach_sources()
	connected=false
	var lambdas: Array[Node3D] = []
	var phis: Array[Node3D] = []
	# The museum seats artifacts directly in their hall. Never search the tree
	# globally: another loaded hall must not become an accidental controller.
	for node in receiver.get_parent().get_children():
		if node is LambdaSlider: lambdas.append(node)
		if node is PhiSlider: phis.append(node)
	if lambdas.size()!=1 or phis.size()!=1:
		_refresh()
		return false
	lambda_source=lambdas[0]
	phi_source=phis[0]
	lambda_source.lambda_changed.connect(_lambda_changed)
	phi_source.phi_changed.connect(_phi_changed)
	_refresh()
	return true

func _detach_sources() -> void:
	if is_instance_valid(lambda_source) and lambda_source.lambda_changed.is_connected(_lambda_changed):
		lambda_source.lambda_changed.disconnect(_lambda_changed)
	if is_instance_valid(phi_source) and phi_source.phi_changed.is_connected(_phi_changed):
		phi_source.phi_changed.disconnect(_phi_changed)
	lambda_source=null
	phi_source=null

func _exit_tree() -> void:
	_detach_sources()

func _sources_available() -> bool:
	return is_instance_valid(lambda_source) and is_instance_valid(phi_source)

func toggle_connection() -> void:
	if not _sources_available() and not discover_sources(): return
	connected=not connected
	if connected:
		receiver.set_lambda(lambda_source.lambda)
		receiver.set_phi(phi_source.phi)
		receiver._update_visuals()
	_refresh()

func _lambda_changed(value: float) -> void:
	if connected:
		receiver.set_lambda(value)
		receiver._update_visuals()
	_refresh()

func _phi_changed(value: float) -> void:
	if connected:
		receiver.set_phi(value)
		receiver._update_visuals()
	_refresh()

func repeat_response() -> void:
	# Keep connection and values; repeat the receiver's animation start.
	# GPU particle histories restart but are not asserted bit-identical.
	receiver.time=0.0
	receiver.pulse_phase=0.0
	receiver._rng.seed=receiver.JITTER_SEED
	receiver._update_animation(0.0)
	receiver._update_visuals()
	receiver.particle_system.restart()
	_refresh()

func _process(delta: float) -> void:
	_refresh_time+=delta
	if _refresh_time<0.1: return
	_refresh_time=0.0
	if not _sources_available(): connected=false
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(receiver) or readout==null: return
	var sources_ok := _sources_available()
	var state := "CONNECTED" if connected and sources_ok else "CUT: inputs held"
	if not sources_ok: state="LOCAL HANDLES UNAVAILABLE"
	var source_text := "-- / --"
	if sources_ok: source_text="%.2f / %+.2f" % [lambda_source.lambda,phi_source.phi]
	var pm: ParticleProcessMaterial = receiver.particle_system.process_material
	readout.text="%s | handles %s\nused %.2f / %+.2f | particle max %.2f m/s" % [state,source_text,receiver.current_lambda,receiver.current_phi,pm.initial_velocity_max]
	var label: Label3D = receiver.get_node_or_null("StateLabel")
	if label:
		# Values on the console are the actual receiver properties.
		label.text="lambda: colour / speed\nphi: lightness"
		label.modulate=Color.WHITE
	if wire_material:
		wire_material.albedo_color=Color(0.1,0.8,0.9) if connected and sources_ok else Color(.22,.24,.26)
	for i in range(wires.size()):
		wires[i].visible=sources_ok
		if not sources_ok: continue
		var source: Node3D = lambda_source if i==0 else phi_source
		var start: Vector3 = to_local(source._handle.global_position)
		var finish: Vector3 = to_local(receiver.global_position)+Vector3(0,-.25,0)
		var direction := finish-start
		wires[i].position=(start+finish)*.5
		(wires[i].mesh as CylinderMesh).height=direction.length()
		if direction.length()>.001: wires[i].basis=Basis(Quaternion(Vector3.UP,direction.normalized()))
