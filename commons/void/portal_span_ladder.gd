extends "res://commons/primitives/combines/combine_portals.gd"
## The original refinement experiment, fitted vertically to a six-metre storey.
func spawn_portals() -> void:
	super.spawn_portals()
	for i in _portals.size():
		var portal: MeshInstance3D=_portals[i]
		# Modest growth within the storey; the last rings open wider in the sky.
		# The source still determines each ring's increasing mesh resolution.
		var size := lerpf(.44,.54,minf(float(i)/16.0,1.0))+maxf(i-16,0)*.1
		portal.scale=Vector3.ONE*size
		portal.position.y=1.0+4.0*size
		for light in portal.find_children("*","OmniLight3D",true,false): light.hide()
	if has_node("ExperimentPanel"):
		get_node("ExperimentPanel").position=Vector3(2.3,1.35,2.2)
	for camera in find_children("*","Camera3D",true,false): camera.current=false
