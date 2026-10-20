# True But Unprovable

Does a machine failing to find a proof show that no proof exists?

## The machine that jams

<!-- @godel_sentence_machine -->

Follow the loop marked by G through one attempt. Watch the mechanism stop and its verdict appear. Before accepting the words “true but unprovable”, ask what the movement has shown you. The floor has already decided, in capitals, from EVERY FORMAL SYSTEM to SELF-REFERENCE IS THE EDGE; walk over its verdict and ask the same question of the machine. Has it exhausted every possible proof, or has one illustrated attempt come to an end?

The machine is a timed sculpture of an argument, not a running proof search. Its jam cannot establish incompleteness by itself. That matters because a slow search, a broken search and a proof that no search can succeed are three different things.

At your smaller bench, the rule is almost nothing: begin with 0; put another S in front. Ask for SSS0 with a budget of two steps. The search stops short. Give it one more step and a derivation arrives. Remove a middle step from the candidate and the checker rejects it. Here the missing proof was a matter of budget, and the damaged proof a matter of a broken link. This little system is decidable; it is not a miniature implementation of Gödel’s theorem.

Think of a proof as a finite object that can be checked step by step against stated rules. Searching for such an object and checking one that has already been supplied are different tasks. A search might continue while each proposed candidate remains straightforward to reject. Keeping those tasks separate makes the sculpture’s stopped arm less misleading: the absence of a proof on the table has not yet told you what every possible candidate would do.

The derivation on your bench is already a record of symbols. Our checker reads it from outside the little language: none of its strings can say “this is a proof.” The next mathematical step is to encode formulas and finite proof sequences as numbers. With sufficient arithmetic, relations between those numbers can express whether a proposed sequence obeys the proof rules. A formal language can then make statements about coded proofs within arithmetic itself. Numbering the strings alone would not provide this expressive capacity.

Gödel’s fixed-point construction uses that capacity to produce a sentence which says, through the encoding, that it has no proof in the given theory. Under an effective axiomatisation with sufficient arithmetic, and assuming soundness for the intended natural numbers, the sentence is true there and unprovable in that theory. The assumptions and the phrase “in that theory” are essential. [The École Polytechnique course chapter develops the encoding and fixed-point argument.](https://www.enseignement.polytechnique.fr/informatique/INF412/uploads/Main/chap10english-goodINF412ENGLISH.pdf)

Before another search step at your bench, choose what you expect its checker to accept. TRY + KEEP retains that prediction with the inputs and the result. If you were wrong, leave the earlier expectation in the record. You will meet it again in Synthesis. A revision of understanding has a history; it need not make its first answer disappear.

## The sentence that names itself

<!-- @godel_statement_plaque -->

At the plaque, press through its sentences. There are nine, each folding further back on itself: a plain claim first, then claims about claims, until the last asserts its own unprovability. From the fifth press the plaque flares; it has reached the part of the series that talks about itself. Read the last sentence twice. The second reading is the sentence speaking about the first. The plaque proves nothing about itself either. What it can show is the shape of the loop the machine across the hall was built to jam on.

<!-- @provability_sorter -->

Now follow a piece outside the sorter’s inner PROVABLE region but within its TRUE region. This nested picture assumes soundness: whatever the theory proves is true in the intended interpretation. The extra region represents the possibility of truths beyond its proofs. The drawing’s areas and piece counts do not measure how many truths lie outside; the pieces have illustrative destinations chosen in advance.

## Adding the truth as an axiom

<!-- @incompleteness_tower -->

Russell’s room challenged an unrestricted construction that produced a contradiction. Here the difficulty can remain even when we choose a sound arithmetic theory. Adding a particular unproved truth as a new axiom may enlarge what is provable, but it does not turn effective arithmetic into a final list of every truth.

The tower is that paragraph built. One ringed platform per formal system; on each, the truth the system below could not prove, bolted on as a new axiom; above it, a new platform holding the sentence the enlarged system cannot prove. A pulse climbs it and finds the gap again on every level. Adding the sentence moves the gap up. It does not close it.

Try replacing G with a personal conviction. What is missing? You would need a defined formal language, axioms, proof rules and the mathematical argument. Incompleteness does not certify every unsupported belief, and it does not make careful proof pointless.

## What checking can do

<!-- @rice_verifier_booth -->
<!-- @negative_control_fixture -->
<!-- @critic_regress_stack -->
<!-- @fluency_seam -->

Four smaller works between the machine and the exit are about checking. A booth stages the distinction between a question about program text and one about behaviour. Its selected answers and refusals are authored examples. Rice’s theorem rules out a general algorithm deciding any given nontrivial property of the functions computed by arbitrary programs. It does not forbid checking particular programs or deciding properties within restricted families. The booth’s refusal cannot establish that your particular question is unanswerable.[^rice] A gauge earns its green light by first being made to go red; pull the lever that plants the fault and watch the needle swing, because a green light you have never seen fail is a claim about the instrument as much as about the world. A stack of critics, each lens pointed at what it can see, none at the dark mark on the floor: add a critic and the blind spot moves, and never goes. And a seam, where one smooth answer stands beside the same question run again, close enough that the gap cannot be talked away. Checking can catch the fault it was built to catch. The planted fault makes that claim inspectable; it does not show that every possible fault will be caught. When an AI supplies our code or our account of it, fluent agreement is no substitute for identifying the input, the rule and the result we actually checked.

## A picture of the room

<!-- @print_gallery_recursion -->

By the exit stands a framed picture on a low plinth. Its subject is the room it stands in, with the picture in it, and the picture in that. Follow the spiral inward and it reaches a gap where the drawing cannot close on itself. Escher left that centre blank in 1956 and put his signature in the blank; the hall keeps the gap. A construction that cannot close itself has two honest endings, hide the gap or show it, and this one shows it.

<!-- @ -->

Douglas Hofstadter brings these crossings between a system and its description into *Gödel, Escher, Bach*. He asks how self-reference might contribute to a sense of “I”; his account of mind grows from an analogy with Gödel's construction, rather than following as another mathematical theorem.[^hofstadter] At our bench, the checker reads a language too small to describe that checker. At the frame, an image contains its own setting. Ask what each representation includes, and where the work of interpreting it takes place. A repeated operation, a nested picture and a sentence about its own proof make different kinds of return.

Escher next changes the medium. Follow locally convincing connections and ask whether they can belong to one consistent spatial whole.

[^rice]: H. G. Rice, “Classes of Recursively Enumerable Sets and Their Decision Problems” (1953), [original paper](https://doi.org/10.1090/S0002-9947-1953-0053041-6). The theorem concerns a general decision procedure for a nontrivial extensional property, not the impossibility of every individual verification.

[^hofstadter]: Douglas R. Hofstadter, *Gödel, Escher, Bach: An Eternal Golden Braid* (1979). In [“What is a strange loop and what is it like to be one?”](https://www.thestrangeloop.com/2013/what-is-a-strange-loop-and-what-is-it-like-to-be-one.html), Hofstadter describes the image of selfhood he drew from incompleteness. This is a philosophical interpretation to consider alongside the formal result.
