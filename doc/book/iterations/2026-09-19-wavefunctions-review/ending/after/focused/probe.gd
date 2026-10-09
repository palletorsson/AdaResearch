extends SceneTree
var out:=""
var current:=false
var checks:Array=[]
var values:Dictionary={}
func _initialize()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	current="--current" in OS.get_cmdline_user_args()
	run.call_deferred()
func check(ok:bool,message:String)->void:
	checks.append({"ok":ok,"message":message});print("ENDING ","PASS " if ok else "FAIL ",message)
func press(demo:Node,index:int)->void:
	var button=demo._panel.find_child("Btn_"+str(index),true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)
	demo._process(0)
func run()->void:
	var world=Node3D.new();root.add_child(world);current_scene=world
	var bar=load("res://algorithms/wavefunctions/resonance/resonating_bar.tscn").instantiate();world.add_child(bar);bar.set_process(false)
	var bar2=load("res://algorithms/wavefunctions/resonance/resonating_bar.tscn").instantiate();bar2.frequency=261.63;world.add_child(bar2);bar2.set_process(false)
	check(bar.audio_player.stream.mix_rate==44100,"bar PCM uses 44100 Hz")
	check(not bar.audio_player.stream.stereo,"bar PCM has one source channel")
	check(bar.audio_player.stream.data.size()==int(7.5*44100)*2,"default note buffer is 7.5 seconds of PCM16")
	var max_error:=0.0
	for i in [100,1024,44101,132301,328321]:
		var t=float(i)/44100.0;var env=exp(-t/3.0)
		if t>7.4:env*=(7.5-t)/.1
		var expected=sin(TAU*440.0*t)*env*.5
		var actual=float(bar.audio_player.stream.data.decode_s16(i*2))/32767.0
		max_error=maxf(max_error,absf(expected-actual))
	check(max_error<.00004,"generated PCM matches assigned sine frequency, decay and final fade")
	values.pcm_max_error=max_error
	bar.hit_velocity=.5;bar._trigger_resonance(.5);bar._process(3.0)
	check(absf(bar.current_amplitude-.25*exp(-1.0))<.00001,"glow amplitude reaches exp(-1) after three seconds")
	bar2.hit_velocity=.8;bar2._trigger_resonance(.8)
	check(bar.is_resonating and bar2.is_resonating,"different bars hold independent source voices")
	bar._trigger_resonance(.5)
	check(bar.resonance_time==0 and bar2.is_resonating,"same bar resets its age without clearing another bar")
	check(bar.audio_player.volume_db==-3.0,"half hit maps to minus3 dB independently of glow amplitude")
	var window=bar.get_audio_window(.012,100)
	check(window.samples.size()==100 and window.has("gain"),"source-audio window exposes sampled data and player gain")
	bar.force_stop();bar2.force_stop()
	var beat=load("res://algorithms/wavefunctions/beat_frequency/beat_frequency_demo.tscn").instantiate();world.add_child(beat);beat.set_process(false)
	check(beat._spheres_a.size()==64 and beat._spheres_b.size()==64 and beat._spheres_sum.size()==64,"beat creates three64-sphere rows")
	check(beat.find_children("*","AudioStreamPlayer3D",true,false).is_empty() and beat.find_children("*","AudioStreamPlayer",true,false).is_empty(),"beat demonstration has no audio player")
	var sa=beat.find_child("Param_0",true,false);var sb=beat.find_child("Param_1",true,false)
	sa.slider_moved.emit("FREQ A",.5);sb.slider_moved.emit("FREQ B",.5)
	check(is_equal_approx(beat._freq_a,5.5) and beat._freq_a==beat._freq_b,"both real control signals map midrange to5.5 Hz")
	beat._time=.173;beat._animate_spheres()
	var raw_a=beat._spheres_a[7].position.y-(beat._base_y+beat.row_spacing)
	var raw_b=beat._spheres_b[7].position.y-beat._base_y
	var raw_sum=beat._spheres_sum[7].position.y-(beat._base_y-beat.row_spacing)
	check(absf(raw_a-raw_b)<.00001 and absf(raw_sum-raw_a)<.00001,"equal frequencies align inputs and half-scaled sum")
	sb.slider_moved.emit("FREQ B",.52);beat._animate_spheres()
	check(beat._beat_label.text.contains("0.2 Hz"),"nearby frequency difference is named with one-decimal precision")
	for i in 64:
		raw_a=beat._spheres_a[i].position.y-(beat._base_y+beat.row_spacing);raw_b=beat._spheres_b[i].position.y-beat._base_y;raw_sum=beat._spheres_sum[i].position.y-(beat._base_y-beat.row_spacing)
		if absf(raw_sum-(raw_a+raw_b)*.5)>.00001:check(false,"half sum at sphere"+str(i))
	check(true,"all64 close-frequency output positions checked against half raw sum")
	var stair=load("res://algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.tscn").instantiate();world.add_child(stair)
	var samples=stair._compute_samples()
	check(samples.size()==80 and stair.get_node("StairSteps").get_child_count()==80,"stair builds one80-tread helix")
	check(stair.STEP_RISE==.11 and stair.WAVE_AMPLITUDE==.45,"shipped staircase supplies uniform rise and radial amplitude")
	var p:Vector3=samples[21].position;var angle=float(21)/79.0*TAU*2.0
	check(absf(Vector2(p.x,p.z).length()-(2.5+.45*sin(2*angle)))<.0001,"sample radius follows source radial sine formula")
	check(absf(p.y+.11-21*.11)<.0001,"sample tread top follows uniform rise")
	await process_frame
	var bridges:=0
	for child in stair.get_children():
		if child is StaticBody3D:
			for shape in child.get_children():
				if shape is CollisionShape3D and shape.shape is ConcavePolygonShape3D:bridges+=1
	values.membrane_colliders=bridges
	check(bridges==79,"membranes provide79 connecting colliders; no full walk inferred")
	var path=load("res://algorithms/wavefunctions/oscillation_driver/TrigWalkingPath.tscn").instantiate();world.add_child(path);path.set_physics_process(false)
	check(path.sine_steps.size()==40 and path.cosine_steps.size()==40,"secondary walkway creates40finite step pairs")
	path._update_escalator(20)
	check(path.sine_steps.size()==40 and path.cosine_steps.size()==40,"escalator circulates existing finite steps")
	var demo=load("res://commons/artifacts/additive_wave_demo/additive_wave_demo.tscn").instantiate()
	var config={"stand":"bench","waveform":"sawtooth"}
	if current:config.name_after_compare=true
	demo.apply_grid_config(config);world.add_child(demo);demo.set_process(false);demo._time=.125;demo._process(0)
	check(demo.harmonic_sliders.size()==5,"configured-before-tree bench wires exactly five sliders")
	check(demo.find_children("Staging","Node3D",true,false).size()<=1 and demo.find_children("Readout","Label3D",true,false).size()==1,"bench has one readout and no duplicate staging")
	check(demo.harmonic_amplitudes==[1.0,.5,.333,.25,.2],"arrival recipe unchanged")
	check(demo.preset_label.text==("ARRIVAL RECIPE" if current else "≈ Sawtooth Wave (all harmonics)"),"arrival naming matches opt-in or legacy policy")
	press(demo,2)
	check(demo.held,"HOLD still freezes the wave")
	if current:check(demo.preset_label.text=="ARRIVAL RECIPE","HOLD preserves first comparison before recipe naming")
	if current:
		demo.harmonic_sliders[4].set_normalized_value(.24);demo._on_harmonic_changed(.24,4);demo._process(0)
		check(demo.preset_label.text=="COMPARE THE SUM","manual edit keeps recognition delayed and avoids calling changed mix arrival")
		demo._set_amplitudes([1.0,.5,.333,.25,.2]);demo._process(0)
		check(demo._explanation_label.text.contains("Five phase-locked") and not demo._explanation_label.text.contains("any periodic"),"opt-in caption describes finite coefficient family")
	var at=demo.display_values(91)
	check(absf(at.sum_of_drawn_rows-at.total)<.00001,"all five arrival rows add to total")
	press(demo,1)
	check(demo.harmonic_amplitudes==[1.0,0.0,0.0,0.0,0.0],"H1 ALONE removes only higher terms")
	check(demo.preset_label.text=="Pure Sine Wave","H1 ALONE reveals recognition")
	press(demo,0)
	check(demo.harmonic_amplitudes==[1.0,.5,.333,.25,.2] and demo.preset_label.text.contains("Sawtooth"),"BASELINE restores coefficients and visible recipe name")
	demo._set_amplitudes([1.0,.5,.333,.25,.24]);demo._process(0)
	check(demo.preset_label.text=="Custom Waveform","fifth-coefficient mismatch leaves named recipe")
	demo.set_preset("triangle");demo._process(0)
	check(demo.preset_label.text=="Odd 1/n² mix (positive terms)","legacy positive odd recipe is not called a triangle")
	if current:
		var legacy=load("res://commons/artifacts/additive_wave_demo/additive_wave_demo.tscn").instantiate();legacy.apply_grid_config({"waveform":"sawtooth"});world.add_child(legacy);legacy.set_process(false)
		check(legacy.preset_label.text.contains("Sawtooth"),"non-opted placements retain immediate recipe naming")
	var f=FileAccess.open(out+"focused.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"values":values,"headset_tested":false,"heard_by_person":false},"  "));f.close()
	print("ENDING COMPLETE ",checks.size());quit(0 if checks.all(func(x):return x.ok) else 1)
