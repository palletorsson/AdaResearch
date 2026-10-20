"""Apply the focused reading changes once; preserve the existing reflective sequence."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def replace(hall,old,new):
    p=ROOT/'commons/maps'/hall/'final.md'
    s=p.read_text(encoding='utf-8')
    if new in s:return
    assert old in s,(hall,old[:70])
    p.write_text(s.replace(old,new,1),encoding='utf-8')

replace('Russell_Paradox', '''The small computation behind this test is almost bare:

```gdscript
var required: bool = not assumed_in
var agrees: bool = assumed_in == required
```

Try the two possible values.''', '''The test compares your answer with its opposite. Carry the familiar point between OUT and IN in the student working copy. Its movement changes the assumption, not the rule. Try the two possible values.''')
replace('Russell_Paradox', 'The collection and a member of the collection are different things.', 'The collection and a member of the collection are different things. In your working copy, change the number of finite sets. The labels and the resulting collection change together; the result still lies outside the domain being filtered. That is a construction you can inspect, not a third answer smuggled between IN and OUT.')

replace('Godel_Incompleteness', 'Think of a proof as a finite object that can be checked step by step against stated rules.', 'At your smaller bench, the rule is almost nothing: begin with 0; put another S in front. Ask for SSS0 with a budget of two steps. The search stops short. Give it one more step and a derivation arrives. Remove a middle step from the candidate and the checker rejects it. Here the missing proof was a matter of budget, and the damaged proof a matter of a broken link. This little system is decidable; it is not a miniature implementation of Gödel’s theorem.\n\nThink of a proof as a finite object that can be checked step by step against stated rules.')
replace('Godel_Incompleteness', 'A booth takes a question at its slot and answers it if the question is about a program’s text, and refuses it if the question is about what the program means: refused by theorem, not by a missing feature.', 'A booth stages the distinction between a question about program text and one about behaviour. Its selected answers and refusals are authored examples. Rice’s theorem rules out a general algorithm deciding any given nontrivial property of the functions computed by arbitrary programs. It does not forbid checking particular programs or deciding properties within restricted families. The booth’s refusal cannot establish that your particular question is unanswerable.[^rice]')
replace('Godel_Incompleteness', 'Checking can catch the fault it was built to catch. It cannot certify its own ground, and none of these four claims to.', 'Checking can catch the fault it was built to catch. The planted fault makes that claim inspectable; it does not show that every possible fault will be caught. When an AI supplies our code or our account of it, fluent agreement is no substitute for identifying the input, the rule and the result we actually checked.')
replace('Godel_Incompleteness', 'Escher next changes the medium. Follow locally convincing connections and ask whether they can belong to one consistent spatial whole.', 'Escher next changes the medium. Follow locally convincing connections and ask whether they can belong to one consistent spatial whole.\n\n[^rice]: H. G. Rice, “Classes of Recursively Enumerable Sets and Their Decision Problems” (1953), [original paper](https://doi.org/10.1090/S0002-9947-1953-0053041-6). The theorem concerns a general decision procedure for a nontrivial extensional property, not the impossibility of every individual verification.')

replace('Escher_Impossible', '''The measurement needs very little code. Each move contributes the difference between two heights:

```gdscript
last_delta = _height(index) - _height(_last_index)
ascent += maxf(last_delta, 0.0)
descent += maxf(-last_delta, 0.0)
```

`_height` reads the displayed tread's centre in world space.''', '''Each move contributes the difference between two heights, measured at the displayed tread centres in world space.''')
replace('Escher_Impossible', 'A portal, a changed gravity or a moved room would require another agreement—and another question about what the body experienced on the way.', 'A portal, a changed gravity or a moved room would require another agreement—and another question about what the body experienced on the way.\n\nThe student working copy reduces the journey to four centres. Three gains, then the closing loss. Tilt the arrangement and the individual height differences change; complete the circuit and their sum still returns to zero. Cut the closing link and the point stops at the open end. These small operations give you something to compare with the five more elaborate arrangements in the installed exhibit.')

replace('Brouwer_Intuitionism', '''Your next press will append it:

```gdscript
terms.append(value)
```''', 'Your next press will add it to the record.')
replace('Brouwer_Intuitionism', 'It fills this instrument.', 'It fills this instrument. Your student copy uses only eight slots, enough to inspect every retained choice at once. Its witness is an address you can check: this position contains 1. After eight zeros, the finite question has an answer and the question about an imagined continuation still asks for more.')
replace('Brouwer_Intuitionism', '''The construction extends with them:

```gdscript
_d[i] = 1 - _list[i][i]
```''', 'At each new diagonal position, the construction takes the opposite bit.')

replace('Florensky_Paraconsistent', '''The small piece of code that keeps the reports is almost disappointingly hospitable:

```gdscript
var report_open: bool = true
var report_closed: bool = true
```

Two places in memory.''', 'The small record that keeps the reports is almost disappointingly hospitable: two places in memory.')
replace('Florensky_Paraconsistent', 'Neither makes a proof out of a door.', 'Neither makes a proof out of a door.\n\nYour working copy goes one step further than the installed gate. It states how two independent supports combine under negation, conjunction and disjunction, using a fragment of Dunn–Belnap four-valued semantics. Now the claim about consequence can be tested: P has both supports, while Q has neither. The opposed premises are designated under these tables; Q is not. We have a countermodel to explosion for the defined rules, rather than just a door that continues to stand. This is one chosen semantics, not a general verdict on every paraconsistent logic.[^tables]')
replace('Florensky_Paraconsistent', '[^1]: See the', '[^tables]: Geoff Sutcliffe, Francis Jeffry Pelletier and Allen P. Hazen, [“Making Belnap’s Useful Four-Valued Logic Useful”](https://cdn.aaai.org/ocs/17599/17599-77711-1-PB.pdf) (2018), Table 1. The student study uses the basic negation, conjunction and disjunction tables, without the paper’s additional conditional connectives.\n\n[^1]: See the')

replace('Crisis_Synthesis', 'An assertion on a wall remains something to question, even here, among the limits of proof.', 'An assertion on a wall remains something to question, even here, among the limits of proof.\n\nIn your working copy, six cards keep a sentence beside its scope and evidence. The first five return to the small computations you have made. The sixth carries an AI proposal with no checking procedure attached. Make its letters as large as the checked sentences. Slow them down. Let them occupy the same time and surface. Nothing in those operations supplies the missing evidence.\n\nNor do the first five cards share one certificate called truth. A failed membership case, a search stopped at a budget, a measured return, an exhibited witness and a countermodel warrant different statements. Their records must travel with them. If our own sentence says more than its record supports, that is where revision begins.')
print('Six reflections revised, existing arguments retained.')
