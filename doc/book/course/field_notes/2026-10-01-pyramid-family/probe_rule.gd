extends SceneTree

func _initialize() -> void:
	var comp = load("res://commons/grid/GridInteractablesComponent.gd").new()
	for tok in ["ca_rule_explorer:180:1.04:1#study:neighbours#rule:90#plinth:0#room:comparison", "ca_rule_explorer:270:1.04#study:neighbours#rule:90#speed:4#plinth:0#room:ring"]:
		var r: Dictionary = comp._parse_config_token(tok)
		print("RULE ", tok.substr(0, 40), " | config=", r.get("config_data", {}), " | overrides=", r.get("overrides", {}))
	comp.free()
	quit()
