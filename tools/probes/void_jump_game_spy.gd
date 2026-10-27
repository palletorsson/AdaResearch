extends "res://commons/void/game.gd"
## Loaded after autoload startup by the binding-only regression probe.
var retries := 0
func _ready() -> void: pass
func _physics_process(_delta: float) -> void: pass
func die(_reason: String) -> void: retries += 1
