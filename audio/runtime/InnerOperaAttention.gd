extends RefCounted
## When an object has earned a thought. Pure state machine: no audio, no nodes,
## no engine — feed it what the player is attending to and it answers with the
## object whose thought should sound now, or "" for silence.
##
## It encodes the four rules the inner-opera direction asks for:
##   intentional  — gaze must settle for DWELL before it counts as choosing;
##                  a touch is already deliberate and skips the wait
##   one at a time — nothing is returned while a thought is sounding
##   not repeated — an object speaks once and stays quiet until the player
##                  has genuinely looked away (RELEASE) and come back
##   silence is allowed — a gap after each thought that nothing can shorten
##
## Separate from the voice on purpose: these timings are the feel of the piece
## and want to be tested and tuned without rendering a single sample.

## Continuous gaze before a look becomes a choice.
@export var dwell_seconds := 0.9
## Gaze away this long means the player has left; the object can speak again.
@export var release_seconds := 0.6
## Quiet after a thought ends. Nothing may start inside it.
@export var silence_seconds := 1.2

var _dwell := 0.0
var _looking := ""
var _spent := {}
var _away := {}
var _speaking := false
var _quiet := 0.0

## What the player is attending to, and the frame time. Pass "" for nothing.
## Returns the object_id whose thought should start now, or "".
func look(object_id: String, delta: float) -> String:
	delta = maxf(delta, 0.0)
	if _quiet > 0.0:
		_quiet = maxf(_quiet - delta, 0.0)
	# Everything not being looked at is drifting towards forgetting this visit.
	for other in _away.keys():
		if other != object_id:
			_away[other] = _away[other] + delta
			if _away[other] >= release_seconds:
				_spent.erase(other)
	if object_id.is_empty():
		_looking = ""
		_dwell = 0.0
		return ""
	if object_id != _looking:
		_looking = object_id
		_dwell = 0.0
	_away[object_id] = 0.0
	_dwell += delta
	if _dwell < dwell_seconds:
		return ""
	return _choose(object_id)

## A deliberate touch or trigger. Intent is not in doubt, so no dwell — but the
## thought still waits its turn and still will not repeat itself.
func touch(object_id: String) -> String:
	if object_id.is_empty():
		return ""
	_looking = object_id
	_away[object_id] = 0.0
	_dwell = dwell_seconds
	return _choose(object_id)

func _choose(object_id: String) -> String:
	if _speaking or _quiet > 0.0 or _spent.has(object_id):
		return ""
	_spent[object_id] = true
	_speaking = true
	return object_id

## The voice has begun. Call this if something other than look/touch started it.
func mark_speaking(object_id: String) -> void:
	_spent[object_id] = true
	_away[object_id] = 0.0
	_speaking = true

## The voice has stopped, by ending or by being cut off. Opens the silence.
func mark_silent() -> void:
	_speaking = false
	_quiet = silence_seconds

func is_speaking() -> bool:
	return _speaking

## True while the gap after a thought is still running.
func is_resting() -> bool:
	return _quiet > 0.0

## Whether this object has already given its thought on this visit.
func has_spoken(object_id: String) -> bool:
	return _spent.has(object_id)

## Progress towards an intentional look, 0..1 — for a reticle or a glow.
func dwell_ratio(object_id: String) -> float:
	if object_id.is_empty() or object_id != _looking or dwell_seconds <= 0.0:
		return 0.0
	return clampf(_dwell / dwell_seconds, 0.0, 1.0)

## Forget the visit entirely: every object may speak again.
func reset() -> void:
	_dwell = 0.0
	_looking = ""
	_spent.clear()
	_away.clear()
	_speaking = false
	_quiet = 0.0
