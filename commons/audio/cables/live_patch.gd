extends Node
## A deliberately small audio graph on the existing Eurorack: VCO -> VCF -> VCA,
## or VCO -> VCA. Geometry only describes a cord; routes authorize its signal.
const RATE := 22050.0
var uvac: Node3D
var manager: SynthCableManager
var player: AudioStreamPlayer3D
var playback: AudioStreamGeneratorPlayback
var filter := AudioEffectLowPassFilter.new()
var effect_index := -1
var powered := false
var audible := false
var filtered := false
var phase := 0.0
var gain := 0.0
var frames_generated := 0
var values: Dictionary = {}

func setup(controller: Node3D, cables: SynthCableManager) -> void:
	uvac = controller; manager = cables; player = uvac.preview_player
	var bus := AudioServer.get_bus_index(uvac.dedicated_bus_name)
	filter.cutoff_hz = 1000; filter.resonance = 0.3
	effect_index = AudioServer.get_bus_effect_count(bus)
	AudioServer.add_bus_effect(bus, filter)
	var source := AudioStreamGenerator.new()
	source.mix_rate = RATE; source.buffer_length = 0.08
	player.stream = source; player.volume_db = -14.0
	player.play(); playback = player.get_stream_playback()

func _process(_delta: float) -> void:
	if not is_instance_valid(uvac) or not is_instance_valid(manager): return
	values = uvac._get_current_values()
	var through_filter := manager.has_route("vco_frequency", "vcf_audio_in") and manager.has_route("vcf_audio_out", "vca_audio_in")
	var direct := manager.has_route("vco_frequency", "vca_audio_in")
	audible = powered and (through_filter or direct) and manager.has_route("vca_audio_out","speaker_audio")
	filtered = through_filter and float(values.get("filter_on",1.0)) >= 0.5
	var bus := AudioServer.get_bus_index(uvac.dedicated_bus_name)
	if bus >= 0:
		AudioServer.set_bus_effect_enabled(bus,effect_index,filtered)
		filter.cutoff_hz = clampf(values.get("cutoff",1000.0),100,8000)
		filter.resonance = clampf(values.get("resonance",0.3),0,0.8)
	for cable in manager.cables:
		if not cable.is_fully_connected():
			cable.flow = 0.0
			continue
		var source: String = cable.get_output_jack().parameter_name
		# A disconnected end never displays a travelling signal.
		if source == "vco_frequency": cable.flow = 1.0 if powered else 0.0
		elif source == "vcf_audio_out": cable.flow = 1.0 if powered and manager.has_route("vco_frequency","vcf_audio_in") else 0.0
		elif source == "vca_audio_out": cable.flow = float(values.get("amp",0.6)) if audible else 0.0
	var target := float(values.get("amp",0.6)) * 0.28 if audible else 0.0
	var frequency := clampf(float(values.get("freq",220.0))*pow(2.0,float(values.get("detune",0.0))/1200.0),20,2000)
	var waveform := clampi(roundi(values.get("source_type",0)),0,3)
	var pan := clampf(values.get("pan",0.0),-1,1)
	var stereo := Vector2(sqrt((1.0-pan)*0.5),sqrt((1.0+pan)*0.5))
	if not playback: return
	var frames := playback.get_frames_available()
	var buffer := PackedVector2Array(); buffer.resize(frames)
	for i in frames:
		# Ten harmonics at most, below Nyquist. Slew gain to avoid unplug clicks.
		phase = fposmod(phase + frequency/RATE,1.0)
		gain = move_toward(gain,target,0.0006)
		var sample := 0.0
		var harmonics := mini(10,int(RATE*0.45/frequency))
		for h in range(1,harmonics+1):
			var weight := 1.0/h
			if waveform == 1: weight = weight if h%2 == 1 else 0.0
			elif waveform == 2: weight = (1.0 if h%4 == 1 else -1.0)/(h*h) if h%2 == 1 else 0.0
			elif waveform == 3: weight = 1.0 if h == 1 else 0.0
			sample += sin(TAU*phase*h)*weight
		buffer[i] = stereo * sample * gain
	playback.push_buffer(buffer); frames_generated += frames

func _exit_tree() -> void:
	if not is_instance_valid(uvac): return
	var bus := AudioServer.get_bus_index(uvac.dedicated_bus_name)
	if bus >= 0 and effect_index >= 0 and effect_index < AudioServer.get_bus_effect_count(bus):
		AudioServer.remove_bus_effect(bus,effect_index)
