extends Node

var text = """
[font_size=28][b]6. The Lineage: Satie, Cage, and The Machine[/b][/font_size]
[i]Furniture, Silence, and the Removal of Ego[/i]

[i][color=gray]Summary: The \"Discreet Music\" system is not an isolated invention. It is the synthesis of two radical 20th-century ideas: Erik Satie’s \"Furniture Music\" (music as spatial environment) and John Cage’s \"Indeterminacy\" (music as a process independent of the composer's will). This code is a machine that uses Cage’s methods to build Satie’s room.[/color][/i]

[hr]

[b]Erik Satie: Music as Wallpaper[/b]

In 1917, Erik Satie proposed [i]Musique d'ameublement[/i] (Furniture Music). He argued that music should not demand attention but should exist in the background, like a chair or a pattern on the wall.

[i]\"There is no need to listen to it. You can walk around it, talk over it, live inside it.\"[/i]

[b]The Loop as Stasis[/b]
Satie's piece [i]Vexations[/i] consists of a short, ambiguous theme repeated 840 times.
*   Traditional music is [b]linear[/b] (Start → Climax → End).
*   Satie’s music is [b]spatial[/b] (State A → State A → State A).

Our [b]Discreet Music[/b] implementation honors this. The loops do not \"progress\"; they circulate. The visualizer’s concentric rings are a map of this stasis—a closed system that creates a texture rather than a story.

[hr]

[b]John Cage: The Removal of Ego[/b]

If Satie defined the [i]function[/i] (Ambient), John Cage defined the [i]method[/i] (Algorithmic).

Cage sought to remove his own likes and dislikes from the creative process. He used the [i]I Ching[/i], star charts, and imperfections in paper to determine notes. He believed that [b]organization[/b] was superior to [b]choice[/b].

[i]\"One must be disinterested in the result.\"[/i]

In our system, the `DiscreetMusicLooper.gd` is a Cagean machine:
*   It does not \"know\" what melody will result from the phasing.
*   It does not \"care\" if the notes clash or harmonize.
*   It simply executes the rule: `Loop A (34) + Loop B (37)`.

The beauty that emerges is [b]emergent[/b], not designed. It is the \"music of changes.\"

[hr]

[b]Eno's Synthesis: The Cybernetic Gardener[/b]

Brian Eno combined these two lineages.
*   [b]Goal:[/b] Satie's \"ignorable\" environment.
*   [b]Tool:[/b] Cage's procedural systems.

But Eno added a crucial Cybernetic twist: [b]Feedback[/b].
Unlike Cage, who often accepted [i]randomness[/i] (Chaos), Eno designed [i]systems[/i] (Order). The loops are deterministic, but their interaction is complex.

[color=green][b]Code as Philosophy[/b][/color]
[color=green][code]
# Satie's Contribution:
var volume = -20.0 # Quiet, background, ignorable

# Cage's Contribution:
func _process(time):
    # The system decides when notes play, not the user
    if time > next_trigger:
        play_note()

# Eno's Contribution:
var delay_feedback = 0.7 # The system listens to itself
[/code][/color]

[hr]

[b]The Algorithm as Performer[/b]

When you run `DiscreetMusicTest.tscn`, you are not listening to a recording. You are listening to a [b]Theorem[/b] being proven in real-time.
*   Satie provided the Room.
*   Cage provided the Dice.
*   The Code provides the Time.

[hr]

[color=cyan][b]→ Next: The Visualizer[/b][/color]
How do we represent this \"ego-less\" music? Not with expressive waves, but with the cold, objective geometry of the Machine.
"""

