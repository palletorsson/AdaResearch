extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var artifact:=Node3D.new()
	root.add_child(artifact)
	var outer_camera:=Camera3D.new()
	artifact.add_child(outer_camera)
	outer_camera.current=true
	var outer_caption:=CanvasLayer.new()
	artifact.add_child(outer_caption)
	var viewport:=SubViewport.new()
	viewport.own_world_3d=true
	artifact.add_child(viewport)
	var inner_camera:=Camera3D.new()
	viewport.add_child(inner_camera)
	inner_camera.current=true
	var inner_caption:=CanvasLayer.new()
	viewport.add_child(inner_caption)
	var embedding=load("res://commons/grid/GridInteractablesComponent.gd").new()
	embedding.call("_suppress_embedded_chrome",artifact)
	embedding.call("_suppress_embedded_chrome",artifact)
	var passed: bool=not outer_camera.current and not outer_caption.visible and inner_camera.current and inner_caption.visible
	print("PRIVATE VIEWPORT EMBEDDING: ",passed)
	artifact.set_meta("em_map","LSystems_Grammars_And_Curves")
	var source:=Node3D.new()
	artifact.add_child(source)
	var outer_light:=DirectionalLight3D.new()
	artifact.add_child(outer_light)
	var inner_light:=DirectionalLight3D.new()
	viewport.add_child(inner_light)
	var outer_label:=Label3D.new()
	outer_label.pixel_size=.01
	artifact.add_child(outer_label)
	var inner_label:=Label3D.new()
	inner_label.pixel_size=.01
	viewport.add_child(inner_label)
	var lesson=load("res://commons/artifacts/interpreter_lesson/interpreter_lesson.gd").new()
	lesson.set("source",source)
	lesson.call("_stage_hall")
	var scoped: bool=not outer_light.visible and inner_light.visible and inner_camera.current and is_equal_approx(outer_label.pixel_size,.002) and is_equal_approx(inner_label.pixel_size,.01)
	print("HALL STAGING SCOPE: ",scoped)
	passed=passed and scoped
	lesson.free()
	embedding.free()
	artifact.free()
	quit(0 if passed else 1)
