# Artifact space: footprint, access and bounded margin

Design conversation with Palle, 2026-10-23. A staging proposal, not an automatic
layout implementation. Review one existing artifact at a time before building.

## Direction from Palle

Treat each artifact as an item in a spatial box model. Give it enough space for
its purpose, without excessive unused space around it. An artifact has a direction:
the approach and interaction area in front usually needs more room. A continuous
walkable route around it is the default. Selected empty space can emphasize an
artifact along the visitor's path; accidental leftover space needs attention.

- Content: the artifact's occupied space.
- Padding: space needed to get close and perform the interaction.
- Border: the walkable circulation around the artifact.
- Margin: space outside that circulation, bounded by the surrounding construction.
- Front: a directional approach / viewing / working area, kept clear as required.

Use walls, boxes and existing prefabs to shape the outer boundary. Preserve the
path connecting encounters. Enclosure must support the artifact's intention.

## Working interpretation to test

Start by reading the artifact script header and identity/intent notes, then the
map's final.md and related texts. Compare this stated intention with the actual
geometry and behaviour. Treat textual intention as evidence for the discussion,
not permission to assume that the current scene already fulfils it.

Plan the footprint from above, then verify its height and changes over time.
The content includes the space swept by moving parts and relevant loose bodies.
Separate solid body from reach, beam, viewing distance and interaction area.
Front clearance and padding may be asymmetric and may overlap the circulation
where interaction and passing can coexist. Shared walkways are shared space,
not two separate margins that must be added together.

A first review asks:

1. What does the visitor see, do and discover here?
2. What space does the actual configured artifact occupy while working?
3. Where does the visitor stand, reach, watch and move around it?
4. Where do the arrival and departure paths connect?
5. What bounds the remaining space, and what job does each open area perform?

Use three provisional assessments: too tight (activity or passage fails),
appropriate (activity and passage work with a readable approach), or too loose
(unclaimed space weakens the encounter or permits unintended bypass).
No universal clearance dimensions or numeric packing score are agreed yet.

Do not fill leftover cells mechanically with random objects. First ask whether
they should be circulation, a purposeful pause/view, space for another encounter,
or construction defining this encounter. Any added prefab should support the
scene and the sequence's available vocabulary.

## Next design question — not settled

Should the default arrangement be an open-front bay, bounded at the sides and
back outside the walk-around route, with intentional entrance and exit openings?
Recommendation: yes as a starting pattern; open islands, walk-through artifacts,
shaft encounters and large moving works may require different arrangements.

## Existing project precedents inspected

- doc/spatial/CURRENT_STATE.md: body footprint and reach are distinct; grouping,
  support, gaps and the authored route already have separate meanings.
- doc/spatial/spikes/09_the_footprint_changes_the_blueprint.md: the host layout
  should respond to measured artifacts; stale size mirrors can mislead.
- doc/space/transformation-staging-2026-09-09/README.md: historical uniform
  padding exists, but is not adopted here as the new default.

No map, source mechanism, chapter or final.md has been changed in this step.

## Care, use and belonging — Palle's addition, 2026-10-23

The artifact should feel deliberately placed by somebody who uses it and puts
things back in order. Its setting should suggest care and continuing use.
It belongs to the skyscraper environment rather than floating as an isolated
museum exhibit.

Use the existing prefab vocabulary to express this:

- Give the artifact and its interface an understandable support or attachment:
  a pillar, bench, wall bracket, ceiling suspension or maintenance structure.
- Give portable pieces a deliberate resting or storage position. Leave the
  working area clear; arrangement should suggest use followed by putting away.
- Form a semi-private working area with selected scaffold sections, timber
  barriers, wood or cardboard boxes, and other suitable existing prefabs.
- Let the enclosure frame the artifact and give it attention. Preserve the
  interaction space, clear front, walk-around passage and route connections.
- Electrical or maintenance attachments can help the object belong to the
  building where they make sense for that particular artifact.

Working review question: "What suggests that somebody works here, cares for
this object and knows where its parts belong?"

These are choices to make per encounter, not a requirement to add every kind of
support, cable, barrier or box to every artifact. No individual staging or new
prefab build has been selected yet.

## Additional rules accepted — 2026-10-23

- Read it from the approach: identify the main object, working position and a
  possible action before arriving.
- Keep cause and effect visible from the operating position.
- Stage every state, including moving parts, opening panels and loose bodies.
- Give the body a place: reach, viewing height, turning and stepping back matter
  in desktop and VR.
- Make failure readable and allow another attempt where that serves the encounter.
- Give each encounter a main focus; its surroundings support that attention.
- Make construction believable through support, attachment and material detail.
- Connect encounters through what the visitor has just discovered or can reuse.
- Keep reused parts recognisable when their roles change.
- Retain the arrangement as an editable recipe of separate parts and clearances.

## A repertoire, not a waterfall — Palle's qualification

These rules can be mixed, revisited and relaxed in response to the artifact.
They are not a mandatory sequence of production stages or a demand for one
predictable result. Leave room for unintended play, accidental combinations and
unexpected discoveries. An unexpected outcome may suggest a better encounter.
Distinguish that opening from an obstructed interaction or accidental dead end.

Use the rules to notice and discuss, not to force every exhibit into the same
bay or remove every ambiguity. Start applying the method to Wavefunctions,
with one existing encounter at a time. No replacement of source behaviours or
chapter rewriting is implied by this staging pass.

## Stronger rooms and principal outputs — Palle's direction, 2026-10-23

Following the CA review, revisit the sequence as a whole rather than accepting
each imported map as an adequately staged floor. Sparse maps can be rebuilt,
combined with related maps, given larger principal artifacts, or extended with
new artifacts. The aim is strong visual and logical output. More colour and
extravagance are welcome.

Use that permission with the earlier rules:

- Give the floor clear principal encounters and make their consequences worth
  crossing the room to see. Scale the relevant output, not every control equally.
- Where a small instrument drives a larger architectural receiver, keep their
  relationship real and visible. A second decorative simulation is not evidence
  that the player's action changed the room.
- Let colour, repetition, light and movement amplify the algorithm's behaviour.
  Preserve distinctions the visitor needs to interpret its state.
- If a map remains too thin, consider a meaningful combination or a new
  encounter before surrounding it with unrelated filler.
- Judge the operating position, circulation and unfolding states in the actual
  skyscraper. A successful footprint audit or a static export is not sufficient.

First implemented experiment: CA floor109's large receiver of the original
32 × 24 rule-explorer history. See
doc/book/iterations/2026-10-23-ca-curation/REVIEW.md. This is a desktop/synthetic-XR
checked experiment, not a physical-headset entry in the successful-strategies ledger.
