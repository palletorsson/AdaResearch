extends SceneTree
## Do the cube props say what the map token tells them to?
##
## Palle, 2026-09-02, for Point_Animatedcube: "instead of fragile it say
## something from the text." The knob is stencil_words on hangar_supply_pile
## and wooden_pallet, ';'-separated, underscores as spaces, cycled across the
## crates in build order. And crate's stamp_label learns the underscore rule.
##
##   1  the pile reads the token: words parsed, underscores to spaces
##   2  the pile with NO words keeps FRAGILE / KEEP DRY          <- negative
##   3  the pallet builds one stencil quad per carton, cycling the words
##   4  the pallet with NO words builds no stencil quads         <- negative
##   5  the crate's stamp shows the space, not the underscore

func _count(n: Node, name: String) -> int:
	# Siblings that share a name are renamed by the engine (Box, Box2, Box3),
	# so match on the prefix -- the first draft of this probe counted exactly
	# "Box" and reported one carton where there were three.
	var c := 0
	if String(n.name).begins_with(name):
		c += 1
	for ch in n.get_children():
		c += _count(ch, name)
	return c

func _init() -> void:
	var fails := 0
	var root := get_root()

	# ---- 1 + 2: the pile ----
	var pile_scene := load("res://commons/artifacts/hangar_supply_pile/hangar_supply_pile.tscn")
	var pile = pile_scene.instantiate()
	pile.set_meta("config_stencil_words", "WITHOUT_COMPOSITION;YET")
	pile.set_meta("config_crate_count", "2")
	pile.set_meta("config_palette", "metal")
	root.add_child(pile)
	await process_frame
	await process_frame
	var words: Array = pile.stencil_word_list()
	print("1  pile words from token: %s (must be [WITHOUT COMPOSITION, YET])" % [words])
	if words != ["WITHOUT COMPOSITION", "YET"]:
		print("   FAIL the token did not reach the stencils"); fails += 1

	var plain = pile_scene.instantiate()
	root.add_child(plain)
	await process_frame
	var w0: Array = plain.stencil_word_list()
	print("2  pile with no words: list %s (must be empty -> FRAGILE / KEEP DRY)" % [w0])
	if not w0.is_empty():
		print("   FAIL the default stencils changed"); fails += 1

	# ---- 3 + 4: the pallet ----
	var pal_scene := load("res://commons/artifacts/wooden_pallet/wooden_pallet.tscn")
	var pal = pal_scene.instantiate()
	pal.set_meta("config_stencil_words", "A_WORLD;WITHOUT;COMPOSITION")
	pal.set_meta("config_box_arrangement", "pyramid")
	root.add_child(pal)
	await process_frame
	await process_frame
	# Count the cartons by their "Carton" mesh: one per box, each under its own
	# box root, so the engine never renames them. (The box roots themselves
	# come out as Box, @Box@2, @Box@3 and defeat a name match.)
	var quads: int = _count(pal, "StencilWord")
	var boxes: int = _count(pal, "Carton")
	print("3  pallet (pyramid): %d cartons, %d stencil words (must be 3 / 3)" % [boxes, quads])
	if boxes != 3 or quads != 3:
		print("   FAIL one word per carton did not happen"); fails += 1

	var pal0 = pal_scene.instantiate()
	root.add_child(pal0)
	await process_frame
	await process_frame
	var q0: int = _count(pal0, "StencilWord")
	print("4  pallet with no words: %d stencil quads (must be 0)" % q0)
	if q0 != 0:
		print("   FAIL the pallet grew words nobody asked for"); fails += 1

	# ---- 5: the crate stamp ----
	var crate_scene := load("res://commons/artifacts/crate/crate.tscn")
	var crate = crate_scene.instantiate()
	crate.set_meta("config_stamp_label", "A_WORLD")
	root.add_child(crate)
	await process_frame
	await process_frame
	print("5  crate stamp_label = '%s' (must be 'A WORLD')" % crate.stamp_label)
	if crate.stamp_label != "A WORLD":
		print("   FAIL the underscore stayed"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
