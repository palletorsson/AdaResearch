# One cut, three rooms

The first wall has a round opening. Through it, another wall has an opening too. A third waits further back. Lean sideways and their edges slide across each other. The rooms have acquired a view they did not have before.

The cone that cut them is gone. You can follow its narrowing reach through the shapes it left. Along the other side of the display, three pieces keep the part the walls have lost. What disappeared from one arrangement has become the subject of another.

Move the cut. All three openings move together. No wall moves, yet what the walls let you see changes. The small doorways beside them still offer the old route. A new line of sight has crossed the building's divisions without becoming the same thing as a walk through it.

This study begins with Gordon Matta-Clark's *Conical Intersect* (1975). The work cut through two Paris buildings marked for demolition. An opening exposed structures and changed what the street could see. These bare digital walls borrow that spatial question; they have never housed anyone. The ease of our reset leaves the original loss unresolved.

Who can make an opening in a wall that separates people? Who needs the wall to remain? A Boolean operation can calculate either result. It cannot give us permission.

## Making score

Use the supplied `conical_sightline/study.tscn`. This exercise assumes Day Zero's running project and the earlier point, coordinate, line, transform and Boolean lessons. The viewer, camera, light and collision setup are supplied apparatus.

Keep all three wall positions fixed. Shift the one shared cutter by 0.75 metres. In the component, `set_cut_x` carries that same offset to each copy of the cutter:

```gdscript
for cutter in cutters:
    cutter.position.x = cut_x
```

Watch through the opening from a fixed eye position, then change the viewpoint. The first action changes the construction. The second changes which edges overlap in the image.

The main display computes `A − B`; its witness display computes `A ∩ B`, using copies of the same wall construction and cutter. It retains the removed region as three geometric specimens. It does not simulate sawing, gravity, debris, structural support or demolition.

## Place in the lineage

**Looking:** a proposed return in Boolean Works, after the existing architectural cavity. The Kapoor egg asks how a surface conceals depth. This study asks how removing a boundary changes relations between spaces.

**Making:** coordinates → connecting points / sightline → transformation → Boolean difference and intersection. It uses capabilities already introduced; it adds no prerequisite node. Full building simulation is outside this exercise.

**Status:** a native Godot companion for review, not yet installed in the museum. Desktop buttons offer Approach, Inside, Offcuts, Before / cut, Shift cut and Reset. The camera viewpoints are observations, not a tested walking-body controller.

## Source

[Centre Pompidou, *Process*, from *Conical Intersect* (1975)](https://www.centrepompidou.fr/en/ressources/oeuvre/crgBqpa). The collection account identifies the two buildings, their impending demolition, the conical cutting and its urban critique. Ada's three-wall arrangement and retained offcuts are an original exercise, not a reconstruction or claim about the exact geometry of those buildings.
