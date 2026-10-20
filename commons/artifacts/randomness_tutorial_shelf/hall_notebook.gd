extends "res://doc/book/studies/randomness-shelf/shelf_notebook.gd"
## Remember which exact saved study LOAD should reopen on the next visit.
@export var last_record_path := "user://randomness-shelf-last.txt"

func _ready() -> void:
	if FileAccess.file_exists(last_record_path):
		load_path = FileAccess.get_file_as_string(last_record_path).strip_edges()

func save_trial() -> String:
	var path := super.save_trial()
	if not path.is_empty():
		var file := FileAccess.open(last_record_path, FileAccess.WRITE)
		if file != null:
			file.store_string(path)
			file.close()
	return path

