# Rhizomatic Networks: Topology Against Hierarchy

## The Problem of the Root

Traditional data structures—trees, graphs, hierarchies—encode a metaphysics of origin. Every node has a parent. Every branch returns to trunk. The tree is genealogy: descent, inheritance, the privilege of the root.

**Deleuze and Guattari** propose the rhizome as counter-figure: "unlike trees or their roots, the rhizome connects any point to any other point... It has neither beginning nor end, but always a middle from which it grows and which it overspills" (*A Thousand Plateaus*, 1987).

## Smooth and Striated Space

The rhizome operates in what Deleuze calls **smooth space**—continuous, intensive, navigable in any direction. The tree enforces **striated space**—discrete, extensive, channeled through predetermined paths.

In this demonstration, **marching cubes** provides a bridge: we begin with discrete voxels (striated) but extract continuous isosurfaces (smooth). The density field has no inherent hierarchy—every point relates to every adjacent point through gradient, not genealogy.

## Disorientation as Method

**Sara Ahmed** (*Queer Phenomenology*, 2006) asks: "What does it mean to be oriented?" Orientation presumes a ground, a horizon, a direction that feels natural. The heteronormative, the colonial, the arborescent—these are orientations so thoroughly naturalized they become invisible.

The rhizome disorients. Without root or destination, one must navigate by **relation** rather than **position**. The cave system generated here has no canonical entrance, no proper path. Like Ahmed's queer phenomenology, it asks: what happens when we refuse the orientations handed to us?

## The Möbius Strip: Non-Orientable Space

The **Möbius strip** is the geometric embodiment of Ahmed's disorientation. It is a *non-orientable surface*: there is no consistent way to define "up" or "inside." Walk a complete circuit and you return to your starting point—but *upside down*.

In mathematical terms, the Möbius strip has:
- **One side**: What appears as two surfaces is continuous
- **One edge**: The apparent boundary is a single loop
- **No inside/outside**: The distinction collapses

This is not merely a curiosity. It demonstrates that **orientation is not intrinsic** to space but imposed by our navigation of it. The surface doesn't change when you walk it—your relation to it does.

Walk the Möbius world here. After one loop, gravity has reversed. After two loops, you return to your original orientation. The surface is the same; you have changed.

## Tactical Topology

**Eyal Weizman** (*Hollow Land*, 2007) documents how the Israeli military developed "walking through walls"—tactical movement that ignores the architectural logic of doors, corridors, public/private boundaries. They called this "inverse geometry."

Underground networks—from resistance tunnels to infrastructure—operate similarly. They don't contest the surface; they become *another surface entirely*. The rhizome doesn't oppose the tree; it grows through and beneath it.

## The Impossibility of Implementation

Here is the paradox: **you cannot implement a true rhizome in discrete computation**.

Every data structure has an origin (memory allocation). Every algorithm has a starting point. The RhizomeGrowthPattern.gd file you see uses `parent` and `children` arrays—the language of trees wearing rhizomatic clothing.

But consider: the **density field** has no such structure. It is simply values at points. The connections emerge from the marching cubes algorithm, which finds surfaces where density crosses a threshold. The topology is **discovered**, not **prescribed**.

This is as close as computation gets to rhizomatic thinking: not implementing the rhizome (impossible) but creating conditions where rhizomatic structures can *emerge*.

## Questions for Exploration

- Where does this cave system begin? Can you find the "root"?
- How would you give directions to someone moving through the inside?
- What would it mean to *own* a rhizomatic space?
- How does the density threshold change what connections are possible?

## Technical Notes

The demonstration uses:
- **RhizomeGrowthPattern.gd**: Generates growth nodes with probabilistic branching and merging
- **RhizomeCaveGenerator.gd**: Converts node network to density field, then applies marching cubes
- **Marching cubes**: Extracts continuous isosurface from discrete voxel grid

The key insight: while the *generation* is hierarchical (nodes spawn children), the *result* is topologically continuous. The surface extracted by marching cubes doesn't know which node came first.

---

*"The tree imposes the verb 'to be,' but the fabric of the rhizome is the conjunction, 'and... and... and...'"*
— Deleuze & Guattari
