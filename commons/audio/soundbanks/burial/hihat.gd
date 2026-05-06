# Burial Hi-Hat - Cobweb Style
# Research: burial.md
#
# Character: Fuzzy, phaser-like, covered in cobwebs
# Source: Processed UK Garage hats
#
# FROM RESEARCH:
# "Snares and hi-hats covered in fuzz and phaser, like cobwebs on forgotten instruments"

class_name BurialHihat
extends RefCounted

const SAMPLE_RATE = 44100.0

const CLOSED_DECAY_S = 0.04
const OPEN_DECAY_S = 0.15
const PHASER_RATE = 10.0          # Phaser LFO
const PHASER_DEPTH = 3.0          # Phaser modulation
const LEVEL = 0.1                 # Quiet, background texture


static func generate(t: float, trigger_time: float = 0.0, open: bool = false) -> float:
	var dt = t - trigger_time
	var max_dur = 0.25 if open else 0.12
	if dt < 0.0 or dt > max_dur:
		return 0.0
	
	var decay = OPEN_DECAY_S if open else CLOSED_DECAY_S
	var env = exp(-dt / decay)
	
	var noise = (randf() * 2.0 - 1.0)
	
	# Phaser effect - "like cobwebs"
	var phaser = sin(2.0 * PI * 2000.0 * dt + sin(dt * PHASER_RATE) * PHASER_DEPTH)
	noise *= phaser
	
	return clampf(noise * env * LEVEL, -1.0, 1.0)


static func generate_closed(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, false)


static func generate_open(t: float, trigger_time: float = 0.0) -> float:
	return generate(t, trigger_time, true)
