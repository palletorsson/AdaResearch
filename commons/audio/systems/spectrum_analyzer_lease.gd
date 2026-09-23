extends RefCounted
## Waveform views share one owned analyser per bus and release the last lease.
## Never remove another instrument's effect, even if bus indices have changed.
static var _entries:Dictionary={}
static func acquire(requested_bus:String)->Dictionary:
	var index:=AudioServer.get_bus_index(requested_bus)
	if index<0:index=AudioServer.get_bus_index("Master")
	var key:=AudioServer.get_bus_name(index)
	if not _entries.has(key):
		var effect:=AudioEffectSpectrumAnalyzer.new()
		effect.buffer_length=.1;effect.fft_size=AudioEffectSpectrumAnalyzer.FFT_SIZE_512
		AudioServer.add_bus_effect(index,effect)
		_entries[key]={"effect":effect,"references":0}
	var entry:Dictionary=_entries[key]
	var effect_index:=-1
	for i in AudioServer.get_bus_effect_count(index):
		if AudioServer.get_bus_effect(index,i)==entry.effect:effect_index=i;break
	if effect_index<0:
		AudioServer.add_bus_effect(index,entry.effect)
		effect_index=AudioServer.get_bus_effect_count(index)-1
	entry.references+=1
	return {"key":key,"effect":entry.effect,"instance":AudioServer.get_bus_effect_instance(index,effect_index)}
static func release(lease:Dictionary)->void:
	if lease.is_empty() or not _entries.has(lease.key):return
	var entry:Dictionary=_entries[lease.key]
	if entry.effect!=lease.effect:return
	entry.references-=1
	if entry.references>0:return
	remove_owned_effect(entry.effect)
	_entries.erase(lease.key)
static func remove_owned_effect(effect:AudioEffect)->void:
	if effect==null:return
	for bus in AudioServer.get_bus_count():
		for index in range(AudioServer.get_bus_effect_count(bus)-1,-1,-1):
			if AudioServer.get_bus_effect(bus,index)==effect:AudioServer.remove_bus_effect(bus,index)
