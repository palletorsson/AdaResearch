extends Node3D
## An opened art-transport crate on skids, foam-lined and empty; its front panel leans on the +X side. Open front +Z.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")

func _ready() -> void:
	var ply := Stock.finish("c4ae88", .9)
	var timber := Stock.finish("9b8f78", .95)
	var foam := Stock.finish("b8bcb6", 1.0)
	var dark := Stock.finish("343b3d", .7, .2)
	var mark := Stock.finish("a5563c", .8)
	# Skids run front to back under the base.
	for x in [-.65, .65]: Stock.box(self, "Skid", Vector3(x, .05, 0), Vector3(.12, .1, .94), timber)
	Stock.box(self, "Base", Vector3(0, .115, 0), Vector3(1.8, .03, .9), ply)
	Stock.box(self, "Back", Vector3(0, 1.215, -.439), Vector3(1.8, 2.17, .022), ply)
	Stock.box(self, "Lid", Vector3(0, 2.289, 0), Vector3(1.8, .022, .9), ply)
	for x in [-.889, .889]:
		Stock.box(self, "Side", Vector3(x, 1.215, .011), Vector3(.022, 2.17, .878), ply)
		var ox: float = x + signf(x) * .0235
		for y in [.2, 1.2, 2.2]: Stock.box(self, "SideBatten", Vector3(ox, y, 0), Vector3(.025, .09, .9), timber)
		for z in [-.405, .405]: Stock.box(self, "SideBatten", Vector3(ox, 1.2, z), Vector3(.025, 2.2, .09), timber)
		# Foam on the inner side wall, held clear of the open front.
		Stock.box(self, "SideFoam", Vector3(x - signf(x) * .036, 1.215, -.0), Vector3(.05, 2.1, .78), foam)
		# Front frame strip around the opening, where the panel was screwed.
		Stock.box(self, "FrontFrame", Vector3(x - signf(x) * .024, 1.2, .43), Vector3(.07, 2.17, .04), timber)
	Stock.box(self, "FrontFrameTop", Vector3(0, 2.243, .43), Vector3(1.74, .07, .04), timber)
	Stock.box(self, "FrontFrameSill", Vector3(0, .165, .43), Vector3(1.74, .07, .04), timber)
	Stock.box(self, "BackFoam", Vector3(0, 1.215, -.403), Vector3(1.656, 2.1, .05), foam)
	for y in [.2, 1.2, 2.2]: Stock.box(self, "BackBatten", Vector3(0, y, -.4625), Vector3(1.85, .09, .025), timber)
	for x in [-.4, .4]: Stock.box(self, "LidBatten", Vector3(x, 2.3125, 0), Vector3(.09, .025, .9), timber)
	# Dark corner protectors on the four front corners of the opening.
	for x in [-.9, .9]:
		for y in [.13, 2.3]:
			Stock.box(self, "Corner", Vector3(x, y, .45), Vector3(.12, .12, .05), dark, false)
		Stock.box(self, "Corner", Vector3(x, 2.3, -.45), Vector3(.12, .12, .05), dark, false)
	# Handling marks on the -X side.
	Stock.box(self, "Mark", Vector3(-.928, 1.75, .15), Vector3(.003, .22, .22), mark, false)
	Stock.box(self, "MarkBand", Vector3(-.928, 1.5, .15), Vector3(.003, .05, .32), mark, false)
	# The removed front panel leans on the +X side battens; it pivots on its inner bottom edge.
	var lean: float = asin(.22)
	var panel := Node3D.new()
	panel.name = "FrontPanel"
	panel.position = Vector3(.925 + 2.3 * .22, 0, 0)
	panel.rotation.z = lean
	add_child(panel)
	Stock.box(panel, "PanelSheet", Vector3(.011, 1.15, 0), Vector3(.022, 2.3, 1.8), ply)
	for y in [.12, 1.15, 2.18]: Stock.box(panel, "PanelBatten", Vector3(.0345, y, 0), Vector3(.025, .09, 1.8), timber)
	for z in [-.855, .855]: Stock.box(panel, "PanelBatten", Vector3(.0345, 1.15, z), Vector3(.025, 2.3, .09), timber)
	Stock.box(panel, "PanelMark", Vector3(.0485, 1.6, .45), Vector3(.003, .2, .2), mark, false)
	Stock.batch_static(self)
