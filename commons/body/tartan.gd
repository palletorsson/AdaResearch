extends RefCounted
## (no class_name on purpose — consumers preload this. A global class name
## resolves in the editor and not at the command line, and the gates are all
## command line.)
## A PINK TARTAN, woven rather than drawn.
##
## 2026-08-29, Palle: "arms and torso should have pink Tartan pattern."
##
## A tartan is not a plaid texture — it is a SETT: one sequence of coloured bands,
## applied to the warp and again to the weft, so the cloth is symmetric about
## every pivot and the pattern repeats by reflection. Where two bands cross, the
## thread of each shows through the other, which is why a tartan has no flat
## fills: every square is a blend of two colours, and only the squares on the
## diagonal are a colour by itself.
##
## So the image here is built the way cloth is: sett(x) blended with sett(y). That
## one line is the difference between a tartan and a grid of rectangles, and it is
## also why the darker crossings appear without anyone authoring them.
##
##     var mat := Tartan.material()          # ready to hang on anything
##     var tex := Tartan.texture(512)        # the cloth itself
##
## THE MESHES HERE HAVE NO UVs. ik_arm_rig builds its arm procedurally and never
## writes ARRAY_TEX_UV, and the garment is a stack of CylinderMesh tiers. So the
## material maps TRIPLANAR, in world space — which on a limb reads as cloth cut
## from a bolt and wrapped, and needs no unwrap that nobody has written.

## The sett, as a weaver would write it: [colour, threads]. Read it as a pivot
## sequence — it is mirrored to make the full repeat, which is what gives tartan
## its symmetry.
const SETT := [
	[Color(0.78, 0.22, 0.42), 26],   # rose — the ground
	[Color(0.95, 0.72, 0.80), 8],    # pale pink
	[Color(0.78, 0.22, 0.42), 14],   # rose
	[Color(0.28, 0.06, 0.16), 6],    # deep maroon — the dark guard
	[Color(0.98, 0.94, 0.92), 3],    # white overcheck, the thin bright line
	[Color(0.28, 0.06, 0.16), 6],    # maroon again, guarding the other side
	[Color(0.88, 0.44, 0.60), 18],   # mid pink
	[Color(0.55, 0.12, 0.30), 5],    # wine
]


## The sett expanded to a thread list, mirrored so the cloth pivots like real
## tartan instead of tiling like wallpaper.
static func threads() -> Array:
	var out: Array = []
	for band in SETT:
		for _i in range(int(band[1])):
			out.append(band[0])
	# mirror all but the two pivot threads — the standard reflective sett
	var back: Array = out.duplicate()
	back.reverse()
	return out + back.slice(1, back.size() - 1)


## The woven cloth. `size` is the pixel side; the sett is scaled to fill it once.
static func texture(size: int = 512) -> ImageTexture:
	var warp: Array = threads()
	var n: int = warp.size()
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in range(size):
		var wy: Color = warp[int(float(y) * n / float(size)) % n]
		for x in range(size):
			var wx: Color = warp[int(float(x) * n / float(size)) % n]
			# THE CROSSING. Over-under twill: which thread shows depends on the
			# diagonal, so the same pair of colours reads light one way and dark
			# the other. A flat 50/50 average loses the weave and looks printed.
			var over: bool = ((x + y) / 3) % 2 == 0
			var c: Color = wx.lerp(wy, 0.35) if over else wy.lerp(wx, 0.35)
			# a little tooth, so it reads as thread rather than as a gradient
			var tooth: float = 1.0 - 0.06 * float((x + y) % 2)
			img.set_pixel(x, y, Color(c.r * tooth, c.g * tooth, c.b * tooth))
	return ImageTexture.create_from_image(img)


## A material that will hang on any mesh, UVs or not.
##
## `scale_m` is how many metres one full sett repeat covers — 0.42 puts roughly
## one repeat across a torso and two down an arm, which is the size a woven check
## actually is. Larger numbers make the cloth coarser.
static func material(scale_m: float = 0.42, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture(512)
	mat.albedo_color = tint
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE / maxf(0.01, scale_m)
	# cloth, not plastic: rough, barely specular, and lit from both sides because
	# a sleeve is a thin tube you can see the inside of at the cuff.
	mat.roughness = 0.92
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat
