extends Node3D
## A 3.6 m run of plywood site hoarding on timber posts, raked back braces behind; sheet face +Z.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")

func _ready() -> void:
	var plies := [Stock.finish("b9a27c", .9), Stock.finish("c4ae88", .9), Stock.finish("ad9670", .9)]
	var timber := Stock.finish("9b8f78", .95)
	var dark := Stock.finish("343b3d", .75, .3)
	# Three 1.2 x 2.4 sheets with 6 mm open joints; the posts behind show through.
	for i in range(3):
		var x: float = -1.2 + i * 1.2
		var ply: Material = plies[[1, 0, 2][i]]
		Stock.box(self, "Sheet", Vector3(x, 1.23, .009), Vector3(1.194, 2.4, .018), ply)
		for dx in [-.56, 0.0, .56]:
			for y in [.12, .7, 1.25, 1.8, 2.36]:
				Stock.box(self, "Fixing", Vector3(x + dx, y, .0195), Vector3(.018, .018, .003), dark, false)
	for x in [-.6, .6]:
		Stock.box(self, "Joint", Vector3(x, 1.23, .0185), Vector3(.008, 2.4, .002), dark, false)
	for x in [-1.75, -.6, .6, 1.75]:
		Stock.box(self, "Post", Vector3(x, 1.25, -.05), Vector3(.1, 2.5, .1), timber)
	for y in [.35, 1.3, 2.25]:
		Stock.box(self, "Waler", Vector3(0, y, -.125), Vector3(3.6, .1, .05), timber)
	Stock.box(self, "TopRail", Vector3(0, 2.465, -.01), Vector3(3.64, .07, .08), timber)
	for x in [-1.2, 1.2]:
		var top := Vector3(x, 2.2, -.175)
		var foot := Vector3(x, .09, -.78)
		var brace := Stock.box(self, "RakingBrace", (top + foot) / 2.0, Vector3(.1, top.distance_to(foot), .05), timber)
		brace.quaternion = Quaternion(Vector3.UP, (top - foot).normalized())
		Stock.box(self, "BraceFoot", Vector3(x, .04, -.8), Vector3(.3, .08, .3), timber)
		Stock.box(self, "Stake", Vector3(x, .1, -.93), Vector3(.05, .2, .05), timber)
	# A dark stencilled block and a painted band in the top left corner.
	Stock.box(self, "Stencil", Vector3(-1.45, 2.12, .0195), Vector3(.42, .16, .003), dark, false)
	Stock.box(self, "Band", Vector3(-1.45, 1.96, .0195), Vector3(.42, .035, .003), dark, false)
	Stock.batch_static(self)
