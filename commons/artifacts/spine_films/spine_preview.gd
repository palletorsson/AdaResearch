extends "res://commons/artifacts/concept_monitor/preview.gd"
var films: Array = []
var selected := 0
var picker: OptionButton

func _ready() -> void:
	films=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/spine_films/catalog.json"))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--collection="):
			var collection := arg.trim_prefix("--collection=")
			films = films.filter(func(f: Dictionary): return f.get("collection", "") == collection)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--film-id="):
			for i in range(films.size()):
				if films[i].id==arg.trim_prefix("--film-id="):selected=i
	monitor_scene=load(films[selected].monitor_scene)
	super._ready()
	picker=OptionButton.new()
	picker.position=Vector2(25,82)
	for film: Dictionary in films:
		picker.add_item(("TRY · " if film.get("collection","")=="foundation" else ("NEW · " if film.get("collection","")=="more" else ""))+film.title)
	picker.select(selected)
	picker.item_selected.connect(select_film)
	add_child(picker)

func select_film(index: int) -> void:
	selected=index
	remove_child(monitor)
	monitor.queue_free()
	monitor=load(films[index].monitor_scene).instantiate()
	add_child(monitor)
	pressed_target=null
	camera.make_current()
