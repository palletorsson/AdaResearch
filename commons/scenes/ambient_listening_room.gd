extends XRToolsSceneBase
## The existing tracked rig is retained. Walk from the entrance into the instrument.
const Travel = preload("res://commons/artifacts/ambient_patch/ambient_room_travel.gd")
var desktop: CharacterBody3D
var leaving := false
var room: Node3D

func _ready() -> void:
	room = $ListeningRoom
	room.exit_requested.connect(return_to_hall)
	$XROrigin3D/XRCamera3D.environment = room.environment
	var xr := XRServer.find_interface("OpenXR")
	if xr == null or not xr.is_initialized():
		$XROrigin3D.process_mode = Node.PROCESS_MODE_DISABLED
		$XROrigin3D.visible = false
		desktop = load("res://commons/scenes/desktop_player.tscn").instantiate()
		desktop.walk_speed = 1.5
		desktop.allow_jump = false
		add_child(desktop)
		desktop.get_node("Head").position.y = 1.65
		desktop.get_node("Head/Camera3D").environment = room.environment
		center_at_entry()

func scene_loaded(_user_data = null) -> void:
	if desktop:
		desktop.get_node("Head/Camera3D").make_current()
	else:
		super.scene_loaded(room.entry)

func center_at_entry() -> void:
	if desktop:
		desktop.global_transform = room.global_transform*room.entry
		desktop.velocity = Vector3.ZERO
		desktop.camera_rotation = Vector2.ZERO
		desktop.get_node("Head").rotation = Vector3.ZERO
		desktop.get_node("Head/Camera3D").make_current()
	else:
		center_player_on(room.global_transform*room.entry)

func return_to_hall() -> void:
	if leaving: return
	leaving = true
	room.audio.stop(true)
	var museum = load("res://commons/scenes/endless_museum.gd")
	museum.open_at("wavefunctions","WaveFunctions_Synthesis_Lab")
	if not Travel.go(self,Travel.MUSEUM): leaving = false
