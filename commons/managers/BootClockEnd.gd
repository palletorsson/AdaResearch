extends Node
## THE BOOT CLOCK'S LAST WITNESS. Registered LAST in [autoload]: its _init
## marks the parade's end, so the museum can split engine_to_ready three ways —
## engine+pak, the autoloads, and the MAIN SCENE CHAIN load (which Palle's
## disable-the-managers test showed is the real ~11 s on Quest).
var t_init_ms: int = 0
var t_staging_ms: int = 0   # stamped by vrStaging._ready — the chain's midpoint
func _init() -> void:
	t_init_ms = Time.get_ticks_msec()
