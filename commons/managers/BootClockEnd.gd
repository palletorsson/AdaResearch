extends Node
## THE BOOT CLOCK'S LAST WITNESS. Registered LAST in [autoload]: its _init
## marks the parade's end, so the museum can split engine_to_ready three ways —
## engine+pak, the autoloads, and the MAIN SCENE CHAIN load (which Palle's
## disable-the-managers test showed is the real ~11 s on Quest).
var t_init_ms: int = 0
var t_staging_ms: int = 0   # stamped by vrStaging._ready — the chain's midpoint
## HOW MANY TIMES THE MUSEUM HAS STOOD UP IN THIS PROCESS (2026-08-26). The
## view toggle, the jump and the follow all call reload_current_scene(), and
## each re-entry stamped em_boot_last.json with RAW PROCESS UPTIME — so a
## record could read scene_chain 12869 ms, or 652485 ms, and mean nothing.
## Two agents in a row optimised against those numbers. Only entry 1 is a boot.
var museum_entries: int = 0
func _init() -> void:
	t_init_ms = Time.get_ticks_msec()
