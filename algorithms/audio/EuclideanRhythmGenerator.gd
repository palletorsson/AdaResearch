class_name EuclideanRhythmGenerator
extends Node

signal pulse(step_index: int, is_active: bool)
signal pattern_changed(new_pattern: Array[bool])

@export_group("Rhythm Parameters")
@export var steps: int = 16:
	set(value):
		steps = max(1, value)
		_dirty = true
@export var pulses: int = 4:
	set(value):
		pulses = clamp(value, 0, steps)
		_dirty = true
@export var rotation: int = 0:
	set(value):
		rotation = value
		_dirty = true

@export_group("Timing")
@export var bpm: float = 120.0
@export var active: bool = true

var _current_pattern: Array[bool] = []
var _current_step: int = 0
var _time_accumulator: float = 0.0
var _dirty: bool = true

func _ready() -> void:
	_update_pattern()

func _process(delta: float) -> void:
	if not active:
		return
		
	if _dirty:
		_update_pattern()
		
	var seconds_per_beat = 60.0 / bpm
	# Assuming 4 pulses per beat (16th notes) implies steps represent 16th notes?
	# Or steps represent the fundamental grid unit.
	# Let's say steps are 16th notes relative to the BPM.
	# If BPM is quarter notes, then one step is 0.25 beats.
	var seconds_per_step = seconds_per_beat / 4.0 
	
	_time_accumulator += delta
	
	if _time_accumulator >= seconds_per_step:
		_time_accumulator -= seconds_per_step
		_advance_step()

func _advance_step() -> void:
	_current_step = (_current_step + 1) % steps
	var is_hit = _current_pattern[_current_step] if _current_step < _current_pattern.size() else false
	pulse.emit(_current_step, is_hit)

func _update_pattern() -> void:
	var base_pattern = EuclideanSequencer.generate_rhythm(steps, pulses)
	_current_pattern = EuclideanSequencer.rotate_pattern(base_pattern, rotation)
	pattern_changed.emit(_current_pattern)
	_dirty = false
	
func reset() -> void:
	_current_step = -1
	_time_accumulator = 0.0
	_update_pattern()

