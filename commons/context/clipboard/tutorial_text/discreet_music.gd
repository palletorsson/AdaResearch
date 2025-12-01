extends Node

var text = """
[font_size=28][b]5. Discreet Music & The Logic of Sets[/b][/font_size]
[i]From Composition to Construction[/i]

[i][color=gray]Summary: Brian Eno’s \"Discreet Music\" (1975) marks a pivotal shift from music as subjective expression to music as objective system. By defining independent loops that phase against each other, Eno replaces the Composer with the Logician. This mirrors the shift in mathematics (Hilbert, Frege, Cantor) where geometry and arithmetic were redefined as formal systems of undefined terms and set relations.[/color][/i]

[hr]

[b]The Shift: From Melody to System[/b]

Traditional composition is a narrative: a composer dictates that [i]Note A[/i] is followed by [i]Note B[/i] because it \"feels right.\" It is linear, teleological, and centered on human will.

[b]Discreet Music[/b] is structural. The composer does not choose the moment-to-moment sequence. Instead, they define a [b]process[/b]:
1.  Loop A has length 34.
2.  Loop B has length 37.
3.  Run them together.

The music is the logical consequence of these two axioms interacting. It is not \"written\"; it is [b]derived[/b].

[color=green][b]Code[/b][/color]
[color=green][code]
# The logic of the piece is entirely contained in this definition:
var left_loop_duration = 34.0
var right_loop_duration = 37.0

# The music is simply the execution of this phasing:
func _process(time):
    play_melody_A(time % left_loop_duration)
    play_melody_B(time % right_loop_duration)
[/code][/color]

[hr]

[b]David Hilbert & The Formalist Turn[/b]

In 1899, David Hilbert recast geometry. He argued that points, lines, and planes are not \"real\" objects we experience, but [b]undefined terms[/b] defined solely by their logical relationships (axioms).

[i]\"One must be able to say at all times—instead of points, straight lines, and planes—tables, chairs, and beer mugs.\"[/i]

Eno does the same for music. The specific timbre of the synthesizer is secondary; the essence of the piece is the [b]formal structure[/b] of the loops. The code treats \"Note\" and \"Time\" as abstract variables. The beauty comes from the system's internal consistency, not its reference to the external world.

[hr]

[b]Frege, Cantor, and Set Theory[/b]

Gottlob Frege and Georg Cantor redefined mathematics as the manipulation of [b]Sets[/b].
*   A [b]Set[/b] is a collection of distinct objects.
*   Operations (Union, Intersection) define the results.

In [i]Discreet Music[/i]:
*   [b]Set A[/b] = { C5, D5, E4, G4 } distributed over time T1.
*   [b]Set B[/b] = { D4, E4, B3, G3 } distributed over time T2.

The piece is the [b]Intersection[/b] of these sets as they slide past each other.
[color=orange]Intersection(A, B, t)[/color]

We are no longer listening to a melody; we are auditing the enumeration of a Cantor Set. The music is the temporal unfolding of a static, perfect logical object.

[hr]

[b]The Visualizer: Rodchenko's Line[/b]

The visualizer reflects this Constructivist logic.
*   [b]The Rings[/b]: Represent the closed, cyclic nature of the Sets (the Loops).
*   [b]The Line (Play Head)[/b]: Represents the [b]Axis of Construction[/b].

Just as Alexander Rodchenko declared the Line to be the primary element of construction (not decoration), the Play Head is the only active agent. It slices through the static sets, rendering them into time.

The visualizer is not a \"picture\" of the music; it is a diagram of the machine that produces it.

[hr]

[color=cyan][b]→ Next: The Trace[/b][/color]
If this system represents the cold perfection of Logic, how do we re-introduce the body? The Trace is the glitch, the wobble, the refusal to be a perfect set.
"""

