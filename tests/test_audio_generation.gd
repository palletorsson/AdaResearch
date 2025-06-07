# Quick test script to generate audio files
# Run this in Godot to generate .wav files

extends Node

func _init():
	print("Generating audio files...")
	AudioSynthesizer.generate_and_save_all_sounds()
	print("Audio generation complete - check commons/audio/ folder")
