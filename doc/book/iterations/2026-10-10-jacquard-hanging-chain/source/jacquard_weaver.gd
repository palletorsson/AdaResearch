extends Node3D
## A small, legible Jacquard model: one card, one shed, one shuttle pass.
## Cloth geometry follows committed lift records, not a cloth physics solver.
signal cloth_changed(records: Array)
const Program = preload("res://commons/artifacts/jacquard_weaver/weave_program.gd")
const Card = preload("res://commons/artifacts/jacquard_weaver/punch_card.gd")
const Chain = preload("res://commons/artifacts/jacquard_weaver/card_chain.gd")
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
const Fabric = preload("res://commons/artifacts/jacquard_weaver/weave_fabric.gd")
const Colours = preload("res://commons/artifacts/jacquard_weaver/yarn_colours.gd")
const BUTTON = preload("res://commons/interactables/push_button.tscn")
const CYCLE := 2.8
const COLOUR_X := 1.63
var program = Program.new()
var cards: Array = []
var slots: Array[Vector3] = []
var chain: Node3D
var reader_loaded := false
var read_caption: Label3D
var selected := 0
var elapsed := 0.0
var running := false
var playback_rate := 1.0
var speed_button: Node3D
var speed_label: Label3D
var status: Label3D
var edit_label: Label3D
var reader: Node3D
var live_yarn: Node3D
var cloth: Node3D
var shuttle: MeshInstance3D
var reed: MeshInstance3D
var hooks: Array[MeshInstance3D] = []
var slot_lights: Array[MeshInstance3D] = []
var punch_lights: Array[MeshInstance3D] = []
var punch_buttons: Array[Node3D] = []
var warp_paths: Array = []
var weft_path := PackedVector3Array()
var frame_mat = G.material("302f35", .55)
var brass = G.material("b79361", .65)
var paper_mat = G.material("e1c799")
var warp_mat = G.material("f3e6c8")
var weft_mat = G.material("e84b7e")
var off_mat = G.material("554b43")
var active_mat = G.material("77d9c0", .2)
var refresh_clock := 0.0
var warp_colors: Array = Colours.uniform("f3e6c8")
var warp_draft: Array = Colours.uniform("f3e6c8")
var weft_colors: Array = Colours.uniform("e84b7e")
var warp_swatches: Array[MeshInstance3D] = []
var weft_swatches: Array[MeshInstance3D] = []
var warp_buttons: Array[Node3D] = []
var weft_buttons: Array[Node3D] = []
var warp_caption: Label3D
var weft_caption: Label3D
var weft_marker: MeshInstance3D
var yarn_materials: Dictionary = {}

func _ready() -> void:
	name = "JacquardWeaver"
	reader = Node3D.new(); add_child(reader)
	live_yarn = Node3D.new(); add_child(live_yarn)
	cloth = Node3D.new(); add_child(cloth)
	_build_frame()
	_build_controls()
	_build_colour_controls()
	_build_cards()
	set_preset("twill")
	_rebuild_cloth(); _draw_live(0.0)
	status.text = "ONE PICK: ADVANCE CARD → LIFT → PASS → CLOTH"

func _build_frame() -> void:
	for x in [-1.08, 1.08]:
		G.box(self, Vector3(x, 1.38, -.62), Vector3(.12,2.76,.13), frame_mat, true)
		G.box(self, Vector3(x, .1, .18), Vector3(.26,.16,1.95), frame_mat, true)
		G.box(self, Vector3(x, .66, .94), Vector3(.10,1.26,.10), frame_mat, true)
	for y in [.17, 1.2, 2.65]:
		G.box(self, Vector3(0,y,-.62), Vector3(2.28,.11,.14), frame_mat, true)
	G.box(self,Vector3(0,1.17,.27),Vector3(1.95,.075,.12),brass)
	G.box(self,Vector3(0,1.13,.82),Vector3(1.95,.1,.13),brass)
	G.box(self,Vector3(0,.58,1.00),Vector3(2.28,.67,.07),frame_mat,true)
	G.label(self,"PUNCH → LIFT → PASS → CLOTH",Vector3(0,2.83,-.59),26)
	G.label(self,"12 HOOKS × 8 REPEATS / 96 WARP THREADS",Vector3(0,2.7,-.52),15)
	for col in range(12):
		var x := -.66 + col * .12
		hooks.append(G.box(self,Vector3(x,2.15,-.25),Vector3(.038,.13,.038),brass))
		G.label(self,str(col+1),Vector3(x,2.34,-.24),11)
	shuttle = G.box(self,Vector3(-.85,1.44,0),Vector3(.22,.06,.11),weft_mat)
	reed = G.box(self,Vector3(0,1.30,.06),Vector3(1.83,.05,.04),brass)
	status = G.label(self,"",Vector3(1.63,1.40,.71),10)
	chain=Chain.new(); add_child(chain)
	for i in range(8):
		slots.append(chain.slot_frame(i).origin)
		slot_lights.append(chain.lights[i])
	read_caption=G.label(self,"READ MASK · 12 HOOKS",Vector3(0,2.61,-.19),11)
	G.label(self,"SPARE CARDS · GRAB AND PLACE IN AN EMPTY CHAIN FRAME",Vector3(0,.85,1.10),12)
	G.box(self,Vector3(0,.47,1.08),Vector3(2.25,.055,.22),brass,true)

func _button(title: String, pos: Vector3, callback: Callable, size := .63) -> Node3D:
	var b = BUTTON.instantiate(); b.position = pos; b.rotation_degrees.x = 90
	b.scale = Vector3.ONE*size; add_child(b)
	b.get_node("InteractableAreaButton").button_pressed.connect(func(_button): callback.call())
	G.label(self,title,pos+Vector3(0,.074,.075),12)
	return b

func _build_controls() -> void:
	G.box(self,Vector3(1.77,.96,.52),Vector3(1.30,.90,.10),frame_mat,true)
	G.box(self,Vector3(1.59,.38,.52),Vector3(.08,.76,.08),frame_mat,true)
	G.box(self,Vector3(1.59,.06,.52),Vector3(.75,.12,.48),frame_mat,true)
	_button("ONE PICK",Vector3(1.39,1.26,.63),start_pick)
	_button("RUN / STOP",Vector3(1.79,1.26,.63),toggle_run)
	speed_button=_button("",Vector3(2.20,1.26,.63),toggle_speed)
	speed_label=G.label(self,"NORMAL\n2.8 SEC",Vector3(2.20,1.35,.705),11)
	_button("CLEAR CLOTH",Vector3(1.39,1.03,.63),reset_cloth)
	_button("NEXT CARD",Vector3(1.79,1.03,.63),func(): select_card((selected+1)%cards.size()))
	_button("PLAIN",Vector3(1.27,.80,.63),func():set_preset("plain"),.48)
	_button("TWILL",Vector3(1.59,.80,.63),func():set_preset("twill"),.48)
	_button("DIAMOND",Vector3(1.91,.80,.63),func():set_preset("diamond"),.48)
	edit_label = G.label(self,"",Vector3(0,1.90,.75),17)
	G.label(self,"PRESS A HOOK BUTTON TO PUNCH / PATCH THE SELECTED CARD",Vector3(0,1.79,.75),12)
	for col in range(12):
		var p := Vector3(-.77+col*.14,1.63,.80)
		punch_buttons.append(_button(str(col+1),p,func():toggle_hole(col),.39))
		punch_lights.append(G.box(self,p+Vector3(0,-.065,0),Vector3(.07,.018,.015),off_mat))
	G.label(self,"HOLE = WARP UP / SOLID = WARP DOWN",Vector3(0,2.03,.75),12)

func _build_colour_controls() -> void:
	# Keep the working shed and emerging cloth visible from standing height.
	G.box(self,Vector3(COLOUR_X,1.74,.52),Vector3(1.88,.59,.08),frame_mat,true)
	warp_caption = G.label(self,"",Vector3(COLOUR_X,1.93,.75),10)
	weft_caption = G.label(self,"",Vector3(COLOUR_X,1.69,.75),10)
	for col in range(12):
		var x := COLOUR_X-.77+col*.14
		var p := Vector3(x,1.84,.68)
		warp_swatches.append(G.box(self,p+Vector3(0,0,-.023),Vector3(.12,.12,.025),_yarn_material(str(warp_draft[col]))))
		warp_buttons.append(_button("",p,func():cycle_colour(true,col),.35))
		p.y=1.60
		weft_swatches.append(G.box(self,p+Vector3(0,0,-.023),Vector3(.12,.12,.025),_yarn_material(str(weft_colors[col]))))
		weft_buttons.append(_button("",p,func():cycle_colour(false,col),.35))
	weft_marker=G.box(self,Vector3(COLOUR_X-.77,1.52,.715),Vector3(.10,.018,.018),active_mat)
	_button("THREAD\n+ CLEAR",Vector3(1.27,.55,.63),apply_warp,.48)
	_button("MATCH\nWEFT",Vector3(1.59,.55,.63),match_weft,.48)
	_button("TARTAN\n+ CLEAR",Vector3(1.91,.55,.63),set_tartan,.48)
	_refresh_colours()

func _yarn_material(hex: String) -> StandardMaterial3D:
	if not yarn_materials.has(hex): yarn_materials[hex]=G.material(hex)
	return yarn_materials[hex]

func cycle_colour(warp: bool, index: int) -> void:
	if index<0 or index>=12: return
	if warp:
		warp_draft[index]=Colours.next(str(warp_draft[index]))
		status.text="WARP %d → %s · THREAD + CLEAR TO APPLY" % [index+1,Colours.colour_name(str(warp_draft[index]))]
	else:
		weft_colors[index]=Colours.next(str(weft_colors[index]))
		status.text="WEFT STEP %d → %s · FUTURE PICKS" % [index+1,Colours.colour_name(str(weft_colors[index]))]
	_refresh_colours()

func _refresh_colours() -> void:
	for col in range(12):
		warp_swatches[col].material_override=_yarn_material(str(warp_draft[col]))
		weft_swatches[col].material_override=_yarn_material(str(weft_colors[col]))
	warp_caption.text="WARP 1–12 · PRESS TO CYCLE"+ (" · THREAD + CLEAR TO APPLY" if warp_draft!=warp_colors else " · THREADED")
	weft_caption.text="WEFT 1–12 · PRESS TO CYCLE · REPEATS EACH 12 PICKS"

func apply_warp() -> void:
	warp_colors=warp_draft.duplicate()
	reset_cloth(); _refresh_colours()
	status.text="NEW WARP THREADED · NEW SAMPLE · CARD CHAIN KEPT"

func match_weft() -> void:
	weft_colors=warp_draft.duplicate(); _refresh_colours()
	status.text="WEFT REPEAT MATCHES WARP DRAFT · FUTURE PICKS"

func set_tartan() -> void:
	for card in cards:
		if card.held():
			status.text="RELEASE THE CARD BEFORE LOADING TARTAN"; return
	warp_draft=Colours.SETT.duplicate(); weft_colors=Colours.SETT.duplicate()
	set_preset("twill"); apply_warp()
	status.text="TARTAN STUDY · SAME COLOUR REPEAT · 2/2 TWILL · PRESS RUN"

func _build_cards() -> void:
	for i in range(12):
		var card = Card.new(); card.loom = self; card.card_id = i
		card.bits = Program.preset("twill",i)
		card.home = Vector3(-.52+(i%2)*1.04,.64-floori((i%4)/2.0)*.33,1.10)
		card.position = card.home; cards.append(card); add_child(card)

func select_card(id: int) -> void:
	selected = clampi(id,0,cards.size()-1); _refresh_edit()

func _refresh_edit() -> void:
	if cards.is_empty(): return
	var card = cards[selected]
	edit_label.text = "EDIT CARD %02d  /  CHANGES APPLY TO FUTURE PICKS" % (selected+1)
	for col in range(12): punch_lights[col].material_override = active_mat if card.bits[col]==1 else off_mat
	for i in range(8):
		var entry = program.deck[i]
		slot_lights[i].material_override = active_mat if entry!=null and int(entry.id)==selected else off_mat

func toggle_hole(col: int) -> void:
	if col<0 or col>=12: return
	var card = cards[selected]
	card.bits[col] = 1-int(card.bits[col]); card.redraw()
	if card.slot>=0: program.put(card.slot,card.card_id,card.bits)
	_refresh_edit()

func set_preset(kind: String) -> void:
	for card in cards:
		if card.held():
			status.text = "RELEASE THE CARD BEFORE LOADING A SET"; return
	for card in cards: program.remove(card.card_id)
	for i in range(cards.size()):
		var card = cards[i]; card.bits = Program.preset(kind,i); card.redraw()
		card.slot = i if i<8 else -1
		card.settle(card.home)
		if i<8: program.put(i,i,card.bits)
	program.cursor = 0
	if program.active.is_empty(): chain.focus(0)
	_sync_chain(); _refresh_edit()
	status.text = kind.to_upper()+" CARDS LOADED / WOVEN HISTORY KEPT"

func remove_card(card) -> void:
	running=false
	program.remove(card.card_id); card.slot = -1; select_card(card.card_id)
	status.text = "CARD %02d REMOVED · CHAIN STOPS AFTER THIS PICK" % (card.card_id+1)

func place_card(card, slot: int) -> bool:
	if card.held() or not program.put(slot,card.card_id,card.bits): return false
	card.slot = slot; _sync_chain(); select_card(card.card_id)
	status.text = "CARD %02d → SLOT %d" % [card.card_id+1,slot+1]
	return true

func drop_card(card) -> void:
	var nearest := -1; var distance := .27
	for i in range(8):
		var d: float = card.position.distance_to(slots[i])
		if d<distance: distance=d; nearest=i
	if nearest>=0 and place_card(card,nearest): return
	# An occupied slot is never silently replaced. Return to a visible spare shelf.
	card.slot = -1
	card.settle(card.home+Vector3(0,0,floori(card.card_id/4.0)*.045))
	status.text = "NO EMPTY SLOT HERE · CARD RETURNED TO RACK"

func _sync_chain() -> void:
	for i in range(8): slots[i]=chain.slot_frame(i).origin
	for card in cards:
		if card.slot<0 or card.held(): continue
		card.transform=chain.slot_frame(card.slot)
		card.linear_velocity=Vector3.ZERO; card.angular_velocity=Vector3.ZERO
		card.force_update_transform()

func _load_reader() -> void:
	reader_loaded=true; G.clear(reader)
	G.card(reader,program.active.bits,paper_mat,1.44)
	reader.position=Vector3(0,2.47,-.26)
	read_caption.text="READ CARD %02d → PICK %d" % [int(program.active.id)+1,program.history.size()+1]

func insert_next(card) -> void:
	# Trigger chooses the punch editor; release is the act that installs a card.
	select_card(card.card_id)
	status.text = "EDITING CARD %02d · RELEASE IN A SLOT TO INSTALL" % (card.card_id+1)

func start_pick() -> bool:
	if not program.begin(warp_colors,str(weft_colors[program.history.size()%12])):
		if not program.active.is_empty(): status.text = "THIS PICK IS STILL RUNNING"
		elif program.history.size()>=Program.LIMIT: status.text = "128 PICKS KEPT · CLEAR CLOTH TO WEAVE AGAIN"
		else: status.text = "INSERT A CARD BEFORE WEAVING"
		return false
	elapsed = 0.0; reader_loaded=false; G.clear(reader)
	chain.begin_move(int(program.active.slot),program.history.is_empty())
	read_caption.text="WAIT FOR CARD TO SEAT"
	shuttle.material_override=_yarn_material(str(program.active.weft_color))
	weft_marker.position.x=COLOUR_X-.77+(program.history.size()%12)*.14
	return true

func toggle_run() -> void:
	running = not running
	if running and program.active.is_empty():
		if not start_pick(): running = false
	elif not running: status.text = "STOPPING AFTER THE CURRENT PICK"

func toggle_speed() -> void:
	# Alter the rate of the current pass without restarting its phase or record.
	playback_rate = .35 if playback_rate==1.0 else 1.0
	speed_label.text = "SLOW\n8 SEC" if playback_rate<1.0 else "NORMAL\n2.8 SEC"

func reset_cloth() -> void:
	running = false; program.reset(); elapsed = 0.0; reader_loaded=false; G.clear(reader)
	chain.focus(0); _sync_chain(); chain.caption.text="CARD CHAIN → READER"
	read_caption.text="READ MASK · 12 HOOKS"
	shuttle.position.x = -.88; reed.position.z = .06
	weft_marker.position.x=COLOUR_X-.77
	_rebuild_cloth(); _draw_live(0.0)
	cloth_changed.emit(program.snapshot()); status.text = "CLOTH CLEARED · CARD CHAIN KEPT"

func _process(delta: float) -> void:
	advance_cycle(delta)

func advance_cycle(delta: float) -> void:
	if program.active.is_empty(): return
	elapsed += maxf(delta,0.0)*playback_rate
	var t := clampf(elapsed/CYCLE,0.0,1.0)
	if not reader_loaded:
		chain.move_to(t/.20); _sync_chain()
		if t>=.20: _load_reader()
	var rise := smoothstep(.20,.35,t)*(1.0-smoothstep(.88,1.0,t))
	refresh_clock += delta
	if refresh_clock>.04 or t>=1.0: _draw_live(rise); refresh_clock=0.0
	var direction := 1.0 if program.history.size()%2==0 else -1.0
	shuttle.position.x = lerpf(-.88*direction,.88*direction,clampf((t-.35)/.43,0.0,1.0))
	reed.position.z = lerpf(.06,.23,sin(clampf((t-.78)/.22,0.0,1.0)*PI))
	var phase := "ADVANCE CARD" if t<.20 else ("READ / LIFT" if t<.35 else ("SHUTTLE THROUGH SHED" if t<.78 else "BEAT / KEEP THIS PICK"))
	status.text = "%s · CARD %02d · PICK %d / %d" % [phase,int(program.active.id)+1,program.history.size()+1,Program.LIMIT]
	chain.caption.text="%s\nCARD %02d → PICK %d" % [phase,int(program.active.id)+1,program.history.size()+1]
	if t>=1.0:
		program.commit(); _rebuild_cloth(); _draw_live(0.0); cloth_changed.emit(program.snapshot())
		var last: Dictionary=program.history[-1]
		read_caption.text="KEPT CARD %02d → PICK %d" % [int(last.id)+1,program.history.size()]
		chain.caption.text="PICK %d WOVEN\nONE PICK / RUN TO CONTINUE" % program.history.size()
		status.text = "%d PICKS KEPT · ONE PICK / RUN TO CONTINUE" % program.history.size()
		if running and not start_pick(): running=false

func _draw_live(rise: float) -> void:
	G.clear(live_yarn)
	for col in range(12):
		var x := -.66+col*.12
		var up: bool = not program.active.is_empty() and int(program.active.bits[col])==1
		var y := 1.44+(.17 if up else -.17)*rise
		G.yarn(live_yarn,PackedVector3Array([Vector3(x,1.3,-.64),Vector3(x,y,-.25),Vector3(x,y,.02),Vector3(x,1.2,.27)]),_yarn_material(str(warp_colors[col])),.009)
		hooks[col].position.y = 2.13+(.13*rise if up else 0.0)
		hooks[col].material_override = active_mat if up and rise>.01 else brass
		G.yarn(live_yarn,PackedVector3Array([Vector3(x,hooks[col].position.y,-.25),Vector3(x,y,-.25)]),brass,.003)
	if not program.active.is_empty():
		var t:=clampf(elapsed/CYCLE,0.0,1.0)
		var span:=clampf((t-.35)/.43,0.0,1.0)
		if span>.001:
			var direction:=1.0 if program.history.size()%2==0 else -1.0
			var beat:=smoothstep(.78,1.0,t)
			var y:=lerpf(1.44,1.20,beat); var z:=lerpf(0.0,.27,beat)
			var path:=PackedVector3Array([Vector3(-.88*direction,y,z),Vector3(lerpf(-.88*direction,.88*direction,span),y,z)])
			var yarn:=G.yarn(live_yarn,path,_yarn_material(str(program.active.weft_color)),.012)
			yarn.name="LiveWeft"

func cloth_point(col: int, row: int, warp: bool) -> Vector3:
	var d: float = (program.history.size()-1-row)*.036
	var centre := Vector3(-.66+col*.12,1.20,.27+d)
	var normal := Vector3.UP
	if d>.53:
		centre = Vector3(centre.x,1.20-(d-.53),.80); normal=Vector3.BACK
	var sign_y := 1.0 if int(program.history[row].bits[col])==1 else -1.0
	return centre+normal*sign_y*(.018 if warp else -.018)

func weave_sample(count := 96) -> void:
	# Batch real card cycles. Preserve an in-flight snapshot and all earlier picks.
	running=false
	var made:=0
	if not program.active.is_empty():
		program.commit();made=1
	while made<count and program.begin(warp_colors,str(weft_colors[program.history.size()%12])):
		program.commit();made+=1
	elapsed=0.0;G.clear(reader);reed.position.z=.06
	reader_loaded=false
	if not program.history.is_empty(): chain.focus(int(program.history[-1].slot)); _sync_chain()
	chain.caption.text="%d PICKS KEPT\nONE PICK / RUN TO WATCH" % program.history.size()
	read_caption.text="FAST SAMPLE · READ MASK WHEN RUNNING"
	weft_marker.position.x=COLOUR_X-.77+(maxi(program.history.size()-1,0)%12)*.14
	_rebuild_cloth();_draw_live(0.0);cloth_changed.emit(program.snapshot())
	status.text="%d PICKS WOVEN · %d / %d KEPT" % [made,program.history.size(),Program.LIMIT]

func _rebuild_cloth() -> void:
	G.clear(cloth);warp_paths.clear();weft_path.clear()
	if program.history.is_empty():
		for col in range(12):
			G.yarn(cloth,PackedVector3Array([Vector3(-.66+col*.12,1.20,.27),Vector3(-.66+col*.12,1.20,.80)]),_yarn_material(str(warp_colors[col])),.009)
		return
	var result:Dictionary=Fabric.build(program.history,true)
	warp_paths=result.warps;weft_path=result.weft
	var mat:=Fabric.material();mat.set_shader_parameter("folded",true)
	var mesh:=MeshInstance3D.new();mesh.mesh=result.mesh;mesh.material_override=mat;cloth.add_child(mesh)
