extends "res://commons/artifacts/spine_films/film_stage.gd"
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
const Draw = preload("res://commons/artifacts/spine_films/more_motion/drawing.gd")
var numbers:Array[int]=[]
var values:Array[int]=[]
var replay_values:Array[int]=[]
var bits:Array[Node3D]=[]
var bars:Array[Node3D]=[]
var twins:Array[Node3D]=[]
var text_:Label3D
var separator:MeshInstance3D
var bit_labels:Array[Label3D]=[]
const SEED_VALUE=3134984190
var active_seed := SEED_VALUE

func generate(seed_value:int) -> Array[int]:
	var source=load(source_paths[0]).new()
	source._state=seed_value
	var out:Array[int]=[]
	for i in 16:
		source._crank()
		for phase in 4:source._advance_animation()
		out.append(source._state)
	source.free()
	return out

func _calculate(value: int) -> void:
	active_seed = value
	numbers.clear()
	var source=load(source_paths[0]).new()
	source._state=active_seed
	source._crank();source._advance_animation();numbers.append(source._anim_intermediate)
	source._advance_animation();numbers.append(source._anim_intermediate)
	source._advance_animation();numbers.append(source._state)
	source.free()
	values=generate(active_seed);replay_values=generate(active_seed)
	evidence={"seed":active_seed,"intermediate_values":numbers,"outputs":values,"replay":replay_values,"first_seed_42_output":generate(42)[0],"low_bits":32}

func _apply_hall_seed(value: int, _receipt: Dictionary) -> void:
	_calculate(value)
	for i in bars.size():
		var height := .1+float(values[i])/4294967296.0*2.2
		for bar in [bars[i],twins[i]]:
			bar.mesh.size.y = height
			bar.position.y = .2+height*.5

func _build() -> void:
	title_text="A NUMBER HAS A PREVIOUS STATE"
	duration=28
	phases.assign(["MULTIPLY THE STATE","ADD THE INCREMENT","KEEP THE LOW 32 BITS","RESET AND REPLAY"])
	notes.assign(["The actual crank multiplies its stored integer by 1,664,525.","The same source adds 1,013,904,223. These blocks show the resulting bits, not an electrical circuit.","The source keeps the low 32 bits. Higher places, if present, disappear; the retained integer is the next state.","Two private cranks start from the same seed. Sixteen outputs agree in order, not merely in their distribution."])
	source_paths.assign(["res://algorithms/randomness/prng_crank_machine/prng_crank_machine.gd"])
	_calculate(HallSeed.current(self) if HallSeed.enabled(self) else SEED_VALUE)
	var inactive:=Kit.material(Color("263240"))
	for bit in 64:
		var at:=Vector3((bit%8-3.5)*.42,.65+(bit/8)*.34,0)
		bits.append(Kit.box(display,at,Vector3(.30,.23,.55),inactive))
	separator=add_box(Vector3(0,1.84,.04),Vector3(3.65,.025,.7),Kit.GOLD)
	bit_labels.append(Draw.caption(display,"HIGH PLACES",Vector3(2.65,2.85,0),Kit.PINK))
	bit_labels.append(Draw.caption(display,"LOW 32 BITS",Vector3(2.65,1.1,0),Kit.TEAL))
	for i in 16:
		var height:=.1+float(values[i])/4294967296.0*2.2
		bars.append(add_box(Vector3(-3.3+i*.44,.2+height*.5,-.6),Vector3(.26,height,.30),Kit.TEAL))
		twins.append(add_box(Vector3(-3.3+i*.44,.2+height*.5,.6),Vector3(.26,height,.30),Kit.PINK))
	text_=Draw.caption(display,"",Vector3(0,3.8,0))
	add_box(Vector3(0,.08,0),Vector3(8,.12,2.6),Color("222b36"))
	HallSeed.bind(self)

func _draw(time:float) -> void:
	if bits.is_empty():return
	var p:=phase_index(time);var u:=phase_progress(time)
	var value:int=numbers[mini(p,2)]
	for i in bits.size():
		bits[i].visible=p<3 and (p<2 or i<32 or u<.2)
		bits[i].position.z=-(u-.2)*2.0 if p==2 and i>=32 and u>.2 else 0.0
		bits[i].material_override=Kit.material(Kit.TEAL if (value & (1<<i))!=0 else Color("263240"),true)
	for i in 16:
		bars[i].visible=p==3 and i<=int(u*16)
		twins[i].visible=bars[i].visible
	separator.visible=p<3
	for label in bit_labels:label.visible=p<3
	text_.text=["MULTIPLY → %d" % numbers[0],"ADD → %d" % numbers[1],"NEXT STATE → %d" % numbers[2],"SAME SEED · SAME SIXTEEN OUTPUTS"][p]
	frame_scene(Vector3(0,1.8,0),12.5,.2+time*.009,.24)

func validation() -> Dictionary:
	return {"passed":values==replay_values and values[0]==numbers[2] and numbers[2]==(numbers[1] & 0xffffffff) and evidence.first_seed_42_output==1083814273,"evidence":evidence}
