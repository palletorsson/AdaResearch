# Point Lines: a line to move with

Four local paragraph edits continue the close reading from connection and measurement into Walk this line and the player trace.

## Decisions

1. Replace an abstract phrase about varying a relation with a visible comparison: the stripe stays straight through different journeys.
2. Locate the effect of the instruction in a possible correction of a step. The artifact draws words and geometry; it does not score compliance. Keep the possibility of dancing available to this reader.
3. Invite inspection of where stripe and trace part company. Remove the guarantee that a particular sideways step was recorded. The authored stripe and the trace have different histories: one waits, the other takes shape during movement.
4. Give the tracking mechanism a bodily consequence. In VR the recorder takes horizontal coordinates from the headset and retains the rig's floor-level height (plus a small drawing offset). A lean can therefore affect the line while the feet stay still. The script samples positions and connects accepted points with straight segments.

The source supports these possible actions; no new headset experience is claimed. Movement below the recording threshold need not add a point. The new wording does not promise a visible record of every footstep, lean or small motion.

## Kept

The preceding connection, barrier and measurement edits; the glass-supported basin; the question of what following means to a body; the comparison between journeys sharing endpoints; all code and footnote definitions; the closing question and “Bring the detour.” Point One and Point Trace are unchanged.

The earlier critical.md describes a different grid-focused route and makes stronger general claims about straightness. Those claims were not imported. The present hall can invite pleasure, guidance, correction and deviation without assigning one moral meaning to each shape. Existing Ahmed references stay in the footnotes; no new historical attribution was added.

## Source checks

- walk_this_line_marking.gd constructs the stripe and lettering. It contains no walk-scoring loop. The current map supplies the black paint and glass basin.
- player_trace.gd: _tracked_position uses the headset's X and Z in VR and the walker position on desktop. Accepted positions pass a movement gate, enter the retained list and are drawn as a line strip by _rebuild_trail.
- player_trace.tscn sets the movement threshold to 0.01 m and retains up to 1024 points without time fading. This pass does not explain every setting; Point Trace takes up the question of what is kept.

No scene, map, script behavior or artifact role changes. No new Godot or headset run. The current manuscript hash and purpose notes are synchronized. Full-book and audio captures remain frozen.

## Next

Point Trace: stay with the held drawing point, its count and its sampled curve. Read the existing opening before changing it; it already gives the reader a concrete pause-and-move comparison. Do not introduce another generic account of loss where the artifact offers a particular choice of resolution.

See changes.json for each paragraph's incitement, Point_Lines.diff for the exact changes, and checks.json for preservation checks.
