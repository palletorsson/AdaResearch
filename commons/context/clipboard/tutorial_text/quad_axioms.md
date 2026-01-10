**The Quad**
Four Points, Two Triangles

The quad appears as a single surface, but it is never whole.
Four positions suggest one face, yet the GPU always sees two triangles.

The quad is the first geometry where representation and execution diverge.

---

## Four Positions, Apparent Unity

A quad is defined by four positions arranged in sequence.

**Code: Defining a Quad**

```
var v0 = Vector3(-0.5, -0.5, 0)
var v1 = Vector3( 0.5, -0.5, 0)
var v2 = Vector3( 0.5, 0.5, 0)
var v3 = Vector3(-0.5, 0.5, 0)
```

Four corners. Four edges.
One surface — apparently.

Unlike the triangle, planarity is not guaranteed.
The quad only appears unified.

---

## The Hidden Diagonal

The GPU does not render quads.
It renders triangles.

Every quad must be decomposed.

**Code: Triangulation**

```
Triangle 1

st.add_vertex(v0)
st.add_vertex(v1)
st.add_vertex(v2)

Triangle 2

st.add_vertex(v0)
st.add_vertex(v2)
st.add_vertex(v3)
```

A diagonal is introduced.
It is never drawn, but it is always present.

This is the quad’s secret:
what appears continuous is already cut.

---

## Choice and Consequence

There are two possible diagonals.

**Code: Alternative Split**

```
Alternative diagonal
Triangle 1: v0, v1, v3
Triangle 2: v1, v2, v3
```

For a perfectly planar quad, both choices appear identical.
For a slightly twisted quad, the choice becomes visible.

A crease appears.
A shadow breaks.
A deformation reveals the cut.

The quad introduces decision into geometry.

---

## The First Geometry That Can Fail

Three positions always define a plane.
Four positions do not.

**Code: Breaking Planarity**

```
v3 = Vector3(-0.5, 0.5, 0.2)
```

The quad twists.
The surface can no longer be flat.

The triangle was rigid.
The quad is unstable.

This is the first geometry that can betray its own form.

---

## Why Humans Prefer Quads

Despite this instability, quads dominate modeling workflows.

They allow:
• clean subdivision
• continuous edge loops
• predictable deformation
• rectangular reasoning

Quads are easier to think with.

But this convenience exists above the rendering layer.
It is not what the machine executes.

---

## Tiled Space

Quads naturally tile space into regular grids.

**Code: Quad Grid**

```
var grid_size = 10
var quad_width = 1.0
```

Terrains, UV maps, and interfaces rely on this regularity.

But every tile is still two triangles.
Every surface is already fragmented.

---

## What the Quad Reveals

The quad exposes a gap:

• between how humans model
• and how machines render

It is the first abstraction in 3D graphics that hides its own implementation.

The triangle was honest.
The quad is diplomatic.

---

## The Quad and the Line of Flight

The triangle closed space.
The quad relaxed that closure.

With the quad, geometry begins to negotiate between:
• stability and flexibility
• clarity and convenience
• representation and execution

This tension will only grow.

---

**Summary:**
The Quad is four positions presented as one surface, but always executed as two triangles. It is the first geometry where planarity can fail and the first where representation diverges from rendering reality. Quads are a modeling abstraction, not a computational primitive.