extends "res://tools/probes/transformation_encounters.gd"
const MODEL = preload("res://commons/artifacts/geiger_counter/geiger_model.gd")

func landing_checks() -> void:
	var counter := find_scene("/geiger_counter.gd")
	check("geiger counter installed",counter!=null)
	if counter==null: return
	check("lava wall retained",find_scene("/lava_entropy_wall.gd")!=null)
	check("seed bench retained",find_scene("/museum_seed_study.gd")!=null)
	var a: Dictionary = counter.current.duplicate(true)
	check("96 increasing event times",a.events_us.size()==96 and _increasing(a.events_us))
	check("same seed repeats the event trace",MODEL.make_record(435,4,1000,a.source)==a)
	check("record roundtrip validates",MODEL.valid(JSON.parse_string(JSON.stringify(a,"",true,true))))
	var gaps: Array = []; var previous := 0
	for stamp in a.events_us: gaps.append(int(stamp)-previous); previous=int(stamp)
	check("variable intervals not a metronome",gaps.min()<25000 and gaps.max()>500000)
	var example := MODEL.extract([0,1000,2000,4000,5000,6000,7000,9000,10000,11000,12000,13000],1000)
	check("four distinct events per bit and alternating comparison",example[0].bit==0 and example[1].bit==1)
	check("ties skipped",example[2].bit==-1)
	check("incomplete group ignored",MODEL.extract([0,1000,2000],1000).is_empty())
	var fine_wav: PackedByteArray = counter._audio.stream.data.duplicate()
	var area: Node = counter._board.find_child("Btn_5",true,false).get_node("InteractableAreaButton")
	area.button_pressed.emit(area)
	check("clock button keeps every event time",counter.current.events_us==a.events_us and counter.current.clock_us==100000)
	check("clock change keeps audio byte identical",counter._audio.stream.data==fine_wav)
	var coarse: Dictionary = counter.current.duplicate(true)
	check("coarse clock produces tied interval pairs",coarse.pairs.any(func(p):return p.bit==-1))
	counter.compare_rate()
	check("rate comparison restores baseline clock and seed",counter.current.seed==a.seed and counter.current.clock_us==a.clock_us and counter.current.rate_per_second==8)
	check("twice the rate approximately halves duration",absi(2*int(counter.current.events_us[-1])-int(a.events_us[-1]))<100)
	counter.reset_model()
	var source: Dictionary = counter.current.source.duplicate(true)
	counter.toggle_sound()
	check("mute leaves trace and source unchanged",counter.current==a and counter.current.source==source and not counter.sound_on)
	counter.toggle_sound()
	counter.record_directory="res://ada_run/geiger_counter_probe"
	check("comparison saved",counter.keep())
	counter.new_sample()
	check("fresh seed correctly labelled simulation",counter.current.source.provider=="system_seed" and MODEL.valid(counter.current))
	check("kept replay restores original trace",counter.replay() and counter.current==a)
	check("replay restores identical click samples",counter._audio.stream.data==fine_wav)
	# AudioStreamPlayer3D starts on the next physics frame, unlike the control signal.
	await tick()
	await create_timer(0.15).timeout
	check("audio playback actually starts",counter._audio.playing and counter._audio.get_playback_position()>0)
	counter.play_hold()
	check("pause holds playback",counter._audio.stream_paused)
	# Let the already queued audio mix finish before measuring a settled pause.
	await create_timer(0.08).timeout
	var held: float = counter._audio.get_playback_position()
	await create_timer(0.2).timeout
	observations["paused_clock"]=[held,counter._audio.get_playback_position()]
	check("paused audio clock stays still",absf(counter._audio.get_playback_position()-held)<0.001)
	counter.play_hold()
	check("resume continues playback",not counter._audio.stream_paused)
	await create_timer(0.2).timeout
	check("resumed audio clock advances",counter._audio.get_playback_position()>held+0.05)
	var clone: Node3D = load(counter.scene_file_path).instantiate(); root.add_child(clone)
	clone.record_directory=counter.record_directory
	check("fresh instance reloads recorded comparison",clone.load_latest() and MODEL.valid(clone.current) and _same_events(clone.current.events_us,a.events_us))
	clone._audio.stop(); clone.queue_free()
	var bad := a.duplicate(true); bad.events_us[5]+=1
	check("edited event receipt rejected",not MODEL.valid(bad))
	bad=a.duplicate(true); bad.pairs[0].bit=1-int(bad.pairs[0].bit)
	check("edited extracted bit rejected",not MODEL.valid(bad))
	var peak := 0; var nonzero := 0
	for i in range(0,fine_wav.size(),2):
		var sample := absi(fine_wav.decode_s16(i)); peak=maxi(peak,sample)
		if sample>0: nonzero+=1
	check("audible waveform with bounded headroom",peak>1000 and peak<=26214 and nonzero>10000)
	check("mono 44.1 kHz PCM",counter._audio.stream.mix_rate==44100 and not counter._audio.stream.stereo and counter._audio.stream.format==AudioStreamWAV.FORMAT_16_BITS)
	check("preview WAV export",counter._audio.stream.save_to_wav("res://doc/book/iterations/2026-10-14-geiger-counter/geiger-preview.wav")==OK)
	var position_value := counter.to_global(Vector3(-1.78,0.02,1.1))
	check("console approach has floor",not floor_at(position_value).is_empty())
	observations["baseline"]=a; observations["coarse_clock"]=coarse
	observations["audio"]={"bytes":fine_wav.size(),"peak_pcm":peak,"nonzero_samples":nonzero,"sample_rate":44100,"volume_db":counter._audio.volume_db}
	observations["position"]=xyz(counter.global_position)
	observations["limits"]=["Simulated detections, no physical radioactive source.","Native interaction events and desktop capture; headset and listening judgement remain open."]
	counter._audio.stop(); counter._refresh_visuals(4.5)
	await snapshot("geiger-counter",counter.to_global(Vector3(-0.35,1.8,4.1)),counter.to_global(Vector3(-0.35,1.25,0)),54)
	await snapshot("geiger-board",counter.to_global(Vector3(-1.45,1.65,2.0)),counter.to_global(Vector3(-1.25,1.2,0.1)),59)

func _increasing(values: Array) -> bool:
	var previous := 0
	for v in values:
		if int(v)<=previous: return false
		previous=int(v)
	return true

func _same_events(a: Array, b: Array) -> bool:
	if a.size()!=b.size(): return false
	for i in range(a.size()):
		if int(a[i])!=int(b[i]): return false
	return true
