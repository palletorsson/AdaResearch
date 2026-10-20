"""Publish complete, small student files in the six remaining canonical lessons."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
STUDY=ROOT/'doc/book/studies/foundations-lineage'
OUT=ROOT/'doc/book/iterations/2026-10-11-foundations-reconstruction'
LESSONS=[
('Russell_Paradox','russell','A demand with no Boolean answer','membership.gd',
'''Membership predicates; Boolean case analysis; finite domains; record versus demand.

We leave the surface comparison with a useful habit: state the conditions before trusting the reading. At the existing Russell workbench, use IN and OUT in cell 5, then compare cell 6. Its membership controls are already installed. Our working copy uses the earlier PointBody as the candidate answer. Put it left for OUT, right for IN; release to test the choice. The sphere remains one object. It does not become an actual set containing itself.

The unrestricted demand is `p = not p`. Exhaust its two Boolean inputs. This is a two-case argument, not a search waiting for enough time. Then define the finite ordinal U = n = {0,...,n−1}. The set represented by each x contains precisely the smaller ordinals. None contains itself; filtering all x in U therefore returns U. U is not a member of U. In this restricted example the demand becomes `p = (result is in U) and not p`, with that domain test false. OUT now agrees. This is a finite example of separation, not an implementation of arbitrary set theory.

`members` builds a new array; it is a snapshot. `test` returns the assumption, required answer and agreement separately. No status is silently promoted into a mathematical object. SIZE cycles 1–6; the model also handles the empty ordinal 0, exercised below. DOMAIN preserves the chosen answer so that the rule, rather than the answer, changes in the comparison.''',
'''Predict all four cases before running: unrestricted IN and OUT both disagree; restricted IN disagrees and OUT agrees. Set n to 2, then 6: the displayed members change, but the result remains outside its domain. Test n = 0 in code: empty U gives empty result, still not a member of itself. Explain why this is not a repair that makes the original unrestricted condition true.

For the hand test, rotate and translate the study node. Right/left are measured in its local frame using `to_local`. The last held coordinate is retained before release, avoiding a physics tick returning the body to its old slot before the choice is read. While held, buttons refuse edits. The inherited frozen PointBody supplies pickup/release; the new lesson supplies the membership rule.

Carry the distinction between an inconsistent demand and a calculation that has not returned. Gödel's lesson will need it.'''),
('Godel_Incompleteness','godel','A derivation you can check','derivation.gd',
'''Formal syntax; axioms and rules; proof checking; bounded enumeration; counterexamples to a claim.

The installed sentence machine already says ILLUSTRATION — NOT PROOF SEARCH. Watch its timed arm, then build a working copy that actually checks a derivation. Bring the finite arrays and explicit conditions from Russell. The same sphere now marks the last candidate inspected; its position is an index, not a truth value. Moving it by hand does not change the calculus: release returns it to that index.

Our entire toy language is 0, S0, SS0, and so on. There is one axiom, 0, and one rule: from w append an S at the front to produce Sw. A proof is an ordered array beginning at 0, advancing by exactly that rule, and ending at the requested target. `verify` checks a supplied array without searching. `search` enumerates rule applications up to a declared budget. Budget 0 still examines the axiom. Budget 2 examines 0, S0 and SS0, so it misses SSS0. Budget 3 finds a proof that the checker accepts.

This deliberately simple system is decidable and does not encode arithmetic proofs or construct a Gödel sentence. The lesson teaches a distinction needed to read the room: a bounded miss cannot establish unprovability. The theorem concerns specified effective theories with sufficient arithmetic; the source linked below develops the argument. Nothing in a timer, a label or this toy enumeration substitutes for it.

MORE increases the budget to at most 8; TARGET switches between SSS0 and SSSSSS0. DAMAGE removes the second line of a copied candidate. It never alters the search result's stored array. RESET restores budget 2 and an undamaged candidate, retaining the selected target. The checker must reject a damaged chain even when its last line is the desired sentence.''',
'''Before running, predict: SSSSSS0 is missed at budget 5 and found at 6. Check the returned array with `verify`. Remove S0 from a valid proof: reaching the target is insufficient when the intermediate inference is invalid. Supply X or 00: syntax validation refuses them, which differs from a bounded miss on a well-formed target.

Write down one claim our test can refute: “not found within two steps means unprovable.” The budget-3 run is its concrete counterexample. Do not replace it with the opposite overclaim that every proof system is this easy. The next hall changes medium: a closed spatial route has a directly checkable height invariant.

Reference: [Olivier Bournez, Incompleteness of arithmetic](https://www.enseignement.polytechnique.fr/informatique/INF412/uploads/Main/chap10english-goodINF412ENGLISH.pdf). Our unary study is an original teaching construction, not that theorem's proof.'''),
('Escher_Impossible','escher','Where the height returns','height_route.gd',
'''Ordered positions; world-frame measurement; open and closed paths; accumulated differences; invariants.

At the existing staircase, STEP follows measured tread centres; FORM offers five arrangements. Our smaller construction isolates one question using four familiar cube treads, the carried LineSkin cylinders and one PointBody marker. No faces of the cube are transformed individually. The player stays on the museum floor; the marker travels the model.

The four centres rise by 0.2 metres three times. Closing the route requires a −0.6-metre move. `step` measures actual centre heights after applying the chosen transform, accumulating positive changes in up and negative magnitudes in down. On return, up minus down is zero within numerical tolerance. `closure` calculates every edge difference independently of the visitor's partial journey. Each height appears once with each sign. This algebraic cancellation explains the general closed-route invariant; the program checks finite instances.

OPEN removes the closing connection and refuses movement past the last centre. It does not wrap through an invisible drop. TILT rotates the entire arrangement by 0.35 radians and starts a new measurement, so no journey mixes coordinate frames. The displayed treads and measured centres use the same transform. Individual signs may change when up changes relative to the model, but a closed route still cancels. RESET keeps the selected arrangement and tilt.

Walk around the installation's separate perspective work. Apparent contact in an image and coincidence in three-dimensional coordinates require different evidence. Our working copy does not fabricate an impossible staircase or prove a result about formal arithmetic.''',
'''Predict the fourth change before pressing it: −0.6 metres in the unrotated study. Assert four steps return the marker to index 0 and equal ascent/descent. Open the route: after three moves, the next attempt must fail and retain index 3. Tilt the whole study around another axis in code; calculate each world height and predict the return difference. Keep that frame fixed during a run.

Try changing only one tread's drawn angle while leaving its centre fixed. The centre measure will miss that surface slope; name the limitation rather than calling the reading wrong. The next hall asks what a produced object can witness.'''),
('Brouwer_Intuitionism','brouwer','A witness, then another choice','witness.gd',
'''Chosen finite prefixes; existential witnesses; validation; a finite diagonal construction.

The existing choice bench waits for a press; its row does not grow on the clock. Rebuild that behaviour with an eight-term working copy. The arrays and loops are familiar from Trace. A stored 1 at a named index witnesses “this prefix contains a 1.” No 1 in the entire stored prefix settles that finite question negatively. It does not settle whether an indefinitely continued sequence will ever contain a 1. NO WITNESS YET is an evidence status, not a third truth value.

Begin with 0, 0, 0. Wait. Nothing is appended. Press 1 and identify the zero-based index 3. `append_bit` validates both value and capacity before mutating the record. The ninth press is refused. Eight is a storage bound; it is not a completed infinity. The PointBody marks the next available slot, or the last slot when full. Its pickup is inherited; the bit buttons remain the only authors of this record.

Then visit the installed diagonal workbench. In the second exercise, DIAGONAL displays four binary rows and constructs d[i] = 1 − rows[i][i]. Every displayed row disagrees with d at a known index. The model validates a square nonempty array of integer bits before constructing the witness. The gold tiles mark those indices. This implements a finite diagonal stage. An infinite argument quantifies over every row of an arbitrary proposed list; rendering four rows is not rendering that infinity.

DIAGONAL changes the view without clearing the chosen prefix. A new 0 or 1 returns to the prefix. RESET clears the prefix and keeps the chosen view. The earlier arrays therefore survive a change of representation rather than being silently recreated.''',
'''Make eight zeros. Predict the finite answer and the continuation status separately. Clear, append three zeros and a 1, and return the witness index. Invalid values and a ninth append must leave the record unchanged.

For the diagonal variation, flip every diagonal entry of the supplied rows. Predict that every output bit flips too; assert disagreement with row i at position i for both versions. Supply a ragged array and refuse it. A displayed “constructed” flag without these checks would not establish the property.

The next hall retains incompatible reports. An absent witness and two opposed reports will be different data states, with different consequences.

Reference: [Joan Rand Moschovakis, Brouwer's Notion of Choice Sequence and Its Descendants](https://www.math.ucla.edu/~joan/Oslonewzoom2022handout.pdf). The finite binary bench is our teaching model.'''),
('Florensky_Paraconsistent','florensky','Two reports, stated consequences','reports.gd',
'''Independent support; four information states; explicit consequence rules; a countermodel to explosion.

At the installed gate, OPEN and CLOSED are independent reports. Both leaves can remain visible; neither supplies evidence for the alarm Q. First reconstruct that store. Then make a small additional step in the student copy: define precisely how negation, conjunction and disjunction combine the reports. This extension is a tiny propositional semantics, not a claim that the installed gate already implements a proof engine or that Florensky proposed this particular logic.

Each Vector2i has two binary components: support for and support against. (0,0) means neither, (1,0) for only, (0,1) against only, and (1,1) both. These are independent flags, not probabilities summing to one. Negation swaps them. For conjunction, positive support requires both positives; negative support needs either negative. Disjunction reverses those AND/OR requirements. A result is designated when its positive component is 1. The code implements the negation/conjunction/disjunction fragment of Dunn–Belnap four-valued semantics; it has no implication connective, quantifiers or proof-search procedure.

Test the consequence claim “P and not P license any Q.” At P=(1,1), both premises are designated. At Q=(0,0), Q is not designated. `explosion_counterexample` enumerates all sixteen assignments of P and Q until it finds that countermodel. This establishes failure of that consequence for these defined tables. It does not establish the truth of both reports about an actual door.

P FOR and P AGAINST toggle the independent components. Q FOR adds a separate report about Q; holding both P reports never performs that action. CLEAR empties both records. The sphere remains the familiar held object; releasing it returns it to the bench rather than resolving a report.''',
'''Predict all four states of P before pressing the buttons. Hold both reports while Q has no support. Then add Q's own positive report: explain what changed and who supplied it. Negating a pair twice must return the original pair. Check the two De Morgan laws over all sixteen input pairs and conjunction elimination: whenever a conjunction is designated, each conjunct is designated.

Compare this with Brouwer's status “no witness yet.” Our four-valued semantics is an explicit choice for combining reports. It does not turn constructive uncertainty into a third or fourth truth value, and it has no connection to quantum amplitudes. The synthesis will keep these scopes attached to their results.

Reference: [Sutcliffe, Pelletier and Hazen, Making Belnap's Useful Four-Valued Logic Useful](https://cdn.aaai.org/ocs/17599/17599-77711-1-PB.pdf), Table 1. Our pair representation implements the basic tables, not the paper's additional conditional connectives.'''),
('Crisis_Synthesis','synthesis','A claim keeps its warrant','claim_record.gd',
'''Evidence records; reuse across models; display scale; word timing; claim versus validation.

The existing hall brings the formula, independent parameter controls and earlier encounters together. Its sentence-authority work repeats the same words at several scales. Build a small working copy of that operation, carrying the five model files just written. The code computes fresh fixture results using them; it does not claim to load your previous interactive sessions. The unchanged models are listed below. Their meanings remain distinct.

Each card keeps three fields: sentence, scope and evidence. The first five concern the two Russell cases, a unary search budget, a closed height route, a chosen prefix and a four-valued countermodel. The sixth is an authored AI proposal with no verification procedure attached. That explicit absence does not acquire a certificate from the neighbouring calculations. These examples are finite scoped records, not an automatic truth service.

`current` returns a deep copy, protecting the stored evidence from display edits. NEXT changes the selected card and starts its word rhythm again. SIZE changes font size; HOLD pauses the strip; PACE alternates 0.6 and 1.2 seconds per word and restarts it. Small label, large label and strip read one sentence. None of these controls reruns a model, changes its assumptions or upgrades its result.

The original QFEP formula remains a research proposal. Its λ and φ displays do not measure the entropy of these cards, and the logistic exhibit's r remains independent. Our work here concerns how an assertion is presented and what supports it. The familiar sphere is present as a carried body, not as an oracle that can settle the formula.''',
'''Freeze a copy of the current card. Change font size, hold for several simulated seconds, change pace, and complete a word cycle. Its scope and evidence must remain exactly the same. At the proof card, identify the target and budget before reading the large sentence. At the AI card, ask for a source or executable test; do not accept size, repetition or fluent wording as that evidence.

Edit a sentence in `cards` and run the three displays. The program will faithfully print even a false or overbroad sentence. This is a deliberate limit of the display, not permission to report the edited claim as validated. Compare it with the evidence kept alongside it and revise the words when they disagree.

Carry this practice into the QFEP laboratory: define the quantities, implement the operation, preserve the record and let someone challenge what the result entitles us to say.''')]

GODEL_BRIDGE = '''
## From a stored proof to a statement about proof

Our proof is already data: an array of strings. The checker receives that array and tests each step. It speaks about the proof from outside our tiny language, whose strings cannot themselves express “this is a proof.”

The bridge to Gödel is a stronger formal language. Finite strings and sequences can be encoded by natural numbers; an effective syntactic check on a proposed proof can then be represented by arithmetic relations. Sufficiently expressive arithmetic can state that a number encodes a proof of a formula. A fixed-point construction uses this capacity to produce a sentence about its own provability. Merely numbering our strings would not supply that construction or the theorem's hypotheses. Keep the small checker as preparation for this additional argument.

## Keep your own experiment

The second row asks about the next search budget: will its candidate pass the checker? PREDICT YES/NO stores the chosen inputs and your expectation without running that next search. TRY + KEEP runs it and appends the full record to `user://ada_foundations_trials_v1.json`. The expectation never enters `search` or `verify`. Up to eight steps are available here; RESET begins another run without clearing the journal. Changing the exploratory setup cancels a pending prediction. Ordinary MORE is exploration and does not save a run.

`trial_archive.gd` validates the file format, keeps earlier entries and writes a complete temporary file before replacing the journal. The record names `unary-derivation-v1` and the SHA-256 of the executed model source. The supplied museum launcher remains infrastructure; this new save/load code is printed below. The journal is local to this project's Godot user-data directory. Another device needs a copy of the file. It records this finite experiment, not a proof of incompleteness.
'''
GODEL_TRIAL = '''
For your carried experiment, RESET at target SSS0. Predict whether the checker will accept a candidate at the **next** budget, 3. Press PREDICT YES or PREDICT NO, then TRY + KEEP. The prediction is fixed before that run. Compare it with the accepted result. Keep a mistaken prediction as it was. Repeat with DAMAGE enabled or target SSSSSS0; earlier entries remain.

Leave the study and open Synthesis. Its first personal card must contain your target, budget, damage setting, prediction, candidate and outcome. Returning to RESET never erases the journal. If the journal cannot be read or saved, the display says so; a missing record is not replaced with an invented personal experiment.
'''
SYNTHESIS_CARRY = '''
## Bring a run you actually made

As in Trace → Grid, your own work travels into another hall. The six reference cards use supplied examples. Your saved Gödel runs are additional cards, read from `user://ada_foundations_trials_v1.json`; the first personal card is selected on entry when available. They retain the target, budget, damage setting, prediction, search output, exact tested candidate, checker result, time in UTC, model identifier and source hash. The journal is read without rerunning the search or rewriting earlier entries. A source change is disclosed alongside the older result. A missing or malformed file produces a notice and no personal cards.

## Keep the difficulties distinct

| Encounter | What must be distinguished |
| --- | --- |
| Plane / sphere | Different geometric models; a changed result can be correct in each. |
| Russell | The unrestricted demand contradicts both Boolean assignments. |
| Gödel | A finite search miss; separately, the theorem's unprovability claim under specified assumptions. |
| Escher | Coincidence in a view versus connection in the measured space. |
| Brouwer | An absent witness now versus a claim about every continuation. |
| Florensky | Opposed reports and the explicitly chosen rules of consequence. |

Each difficulty calls for its own response. They do not accumulate into a verdict that justification has failed. Choose one earlier museum artifact—a trace, a woven pattern or the trained sphere—and state its inputs, rule, observed result and what the result leaves open. This final comparison is a written investigation; the current journal imports Gödel experiments only.
'''
SYNTHESIS_CHECK = '''
At your own card, identify what you predicted before the run and whether it matched. A failed prediction is part of the evidence. Visit another card and return; restart the hall. The saved inputs and result must survive both. If the model source changes, retain the earlier card and read its source warning; a hash identifies bytes, not the truth or authorship of a record. The reader validates the record's format, not the historical honesty of someone editing its JSON.
'''

def block(name):
    return f'### `{name}`\n\n<!-- student-code:{name} -->\n```gdscript\n'+(STUDY/name).read_text(encoding='utf-8').rstrip()+'\n```\n\n'

def main():
    for hall,key,title,model,intro,exercise in LESSONS:
        if key=='godel':
            intro=intro.replace('counterexamples to a claim.', 'predictions and saved experiments.')+'\n'+GODEL_BRIDGE
            exercise+='\n'+GODEL_TRIAL
        if key=='synthesis':
            intro=intro.replace('The code computes fresh fixture results using them; it does not claim to load your previous interactive sessions.', 'The code keeps six supplied reference cards and also imports your saved experiments from Gödel.')+'\n'+SYNTHESIS_CARRY
            exercise+='\n'+SYNTHESIS_CHECK
        labels,prose=intro.split('\n\n',1)
        labels='\n'.join('- '+word.strip().rstrip('.') for word in labels.split(';'))
        carry='Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there.'
        if key!='russell':carry+=' Carry `bench.gd` unchanged from Russell. It supplies only geometry, labels, the visible sphere and button wiring; the rule below remains new.'
        if key=='synthesis':carry+=' Also carry `membership.gd`, `derivation.gd`, `height_route.gd`, `witness.gd` and `reports.gd` from the five preceding lessons. These are executable dependencies, not hidden services.'
        if key=='synthesis':carry+=' Carry `trial_archive.gd` from Gödel too. It reads the saved experiment file; no live node is transferred.'
        setup=f'''## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. {carry}

Run the supplied `{key}.tscn` in that folder with F6. Its `{key}_museum.gd` launcher opens **{hall}** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

'''
        code=block(model)
        if key=='russell':code+=block('bench.gd')
        if key=='godel':code+=block('trial_archive.gd')
        code+=block(key+'_study.gd')
        text=f'# {title}\n\n**Learning elements**\n\n{labels}\n\n{prose}\n\n'+setup+code+'## Predict, build, check\n\n'+exercise+'\n\nThe automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.\n'
        (ROOT/'commons/maps'/hall/'tutorial.md').write_text(text,encoding='utf-8')
    print('Six complete canonical tutorials written')

if __name__=='__main__':main()
