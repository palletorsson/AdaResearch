extends SceneTree
var out := "res://doc/reports/ambient-room-2026-09-22/"
var checks: Array = []
var failures: Array = []
var controls: Array = []
var room: Node3D
var camera: Camera3D
class RoomTestGrabber extends Node3D:
	var picked_up_ranged := false
	var held: Node3D
	func drop_object() -> void:
		held.let_go(self,Vector3.ZERO,Vector3.ZERO)
class StagingProbe extends Node3D:
	signal scene_loaded
	var requested := ""
	func load_scene(path: String) -> void: requested = path

func _initialize() -> void: run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks.append({"passed":ok,"label":text})
	if not ok: failures.append(text)
	print("AMBIENT_ROOM ","PASS " if ok else "FAIL ",text)

func run() -> void:
	room = load("res://commons/artifacts/ambient_patch/ambient_listening_room.tscn").instantiate()
	root.add_child(room)
	camera = Camera3D.new()
	camera.environment = room.environment
	camera.position = Vector3(0,1.65,0)
	camera.fov = 82
	root.add_child(camera)
	camera.make_current()
	await physics_frame
	check(room.sliders.size()==6 and room.buttons.size()==4,"Six continuous sliders and four physical buttons")
	check(not room.audio.playing,"Arrival remains silent")
	var state := room.get_world_3d().direct_space_state
	var capsule := PhysicsShapeQueryParameters3D.new()
	capsule.shape = CapsuleShape3D.new()
	capsule.shape.radius = .22
	capsule.shape.height = 1.7
	capsule.collision_mask = 1
	capsule.transform.origin = Vector3(0,.87,0)
	check(state.intersect_shape(capsule).is_empty(),"Standing body has clear space in the open centre")
	capsule.shape.height = 1.7
	capsule.transform.origin = Vector3(0,.87,2.5)
	capsule.motion = Vector3(0,0,-2.5)
	check(state.intersect_shape(capsule).is_empty() and state.cast_motion(capsule)[0]>.99,"Clear walking approach from the doorway to the centre")
	var supported := true
	for i in 11:
		var at := Vector3(0,.15,i*.25)
		supported = supported and not state.intersect_ray(PhysicsRayQueryParameters3D.create(at,at-Vector3.UP*.25,1)).is_empty()
	check(supported,"Entry path and listening position have solid floor")
	for key in room.stations:
		var station: Node3D = room.stations[key]
		var operating := station.global_position+station.global_basis.z*.55
		capsule.motion = Vector3.ZERO
		capsule.transform.origin = operating+Vector3.UP*.87
		check(state.intersect_shape(capsule).is_empty(),key+" standing pose fits in front of its station")
		capsule.transform.origin = Vector3(0,.87,0)
		capsule.motion = operating
		check(state.cast_motion(capsule)[0]>.99,key+" can be reached across the open centre")
	for key in room.sliders:
		var slider: Node3D = room.sliders[key]
		var original: float = slider.get_normalized_value()
		for value in [0.0,1.0]:
			slider.set_normalized_value(value)
			await physics_frame
			inspect(slider,slider._handle.global_position,key+" "+str(value))
		var grabber := RoomTestGrabber.new()
		root.add_child(grabber)
		grabber.global_transform = slider._handle.global_transform
		grabber.held = slider._handle
		slider._handle.pick_up(grabber)
		grabber.global_position = slider._track.get_parent().to_global(Vector3(.18*.6,0,0))
		for i in 6: await process_frame; await physics_frame
		check(absf(float(room.audio.parameters[key])-.6)<.01,key+" native grab works on the wall station")
		grabber.drop_object()
		slider.set_normalized_value(original)
		room.audio.set_parameter(key,original)
		grabber.queue_free()
	for key in room.buttons:
		var button: Node3D = room.buttons[key]
		inspect(button,button.get_node("InteractableAreaButton/CollisionShape3D").global_position,key)
	var exiting := [false]
	room.exit_requested.connect(func(): exiting[0] = true)
	room.buttons.exit.pressed.emit()
	check(exiting[0],"BACK TO HALL emits an exit request")
	room.buttons.transport.pressed.emit()
	var start := Time.get_ticks_msec()
	while room.audio.preparing and Time.get_ticks_msec()-start<30000: await process_frame
	check(room.audio.playing,"PLAY prepares the shared samples and starts the room")
	await create_timer(3).timeout
	check(room._peak>0,"Front-wall scope receives actual output sound")
	var e: Node3D = room.audio
	for lane in 3:
		for voice in e.voices: voice.stop()
		e._play_note(lane,60+lane*12)
		var voice: Node3D = e.voices[0]
		check(voice.position.is_equal_approx(e.source_positions[lane]),"Lane %d sounds from its own visible position"%lane)
	room.buttons.route.pressed.emit()
	e.elapsed = 7.25
	e._process(.05)
	check(e.route=="pan" and is_zero_approx(e.pan.pan),"Room orbit uses 3D positions, not a global stereo pan")
	for i in 3:
		check(e.source_position(i).distance_to(e.source_positions[i])>.1,"Lane %d moves under the orbit modulation"%i)
	await create_timer(.2).timeout
	check(room.sources[2].position.distance_to(e.voices[0].position)<.06,"Visible source and actual audio source move together")
	camera.look_at(Vector3(0,1.70,-2.8))
	await shot("inside-room.png")
	camera.global_position = room.stations.RHYTHM.global_position + room.stations.RHYTHM.global_basis.z*.7 + Vector3.UP*1.65
	camera.look_at(room.stations.RHYTHM.to_global(Vector3(0,1.06,0)))
	await shot("rhythm-station.png")
	camera.position = Vector3(0,1.55,2.5)
	camera.look_at(Vector3(0,1.1,-1))
	await shot("room-from-door.png")
	camera.position = Vector3(-2.2,1.8,1.5)
	camera.look_at(Vector3(.1,1.0,-.65))
	await shot("room-overview.png")
	# Signal-path test without loading or destroying the user's museum.
	var staging := StagingProbe.new()
	root.add_child(staging)
	var compact: Node3D = load("res://commons/artifacts/ambient_patch/ambient_patch.tscn").instantiate()
	staging.add_child(compact)
	compact.buttons.room.pressed.emit()
	await process_frame
	check(staging.requested=="res://commons/scenes/room_memory.tscn","Console ENTER ROOM uses the real staging contract")
	staging.queue_free()
	var bus := String(e.bus_name)
	room.queue_free()
	await process_frame
	check(AudioServer.get_bus_index(bus)==-1,"Unloading the room removes its audio bus")
	# Load the complete inherited VR scene and exercise its desktop fallback and return.
	var wrapper = load("res://commons/scenes/ambient_listening_room.tscn").instantiate()
	var return_staging := StagingProbe.new()
	root.add_child(return_staging)
	return_staging.add_child(wrapper)
	await process_frame
	await shot("scene-entry.png")
	check(wrapper.has_signal("request_load_scene") and wrapper.has_method("center_player_on"),"Room scene is accepted by XR staging")
	check(wrapper.desktop!=null and is_equal_approx(wrapper.desktop.get_node("Head").position.y,1.65),"Desktop preview uses standing eye height")
	wrapper.desktop.position = Vector3(1,0,1)
	wrapper.center_at_entry()
	check(wrapper.desktop.position.is_equal_approx(Vector3(0,0,2.05)),"Entry positioning restores the actual desktop body position")
	# Exercise the inherited XR recenter arithmetic with a tracked head offset.
	var saved_desktop = wrapper.desktop
	wrapper.desktop = null
	var xr_eye: Node3D = wrapper.get_node("XROrigin3D/XRCamera3D")
	xr_eye.position = Vector3(.65,1.63,-.40)
	wrapper.center_at_entry()
	check(Vector2(xr_eye.global_position.x,xr_eye.global_position.z).distance_to(Vector2(0,2.05))<.001,"XR entry compensates for the tracked head's horizontal offset")
	check(absf(xr_eye.global_position.y-1.63)<.001,"XR entry preserves tracked eye height")
	wrapper.desktop = saved_desktop
	wrapper.return_to_hall()
	await process_frame
	check(return_staging.requested=="res://commons/scenes/endless_museum_staged.tscn","Exit requests the staged museum scene")
	var museum = load("res://commons/scenes/endless_museum.gd")
	check(museum.menu_chapter=="wavefunctions" and museum.menu_map=="WaveFunctions_Synthesis_Lab","Exit restores the Synthesis Lab as the destination")
	return_staging.queue_free()
	await process_frame
	var result := {"checks":checks,"failures":failures,"controls":controls,"eye_height_m":1.65,"scope":"Desktop geometry, native grab and audio tests; headset comfort and OpenXR hardware not tested."}
	FileAccess.open(out+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("AMBIENT_ROOM_RESULT ",checks.size()," checks; failures ",failures)
	quit(0 if failures.is_empty() else 1)

func inspect(host: Node3D, target: Vector3, label: String) -> void:
	var station: Node3D = host.get_parent()
	if not station.name.ends_with("Station"): station = station.get_parent()
	var feet := station.global_position + station.global_basis.z*.55
	var from := feet+Vector3.UP*1.2
	var distance := Vector2(target.x-feet.x,target.z-feet.z).length()
	var ray := PhysicsRayQueryParameters3D.create(from,target+(target-from).normalized()*.015,1|(1<<20)|(1<<22))
	ray.collide_with_areas = true
	var hit := room.get_world_3d().direct_space_state.intersect_ray(ray)
	var clear: bool = not hit.is_empty() and (hit.collider==host or host.is_ancestor_of(hit.collider))
	controls.append({"label":label,"horizontal_distance":distance,"height":target.y,"clear_ray":clear,"collider":str(hit.collider.get_path()) if not hit.is_empty() else "none"})
	check(distance<=.70,label+" is within 0.70 m from its station operating pose")
	check(target.y>=.68 and target.y<=1.22,label+" is at standing working height")
	check(clear,label+" has a clear interaction ray")

func shot(file: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+file)
