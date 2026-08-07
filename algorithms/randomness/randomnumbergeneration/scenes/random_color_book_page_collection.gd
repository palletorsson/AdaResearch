extends Node3D

## Colour Book Page Collection — three pages of the RAND book, and one rung for all three.
##
## @identity
## essence: the shelf that makes the colour book's disclosure rung reachable. The pages already argue; this root is what a map can talk to
## desire: to be addressable. The axis lived on a child scene with no registry name, so four placements of this collection could never reach it
## critical_parameter: disclosure — forwarded verbatim to every page, so the collection states ONE claim about where its colours came from
## triggers: _ready() forwards only when a value departs from the shipped default; apply_grid_config({disclosure, page_seed}) restages
## emerges: three pages that agree. A shelf where every page admits the same amount is a different object from a shelf of pages that each admit their own
## needs: random_color_book_page_1955.gd (the pages), which owns the rung and every mark on it
## relationships: the reachability half of [[random_color_book_page_1955]]'s `disclosure`; kin of [[random_number_book_page_collection]], the digit shelf
## truth: an axis a map cannot address is not an axis. The scriptless root was the whole distance between an argument and an artifact
##
## WHY THIS FILE EXISTS. The pages carry `disclosure` and the collection's root was a bare
## Node3D instancing them three times. GridInteractablesComponent stamps config metadata and
## calls apply_grid_config on the ROOT — so a `#disclosure:` token on any of this
## collection's four placements landed on a node with no such property and vanished. The
## axis was declared, implemented, and unreachable.
##
## R1, THE SHIPPED LINEAGE: at the default rung and an unpinned seed this script forwards
## NOTHING. The pages ready themselves before their parent does, exactly as before, each
## dealing from the global generator. The legacy shelf is the untouched branch.

const DISCLOSURES: PackedStringArray = ["oracle", "tally", "ledger", "works", "origin"]

## Which rung every page on this shelf stands on. Same spelling, same order, same default
## as the page's own export — this forwards a value, it never invents one.
@export_enum("oracle", "tally", "ledger", "works", "origin") var disclosure: String = "works"

## -1 deals each page from the global generator, exactly as today. A non-negative value
## pins the shelf for capture — and each page gets seed + its own index, so a pinned
## collection is still THREE different pages rather than one page printed three times.
@export var page_seed: int = -1


func _ready() -> void:
	_read_meta_overrides()
	if disclosure == "works" and page_seed < 0:
		return                        # the shipped shelf: forward nothing, touch nothing
	_forward()


func apply_grid_config(config: Dictionary) -> void:
	var before_rung: String = disclosure
	var before_seed: int = page_seed
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if disclosure == before_rung and page_seed == before_seed:
		return                        # an unchanged rung touches nothing
	_forward()


func _read_meta_overrides() -> void:
	if has_meta("config_disclosure"):
		var d: String = str(get_meta("config_disclosure")).strip_edges().to_lower()
		if DISCLOSURES.has(d):
			disclosure = d
	if has_meta("config_page_seed"):
		page_seed = int(str(get_meta("config_page_seed")))


## Hand the value down to whichever children are pages. Camera3D and OmniLight3D are in
## this scene too and answer nothing; asking by method rather than by name keeps the
## forwarding honest if the shelf ever grows a fourth page.
func _forward() -> void:
	var i: int = 0
	for c in get_children():
		if not c.has_method("apply_grid_config"):
			continue
		var cfg: Dictionary = {"disclosure": disclosure}
		if page_seed >= 0:
			cfg["page_seed"] = page_seed + i
		c.call("apply_grid_config", cfg)
		i += 1
