---
title: "Learning to steer the glitch"
subtitle: "From uncertain surfaces to an image instrument inside Endless Museum"
date: "2026-10-09"
author: "Ada Research"
sequence: "shaders"
tags: ["endless-museum", "glitch", "noise", "shaders", "interaction", "research-process"]
thumbnail: "images/07-dials.png"
---

The room is still there. On one screen, the camera shows its floor, walls and patterned surfaces. Beside it, the same view has become a field of broken horizontal bands. A small change in how the image is read has made the familiar difficult to recognise. Between the two screens stands a pink camera you can pick up. In front of them, two dials let you choose the operation and change its strength.

This is where our recent work on glitch has arrived: an instrument inside Endless Museum, looking back into the world that contains it.

![The camera study inside the shader hall, with its source image, disrupted image and compact control panel.](images/01-in-the-hall.png)

*The current installation in Shader_05_Patterns. The reference stays visible beside the changed image. All seven images in this post are captures from Godot running the museum; the earlier captures show earlier controls.*

The work began with a broader question about computational uncertainty. What happens when we disturb a working system at a particular point? We wanted to locate the intervention closely enough to follow its consequences. Moving a vertex, disturbing a force and giving a navigator an inaccurate observation produce different kinds of uncertainty. Their units, histories and conditions matter.

Our first surface experiment made that distinction tangible. Two meshes keep the same connections between their vertices. One remains flat; the other receives saved random offsets. Increasing the strength enlarges those same offsets. Changing the seed produces another sample. The comparison lets us follow one variable while keeping something else still.

![A flat triangulated surface beside a displaced version, with measured differences displayed above them.](images/02-uncertain-surface.png)

*The Uncertain Surface: 289 vertices and 512 triangles in each mesh. Positions change; the index list remains. The edge overlay makes that continuity visible.*

There is already a question here for the reflective text. A form can look unsettled while retaining its connections exactly. Which part of the object did we expect to remain itself? A measurement can tell us how far the vertices moved. Recognition asks something further.

Related studies carried this method into a pendulum, a navigator and a thrown body. We compared a release with and without a recorded disturbance, accurate and imperfect observations, and the same throw advanced with different time steps. Together they gave the larger glitch proposal several precise places to begin. They also kept the proposal open: these studies do not complete every planned experiment.

The camera introduced another possibility. We could use the museum itself as material. Aim at a nearby pattern, keep a frame, and give that image a different surface to inhabit.

We built ten spatial variants. Scanlines separate into strips. The image gathers into folds or curls around an arc. Colour channels occupy separate planes. Brightness can push vertices forward. Each operation changes a named relationship between the captured image and the surface receiving it.

![The same museum image shown on a flat reference screen and on a curled surface.](images/03-curl-the-view.png)

*Curl the view. The receiver bends while its image coordinates remain attached. This capture records the first, wider console.*

At the end of this set, the rectangular image wraps around a torus. Earlier in the museum, a torus was a primitive to construct and examine. Here it becomes a surface for another view of the room. A familiar form returns with another job.

![A camera view of the museum wrapped around a torus beside its flat source image.](images/04-wrap-the-room.png)

*Wrap the room. The geometric surface closes, although the opposite edges of the photograph need not join seamlessly.*

That continuity matters to Ada. The point, mesh, array and coordinate system keep returning as working material. In this study, the student could follow where an image sample goes, where a vertex moves, or which frame a fragment belongs to. The larger exhibition can contain twenty variations while a tutorial chooses one operation to reconstruct carefully.

Then came a useful correction: we should also disrupt the actual pixels. Chopping an image into geometry left another territory unexplored. What happens if the screen stays flat and its reading rule changes?

The second set keeps the same two-triangle rectangle. It changes pixel addresses, channel values or the choice of frame. Bands shift sideways. Scanlines repeat. Red and blue lose registration. A region reads an earlier image while its neighbours continue updating. Odd rows can be read backwards.

One of the strongest examples is the wrong row width. Treat the image as a flat list, then use a different step between rows when reading it back. The source pixels remain available, but the rule that gathers them into a picture has changed.

![A recognisable source image beside the dense horizontal disruption produced by reading with a different row width.](images/05-wrong-row-width.png)

*The wrong row width. A shader deliberately models the address mismatch. The source image remains intact.*

Another operation exchanges blocks. At full strength, the image's forty-eight blocks each appear once in a different location. Pieces remain recognisable even as their neighbours change. This gives us a direct encounter with something an array lesson can otherwise leave abstract: keeping every item does not preserve the relationships between them.

![The museum camera image broken into an eight by six arrangement of exchanged blocks.](images/06-exchanged-blocks.png)

*Exchange the blocks. At maximum strength, all 48 blocks are rearranged once each. Intermediate strengths move their sampling offsets and can repeat or omit parts of the source.*

These are constructed glitches. The engine is carrying out the operations we gave it. We are using a readable model of disruption to investigate what an image depends on: ordering, registration, continuity, a shared moment. An actual damaged file or malfunctioning device would require other evidence. Here the visible disturbance has an inspectable cause.

The interface became part of the research. The earlier row of controls worked, but made every choice feel separate. Bringing the buttons together and adding dials gives the visitor a more continuous way to compare results. One dial chooses among ten operations in the selected set; the other varies strength. Nearby rectangular buttons switch between FORM and PIXELS, save a frame, hold the view, return the camera or reset the study.

![The new cream, charcoal and pink console with effect and strength dials and grouped rectangular buttons.](images/07-dials.png)

*The current 1.16-metre panel. Its dials and working buttons reuse the museum's interaction components. Pink indicates the selected PIXELS and HOLD states.*

The separation between the two dials is useful. Choosing a rule and varying its amount become distinct gestures. You can stay with one operation long enough to notice when a wall loses its continuity, when a repeated row becomes a texture, or when a picture begins to read as a sculpture. The instrument gives a place to that hesitation.

We also tested what the images alone cannot establish. The pixel checks compare sampled addresses and channel values, verify that zero strength restores the source sampling, and confirm that the saved source stays unchanged. Deliberately altered shader copies have to fail the checks: one removes the wrong-stride operation; another substitutes the live frame for the saved one. The latest installed-room run passed 82 checks covering the study and its controls. Those results come from automated Godot runs, including supplied controller poses. Headset use and an unfamiliar student's reconstruction still need their own assessment.

The useful discovery is a way of working. Keep the source available. Name where the intervention occurs. Let the result remain strange long enough to look at it, then follow the operation that produced it. The code gives the difference a precise location; the room gives us somewhere to encounter it.

There is a pleasure in turning the dial back toward recognition. There is another in stopping before the picture recovers. We have built an instrument that leaves room for both.

[Surface experiment and measurements](../../book/iterations/2026-10-09-geometry-noise-test/index.html) · [Ten spatial views](../../book/iterations/2026-10-09-camera-image-becomes-body/index.html) · [Ten pixel views and checks](../../book/iterations/2026-10-09-cut-the-image-pixels/index.html) · [Current controls and evidence](../../book/iterations/2026-10-09-glitch-dials/index.html)
