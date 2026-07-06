# Ada and its ancestors

*(front matter — the book stating where it comes from)*

This book has two parents it is glad to name and a third strand neither of them
carried.

The first parent is **Daniel Shiffman's *Learning Processing***. Its opening
chapter is called "Pixels," and it begins exactly where this book begins: a
coordinate system, a point, and the small vocabulary of primitives — line,
rectangle, ellipse — drawn onto a screen understood as a grid of addressable
cells. Its method is a discipline we have tried to keep: one concept per step,
the smallest example that runs, nothing shown that cannot be executed, and a
relentless upward climb from the single mark to arrays, objects, and motion.
Point_One — one cube, one frame, one decision — is our "Pixels," and it owes the
restraint to Shiffman.

The second parent is the same author's ***The Nature of Code***, which taught a
generation that a simulation should be built from its first principle outward — a
vector before a force, a force before a flock — so that the learner earns the
complex thing by assembling it rather than importing it. Our spine is that
argument: primitives before transformation, change before forces, forces before
soft bodies. Each chapter builds on the vocabulary of the ones before it, and
nothing arrives unearned.

The third strand is ours, and it is the reason the book exists. Shiffman is,
deliberately and generously, *a-critical* — a warm technical on-ramp that does not
stop to ask who drew the coordinate system or what the grid forecloses. This book
stops to ask. Every tutorial beat here is woven with a **critical trajectory**:
the point is a decision made inside someone else's clock; measure is pleasure and
also violence; the grid is Foucault's diagram in Vector3; the soft body is matter
that can be affected. We call this pairing, after the figure who haunts the whole
curriculum, *thinking with Turing* — the tutorial and the critique running
together on one page, neither flattening the other.

And all of it is re-staged. Processing draws on a flat screen you face from
outside; this book is walked from inside, in three dimensions, with a body. That
single move — from *viewed* to *inhabited* — changes what the first chapter can
teach, and names the five shifts that make 3D algorithm thinking its own thing:

1. **The coordinate frame is inhabited, not viewed.** You do not plot a point onto
   a plane you face; you place yourself relative to a frame you stand inside.
2. **The atom inverts — pixel to Vector3 — so discrete and continuous swap order.**
   Processing's pixel is already quantized; our point is continuous, and the grid
   is imposed on it later, as an argument (Point_One → Point_Line_Grid), not a
   given.
3. **The render loop is presence, not animation.** The world was running before you
   arrived; the loop is the fact of a live world, not a redraw of a still one.
4. **Input is the body, not the mouse.** The hand, the head, the trace — the learner
   is *in* the data structure, and the structure records them.
5. **Reading is a walk, not a glance.** Depth, occlusion, and viewpoint mean a scene
   is understood by moving through it — comprehension is locomotive and takes time.

What we keep from the ancestors: the minimal, runnable, one-step-at-a-time
progression, and the build-it-from-the-primitive-outward spine. What we resist,
which 3D always tempts: spectacle, and the all-at-once scene. What we add: the
body, the depth, and the critique.

*Learning Processing* teaches you to draw. *The Nature of Code* teaches you to
simulate. This book asks what it means to have drawn, to have simulated, to have
stood inside the thing and made the first mark in a world that was already
running — and it asks you to build anyway.
