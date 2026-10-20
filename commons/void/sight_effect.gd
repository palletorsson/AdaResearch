extends Node
## One health-driven display adapter for desktop and XR. Mobile/Forward+ use
## per-eye raster passes. Compatibility desktop uses a final 2D screen pass.
const Blur := preload("res://commons/void/sight_blur.gd")
const Compat := preload("res://commons/void/sight_blur_compat.gdshader")
var blur: CompositorEffect
var overlay: ColorRect
var amount := 0.0

func configure(camera: Camera3D, health: Node) -> void:
	if DisplayServer.get_name()=="headless":
		pass # Behavior tests still exercise exactly the same health/sight state.
	elif RenderingServer.get_current_rendering_method()=="gl_compatibility" and not camera is XRCamera3D:
		var layer := CanvasLayer.new()
		layer.name="BiteSightCompatibility"; layer.layer=110
		add_child(layer)
		overlay=ColorRect.new()
		overlay.name="BiteSight"
		overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var material := ShaderMaterial.new()
		material.shader=Compat
		overlay.material=material
		layer.add_child(overlay)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	elif RenderingServer.get_rendering_device()!=null:
		blur=Blur.new()
		if camera.compositor==null: camera.compositor=Compositor.new()
		var effects := camera.compositor.compositor_effects
		effects.append(blur)
		camera.compositor.compositor_effects=effects
	else:
		push_warning("Void headset sight blur requires the Mobile or Forward+ renderer.")
	health.sight_changed.connect(set_amount)
	set_amount(health.sight_impairment)

func set_amount(value: float) -> void:
	amount=value
	if blur!=null: blur.set_amount(value)
	if overlay!=null:
		overlay.visible=value>0.0001
		overlay.material.set_shader_parameter("amount",value)

func _exit_tree() -> void:
	if blur!=null: blur.release()
