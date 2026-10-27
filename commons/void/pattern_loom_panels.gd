extends "res://commons/ui/panel_bridge/test_panel_bridge.gd"
## A shaft-count token selects the existing complete loom example. Passing only
## {shafts:8} as capture data would replace the draft with an empty dictionary.
func _ready() -> void:
	# Build once. Replacing the default panels in the same frame cancels their
	# pending viewport injection and retains the previous DraftDataStore.
	_load_example(1 if int(get_meta("config_shafts",4))>4 else 0)

func apply_grid_config(config: Dictionary) -> void:
	if config.size()==1 and config.has("shafts"):
		var wanted:=1 if int(config.shafts)>4 else 0
		if current_example!=wanted:_load_example(wanted)
	else:
		super(config)

func _create_info_label() -> void: pass
