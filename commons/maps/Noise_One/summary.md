# Noise One — Summary

Noise_One is the third map in the Noise sequence. It introduces octave stacking — the technique that turns coherent noise from a single smooth layer into the rough, multi-scale patterns that read as natural. A large torus at the centre of the room carries the demonstration.

The torus surface is coloured by a noise function. A bank of sliders next to it controls four parameters: the number of octaves, the lacunarity, the persistence, and the base frequency. At one octave, the surface reads as a slow gradient. Adding octaves layers progressively finer noise on top, each at roughly twice the frequency and half the amplitude of the one before. The surface grows texture — first wide strokes, then grain, then pore-scale detail.

Because the torus is a closed surface, the learner can walk around it and see how the noise wraps. A seam is drawn lightly where the sampling coordinates restart, and the map uses that seam to show that coherent noise is continuous across space but not automatically across wrapping — the seam has to be handled deliberately.

Within the sequence, Noise_One is the pivot from single to composite fields. Noise_Voxel will next take this kind of layered field and discretise it into habitable architecture.

## The pair (2026-09-12)

`noisetorus:180#stand:pair` stands on the hall's north strip as two rings on one bench: the same size, the same shader, the same noise scale, sampling one field. One is allowed to spend that field as relief and the other as colour, and neither does both. A lamp stands on the same coordinate of each, and the plate names the coordinate, the field's value there, and what each reading makes of it.

The two readings are not equivalent, which is the room's finding. The field runs from minus one to plus one. The relief spends all of it, outward where the value is positive and inward where it is negative. The colour cannot, because brightness has no negative: wherever the field is below zero the ring is black, and black however far below it goes. Half the field is invisible in colour and perfectly legible in relief, and neither ring is lying.

FREEZE stops both of the shader's clocks, which is more than it sounds: one moves the coordinate the field is sampled at and the other rotates the hue, and a ring whose colours had stopped could still be sliding its sample. Every use of time in that shader passes through one of those two speeds. SAMPLE walks the lamps round the ring together. AMPLITUDE changes what the surface does with a value and leaves the value alone; FREQUENCY changes which value is at the coordinate at all, and the plate says which of the two was touched last.

Nothing here carries a collider. The corrugation lives in the vertex stage of a shader, where no collider can see it, and the plate says so: what you can see is not what you could touch.

Corrected in the same pass: the hall's description promised octave summation and a VR brush, neither of which this room contains, and the ring itself stood in the middle of the hall's own hole where no visitor can stand near it.
