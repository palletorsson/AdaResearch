extends Resource
class_name SoundCollection

@export var collection_name: String = "New Collection"
@export var layout_columns: int = 4
@export var items: Array[Dictionary] = [] # Array of { "sound_id": "...", "label": "...", "color": Color(...) }
