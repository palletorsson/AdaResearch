extends Node3D
## THE ROOT THAT FORWARDS (2026-08-27).
##
## GridInteractablesComponent hands an artifact its map-token configuration by
## calling apply_grid_config on the node it PLACED — the .tscn root. In all six
## walker scenes that root was a bare Node3D with no script, so the call landed
## nowhere and the grid fell back to setting properties by name on whichever
## child had them. Measured in VFM_09_Legs: that fallback set the booleans and
## silently refused every float, because a token value is a String and a typed
## float property refuses a String assignment without raising anything.
##
## So driven_by_player arrived and walker_scale, pace_reach, patrol_speed and
## show_foot_markers did not — an artifact half-configured, with every gate
## green. This forwards the whole dictionary to the Body that can read it.
func apply_grid_config(config: Dictionary) -> void:
	var body: Node = get_node_or_null("Body")
	if body == null:
		for c in get_children():
			if c.has_method("apply_grid_config"):
				body = c
				break
	if body != null and body.has_method("apply_grid_config"):
		body.call("apply_grid_config", config)
