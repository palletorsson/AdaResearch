# Pattern Atlas — traditions worth reproducing for the commons

> Salvaged 2026-07-08 from an old Stable-Diffusion prompt set
> (`ML/stablediffusion/.../scripts/csv/prompts_*.txt`). Those files used
> art-history and textile vocabulary as style tokens for an image generator;
> the generation intent (sexual, excluded here) is discarded. What survives —
> and what is genuinely valuable — is the underlying **atlas of pattern and
> craft traditions**, a world map of makers. This file keeps only the pattern
> scholarship, cleaned, and marks what each could contribute to Ada: a symmetry
> artifact, a nature specimen, a form-finding case, and — for the collective
> craft traditions — a new maker to name in the [[commons_ledger]], which is
> currently thin outside the Mediterranean.
>
> Selection rule: a tradition earns a place only if it is a genuine *pattern
> system* (a rule that generates form), not a mood. Great pattern = a
> reproducible geometry with named or nameable makers.

## Tile & tessellation — the symmetry chapter's world beyond the Alhambra

The symmetry chapter currently credits the Alhambra (p6m) and the Pompeii
meander. These extend the seventeen-group census into other craft traditions
that closed it independently — each a candidate `mill_*` / `loom_*` artifact and
a new **collective** source for the ledger.

| Tradition | Region · makers | Pattern character | For Ada |
|---|---|---|---|
| **Iznik tilework** | Ottoman Turkey · workshop potters (16–17c) | fritware tiles, floral-geometric, near-p4m/p6m repeats, the famous "Armenian bole" red | new `mill_iznik_*`; ledger: **Iznik tile potters** (collective) |
| **Moroccan zellige** | Maghreb · *maalem* mosaic masters | hand-cut glazed tesserae, girih star-and-polygon, aperiodic-adjacent | folds into the al-Andalus source already credited; a distinct `mill_zellige` |
| **Iranian girih** | Persia · master builders | strapwork stars, decagonal quasi-symmetry (Penrose-adjacent, centuries early) | ties Persian source to the Penrose/aperiodic thread |

## Textile & weave — the loom, worldwide (the ledger's heart, globalized)

The commons ledger's largest debt was the loom, and it was paid to a generic
"weavers, largely women." These name specific traditions — each a real symmetry
program in thread, most of them collective, most non-European, most women's
labor. The strongest single expansion of the ledger available.

| Tradition | Region · makers | Pattern character | For Ada |
|---|---|---|---|
| **Kente** | Ashanti/Ewe, Ghana · strip-weavers | narrow strips woven then sewn edge-to-edge; each cloth a *named* proverb-pattern; block-and-stripe symmetry | `loom_kente_*`; ledger: **Kente strip-weavers** (collective) |
| **Ikat** | Indonesia, Central Asia, Japan, India · resist-dyers/weavers | pattern dyed into the *threads before weaving* — the blur is the signature; the plan precedes the cloth | `loom_ikat_*`; ledger: **Ikat resist-dyers** (collective) — a beautiful "seed encodes the pattern" rhyme |
| **Bingata** | Ryukyu/Okinawa · stencil-dyers | stencil-and-paste resist dyeing, bright tropical repeats | ledger: **Bingata dyers** (collective) |
| **Kanga** | East Africa (Swahili coast) · printers | printed cotton with a border + central motif + a *jina* (proverb) — text woven into pattern | ledger: **Kanga printers** (collective) |
| **Indigo (aizome / adire / shibori)** | Japan, Yoruba Nigeria, worldwide · dyers | resist-dye repeats; fold/bind/stitch determines the symmetry | ledger: **indigo resist-dyers** (collective) |
| **Tibetan tiger rugs** | Tibet · carpet-knotters | the tiger-pelt abstracted to stripe fields; asymmetry inside a grid | ledger: **Tibetan carpet-knotters** (collective) |
| **Anni Albers** | Bauhaus/Black Mountain · *named* weaver | tessellation and thread as a formal grammar; "On Weaving" | **named** source — ties the anonymous loom to the credited canon; a woman who wrote the theory the weavers embodied |
| **Sonia Delaunay** | Orphism · *named* | simultaneous colour, rhythmic geometric repeats across textile + paint | **named** source (color + symmetry chapters) |
| **Reiko Sudo / NUNO** | Tokyo · *named* + studio | engineered contemporary textiles, weave-as-material-computation | **named** source (softbodies/cloth) |

## Naturalist illustration — form from the living world (nature thread)

Ada already has Haeckel (radiolaria). One strong companion:

- **Maria Sibylla Merian** (1647–1717, naturalist & illustrator) — metamorphosis
  drawn from life: the *sequence* of a caterpillar → chrysalis → moth on its host
  plant, insect and plant as one system. A woman naturalist two centuries before
  it was allowed; the perfect **named** companion to Haeckel and to the L-system
  "growth as writing" thread. Candidate: a `merian_metamorphosis` specimen.

## Mathematical / op / constructed pattern — named artists (symmetry & color)

- **Victor Vasarely** — op-art, the deformed grid, figure emerging from pure
  periodic modulation. The named face of "pattern that moves." Candidate
  `vasarely_grid` (symmetry/color voltage).
- **Ruth Asawa** — looped-wire hanging sculptures, minimal surfaces and nested
  volumes made by a single continuous crochet of wire; a woman, Japanese-American,
  interned as a child. A near-perfect **form-finding** artifact (the hanging wire
  finds its own catenary volumes) *and* a named maker. Candidate `asawa_looped_form`.
- **Lyubov Popova / El Lissitzky** — Constructivist geometric composition, the
  grid as political form. Ties to the arrays/color composition thread.
- **Bridget Riley** (implied, adjacent to Vasarely) — perceptual pattern.

## The recommendation

Three moves, in order of value:

1. **Globalize the loom in the commons ledger.** Add the collective textile
   sources (Kente, Ikat, Bingata, Kanga, indigo, Tibetan) as new
   `commons_sources.json` entries. The ledger's weaving credit is currently one
   generic line; these name the actual traditions and, crucially, move the
   ledger's world beyond the Mediterranean. They enter as **candidate** sources
   (0 artifacts) until reproduced — new opportunity, honestly marked.

2. **Reproduce two or three as symmetry artifacts.** `loom_kente` (strip-weave
   block symmetry), `loom_ikat` (pattern-in-the-thread = the seed encodes the
   cloth — a gift to the symmetry/randomness rhyme), and a `mill_iznik` tile.
   Each is a real wallpaper-group program; each pays a new maker as it's built.

3. **Two named artifacts that fill genuine gaps:** `merian_metamorphosis`
   (a woman naturalist beside Haeckel) and `asawa_looped_form` (a woman sculptor
   whose wire finds its own minimal volumes — a form-finding voltage piece).

The old project reached for the whole world's ornament to feed a generator.
Turned around, the same reach is a map of the makers Ada's commons ledger should
grow to name — most of them women, most of them anonymous, most of them outside
the canon the book started from.

---

## Investigation II (2026-07-08) — the second sweep

Six more pattern systems, chosen by the same rule (a reproducible grammar with
nameable makers), plus one mathematical jewel that makes the Same Desire room's
claim a theorem rather than a metaphor.

| Tradition | Makers | The rule | Why it matters here |
|---|---|---|---|
| **Wang tiles** | Hao Wang (1961), Robert Berger (1966); the mathematical commons | square tiles with colored edges; adjacent edges must match | THE THEOREM OF THE SAME-DESIRE ROOM: whether a given tile set can tile the plane is UNDECIDABLE — Berger reduced the domino problem to the halting problem, and the first aperiodic tilings fell out of the proof. A craft-shaped question (do these tiles fit?) IS Godel/Turing territory, literally. |
| **Batik (Java)** | batik makers of Java — canting hands & cap stampers, largely women; UNESCO-listed | hot wax resists the dye; the CRACKLE is where the wax broke — the fault-lines are the signature | the wobble gene's ancestor: the crack is not an error, it is the proof a hand and hot wax were there. Kawung, parang, sekar jagad grammars. |
| **Kuba / Shoowa cloth** | Kuba kingdom weavers & embroiderers (DR Congo) — men weave the raffia, women embroider | angular interlace whose RULE CHANGES section by section — celebrated improvisational grammar (admired by Klee and Matisse) | pattern as jazz: the grammar mutates mid-cloth on purpose; the L-systems chapter's stochastic rule, centuries early |
| **Sashiko / hitomezashi** | northern-Japan farm households, mostly women — mending as pattern | one random bit per row and per column; a stitch appears where the bits agree — an XOR rule | the purest binary pattern in the atlas: emergent mazes from per-line coin flips; mending-as-mathematics |
| **Sámi band weaving (duodji)** | Sámi band weavers, Sápmi | pick-up band weave: diamond and zigzag chains on narrow warps | the atlas comes home north: the Nordic craft lineage nearest Vamlingbo's looms |
| **Adinkra** | adinkra carvers & stampers of Gyaman / Asante (Ghana) | calabash stamps in comb-divided fields; every symbol is a NAMED proverb | like kanga's jina: the pattern is a text; stamped repetition as rhetoric |

Considered and deferred: Aboriginal dot painting (sacred-knowledge protocols —
not ours to reproduce without collaboration), Navajo weaving (same care),
Marimekko + kurbits/Dala (the Swedish folk thread — belongs to a future
Mamma Monster II with Kristina's actual archive), Hannah Hoch (collage is
assemblage, not repeat — already honored by the map's FORM), Molas, tatreez,
Fair Isle (candidates for Investigation III).
