---
title: "A Place for the Hand"
subtitle: "The plan for Ada's interfaces: controls within reach, text on surfaces, and shared references tested in the rooms that use them."
date: "2026-09-20"
author: "Palle + Codex"
tags: ["interfaces", "VR", "embodied-learning", "artistic-research", "museum", "work-in-progress"]
sequence: "spine"
---

A button has no backplate. Another belongs to a row whose far end is difficult to reach. A screen explains an object while standing between the visitor and that object.

These observations give the next round of work its starting point. Before asking what an interface looks like, stand where someone is supposed to use it. Where does the hand go? Where do the eyes go? Can the person see what their action changed?

Ada Research asks a visitor to discover something through an encounter: try, observe, compare, then follow the explanation into code. A poorly placed control interrupts that sequence. The visitor may be investigating the limits of a cellular automaton, but first they have to work out whether the button is dead, beyond reach, or waiting for an unfamiliar gesture. That uncertainty can swallow the question the room was built to ask.

![A broad sampler of buttons, sliders, grouped controls and displays mounted across a pale board in Godot.](/blog-images/2026-09-20-a-place-for-the-hand/default-demo.png)

*The existing InteractableDemo, captured in Godot. This is a catalogue view of the whole assembly, not a view from a player's operating position. Some entries are working controls, others passive displays or visual prototypes. The picture does not establish that every item works.*

We began by looking for the interfaces already in the project. The expanded source census reached buttons and sliders, audio racks, screens, embedded scene scripts and controls assembled from configuration. It read 22,285 source and configuration files, including dependencies and test material. That number describes the search, not the number of interfaces or the number of successful encounters.

The distinction matters. Two specialised rack sliders draw stepped and bipolar scales, but a direct test of their local pointer handlers left their values unchanged. Their ordinary horizontal and vertical relatives responded. The specialised controls still need an input-path repair or a verified connection to another handler. Changing their casing would leave that problem intact.

The earlier post, [The Instrument Was Blind First](/blog/2026-09-19-the-instrument-was-blind-first), asked what a review tool had actually managed to see. Here the same question returns: finding a button in the source is only the beginning of finding out what it lets someone do.

Three requirements now guide the work.

**Give controls a place to belong.** A standalone button needs its own mounting. A button in a panel can share the panel's backing. A control embedded in a sculpture can belong to the sculpture's body. We need to check the assembled result: two components can each assume that the other supplies the plate. A node called “BackPanel” does not tell us whether the button is visibly seated on it.

**Bring related actions together.** The shared ControlPanel currently lays its items in one horizontal row, with a default spacing of 0.30 metres. Eight ordinary button slots put the first and last centres 2.10 metres apart at normal scale. We will compare that arrangement with four buttons over four, retaining usable control sizes and room for labels and hands. Compactness means reducing unnecessary travel. Long sliders, moving levers and consequential actions still need their own clearance.

**Make all text 2D in 3D.** Labels, numbers, instructions, signs and code should sit on surfaces in the world: printing on a plate, a page, a screen, an object's material. This includes small values carried by individual controls. Static captions can use baked textures; changing readouts can use 2D interface content rendered onto a screen. The surface needs an orientation, a readable scale and a relation to what it names.

![An upright grey console with a tilted pale panel, slider, dial, stick, push button and a dark readout showing ready.](/blog-images/2026-09-20-a-place-for-the-hand/console-flat-text.png)

*An initial change, already running: shared console titles and panel-generated labels now use flat textured text. Runtime inspection found no extruded text meshes in this assembly, but the slider and dial still contain older Label3D value labels awaiting migration. This capture verifies rendering; headset readability and comfort remain untested.*

The shared text change is implemented. The compact row layouts, mounting review and migration of older labels remain ahead of us.

There is enough variety in Ada to learn from its own instruments. The pattern control plate offers grouped controls. The whiteboard connects a held tool to a surface. A spring handle makes displacement and release distinct actions. The fabric studio separates previewing, saving and applying. Each supplies something a useful reference should preserve.

We can connect these examples through three layers. **InteractableDemo** becomes a working vocabulary, with prototypes clearly identified and each operational control attached to something it changes. The **[principal setups gallery](/interface-presets-gallery)** supplies arrangements: a compact parameter panel, a comparison station, a pen beside a drawing surface. The **museum halls** show what happens when those arrangements acquire a scale, a location and a particular body trying to use them.

The reference must connect an action to an observable consequence. A lamp can reveal a button press. An object travelling along a rail can reveal a slider value. A retained trace can reveal what a pen sampled. A handsome cabinet alone cannot do this work.

For each placement, the review will ask:

- Can the player identify and reach the control from the intended position?
- Does its mounting make the action and direction clear?
- Can the text be read, including its units and current value?
- Does the input produce the stated change, and can the player see it happen?
- Can a mistaken action be recovered from, where recovery belongs to the encounter?
- Do screens and controls leave the relevant object visible?
- What does the interface cost while idle and while being used?

A master reference helps us ask those questions consistently. Differences need reasons. Drawing, pulling a spring and stepping into a force field involve different bodily knowledge; their interfaces should retain that difference. A useful comparison asks whether a variation serves the encounter and remains understandable.

Images can support that review by exposing misplaced labels, obscured receivers and inconsistent mounting. Geometry can measure the spread of a group. Actual input tests establish whether an action reaches its receiver. Headset sessions establish how these arrangements feel to use. A visual score from an automated reviewer must keep those kinds of evidence separate.

The first implementation pass is deliberately small: one button family shown standalone, on a shared panel and embedded in an object; then a compact arrangement and a dense arrangement. We will carry those into three real uses, including the pattern plate's randomise control and a time/comparison instrument. Before-and-after captures will use the same operating position, followed by the same actions. Once those work, the inventory can lead us to the next consumers of the shared components. Sliders and screens follow, including the input gaps already found.

Progress will mean knowing which configured uses have been checked and which remain unresolved. Fixing a shared factory can improve many artifacts at once. Their placement still needs attention in each room.

An interface establishes a small bodily order: where to stand, what to touch, what range of change is available. Ada can make that order available for investigation too. When a visitor finally reaches the control, the question should open further. What does this range permit? What has been kept outside it? What would happen if we changed the rule that set the limit?
