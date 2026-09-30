extends XRToolsSceneBase
## Staged museum arrival belongs to its portal coordinator. Ordinary XRTools
## centering uses the origin as a spawn, which re-applies the tracked head offset.

func scene_loaded(user_data = null) -> void:
	var museum := get_node_or_null("Museum")
	if museum == null or not bool(museum.get("_portal_mode")):
		super.scene_loaded(user_data)
		return
	$XROrigin3D.current = true
	$XROrigin3D/XRCamera3D.current = true
	var portal: Node = museum.get("_portal_stream")
	if portal != null:
		portal.call("staging_rig_ready")
