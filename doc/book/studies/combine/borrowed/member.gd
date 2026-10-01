extends RefCounted
## Borrowed from Families (chapter 14), in a small version: one member of the
## family of globes. Use it by path:
##   const Member := preload("res://borrowed/member.gd")
## Contract:
##   Member.make(segments)   a SphereMesh 1 m across with `segments` cuts around
##                           and half as many rings; `segments` is kept between
##                           4 and 64, as the class Globe kept it.
## The Families kit has the whole class, with its fields and its sheet.

static func make(segments: int) -> SphereMesh:
	segments = clampi(segments, 4, 64)
	var sphere := SphereMesh.new()
	sphere.radial_segments = segments
	@warning_ignore("integer_division")
	sphere.rings = segments / 2
	return sphere
