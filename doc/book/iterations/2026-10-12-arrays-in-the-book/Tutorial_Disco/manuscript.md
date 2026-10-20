# Disco — a reader returns

**Learning elements**

- A Boolean score
- A playhead that wraps through addresses
- Elapsed time, tempo and retained remainder
- Independent readers of independent records

Hold the museum floor, then press ONE STEP. Black and white exchange places. Hold the sequencer instead and let the floor run. One clock can stop while the other continues. Your footsteps are not being recorded into its score.

We bring back the clock from Transformation and the retained addresses from Array. This lesson has two short readings: the floor uses a changing phase in a rule; the score keeps decisions that a playhead visits. The installed instrument has four tracks and sixteen steps. Our construction begins with one track and eight steps so you can hear and follow each visit.

## Begin with both clocks held

Save the two files below together. Attach `lesson.gd` to an empty unit-scale `Node3D`, `DiscoStudy`, at floor level on clear floor in this museum hall. Allow about six metres across and seven deep. Keep the museum's player and support floor. The little floor behind the score is visual; it does not add holes or steps to the museum floor.

The four labelled pads use the overlap connection from Array. Walk into a pad to activate it, then leave before entering again. A pad is an `Area3D` sensor, not a physical push switch. The VR player's declared group and layer are the same as before. No controller installation or new input mapping is required here.

First use FLOOR STEP twice. Then leave the pad and return to SCORE STEP until you have visited all eight places. White score cells mean `true`, asking for a click; dark cells mean `false`, asking for silence. A small raised marker shows the last address read. It starts hidden because step `-1` means no address has been read yet.

### lesson.gd

<!-- include:lesson.gd -->

### click_sound.gd — supplied receiver

This small receiver creates one short, quiet sound used by every event. Copy it unchanged for now. Its sample construction is printed so `speaker.play()` has a real source. Learning sound synthesis is a later task.

<!-- include:click_sound.gd -->

## A field receives a phase

The floor uses `(x + z + phase) % 2`. At phase zero, neighbouring cells alternate. Adding one exchanges them; adding another returns to the first arrangement. Sixteen boxes keep their positions. Their separately owned materials let one address change without repainting every box through a shared material.

The construction function returns each new box, as in Array. The floor stores those references in `tiles[x][z]`. The two nested loops in `refresh_floor` revisit them. This time we change an appearance instead of occupancy. We still use only black, white and grey before Colour.

Start FLOOR PLAY/HOLD. Every `floor_period` seconds the phase advances. Hold it again. FLOOR STEP changes the phase only while held, giving you time to compare two states. Walking on the little field does not advance or record anything.

## A score receives a reader

`score` is an `Array[bool]`: each entry is either `true` or `false`. The first and fifth entries begin true. `step` names the most recently read address. Adding one and taking `% score.size()` visits the next address and returns from seven to zero. Reading an event does not consume it. Its value remains available on the next circuit.

SCORE STEP makes one visit while playback is held. SCORE PLAY/HOLD lets elapsed time choose when to visit. The duration `60.0 / bpm / 4.0` gives a sixteenth-note step when BPM counts quarter-note beats. At 120 BPM, one step takes 0.125 seconds. Tempo describes visits, not how many entries the array owns.

`floori` takes the integer part of a non-negative quotient. Dividing accumulated seconds by step duration tells us how many complete steps have elapsed. Subtracting those complete durations keeps the leftover fraction. Resetting the accumulator to zero would repeatedly discard that time and make playback drift.

There is a deliberate rule for a stalled frame: advance the playhead past all elapsed steps, but sound only the final visited address. Missed visits stay in the stored score; they are not played in a burst. This small reader follows elapsed time without claiming to be an audio-accurate scheduler. Synthesis and precise musical scheduling can develop later.

The receiver stores signed sample bytes, their sample rate and a short decay. Its masking expression keeps a signed value's byte representation in the byte array. Those encoding details belong to the supplied sound helper, not to the meaning of a Boolean score. [Godot's AudioStreamWAV reference](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html) specifies signed eight-bit PCM for this format.

## Keep one thing; change another

Play the score while holding the floor. Then reverse the arrangement. Neither clock writes into the other clock's record. Holding a reader retains its position and fractional elapsed time; resuming continues it. Stopping does not abruptly cut a click already sounding. Our small study omits the museum's additional sound-to-floor flash bridge.

Keep BPM at 120. Move the second `true` from index four to index three, and run again. The sound is the same; the interval between its visits changes. Restore that score, then change BPM to 90. The addresses stay fixed while their visits spread out in time.

Choose your own eight-entry score. Predict which steps will sound before you use SCORE STEP. Then run it, hold it, and resume. Explain which variable keeps your decisions and which keeps the reader's place. Changing the source and starting again makes a fresh study; pause and resume happen within the current run.

Across these halls, a value has meant an occupant, an orientation and an instruction to sound. The array gives each value an address; the reader gives it work to do. Keep that distinction for Colour. The same familiar forms will receive material values, and the neighbours already held in an arrangement will change how those values appear.
