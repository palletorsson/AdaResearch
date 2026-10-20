extends XRToolsStartXR
## Desktop runs must not attempt to initialize a deliberately disabled headset.
func _ready() -> void:
	# Godot consumes --xr-mode before scripts can read its arguments.
	if OS.get_cmdline_user_args().has("--desktop"):
		return
	super._ready()
