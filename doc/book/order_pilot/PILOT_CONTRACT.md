# The Order-Pilot Contract

> Palle: "the writing can produce the order of the artifacts... introducing one
> concept at a time, building and criting... the order in the text is natural
> because it has good rules, discovered, and iterated. Then we have an order we
> can lean on."

You are a drafter in the order pilot. Your sequence is named in your task
prompt as `<seq>`. You write exactly TWO files and touch nothing else:

1. `doc/book/order_pilot/<seq>_lexicon.json`
2. `doc/book/order_pilot/<seq>_draft.md`

Sibling agents are writing other sequences concurrently — never touch their
files. Do not run Godot. Do not commit.

READ FIRST as the exact format model (a finished, clean pilot):
`doc/book/order_pilot/randomness_lexicon.json` and `randomness_draft.md`.

## Step 1 — the lexicon

From `doc/book/baselines/<seq>.json` (beats: role + cast + alts; voltage):

- One concept per beat: short lowercase id for the IDEA, `cast` = the beat's
  cast artifact. Plus 1–3 voltage pieces as extra concepts if they are
  distinct ideas. Total 9–13 concepts.
- `baseline_order` = the beat concepts in beat order (voltage excluded).
- `aliases`: 4–6 distinctive words/phrases per concept. They are matched as
  WHOLE WORDS ANYWHERE in the text, so: never reuse a word across two
  concepts, and never pick a word too common to withhold before its debut
  (if the chapter's central noun — cell, rule, noise, branch, force, wave —
  belongs to a concept, either that concept debuts first or you pick rarer
  aliases you can genuinely hold back).
- `aside`: the sequence's notable artifacts your concepts do NOT cover — the
  honest leftover (they attach around the ordered spine later).

## Step 2 — the draft

`# <Title> — the order the writing found`, then 16–24 sections. Each:

    ## <n>. <title>
    *register: walk*   OR   *register: code*   OR   *register: turn*
    <body: 60–140 words for walk/turn; a fenced source block for code>

THE GRAMMAR (mechanically checked):

- **R1** each section introduces at most ONE new concept (first alias-mention
  anywhere = its debut).
- **R2** debuts happen in walk sections, never turns, never code.
- **R3** every introducing section (after the first) also mentions ≥ 1
  earlier concept — the new arrives through the old.
- **R4** every concept is mentioned in a turn section within 4 sections
  after its debut.
- **R5** before each new debut, the previous debuted concept is mentioned at
  least once more.
- **R6** the chapter carries at least **3 code sections**, each quoting a
  concept's REAL cast `.gd`, each placed **after that concept's debut walk
  and before its critiquing turn** — the walk → code → turn hinge.

### The code register (walk → code → turn)

The code is not decoration; it is where the walk's innocence and the turn's
suspicion meet and get adjudicated by real source. For at least three of the
chapter's most load-bearing concepts, insert a code section between the
concept's debut walk and its critiquing turn:

    ## <n>. <title>
    *register: code*
    ```gdscript
    <6–14 lines of the concept's ACTUAL cast .gd — the core function>
    ```

Get the source honestly: `Glob **/<cast>.gd` (the cast is in the lexicon),
read the file, quote a faithful trimmed snippet of the load-bearing function
— never pseudocode, never invented. **Strip any `##` doc-comment lines** from
the snippet (they break section parsing; single-`#` comments are fine). The
code section itself introduces no concept and mentions no new alias; it is
tied to its concept by the `<cast>` token it contains. Then the turn may
point at a specific line — the strongest critique names the exact line where
an assumption is typed into being (or, as with `coin_toss.gd`, discovers the
code is *honester* than the label, and says so).

Alias discipline: never use ANY concept's alias words before its debut
(metaphor counts). Braid roughly walk · walk · code · turn. The final section
is a turn that looks back along the whole chain and introduces nothing.

VOICE — walks teach through the concrete artifact: present tense, what the
hand does and the eye sees; naming thinkers, theorems, and algorithms is
content and allowed; banned in walks are only the meta-words (QFEP,
ontology, epistemology, discourse). Turns critique concretely — what the
concept forecloses, assumes, flattens; no however/moreover/furthermore.
Banned everywhere: feel, felt, suddenly, delves, tapestry, symphony, realm,
pivotal, leverage, robust, landscape, paradigm, journey, dive.

YOU ARE FREE TO CHOOSE THE ORDER — that freedom is the experiment. When the
prose resists an order, REORDER and remember why. If a concept resists
becoming concrete at all, that is a finding — record it.

End the draft file with:

    <!-- order-declaration
    <concept ids, one per line, in your final introduction order>
    why: <3–6 specific sentences: at least one reordering you actually made
    because the prose resisted, and what the resistance was>
    -->

## Step 3 — the self-check loop

Run `python tools/order_grammar.py check doc/book/order_pilot/<seq>_draft.md`.
Fix violations and re-run until it prints **GRAMMAR CLEAN**. Edit lexicon
aliases ONLY to fix genuine matcher noise (an alias too common to withhold) —
never to cheat a rule.

Final message: the order-declaration block verbatim + confirmation that the
checker printed GRAMMAR CLEAN.
