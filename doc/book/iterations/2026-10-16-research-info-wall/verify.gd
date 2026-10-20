extends SceneTree
const WALL="res://commons/artifacts/research_info_wall/research_info_wall.gd"
const Objects=preload("res://commons/artifacts/ordinary_entropies/objects.gd")
const DIR="res://doc/book/iterations/2026-10-16-research-info-wall/"
var checks: Array=[]
var failures: Array=[]
class SuppliedGrabber extends Node3D:
	var picked_up_ranged:=false
func _initialize() -> void:run.call_deferred()
func check(label: String,ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:failures.append(label);print("FAIL ",label)
func tip(pen: Node3D,surface: Node3D,xy: Vector2) -> void:
	pen.global_position+=surface.to_global(Vector3(xy.x,xy.y,0.005))-pen.get_node("WritingTip").global_position
	pen.call("_process",0.02)
func pixel(surface: Node3D,uv: Vector2) -> Color:
	return surface.canvas._image.get_pixelv(Vector2i(uv*Vector2(surface.canvas.texture_size)))
func run() -> void:
	root.size=Vector2i(1600,1050)
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("abb7b3");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=0.65;world.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-25,0);world.add_child(sun)
	Objects.box(world,Vector3(0,-0.06,0),Vector3(20,0.1,20),Color("c3c1b8"),true)
	var wall: Node3D=load(WALL).new();wall.storage_key="native-test-%d" % Time.get_ticks_usec();world.add_child(wall)
	var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(0,1.6,6);camera.look_at(Vector3(0,1.2,0));camera.fov=62;camera.current=true
	await process_frame;await physics_frame
	check("full-height solid partition",wall.get_node("SolidPartition").mesh.size==Vector3(6.2,2.35,0.24))
	check("three movable writable notes",wall.notes.size()==3 and wall.writing_surfaces().size()==4)
	check("two markers and eraser",wall.pens.size()==3 and wall.pens[2].eraser)
	check("replaceable image uses existing capture",wall.image_view.material_override.albedo_texture!=null)
	var grabber:=SuppliedGrabber.new();world.add_child(grabber)
	var pen: Node3D=wall.pens[0];pen.set_process(false);grabber.global_transform=pen.global_transform;pen.pick_up(grabber)
	check("actual XR pickup callback",pen.is_picked_up())
	tip(pen,wall.whiteboard,Vector2(-0.35,0));tip(pen,wall.whiteboard,Vector2(0.35,0))
	check("nib writes real board pixels",pixel(wall.whiteboard,Vector2(0.5,0.5)).r<0.3)
	var strokes: int=wall.whiteboard.stroke_events
	pen.global_position+=wall.global_basis.z*0.25;pen.call("_process",0.02)
	check("air cannot write",wall.whiteboard.stroke_events==strokes and pen._previous.x<0)
	tip(pen,wall.notes[0].surface,Vector2(-0.08,0));tip(pen,wall.notes[0].surface,Vector2(0.08,0))
	check("same pen writes on sticky note",pixel(wall.notes[0].surface,Vector2(0.5,0.5)).r<0.3)
	check("changing surface does not connect a stroke",wall.notes[0].surface.stroke_events==2)
	pen.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	pen.return_to_shelf()
	check("released tool returns to shelf",pen.docked and pen.freeze)
	var eraser: Node3D=wall.pens[2];eraser.set_process(false);eraser.on_desktop_grab(null)
	tip(eraser,wall.whiteboard,Vector2.ZERO)
	check("desktop eraser removes local pixels",pixel(wall.whiteboard,Vector2(0.5,0.5)).r>0.9)
	check("eraser preserves neighbouring ink",pixel(wall.whiteboard,Vector2(0.35,0.5)).r<0.3)
	tip(eraser,wall.notes[0].surface,Vector2.ZERO)
	check("sticky eraser restores paper colour",pixel(wall.notes[0].surface,Vector2(0.5,0.5)).is_equal_approx(wall.notes[0].tint))
	eraser.on_desktop_drop(null);eraser.return_to_shelf()
	var note: Node3D=wall.notes[0];grabber.global_transform=note.global_transform;note.pick_up(grabber)
	check("sticky note actual pickup",note.is_picked_up())
	note.global_position=wall.to_global(Vector3(-0.35,0.64,0.25));note.let_go(grabber,Vector3.ZERO,Vector3.ZERO);await process_frame
	check("sticky note pins where released",note.pinned_at.is_equal_approx(Vector2(-0.35,0.64)) and note.freeze)
	note.on_desktop_grab(null);note.global_position=wall.to_global(Vector3(1,1,4));note.on_desktop_drop(null);await process_frame
	check("note released in air returns to last pin",note.position.is_equal_approx(Vector3(-0.35,0.64,0.22)))
	var original_ink: String=wall.whiteboard.encode_ink();var note_ink: String=note.surface.encode_ink()
	for value in ["gallery","workshop","night"]:
		wall.apply_style(value);check("style keeps writing "+value,wall.whiteboard.encode_ink()==original_ink)
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(DIR+"style-"+value+".png")
	wall.mark_dirty();wall.call("_process",1.0)
	check("autosave durable wall record",not wall.dirty and wall.last_save_ok and FileAccess.file_exists(wall.record_path()))
	var fresh: Node3D=load(WALL).new();fresh.storage_key=wall.storage_key;fresh.position.x=10;world.add_child(fresh);await process_frame
	check("fresh wall restores drawing",fresh.loaded_record and fresh.whiteboard.encode_ink()==original_ink)
	check("fresh wall restores note ink and position",fresh.notes[0].surface.encode_ink()==note_ink and fresh.notes[0].pinned_at==note.pinned_at)
	var before: Vector2=fresh.notes[0].pinned_at;fresh.position.z=3;fresh.rotation.y=0.3
	check("moved wall keeps writing coordinates",fresh.whiteboard.sample_uv(fresh.whiteboard.to_global(Vector3.ZERO)).is_equal_approx(Vector2(0.5,0.5)))
	check("moved wall keeps pinned position",fresh.notes[0].pinned_at==before)
	var isolated: Node3D=load(WALL).new();isolated.storage_key=wall.storage_key+"-other";isolated.position.x=-10;world.add_child(isolated);await process_frame
	check("different wall key has independent blank notes",not isolated.loaded_record and pixel(isolated.whiteboard,Vector2(0.35,0.5)).r>0.9)
	var result:={"passed":failures.is_empty(),"checks":checks,"failures":failures}
	var file:=FileAccess.open(DIR+"verification.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
	print("Research wall: ",checks.size()," checks; ",failures.size()," failures")
	world.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
