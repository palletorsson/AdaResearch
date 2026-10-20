# A pattern is also work

Endless Museum · Tiling · editorial proposal · 9 October 2026

**The sequence has a clear technical progression. Its cultural and material progression is less present.** We move from a value to a source, from a source to a reading rule, from that rule to an architectural surface and eventually a garment. But several rooms still read as another console demonstration. *Mamma Mönster* supplies a stronger question: who makes the pattern, with which materials, and what do they hope it will change?

This editorial proposal is based on the nine tutorials and reflections, the existing artifact implementations, and Palle Torsson's supplied July 2022 essay. It preserves the hall order, lesson code and agreed subjects. **Update after your request to build a real loom:** the weaving part is now implemented as thread geometry in Symmetry Seventeen; the knitting comparison remains proposed. [Working loom and native images](../2026-10-09-thread-loom/index.html).

## Compress the explanation, make room for the material

Before the loom addition, the nine reflections contained approximately 6,261 whitespace-separated words. Several explain buttons, undo behavior and implementation details already covered by the tutorials. That gives us somewhere useful to cut. A working editorial target is around 4,000–4,300 words, including the textile connection; it is not a quota for each room. This compression is proposed, not yet applied across the sequence.

Keep the complete runnable examples, declared dependencies and meaningful tests in tutorial.md. In final.md, keep enough action to locate the encounter, then let the consequence carry the passage. Detailed control tours can remain in the tutorial or a return-visit reading. Foundry and Temple are already comparatively concise.

| Hall | Reading job | Compression or addition |
| --- | --- | --- |
| Pattern Disco | Recognise the same arrangement through another palette. | A short return from Colour. Move the extended sequencer tour out of the main reflection. |
| Pattern Foundry | Make one source and see its reach. | Keep the small source lesson. Add a brief distinction between the digital loom's image and cloth made from thread. Introduce the maker's desire here. |
| Tutorial Pattern | Change how the mark is read; distinguish this from changing the mark. | Keep the revealing comparison. Shorten the second explanation of shared-source edits and the catalogue of controls. |
| Array Patterns | Give the repeat physical dimensions and a direction in space. | Keep the walk through the tunnel. Use the tennis-court story as a short material counterpoint: scaling required different tools, not just another number. |
| Symmetry Seventeen | Compose a glide; recognise what classification describes and omits. | Assume reflection is understood. Keep one visible glide and the limits of the classification. Let a thread comparison be a wider encounter, not another mandatory coding course. |
| Pattern Temple | Compose a place; copy recipes that can subsequently diverge. | Preserve its concise, distinct job. Connect apparent unity to the decisions and labour that produce it. |
| Ribbon 01 | Try height as another address input. | Keep this as a short optional volume branch. It does not need to become a compulsory step towards fabric. |
| Ribbon 02 | Notice how carrier, light and surroundings alter an appearance. | A brief observation pause. Keep one strong comparison in the main reflection; retain the others for investigation. |
| Ribbon 03 | Sample a surface, save a recipe, wear it. | Shorten the control catalogue. End with the body and the wish that clothing might change how people live and meet each other. |

The resulting rhythm is: **recognise → author → read differently → place → compose → wear**, with a volume branch and a perceptual pause. These are reading movements across the existing rooms, not a proposal to silently reorder their dependencies.

## Three different meanings of pattern

| Making process | What the operation does | What the student should distinguish |
| --- | --- | --- |
| Printing onto cloth | Places colour on an existing textile. | The motif and the construction of its support can be changed separately. |
| Weaving | Interlaces warp and weft threads. | An over/under relationship belongs to the fabric's construction, not merely its drawn appearance. |
| Knitting | Forms fabric through interlocking loops of yarn. | The path and connections of the yarn matter. A knitting stitch is not another name for a woven crossing. |

The V&A's accounts of [weave analysis](https://www.vam.ac.uk/blog/projects/project-interwoven-studying-textiles-from-the-outside-in) and [knitting](https://www.vam.ac.uk/blog/museum-life/how-things-are-made-knitting) support these structural distinctions. A textile can combine several processes; these are operations to distinguish, not exclusive categories of objects.

This fits the project's type-safe approach. A colour index, an over/under instruction and a loop connection can all be recorded as data, but they have different meanings and need different interpreters. Shared grids do not make their materials interchangeable. Handwork also involves judging tension, handling yarn and correcting a developing piece; those capacities should not disappear into the claim that knitting is coding.

## One focused addition: follow the thread

The following was the proposal. Its weaving component is now built: twelve warp threads, one continuous weft, a four-by-four draft and a hand-held shuttle. The committed cloth retains its earlier draft. Thread highlighting and the knitting comparison remain possible extensions. The [loom report](../2026-10-09-thread-loom/index.html) records the implemented behavior and tests.

Use a small comparison beside the existing loom in Symmetry, foreshadowed by the brief Foundry passage. This should earn its space through an action the current controls cannot provide.

1. Start with a four-by-four plain-weave study. Keep both thread systems visible. Select one thread and highlight its continuous path; advance one weft pass at a time.
2. Show its crossing chart beside it. A cell means **warp over / warp under**, not a palette colour. Change a crossing and inspect the reconstructed path. Repeating a valid chart, changing thread colour and moving the whole cloth are separate operations.
3. Place a small hand-knitting study beside it. Show a new loop being drawn through an existing loop, then trace the yarn through neighbouring stitches. Replay or undo a construction step so the order of making stays visible.
4. Compare these with the existing printed motif. Ask: did the change alter colour, the path of a thread, or which parts hold through one another?

First build an explicit geometry model whose thread paths and crossings can be inspected. Stretching, tension, friction and unraveling would require further mechanics and validation. A scripted reversal of construction must not be presented as a physical tear simulation.

This recalls Point Trace without inventing a historical dependency: a remembered path now needs a thickness and relationships to other paths. Arrays and loops can describe a simple weave draft. Full knitting topology and cloth mechanics can remain future work. One small woven example can carry the coding lesson; the knitting comparison can remain an encounter.

### What the current code actually provides

- `pattern_loom` renders a wallpaper image, applies it to a surface, and animates its texture offset. It also draws luminous thread-like elements and a pulsing bar. The carpet is not constructed by those threads crossing each other.
- Foundry's `pattern_machine_a` supplies an editable source, repeated images and a short history of carpet bands. This already teaches production and stored decisions, but it is not a material weave model.
- `cloth_loom` elsewhere in the project uses a particle-and-spring cloth mesh. It offers a later connection to forces and deformation, but it does not teach actual yarn interlacement or knitted loops.
- The fabric studio samples a pattern onto a wall and garment. Its shader deformation is not cloth simulation.

These implementations give us useful starting points. Their names alone do not establish textile mechanics.

## Let Mamma Mönster give the sequence its stakes

**Foundry: the maker.** Your account of Kristina Torsson begins with the hope that different clothes could change people. That gives the source tile a purpose beyond efficient repetition. An imperfect contour can be an authored choice to retain. Do not automatically replace the hand with random jitter in the name of handmade appearance.

**Array Patterns: the tennis court.** Keep the specificity of your account: Mimmi's drawings, experiments with stencils, the metal templates, the move from heavy canvas to a lighter windbreak, and unavailable colours. The motif survived through negotiation with tools, labour and support. The black-and-white court belongs to the state described in your 2022 essay, not a claim about the court today.

**Temple: the work behind the whole.** The existing text asks what gives a patterned room authority. Your account lets it also ask whose work the unified appearance makes visible or hides. This is stronger than adding another generic historical name.

**The final garment: the hope returns.** The last room can return to the mother's wish and the child's patterned room. Clothing has already had social consequences in your account. The chapter can reach that ground without making the childhood violence a decorative example, or inventing a first-person recollection for you.

Lovelace and Jacquard can enter through a short, sourced note attached to the loom. The punched cards specify a repeatable weaving pattern; the mechanism still has to select threads and carry out the work. The [Science and Industry Museum's account](https://blog.scienceandindustrymuseum.org.uk/jacquard-loom/) documents the connection with Babbage and Lovelace. Use that particular connection rather than trying to fit the whole industrial revolution, Turing, entropy and computation into this sequence. Those questions have other places in the spine.

## A possible short reflective insertion

*Draft for Foundry; describes its existing image-making loom. The new thread loom stands later, in Symmetry Seventeen.*

> The loom sends another length of pattern across the floor. Its threads shine, but the carpet below them is an image. A woven cloth asks something else of the rule: which thread passes over, which passes under? In knitting, one loop is drawn through another. Here the pattern can help make the surface that carries it. What have we kept when we keep the appearance and leave out the work?

*A possible closing question at the garment, to sit beside your own account rather than replace it:*

> The mark has reached a garment. We know how its copies are addressed. What did we hope that wearing it would make possible?

## Working decision

Compress repeated control tours first. Preserve the useful differences between source, reading rule, receiver and ownership. Add the textile connection at Foundry, one small physical thread comparison beside the loom, the tennis-court encounter at Array Patterns, and a return to clothing's social desire at the end. That strengthens the same progression instead of adding a second syllabus on top of it.

Sadie Plant's *Zeros + Ones* belongs alongside this material history. The new [textile note](../2026-10-09-thread-loom/textile-note.html) places it beside *Mamma Mönster* and distinguishes our interpretation from a documented quotation. Its useful question here is whose work becomes visible when a pattern is called a program.

The tutorial examples and order remain unchanged. The new loom has its own runtime and placement checks, recorded separately. The learner question remains: can the student explain why changing a colour and changing an interlacement are different actions?
