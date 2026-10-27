extends Node3D
## Bounded pages shared by mouse/dwell and XR pointer input in the main menu.
const ButtonScene := preload("res://commons/scenes/main_menu/components/MenuButton3D.tscn")
const PAGE_SIZE := 6
var menu: Node3D
var layout: Dictionary
var rooms: Dictionary
var selected_sequence := -1
var page := 0
var separate_trials := false
var buttons: Array[Node3D] = []
var used := 0

func _exit_tree() -> void:
	# Detach geometry before unique button shaders are released by script teardown.
	for mesh in find_children("*", "MeshInstance3D", true, false):
		mesh.mesh = null

func configure(owner_menu: Node3D) -> void:
	menu = owner_menu
	# This menu always lists the saved main spine, even if the process was
	# launched with a separate trial or editor draft. Choose the context on play.
	layout = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/layout.json"))
	rooms = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/rooms.json"))
	show_page()

func _button(caption: String, at: Vector3, action: Callable) -> void:
	var button: Node3D
	if used < buttons.size():
		button = buttons[used]
		button.prepare_new_action()
		for connection in button.clicked.get_connections():
			button.clicked.disconnect(connection.callable)
	else:
		button = ButtonScene.instantiate()
		add_child(button)
		buttons.append(button)
	used += 1
	button.set_text(caption)
	button.get_node("Label3D").font_size = 32
	button.get_node("Label3D").pixel_size = .0014
	var hitbox := BoxShape3D.new()
	hitbox.size = Vector3(1.35, .22, .12)
	button.get_node("CollisionShape3D").shape = hitbox
	button.get_node("CollisionShape3D").position.x = .05
	button.position = at
	button.show()
	button.collision_layer = 1048576
	button.clicked.connect(action)

func show_page() -> void:
	# Keep a small pool of actual menu buttons. Rebuilding shader materials on
	# every page change can leave stale rendering RIDs during the same frame.
	used = 0
	for button in buttons:
		button.hide()
		button.collision_layer = 0
	var sequences: Array = layout.get("spine", [])
	var trials: Dictionary = {}
	if preload("room_source.gd").trials_available():
		trials = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/trials/playable.json")).trials
	var items: Array = trials.keys() if separate_trials else (sequences if selected_sequence < 0 else sequences[selected_sequence].floors)
	var pages := maxi(1, ceili(float(items.size()) / PAGE_SIZE))
	page = clampi(page, 0, pages - 1)
	var title := get_node_or_null("SpinePageTitle") as Label3D
	if title == null:
		title = Label3D.new()
		title.name = "SpinePageTitle"
		add_child(title)
	title.text = ("SEPARATE TRIALS" if separate_trials else ("THE VOID / CHOOSE A SEQUENCE" if selected_sequence < 0 else str(sequences[selected_sequence].title).split(":")[0])) + "  %d/%d" % [page+1,pages]
	title.font_size = 32
	title.pixel_size = .0015
	title.position = Vector3(0, 1.12, .05)
	if not separate_trials:
		var first_floor := 0 if selected_sequence < 0 else int(sequences[selected_sequence].floors[0])
		var start_caption := "Start from the beginning" if selected_sequence < 0 else "Start sequence / floor %d" % first_floor
		_button(start_caption, Vector3(0, .85, 0), func(): menu._open_void_floor(first_floor))
	for row in range(PAGE_SIZE):
		var offset := page * PAGE_SIZE + row
		if offset >= items.size(): break
		if separate_trials:
			var id: String = str(items[offset])
			_button(id.capitalize().left(37), Vector3(0,.55-row*.25,0), func():menu._open_void_trial(id))
		elif selected_sequence < 0:
			var caption := str(items[offset].title).split(":")[0].left(37)
			_button(caption, Vector3(0, .55-row*.25, 0), func(): selected_sequence=offset;page=0;show_page())
		else:
			var index := int(items[offset])
			var floor_title := str(rooms.floors[index].get("title", rooms.floors[index].map)).split(" / ")[0].replace("_", " ")
			var caption := "%03d / %s" % [index, floor_title]
			_button(caption.left(40), Vector3(0, .55-row*.25, 0), func(): menu._open_void_floor(index))
	if page > 0:
		_button("Previous", Vector3(-1.1,-.95,0), func(): page-=1;show_page())
	if page+1 < pages:
		_button("Next", Vector3(1.1,-.95,0), func(): page+=1;show_page())
	if selected_sequence < 0 and not separate_trials and preload("room_source.gd").trials_available():
		_button("Separate trials", Vector3(0,-.95,0), func():separate_trials=true;page=0;show_page())
	_button("Back", Vector3(0,-1.25,0), func():
		if selected_sequence >= 0 or separate_trials: selected_sequence=-1;separate_trials=false;page=0;show_page()
		else: menu._close_void_trials())
