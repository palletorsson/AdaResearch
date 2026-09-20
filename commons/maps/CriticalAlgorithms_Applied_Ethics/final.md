# Before the first person speaks

Who does this room make easiest to address?

<!-- @room_shape_demonstrator -->

Walk around the two miniature rooms. In the long-table plan, locate the head chair and compare its size with the other chairs. In the circular plan, choose one seat and imagine speaking from it. Trace the distances to the other positions rather than simply choosing the greener model.

The long table gives one position a conspicuous role. Its six smaller accompanying chairs carry less visual weight. The other model places six equal chairs around a round table. The comparison changes more than an outline on the floor: it changes relative size, position and the implied relation between participants.

The source makes the operation inspectable:

```gdscript
for i in 6:
    var a: float = TAU * float(i) / 6.0
    var chair := _make_chair(chair_color_distributed)
    chair.scale = Vector3(s, s, s)
    chair.position = origin + Vector3(cos(a) * 0.4 * s, floor_y + 0.1 * s, sin(a) * 0.4 * s)
    _add_part(chair)
```

Six iterations divide a full turn, TAU, into equal angles. cos and sin place each chair on a ring around origin. The little circle carries the arrays, transformations and waves we have already learned. Equal spacing is what this loop guarantees. Equal opportunity to speak would require another kind of evidence.

These are affordances and invitations. A head position can make it easy to identify a speaker; a circle can support addressing several neighbours around a shared centre. Neither miniature contains actual speech, listening or an agreement about whose turn comes next. The geometry proposes conditions under which those activities might happen.

Notice how the exhibit colours its own argument. Red singles out authority; green recommends the distributed arrangement. That visual judgement arrives before you have tested whether the plan meets a particular group’s needs. Looking critically at a model includes looking at the persuasion built into its presentation.

Find one use for the head position that you would preserve, then one difficulty the circle would not automatically solve. A designated interpreter, a speaker who needs a clear sightline or someone who cannot easily turn towards every other participant can complicate the familiar good-circle story. These possibilities call for observation with people, not a verdict from chair shapes alone.

A future version could compare actual sightlines and turn-taking across the two plans. The ethical question would become a design question with observable consequences: which participant gained access, which difficulty remained, and what change should follow?

<!-- @ -->

The next room lets two requirements meet without immediately deleting one. Participation can be shared while the resulting claims still conflict.
