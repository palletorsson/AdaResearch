extends SceneTree

## Does `point_finish:dark` actually reach the floating point's MATERIAL?
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_point_finish.gd
##
## Written because the log lied by omission. GridInteractablesComponent calls
## apply_grid_config with call_deferred, so a map token's point_finish lands after
## _ready has already built the point — the log printed
## `Applying config … "point_finish": "dark"` and the bead stayed pale. A capture
## at map scale is too small to tell. This reads the albedo off the surface.
##
## It builds the frame the way the component does: metadata set BEFORE the node
## enters the tree, which is the ordering the fix depends on.

const FRAME := "res://algorithms/vectors/00_coordinates/CoordinateSystem3M.tscn"


func _initialize() -> void:
	var fails: int = 0
	for want in ["glow", "dark"]:
		var ps: PackedScene = load(FRAME)
		var n: Node3D = ps.instantiate() as Node3D
		n.set("floating_point", true)
		n.set_meta("config_point_finish", want)   # as the component does it
		root.add_child(n)
		# _initialize runs BEFORE the first frame, so add_child does not run _ready
		# here the way it does mid-game. Without this the probe reports children=[]
		# and blames the artifact for the harness.
		await process_frame
		await process_frame

		var pt: Node = n.get_node_or_null("FloatingPoint")
		if pt == null:
			var kids: Array[String] = []
			for c in n.get_children():
				kids.append(c.name)
			print("FAIL  %-5s no FloatingPoint. floating_point=%s ready=%s scene_exists=%s children=%s"
				% [want, str(n.get("floating_point")), str(n.is_node_ready()),
				   str(ResourceLoader.exists("res://commons/primitives/point/interactive_point_origin.tscn")),
				   str(kids)])
			fails += 1
			n.queue_free()
			continue

		var got: String = str(pt.get("finish"))
		var mi: MeshInstance3D = pt.get_node_or_null("MeshInstance3D") as MeshInstance3D
		var mat: BaseMaterial3D = null
		if mi != null:
			mat = mi.material_override as BaseMaterial3D

		if mat == null:
			print("FAIL  %-5s finish=%s but no material_override on the mesh" % [want, got])
			fails += 1
		else:
			var a: Color = mat.albedo_color
			var lum: float = 0.2126 * a.r + 0.7152 * a.g + 0.0722 * a.b
			var coat: bool = mat.clearcoat_enabled
			print("%-5s finish=%-5s albedo=(%.3f, %.3f, %.3f) lum=%.3f metallic=%.2f "
				% [want, got, a.r, a.g, a.b, lum, mat.metallic]
				+ "spec=%.2f clearcoat=%s rim=%s" % [mat.metallic_specular, str(coat), str(mat.rim_enabled)])
			# the whole point of the request: dark has to be DARK, and glossy has to
			# have the second lobe. Numbers, not an opinion about a screenshot.
			if want == "dark":
				if lum > 0.18:
					print("      FAIL  dark is not dark — luminance %.3f" % lum); fails += 1
				if not coat:
					print("      FAIL  no clearcoat — one lobe reads as a disc, not a ball"); fails += 1
			else:
				if lum < 0.30:
					print("      FAIL  glow default changed — luminance %.3f, the 44 other maps moved" % lum)
					fails += 1
		n.queue_free()

	print("\nprobe_point_finish: %s" % ("PASS" if fails == 0 else "%d FAILURE(S)" % fails))
	quit(1 if fails > 0 else 0)
