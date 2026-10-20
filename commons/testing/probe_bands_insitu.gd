extends SceneTree
## WHAT DOES THE CAPTURE ACTUALLY SEE? Default tick rate, wall-clock waits.

const SCENE := "res://commons/artifacts/forbidden_bands/forbidden_bands.tscn"


func _init() -> void:
	print("project physics ticks/s = %d" % Engine.physics_ticks_per_second)
	var n = load(SCENE).instantiate()
	get_root().add_child(n)
	for i in range(16):
		await create_timer(0.5).timeout
		print("t=%4.1fs  rho=%3.0f mm  az=%+4.0f  settled=%s" % [
			float(i + 1) * 0.5, n.rest_rho_m() * 1000.0,
			n.rest_azimuth_deg(), n.is_settled()])
	quit(0)
