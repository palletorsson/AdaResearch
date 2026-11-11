extends Node3D
## One 3 m bay of temporary timber scaffolding: open front, plank deck at 2.3 m, braced sides and back.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")

func _beam(title: String, a: Vector3, b: Vector3, cross: Vector2, material: Material) -> MeshInstance3D:
	var node := Stock.box(self, title, (a+b)/2.0, Vector3(cross.x, a.distance_to(b), cross.y), material)
	node.quaternion = Quaternion(Vector3.UP, (b-a).normalized())
	return node

func _ready() -> void:
	var timber := Stock.finish("9b8f78", .95)
	var aged := Stock.finish("7d7260", .95)
	var steel := Stock.finish("899599", .5, .7)
	for x in [-1.45, 1.45]:
		Stock.box(self, "SolePlate", Vector3(x, .025, 0), Vector3(.24, .05, 1.4), aged)
		for z in [-.6, .6]:
			Stock.box(self, "Post", Vector3(x, 1.725, z), Vector3(.1, 3.35, .1), timber)
		# Side rails (transom level) on the outside of the posts at both lifts.
		var sx: float = x + signf(x) * .075
		for y in [1.15, 2.1]:
			Stock.box(self, "SideRail", Vector3(sx, y, 0), Vector3(.05, .15, 1.4), aged)
			for z in [-.6, .6]: Stock.box(self, "Bolt", Vector3(sx + signf(x) * .03, y, z), Vector3(.012, .035, .035), steel, false)
		_beam("SideBrace", Vector3(x - signf(x) * .0625, .12, .55), Vector3(x - signf(x) * .0625, 2.0, -.55), Vector2(.025, .1), aged)
	# Ledgers run along the bay outside the posts: two lifts at the back, only the deck lift in front.
	for spec in [[-.675, 1.15], [-.675, 2.1], [.675, 2.1]]:
		var z: float = spec[0]
		var y: float = spec[1]
		Stock.box(self, "Ledger", Vector3(0, y, z), Vector3(3.06, .15, .05), timber)
		for x in [-1.45, 1.45]: Stock.box(self, "Bolt", Vector3(x, y, z + signf(z) * .03), Vector3(.035, .035, .012), steel, false)
	for x in [-1.3575, 0.0, 1.3575]:
		Stock.box(self, "Transom", Vector3(x, 2.225, 0), Vector3(.075, .1, 1.4), aged)
	for i in range(5):
		var z: float = -.5 + i * .25
		Stock.box(self, "DeckPlank", Vector3(0, 2.295, z), Vector3(2.78, .04, .22), timber)
		for x in [-1.3575, 0.0, 1.3575]: Stock.box(self, "Nail", Vector3(x, 2.317, z), Vector3(.02, .004, .02), steel, false)
	Stock.box(self, "ToeBoard", Vector3(0, 2.39, .5975), Vector3(2.78, .15, .025), aged)
	Stock.box(self, "GuardRail", Vector3(0, 3.3, .675), Vector3(3.06, .1, .05), timber)
	for x in [-1.45, 1.45]: Stock.box(self, "Bolt", Vector3(x, 3.3, .705), Vector3(.035, .035, .012), steel, false)
	_beam("BackBrace", Vector3(-1.35, .12, -.5375), Vector3(1.35, 2.0, -.5375), Vector2(.1, .025), aged)
	Stock.batch_static(self)
