extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## The editable bench and two wall projections share one measured world displacement.
var bench: Node3D
var start_handle: Node3D
var end_handle: Node3D
var parts := false
var diagram: Node3D
var measured := Vector3.ZERO
var heading: Label3D
var interval := 0.0
var shift_sign := 1.0
var last_vector := Vector3.INF
var last_parts := false
func _ready() -> void:
	bench=get_parent()
	# The legacy bench is half scale. Keep this furniture in metres at floor level.
	scale=Vector3.ONE*2.0;position.y=-2.2
	bench.reading="bare";bench._apply_reading();bench.info_root.hide();bench.set_process(false)
	start_handle=bench.vector_a.get_node("lineContainer/GrabSphere")
	end_handle=bench.vector_a.get_node("lineContainer/GrabSphere2")
	bench.vector_a.position.z=3.6
	box(Vector3(0,1.8,-1.05),Vector3(5.6,3.2,0.12),material("122b35"),true)
	console(["SHORT","LONG","SHIFT","ZERO","PARTS"],1.65,"ONE DISPLACEMENT / TWO VIEWS")
	for child in get_children():
		if child is MeshInstance3D and child.position.is_equal_approx(Vector3(0,1.52,1.48)):
			child.position=Vector3(0,2.97,-1.0)
	readout.position=Vector3(0,2.97,-0.95)
	heading=label("",Vector3(0,3.3,-0.97),0.0013)
	label("XY / elevation",Vector3(-1.35,0.45,-0.97),0.0012)
	label("XZ / floor plan",Vector3(1.35,0.45,-0.97),0.0012)
	diagram=Node3D.new();add_child(diagram)
	var light=OmniLight3D.new();light.position=Vector3(0,3,1);light.omni_range=7;light.light_energy=1.5;add_child(light)
	refresh()
func sample_vector() -> Vector3:
	return end_handle.global_position-start_handle.global_position
func act(id: String) -> void:
	var v=sample_vector();var direction=v.normalized() if v.length()>0.0001 else Vector3(1,1,1).normalized()
	match id:
		"SHORT":end_handle.global_position=start_handle.global_position+direction*0.25
		"LONG":end_handle.global_position=start_handle.global_position+direction
		"SHIFT":
			# Move both pins together, retaining their difference in world coordinates.
			var step=global_basis.x.normalized()*0.2*shift_sign
			start_handle.global_position+=step;end_handle.global_position+=step;shift_sign*=-1
		"ZERO":end_handle.global_position=start_handle.global_position
		"PARTS":parts=not parts
	if bench._cached_vector_a_nodes.line_container.has_method("refresh_connections"):
		bench._cached_vector_a_nodes.line_container.refresh_connections()
	refresh()
func _process(delta: float) -> void:
	interval+=delta
	if interval>=0.05:interval=0;refresh()
func segment(a: Vector3, b: Vector3, color: String, radius: float=0.012) -> void:
	if a.distance_to(b)<0.00001:return
	var n=MeshInstance3D.new();var c=CylinderMesh.new();c.top_radius=radius;c.bottom_radius=radius;c.height=a.distance_to(b);c.radial_segments=8;n.mesh=c;n.material_override=material(color,true);n.position=(a+b)*0.5
	var direction=(b-a).normalized();var axis=Vector3.UP.cross(direction)
	n.quaternion=Quaternion(axis.normalized(),acos(clampf(Vector3.UP.dot(direction),-1,1))) if axis.length()>0.0001 else (Quaternion(Vector3.RIGHT,PI) if direction.y<0 else Quaternion.IDENTITY)
	diagram.add_child(n)
func refresh() -> void:
	measured=sample_vector()
	if measured.is_equal_approx(last_vector) and parts==last_parts:return
	last_vector=measured;last_parts=parts
	for n in diagram.get_children():diagram.remove_child(n);n.queue_free()
	heading.text="ONE WORLD VECTOR / two flat projections"
	readout.text="Move either pin. Predict the other view.\n"+("v = (%.2f, %.2f, %.2f) m / length %.2f m" % [measured.x,measured.y,measured.z,measured.length()] if parts else "PARTS reveals the world components")
	for i in 2:
		var origin=Vector3(-1.35+i*2.7,1.55,-0.97)
		segment(origin+Vector3(-1.05,0,0),origin+Vector3(1.05,0,0),"697b87",0.004)
		segment(origin+Vector3(0,-1.05,0),origin+Vector3(0,1.05,0),"697b87",0.004)
		var projection=Vector3(measured.x,measured.y if i==0 else measured.z,0)*0.85
		# Readout retains the exact vector when a hand drags beyond the drawing window.
		var fitted=projection.limit_length(1.05)
		var tip=origin+fitted
		segment(origin,tip,"ffe075")
		if fitted.length()>0.001:
			var d=fitted.normalized();var side=Vector3(-d.y,d.x,0)
			segment(tip,tip-d*0.1+side*0.055,"ffe075");segment(tip,tip-d*0.1-side*0.055,"ffe075")
		if parts:
			var elbow=origin+Vector3(fitted.x,0,0)
			segment(origin,elbow,"ed789d",0.009);segment(elbow,tip,"76d9cd",0.009)
		if projection.length()>1.05:heading.text="Projection clipped to wall window / read the numbers"
