# Edges of Algorithm

> *Where algorithms end — what bounds them, what they cannot see, what they make of the world by trying to compute it, what the world makes of them in return.*

This document maps the question that anchors the late spine of the curriculum: **what is the edge of an algorithm, and what is on the other side?**

Thirteen edges, in two layers. The first six (A–F) come from the formal tradition of computer science: where a closed-form description of computation says *no further*. The next seven (G–M) come from queer, feminist, post-Marxist, and critical-technology traditions: where the algorithm is encountered not as a description but as a force in the world, producing what it claims merely to read. The two layers are not in opposition; they are **transversal**. They are best taught together, paired.

The catalyst introduced in `qfeplaboratory` is the *fold catalyst* — the player carries it as a transformation that lets one principle become another. The edges are what that fold runs into when it tries to extend.

---

## A. Formal impossibility

> The algorithm ends because it provably cannot continue.

**Lineage.** Turing 1936 (halting); Gödel 1931 (incompleteness); Rice 1953 (semantic-property undecidability); Church-Turing thesis and its critics.

**Definition.** Some questions cannot be answered by any algorithm in any finite time. Not "we don't know how" — *no procedure exists*.

**QFEP.** Tracks **F**: the formal term itself runs out. The closed-form has a hole.

**Map sketch.** A small Turing machine running on a tape the player can read. The map's exit only opens when the machine halts. After thirty seconds the map's narrator says: *no algorithm can decide whether this stops*. The exit becomes a question, not an answer.

**Sequence home.** `foundationscrisis`.

---

## B. Tractability cliff

> The algorithm ends because the runtime explodes.

**Lineage.** Cook 1971; Karp 1972; the canonical NP-completeness corpus; no-free-lunch theorems.

**Definition.** Some computations are possible in principle but unaffordable in practice. The cost grows faster than the world has room for.

**QFEP.** Tracks **λ·E(S)**: entropy is computable, but the loss of computing it grows past the universe.

**Map sketch.** A 5-city travelling-salesperson solves in front of you. A 6-city. A 7-city. By 12, the search tree has filled the room. By 15 the room is searches all the way to the ceiling. The map ends when the player accepts that the solution is *there but not for them*.

**Sequence home.** `searchpathfinding`.

---

## C. Local-versus-global

> The algorithm settles on something that isn't the answer.

**Lineage.** Cauchy and gradient descent; simulated annealing (Kirkpatrick 1983); the no-free-lunch theorem (Wolpert & Macready 1997).

**Definition.** Local optimisation can converge on a minimum that is not the minimum. The starting position determines what looks "right."

**QFEP.** Tracks the *minimum* of **E(S)**: the system has multiple resting points; the algorithm picks one based on initial conditions.

**Map sketch.** A physical loss-landscape map with hills and bowls. You walk downhill. You stop, because you cannot go lower. The teleporter is on the next ridge. You can see it. Your algorithm cannot.

**Sequence home.** `machinelearning`.

---

## D. Representational silence

> The algorithm ends because it does not see what is there.

**Lineage.** Suchman 1987; the AI-fairness literature 2014–present; Bowker & Star *Sorting Things Out*; Iris Marion Young.

**Definition.** Algorithms operate on features, and features are choices. What is not encoded is invisible to the system, and what is invisible cannot be acted on except by accident.

**QFEP.** Tracks **φ·ΔE(S, t)**: the phenomenology term. The thing F missed.

**Map sketch.** A sorting room. The classifier sorts you into a box that does not apply. The player has a property the algorithm does not have a column for. The room will not let you out until you fit. You do not fit.

**Sequence home.** `criticalalgorithms` / `postfoundationscrisis`.

---

## E. Embodiment / continuous-discrete

> The algorithm ends because it is not built for the body running it.

**Lineage.** Maurice Merleau-Ponty; Iris Marion Young's *Throwing Like a Girl*; phenomenology of computing (Suchman, Dourish); current VR-gait literature.

**Definition.** The algorithm operates in discrete frames, classes, and binaries. Bodies are continuous, plural, and analogue. The mismatch is not a bug; it is the condition.

**QFEP.** Tracks the bracket between **F** and **E(S)** — the formal and the lived. The hyphen.

**Map sketch.** A dance map. The CA wants you on the grid. Your VR controller is continuous. The map progresses only when your motion is *quantised* — and it punishes you when it isn't. The map ends when you decide whether to dance for the algorithm or beside it.

**Sequence home.** `bodyprogression` / `joints`.

---

## F. Folding

> The algorithm ends because it becomes another algorithm.

**Lineage.** Hofstadter's strange loops; categorical and topological folding; Yuk Hui's *recursivity and contingency*; the existing `fold_system` in this project.

**Definition.** Principles do not stay separate. Cellular automata stabilise into fractals; fractals reveal search trees; search produces classifiers; classifiers fold back into rules. The fold is not a passage between disciplines — it is the relation that makes them disciplines.

**QFEP.** The whole formula read as fold: `QFE = F − λ·E(S) + φ·ΔE(S, t)` is one principle re-expressed as another, transformed by negation, restored by integration.

**Map sketch.** A Rule 30 floor that, over time, becomes a Sierpinski floor that becomes a BFS frontier. Same substrate, same instances, same player route. The map ends when the player names the fold.

**Sequence home.** `qfeplaboratory`.

---

## G. Opacity refusal

> The right not to be rendered.

**Lineage.** Édouard Glissant *Poetics of Relation* (right to opacity); Eve Sedgwick *Epistemology of the Closet*; Saidiya Hartman *Wayward Lives*; Simone Browne *Dark Matters*; trans-feminist data-refusal traditions; Hito Steyerl *In Defense of the Poor Image*.

**Definition.** Algorithms demand legibility — to be classified, predicted, scored. There are bodies, communities, and ways of life whose first move is to refuse that legibility, and whose flourishing depends on staying unrendered.

**QFEP / formal pair.** Active inverse of **D**. D was about what the algorithm *cannot see*; G is about *withholding* what the algorithm wants to see.

**Map sketch.** A recognition map. The classifier is hungry; everywhere you stand, it labels you. There is one cell where its sensors fail. The map is solved by *staying in the dark cell long enough to leave through it*.

**Sequence home.** `criticalalgorithms`, paired with D.

---

## H. Apparatus-as-phenomenon

> The algorithm does not measure; it makes.

**Lineage.** Karen Barad *Meeting the Universe Halfway*; Donna Haraway *Situated Knowledges*; Lucy Suchman *Human-Machine Reconfigurations*; Marilyn Strathern *Partial Connections*.

**Definition.** The algorithm and the thing it processes are not separate. The apparatus enacts a *cut* that produces both observer and observed. What the algorithm finds was made findable by the algorithm being there.

**QFEP / formal pair.** Deepens **F**. F said one principle becomes another; H says the *frame* doing the becoming is itself part of what becomes. The fold is constitutive.

**Map sketch.** A phenomenon-room. There is an "object" in the centre. Walk one path: it reads as a wave. Walk another path: it reads as a particle. The path is the apparatus. The object is what the apparatus made of itself.

**Sequence home.** `qfeplaboratory`, paired with F.

---

## I. Entropy debt

> The algorithm's order is paid for in disorder somewhere else.

**Lineage.** Nicholas Georgescu-Roegen *The Entropy Law and the Economic Process* (1971); Jason Moore *Capitalism in the Web of Life*; Donna Haraway *Staying with the Trouble*; Yuk Hui on technodiversity; Bernard Stiegler on the pharmakon.

**Definition.** Every computed result has a thermodynamic, ecological, and human cost. The algorithm sorts atoms into pattern by burning order from a body, a watershed, a labour pool, an attention span. The bill is real and falls outside the frame.

**QFEP / formal pair.** Shadow of **B**. B asked *can the computer afford this run?*. I asks *can the world?*

**Map sketch.** A "where does the heat go" map. You watch a small algorithm run. Behind a wall, you find what it ran on — coal, a worker's hand, a river's flow rate, your own attention. You return to the algorithm carrying that knowledge. The algorithm has not changed. You have.

**Sequence home.** `criticalalgorithms` / `postfoundationscrisis`, paired with B.

---

## J. Training-fossil

> Every model is the suppressed labour of those who built it.

**Lineage.** Mary L. Gray & Siddharth Suri *Ghost Work*; Kate Crawford *Atlas of AI*; Trebor Scholz on platform cooperativism; Antonio Casilli *En attendant les robots*; the model-collapse and data-exhaustion literature 2024–2026.

**Definition.** The model's ability to do a task is the inverse image of the labour suppressed to make it. What the algorithm knows is what its annotators were paid not to claim.

**QFEP / formal pair.** Intersection of **D** and **I**. What is missing in D is what was *taken* in J.

**Map sketch.** A fossil-bed map. You are standing on a training set. You can *see* who is in there — labellers, scrapers, source authors, deduplicated faces, removed slurs and the people who removed them. The model in the next room speaks fluently; you hear, in its voice, the people who taught it.

**Sequence home.** `postfoundationscrisis`, paired with D.

---

## K. Cosmotechnics

> There is no "the" algorithm.

**Lineage.** Yuk Hui *The Question Concerning Technology in China*; Achille Mbembe; Walter Mignolo's pluriversality; Vandana Shiva; Marisol de la Cadena.

**Definition.** The universalist framing of *computation as such* is a particular cosmology — Western, Greek-then-Newton-then-Turing. Other moral, technical, and metaphysical relations to making-and-knowing exist. Treating one of them as universal is a colonial gesture.

**QFEP / formal pair.** Civilisational shadow of **A**. A asks where Turing's frame ends. K asks why Turing's frame became *the* frame.

**Map sketch.** A many-rooms map. Each room is an algorithm — but the rooms feel different. One runs Euclidean logic; another runs Yoruba ifa-divination logic; another runs Indigenous-Australian songline-as-recursion. They produce different "answers" to the same input. The map's question is: *why did you assume the first room was the default?*

**Sequence home.** `foundationscrisis`, paired with A.

---

## L. Failure as method

> The optimum is not always the goal.

**Lineage.** Jack Halberstam *The Queer Art of Failure*; José Esteban Muñoz *Cruising Utopia*; Lee Edelman *No Future*; Sara Ahmed's "killjoy"; Saidiya Hartman's "wayward."

**Definition.** Optimisation pressures (gradient descent, RLHF, OKRs, school-leaving exams, dating-app match scores) presume a single function to maximise. Queer theory says the refusal to converge is itself a stance, and what looks like failure inside the optimisation may be flourishing outside of it.

**QFEP / formal pair.** Deepens **C**. C said the algorithm settles. L says: settling, deliberately, in the wrong place, is sometimes correct.

**Map sketch.** A no-converge map. The hill-climber in the middle of the room is rewarded for reaching the top. There are objects on the *non-summit* terraces — better art, slower jokes, weirder gardens — that only stay there if no one is climbing. The map ends not when you reach the top but when you decide not to.

**Sequence home.** `machinelearning` / `criticalalgorithms`, paired with C.

---

## M. Authenticity collapse

> After generative models, the real / synthetic distinction is gone — and we live downstream of that edge.

**Lineage.** Hito Steyerl post-2022; Trevor Paglen *Adversarially Evolved Hallucinations*; Molly Crabapple on AI-art labour; Tung-Hui Hu *A Prehistory of the Cloud*; Wendy Hui Kyong Chun *Discriminating Data*; the late-2025 / early-2026 literature on training-on-synthetic-data and model collapse.

**Definition.** By 2026 the dominant signal in any large training corpus is itself model-generated. Models train on their own output. The cultural condition for any reader, viewer, or learner is that *they cannot tell, and the question is no longer whether they can but whether they should care*.

**QFEP / formal pair.** Real-time edge — a cultural condition, not a math one. Sits beside **F**. F said one principle becomes another; M says folds without ground.

**Map sketch.** A forensics map. You are presented with five works — text, images, sound, recipes, code. Three are human-made, two are model-made. The map gives you tools to investigate. You investigate. At the end the map asks: *what did the question feel like to be asked? what did wanting to know change in how you read?*

**Sequence home.** `postfoundationscrisis`, paired with F.

---

## The pairing — late-spine arc as six pairs plus one solo

| Formal edge (A–F) | Critical pair (G–M) | What the pair teaches |
|---|---|---|
| **A.** Formal impossibility | **K.** Cosmotechnics | Turing's frame is one frame |
| **B.** Tractability cliff | **I.** Entropy debt | The cost is also out-of-frame ecologically |
| **C.** Local-vs-global | **L.** Failure as method | "Stuck" is not always failure |
| **D.** Representational silence | **G.** Opacity refusal + **J.** Training-fossil | What the system can't see *and* what it took |
| **E.** Embodiment | **H.** Apparatus-as-phenomenon | The body is co-constituted, not external |
| **F.** Folding | **M.** Authenticity collapse | Folds without ground; everything is mediated |

Read top to bottom: thirteen edges as six pairs plus one solo. A late-spine arc moves A→K, B→I, C→L, D→G/J, E→H, F→M. Each map presents *both* edges of a pair simultaneously — formal scaffolding plus its critical shadow.

---

## What this changes about QFEP

If we take the critical layer seriously, **φ·ΔE(S, t)** stops reading as a phenomenology bonus term and starts reading as the *political* term — the place where what F leaves out, S accumulates as deferred consequence over t. The fold catalyst from `qfeplaboratory` is the player's instrument for tracing those accumulations: when they walk a closed-form algorithm, the catalyst marks where its consequences spilled into a different domain (a body, a labourer, a watershed, an Other knowledge tradition).

---

## The visual grammar problem

VR is not text. The thirteen edges above are written in language because language is where critique has lived; but the late spine has to *show* them, not say them. None of the existing maps in spine sequences 14+ are yet legible from inside VR. The argument has to become an image.

This is the first design problem the late spine inherits from this document. See the auto-research proposal in the chat alongside this commit; the loop combines:

- the **substrate** (`commons/grid/mutators/`) for floor-as-argument,
- the **mesh-grammar auto-research** in the project,
- the **screenshot pipeline** (`commons/testing/capture_*.gd`) for visual diff,

…to iterate from a written edge → mesh-grammar seed → captured image → critique → next iteration. The goal is not to "illustrate" the edges; it is to find the form in which each edge becomes obvious to someone walking through it.

References worth holding nearby while we iterate:
- **Ernst Haeckel**, *Kunstformen der Natur* — taxonomic plate as argument.
- **Luigi Serafini**, *Codex Seraphinianus* — diagram legible without language.
- **Athanasius Kircher**, *Mundus Subterraneus* — diagram of the unseen as an answer.
- **Robert Fludd**, *Utriusque Cosmi Historia* — the cosmos as a single composite image.
- The workshop floor-plan tradition — sticky-note design as substrate-of-the-real.

These are not styles to copy. They are proofs that an idea can become an image without losing its precision.

---

## Status

Living document. Expand as new edges are named or existing edges deepen. When this doc and the visual-grammar auto-research loop converge, the late-spine sequence designs (`foundationscrisis`, `qfeplaboratory`, `criticalalgorithms`, `postfoundationscrisis`) can be authored against it.

*Started 2026-04-27. Anchored to the substrate refactor of 2026-04-26.*
