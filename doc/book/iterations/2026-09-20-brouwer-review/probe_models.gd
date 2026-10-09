extends SceneTree
const OUT := "res://doc/book/iterations/2026-09-20-brouwer-review/"
var checks: Array=[]
var evidence: Array=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void: checks.append({"ok":ok,"message":message})
func press(bench: Node,which: String) -> void:
	bench.get_node(which+"/InteractableAreaButton").button_pressed.emit(null)
func run() -> void:
	var camera := Camera3D.new(); root.add_child(camera); camera.current = true
	var choice: Node3D=load("res://commons/artifacts/brouwer_choice_sequence/brouwer_choice_sequence.tscn").instantiate()
	choice.apply_grid_config({"visitor_choices":"on"});root.add_child(choice)
	await process_frame
	check(choice.terms.is_empty(),"Visitor bench begins with no chosen terms")
	choice._process(10000.0)
	check(choice.terms.is_empty(),"Time never supplies the first term")
	for value in [0,1,1,0,1]:press(choice,"Choose%d" % value)
	check(choice.terms==[0,1,1,0,1],"Physical button signals append exactly the chosen values, in order")
	var before: Array=choice.terms.duplicate()
	choice._process(10000.0)
	check(choice.terms==before,"A pause neither extends nor erases a chosen prefix")
	check(choice._choice_view.get_node("Unchosen").text=="?","The next unchosen term remains a question")
	check(not choice.choose(-1) and not choice.choose(2) and choice.terms==before,"Out-of-domain choices cannot alter the prefix")
	var foreign:=Node3D.new();foreign.name="MapLabel";choice.add_child(foreign)
	choice.apply_grid_config({"horizon":"spread"})
	check(is_instance_valid(foreign) and foreign.get_parent()==choice and choice.terms==before,"A rebuild preserves external map nodes and chosen values")
	press(choice,"ResetChoices")
	check(choice.terms.is_empty() and choice._choice_view.find_children("Term_*","MeshInstance3D",false,false).is_empty(),"RESET removes the actual chosen terms and their meshes")
	for i in 256:
		choice.choose(i%2)
		if i%16==0:await process_frame
	check(choice.terms.size()==256 and not choice.choose(1),"Finite storage limit refuses further terms without overwriting the past")
	check(choice._choice_view.find_children("Term_*","MeshInstance3D",false,false).size()==10,"Long prefixes use a bounded ten-term display")
	check(choice._choice_view.has_node("Term_255") and not choice._choice_view.has_node("Term_0"),"Window shows the latest terms while the full prefix remains stored")
	check("instrument is full" in choice._choice_status.text,"The limit is labelled as an instrument limit")
	press(choice,"ResetChoices");press(choice,"Choose1")
	check(choice.terms==[1],"Reset after the limit starts a fresh prefix")
	var legacy: Node=load("res://commons/artifacts/brouwer_choice_sequence/brouwer_choice_sequence.tscn").instantiate()
	root.add_child(legacy)
	check(not legacy.visitor_choices and legacy._dots.size()==8,"Legacy placements retain the fixed illustration")
	check(not legacy.choose(0) and legacy.terms.is_empty(),"Illustration does not pretend to accept a visitor choice")
	legacy.apply_grid_config({"visitor_choices":"on"})
	check(legacy.has_node("Choose0"),"Deferred map config installs the controls after ready")
	var cantor: Node3D=load("res://commons/artifacts/cantor_diagonal_workbench/cantor_diagonal_workbench.tscn").instantiate()
	root.add_child(cantor)
	var previous: Array=[]
	for n in [4,8,16,24,32]:
		cantor._slider.set_normalized_value(cantor._normalized_for_n(n))
		cantor._slider.slider_moved.emit(0.0)
		cantor._process(1.0)
		check(cantor._n==n and cantor._d.size()==n,"Slider selects finite N="+str(n))
		var differs:=true
		for r in n:
			if cantor._d[r]==cantor._list[r][r] or cantor._d==cantor._list[r]:differs=false
		check(differs,"N="+str(n)+": constructed string differs from every displayed row at its diagonal bit")
		var stable:=true
		for r in previous.size():
			for c in previous[r].size():
				if previous[r][c]!=cantor._list[r][c]:stable=false
		check(stable,"N="+str(n)+": extending the display preserves earlier bits")
		previous=cantor._list.duplicate(true)
		evidence.append({"N":n,"diagonal":Array(cantor._d),"readout":cantor._plate_readout.text})
	var excluded: Node=load("res://commons/artifacts/excluded_middle_demo/excluded_middle_demo.tscn").instantiate();root.add_child(excluded)
	excluded._slider.set_normalized_value(0.0);excluded._slider.slider_moved.emit(0.0)
	check("CLASSICAL READING" in excluded._label.text,"Reading slider exposes the classical explanation")
	excluded._slider.set_normalized_value(1.0);excluded._slider.slider_moved.emit(1.0)
	check("not a third truth value" in excluded._label.text,"Constructive caption does not invent a third truth value")
	for i in 8:await process_frame
	var failures=checks.filter(func(c):return not c.ok)
	var f=FileAccess.open(OUT+"model-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"evidence":evidence,"failures":failures},"  "));f.close()
	print("BROUWER_MODELS ",checks.size()," checks; failures ",failures)
	quit(0 if failures.is_empty() else 1)
