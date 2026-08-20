extends Node
## THE BOOT CLOCK'S FIRST WITNESS (2026-08-20). Registered FIRST in
## [autoload], so its _init stamp is the moment the engine and the pak are
## done and the autoload parade begins. The museum reads it into boot_ms:
##   engine_pak      = t_init_ms                    (engine + pak mount)
##   autoloads_scene = engine_to_ready - t_init_ms  (22 autoloads + scene load)
## Quest measured engine_to_ready at 15 s — this tells the two halves apart.

var t_init_ms: int = 0
var t_ready_ms: int = 0


func _init() -> void:
	t_init_ms = Time.get_ticks_msec()


func _ready() -> void:
	t_ready_ms = Time.get_ticks_msec()
