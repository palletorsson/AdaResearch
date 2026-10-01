extends Resource
## A palette: two colours, the space they are mixed in, and the reason.
## A Resource is something Godot can keep as a file. palette.tres, beside this
## script, is one. Every script that loads that file gets the same palette, so
## a change made there reaches every body that asks it for a colour.
##   mix(t)    the colour `t` of the way from `first` to `second`, t from 0 to 1
##   step(i)   the colour of step `i` of `steps`, counted from 0
## It is the function mix() of the lesson's wall.gd, moved here. A guest names
## nothing outside its folder, so the OKLab arithmetic is written out below
## (Björn Ottosson's numbers, 2020) instead of being lent from the kit.

@export var first := Color("c6ff3d")
@export var second := Color("3900c2")
@export_enum("rgb", "hsv", "linear", "oklab") var space := "rgb"
@export var steps := 9
@export_multiline var because := ""   # the argument for this pair in this space: one sentence

func step(i: int) -> Color:
	return mix(i / float(maxi(steps, 2) - 1))

func mix(t: float) -> Color:
	if space == "rgb":
		return first.lerp(second, t)
	if space == "hsv":
		var turn := second.h - first.h
		if turn > 0.5:
			turn -= 1.0
		elif turn < -0.5:
			turn += 1.0
		var h := fposmod(first.h + turn * t, 1.0)
		return Color.from_hsv(h, lerpf(first.s, second.s, t), lerpf(first.v, second.v, t))
	if space == "linear":
		var light := first.srgb_to_linear().lerp(second.srgb_to_linear(), t)
		return light.linear_to_srgb()
	if space == "oklab":
		return _from_oklab(_to_oklab(first).lerp(_to_oklab(second), t))
	push_error("palette.gd has no space called " + space)
	return Color.BLACK

func _to_oklab(c: Color) -> Vector3:
	var lin := c.srgb_to_linear()
	var l := pow(0.4122214708 * lin.r + 0.5363325363 * lin.g + 0.0514459929 * lin.b, 1.0 / 3.0)
	var m := pow(0.2119034982 * lin.r + 0.6806995451 * lin.g + 0.1073969566 * lin.b, 1.0 / 3.0)
	var s := pow(0.0883024619 * lin.r + 0.2817188376 * lin.g + 0.6299787005 * lin.b, 1.0 / 3.0)
	return Vector3(
		0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)

func _from_oklab(lab: Vector3) -> Color:
	var l := pow(lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z, 3.0)
	var m := pow(lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z, 3.0)
	var s := pow(lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z, 3.0)
	var lin := Vector3(
		4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
		-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
		-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s).clamp(Vector3.ZERO, Vector3.ONE)
	return Color(lin.x, lin.y, lin.z).linear_to_srgb()
