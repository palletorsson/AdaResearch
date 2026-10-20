extends "res://commons/hazards/DangerZone.gd"
## Existing electrical hazard visuals/contact, adapted only to Void charge.
const DISCHARGE := 20.0
var cooldown := 0.0
var shock_count := 0

func _ready() -> void:
	danger_type = Type.ELECTRIC
	flash_on_damage = false
	super()
	if warning_label != null: warning_label.text = "LIVE / DISCHARGE"

func _process(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	super(delta)

func _deal_damage(_amount: float) -> void:
	if cooldown>0 or _neutralized: return
	var battery := get_tree().get_first_node_in_group("void_health")
	if battery == null or battery.suspended: return
	var world := battery.get_parent()
	if not world.ready_for_play or world.returning or not is_visible_in_tree(): return
	cooldown = 1.5
	shock_count += 1
	battery.discharge(DISCHARGE,"electric shock")
	damage_dealt.emit(DISCHARGE,danger_type)

func _flash_screen(_color: Color) -> void:
	pass # The Void's one shared feedback layer handles this event.
