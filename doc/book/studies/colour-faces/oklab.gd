extends RefCounted
## Supplied with this kit: OKLab, a colour space built to follow the eye.
## Use it by path:
##   const Oklab := preload("res://oklab.gd")
##   var middle: Color = Oklab.mix(first, second, 0.5)
## Contract:
##   mix(a, b, t)     the colour `t` of the way from a to b along a straight
##                    line in OKLab; t = 0 gives a, t = 1 gives b. A colour the
##                    screen cannot show is cut to the nearest it can, channel by channel
##   from_srgb(c)     a Color as OKLab: Vector3(L, a, b). L is lightness, 0 to 1;
##                    a runs from green to red, b from blue to yellow
##   to_srgb(lab)     the way back; `cut(lab)` says whether to_srgb() had to cut
##   apart(c, d)      how far apart two Colors are in OKLab, times 100:
##                    about 2 is a difference an eye can just find, on a good screen
## OKLab was published by Björn Ottosson in 2020; the numbers below are his.
## It is built so that equal distances in it look about equally different.
## This file is lent: use it, and open it when you want to know how.

static func from_srgb(c: Color) -> Vector3:
	var lin := c.srgb_to_linear()
	var l := pow(0.4122214708 * lin.r + 0.5363325363 * lin.g + 0.0514459929 * lin.b, 1.0 / 3.0)
	var m := pow(0.2119034982 * lin.r + 0.6806995451 * lin.g + 0.1073969566 * lin.b, 1.0 / 3.0)
	var s := pow(0.0883024619 * lin.r + 0.2817188376 * lin.g + 0.6299787005 * lin.b, 1.0 / 3.0)
	return Vector3(
		0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)

## The linear-light red, green and blue of an OKLab colour, not yet cut to 0..1.
static func _linear(lab: Vector3) -> Vector3:
	var l := pow(lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z, 3.0)
	var m := pow(lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z, 3.0)
	var s := pow(lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z, 3.0)
	return Vector3(
		4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
		-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
		-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)

static func to_srgb(lab: Vector3) -> Color:
	var lin := _linear(lab).clamp(Vector3.ZERO, Vector3.ONE)
	return Color(lin.x, lin.y, lin.z).linear_to_srgb()

## True when the screen cannot show this OKLab colour and to_srgb() cut it.
static func cut(lab: Vector3) -> bool:
	var lin := _linear(lab)
	return lin != lin.clamp(Vector3(-0.0005, -0.0005, -0.0005), Vector3(1.0005, 1.0005, 1.0005))

static func mix(a: Color, b: Color, t: float) -> Color:
	return to_srgb(from_srgb(a).lerp(from_srgb(b), t))

static func apart(c: Color, d: Color) -> float:
	return from_srgb(c).distance_to(from_srgb(d)) * 100.0
