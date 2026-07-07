extends SceneTree

## Proof-of-concept runner: render ScribbleControl to a PNG so we can
## judge whether the hand-stroke math reads as genuinely hand-drawn.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_scribble_test.gd

const W := 1280
const H := 900


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var ctrl_script: GDScript = load("res://commons/primitives/scribble/scribble_control.gd")
	var ctrl: Control = ctrl_script.new()
	# "All about triangles" — labelled diagram on the left, facts on the
	# right, in a handwriting font + hand-stroke Greek/math.
	ctrl.set("diagram", "triangle")
	ctrl.set("lines", PackedStringArray([
		"α + β + γ = 180°",
		"a² + b² = c²",
		"A = ½ a b",
		"A = √(s(s−a)(s−b)(s−c))",
	]))
	ctrl.size = Vector2(W, H)
	ctrl.custom_minimum_size = Vector2(W, H)
	vp.add_child(ctrl)

	# Let it lay out + draw.
	for i in range(8):
		await process_frame

	var img: Image = vp.get_texture().get_image()
	var out := "user://scribble_test.png"
	var err := img.save_png(out)
	if err == OK:
		print("[scribble] saved -> %s" % ProjectSettings.globalize_path(out))
	else:
		push_error("[scribble] save failed err=%d" % err)
	quit()
