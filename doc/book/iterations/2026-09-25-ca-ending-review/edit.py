from pathlib import Path
import hashlib,json
r=Path.cwd();o=Path(__file__).resolve().parent;base=json.loads((o/'baseline.json').read_text());owned=[]
def replace(rel,pairs):
 p=r/rel;assert hashlib.sha256(p.read_bytes()).hexdigest()==base[rel], 'Concurrent edit: '+rel
 s=p.read_text()
 for old,new in pairs:
  assert s.count(old)==1,(rel,old[:80]);s=s.replace(old,new)
 p.write_bytes(s.encode());owned.append(rel)
agent='commons/maps/CA_AgentsCircuits/final.md'
old=(r/agent).read_text();start=old.index('Before leaving the desk,');end=old.index('\n\n<!-- @ -->',start)
replace(agent,[(old[start:end],'''Before leaving the desk, turn RULE until the plate reads 222 and step from the single seed. A filled triangle spreads until its edges meet around this ring. One dark address remains; the rest has stopped changing. Try 190, then the 30 and 110 buttons. Follow a small patch rather than the whole picture. Does it return, travel, disappear? How many rows would you need before trusting that description?

Stephen Wolfram proposed four broad kinds of behaviour: settling into uniformity, repeating, appearing random, and sustaining local structures that interact.[^ca-classes] These names make differences easier to discuss. Our short history, from one chosen seed, cannot settle how a rule behaves from other beginnings. Nor does the plate's “Turing Complete” turn the picture into a demonstrated computer. We can let the name give us another task.'''),
 ('None of the four choices applies to it: the pyramid is not an automaton at all, which is the point of standing it here.', 'The cubes inherit a position in a copying arrangement; they do not consult a neighbourhood to decide their next state.'),
 ('[^ca-classes]: Stephen Wolfram, “Universality and complexity in cellular automata”, *Physica D* 10 (1984).','[^ca-classes]: Stephen Wolfram, [“Universality and complexity in cellular automata”](https://doi.org/10.1016/0167-2789(84)90245-8), *Physica D* 10 (1984). The classification concerns broad behaviour across initial conditions; his [later account](https://www.wolframscience.com/nks/p231--four-classes-of-behavior/) illustrates it from random beginnings. A finite, single-seed run supplies an example to investigate, not a proof of a class.'),
 ('(“Universality in elementary cellular automata”, *Complex Systems* 15)', '([“Universality in elementary cellular automata”](https://www.complex-systems.com/abstracts/v15_i01_a01/), *Complex Systems* 15)')])
edge='commons/maps/CA_EdgeOfChaos/final.md';old=(r/edge).read_text();start=old.index('The hall is called Edge of Chaos.');end=old.index('\n\nThe other works',start)
replace(edge,[(old[start:end],'''This hall was conceived under the name *Edge of Chaos*. It borrows a question from Christopher Langton: under what conditions can a pattern retain information, carry it elsewhere and change it through an encounter?[^ca-edge] Let the name remain a question here.

The neighbour average belongs to the same family of operations as a blur: a mark can spread while becoming fainter. With matched forcing added, our two volumes let us follow what survives that smoothing and what storage discards. A spreading difference alone does not establish chaotic amplification. The integer conversion introduces thresholds of its own. We have measured some consequences of those choices. We have not located the one permissible region where life, computation or queerness can exist.'''),
 ('Of the four choices, this hall moves the first alone.', 'In this comparison the neighbour rule stayed the same; storage decided how much of its answer could remain.'),
 ("[^ca-edge]: Christopher Langton, “Computation at the edge of chaos: phase transitions and emergent computation”, *Physica D* 42 (1990). His measure was λ, the share of neighbourhoods a rule answers with a living cell; the band lies where λ is neither small nor large. PULL here is a different knob on a different rule, and the name is borrowed, not measured.", "[^ca-edge]: Christopher Langton, [“Computation at the edge of chaos: phase transitions and emergent computation”](https://doi.org/10.1016/0167-2789(90)90064-V), *Physica D* 42 (1990). His experiments associated information storage, transmission and modification with a transition between ordered and disordered behaviour. His λ counts the fraction of rule-table entries whose output differs from a designated quiescent state. It is not the proportion of living cells in a displayed field. PULL changes the strength of neighbour averaging in another model; this hall has not measured Langton's transition.")])
critical='commons/maps/CA_AgentsCircuits/critical.md';old=(r/critical).read_text();archive='commons/maps/CA_AgentsCircuits/wireworld-proposal.md'
replace(archive,[((r/archive).read_text(),(r/archive).read_text()+'\n\n---\n\n## Earlier critical.md — speculative research, not established findings\n\nRetained verbatim on 25 September 2026. This earlier essay refers to a proposed Wireworld encounter. Its claims that code confirms philosophical theories or makes fixed political necessities are not conclusions established by the current two-work hall. They remain questions for a future artifact and a separate critical argument.\n\n'+old)])
replace(critical,[(old,'''# What does a resemblance let us assume?

The explorer gives a cell its next state through a neighbourhood. The pyramid places another copy through a recursive arrangement. Their triangular gaps invite the same eye. A likeness can bring us close enough to notice that the procedures differ.

The floor adds another difference. We can stand in a dark triangle without falling. Its emptiness belongs to the recorded row; support belongs to the museum floor. At the pyramid, a sideways movement changes which cubes hide one another. The same word, *gap*, has not guaranteed the same relation to a body.

Recognition is useful, but it can finish the encounter too early. Calling both works Sierpiński may let a shared name stand in for the comparison. We could ask instead what the name helped us see, and what became harder to notice once the match seemed settled. Keeping a failed correspondence in view gives it a chance to teach us something.

There is a queer possibility in that unfinished likeness: relation without requiring one body to reproduce another's conditions. The flat history and the overlapping copies can belong in the same inquiry while refusing a complete match. This is a way to arrange and attend to them. No transition rule certifies it as a property of the pattern.

Change the seed while leaving the pyramid fixed. Some of the resemblance returns; some depends on the particular beginning we supplied. The visitor takes part in selecting the evidence. That selection should remain available to question, including when a familiar silhouette makes the result feel inevitable.

“Turing Complete” on a plate names a mathematical result about Rule 110. It does not show an encoded task, an input, or how to read its answer. A circuit encounter could make those relations available to inspect. The present hall asks a prior question: how much of our account came from following the making, and how much from recognising the image?

The earlier Wireworld essay is retained whole in [wireworld-proposal.md](wireworld-proposal.md), alongside its proposed technical lesson. It contains speculative links to thrownness, performativity, agential realism and QFEP. Those links need their own arguments and encounters; they are not verified by a neighbour count. The current hall retains both the explorer and pyramid as primary works.
''')])
replace('commons/maps/CA_AgentsCircuits/intent.md',[('Existing critical.md is retained as earlier research material; final.md is the current visitor-facing account.', 'The earlier critical essay is retained there too as speculative research. Current critical.md follows the installed comparison; final.md is the visitor-facing account.')])
registry='commons/artifacts/registry/commons_artifacts.json';p=r/registry;s=p.read_text();d=json.loads(s);item=d['artifacts']['ca_rule_explorer']
new={
 'description':'Explore elementary one-dimensional cellular automata by changing their eight-bit rule and initial seed. The configured neighbourhood study exposes held steps and retained rows; comparison mode enlarges the same history on the floor.',
 'qfep_connection':'A visible resemblance can invite comparison without proving a shared procedure. Rule 110 has a universality proof; its finite museum display does not itself demonstrate an encoded computation.'}
pairs=[(json.dumps(item[k],ensure_ascii=False),json.dumps(v,ensure_ascii=False)) for k,v in new.items()]
replace(registry,pairs)
(o/'changed-files.json').write_bytes((json.dumps(owned,indent=2)+'\n').encode())
print('Edited',len(owned),'scoped files; retained Wireworld essay verbatim')
