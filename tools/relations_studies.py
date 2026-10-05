"""Three application returns: relations, public language, situated images."""
REVIEW = '2026-10-02-relations-sentences-and-witnesses'
SPECS = [
 ('evidence_network','network','GT_Network_Analysis','graphtheory',23,21,0,'A relation needs a record','Mark Lombardi',['graph','line','array'],'Remove one recorded relation; compare incoming and outgoing counts before moving the layout.',REVIEW),
 ('sentence_authority','sentence','Crisis_Synthesis','foundationscrisis',23,21,0,'Permission at three scales','Jenny Holzer',['loop','array','inscription','limit'],'Change one sentence once; follow the same words across label, strip and wall.',REVIEW),
 ('museum_witnesses','witness','SpeculativeComputation_Situated_Computation','postfoundationscrisis',23,21,0,'The room arrives late','Melanie Gilligan',['loop','trace','array','situation'],'Change the delay from three seconds to one; retain the camera and compare the recorded times.',REVIEW),
]
READINGS = {
'evidence_network': '''A fine curve joins the Studio to the Builder. It seems easy to follow. Select RECORD. A date and a payment appear beneath it. The arrow says which way the payment went; it says nothing about whether the work was done.

Move the arrangement. The Archive travels towards the centre without receiving another report. Its incoming count stays the same. Choose only PAYMENTS and several connections disappear. The people have not ceased to know one another. We have narrowed the question.

Lombardi's drawings make the labour behind a connection matter. This small archive is openly fictional. Each line can be traced to one authored record; none can stand as evidence about an actual person. A convincing network can still be a poor account.''',
'sentence_authority': '''YOU MAY REMAIN HERE. On a small label, the sentence is easy to overlook. Above it, a strip gives you one word at a time. Across the wall, the whole permission waits in letters larger than your hand.

Hold the strip on MAY. The other two displays continue to offer the sentence in full. Who is speaking from that height? The words have acquired a place from which to address you, without acquiring a reason you should obey.

These are our sentences, placed in relation to Holzer's public uses of language. Slow the strip. The permission takes longer to arrive. An assertion on a wall remains something to question, even here, among the limits of proof.''',
'museum_witnesses': '''The room you just crossed returns on five monitors. Pink cameras A and B wait beside its readouts. Pick one up and turn it. A third camera stays fixed. A fourth screen receives the first camera's image late. On the fifth, HOLD keeps a frame while the museum continues.

Compare the times beneath them. The earlier image can look as immediate as the present one. Keep it. Aim camera A somewhere else and release it; the camera stays where you leave it. The held frame now belongs to somewhere you are no longer looking, but its address stays with it.

Gilligan's distributed moving images offer a way to keep these partial accounts beside one another. Here every view comes from this museum. Sharing an image does not give us the position from which it was seen. Before agreeing about what happened, we may need to agree about which moment we are seeing.''',
}
ANCHORS = {
 'GT_Network_Analysis':'Connectivity next gives us one exact question',
 'Crisis_Synthesis':'Leave the formula lit.',
 'SpeculativeComputation_Situated_Computation':'Collective knowledge asks',
}
EDITS = {
 'evidence_network':('commons/artifacts/spine_studies/evidence_network.gd','[3,7,"payment","04-16","P04: Office pays Maintenance 1 unit."]','In RECORDS, remove this final entry. Predict whose incoming and outgoing counts fall by one. FILTER to payment, then change LAYOUT: a different position must not create a different count. These are fictional source records, not historical evidence. The curved-line renderer is supplied.'),
 'sentence_authority':('commons/artifacts/spine_studies/sentence_authority.gd','"YOU MAY REMAIN HERE"','Replace this first entry in SENTENCES with your own short sentence. All three displays read the same array entry. Compare WORD / WHOLE and PACE while keeping that entry fixed. The loop and string array are the learner’s tools; font geometry and pointer fabrication are supplied. Keep the sentence short enough to fit and test all displays.'),
 'museum_witnesses':('commons/artifacts/spine_studies/museum_witnesses.gd','var delay_seconds := 1.0','Change the initial delay from 3.0 to 1.0 and reload. D stays blank until enough frames exist. Compare A and D using their exposure times; then HOLD E and change VIEWPOINT. The first edit uses the clock and retained state. The supplied SubViewport cameras share the current museum World3D; the bounded image buffer is a close-reading extension, not a prerequisite for the edit.'),
}
REFERENCES = {
 'evidence_network':('Whitney Museum: Mark Lombardi','https://whitney.org/artists/7340','Lombardi assembled narrative structures from researched relations. Our invented institutional records make provenance inspectable without pretending to reconstruct his historical investigations.'),
 'sentence_authority':('MoMA: Jenny Holzer, Truisms','https://www.moma.org/collection/works/63755','Holzer circulated statements in different public formats. The installation uses original Ada sentences; changing their scale or rhythm does not establish their truth and is not an illustration of an incompleteness proof.'),
 'museum_witnesses':('ZKM: Melanie Gilligan, The Common Sense','https://zkm.de/en/artwork/the-common-sense','The ZKM presentation describes five episodes on separate monitors linked by steel tubing. Our five monitors carry museum cameras, not Gilligan’s films. The relation concerns distributed attention, mediation and dependence on a shared system.'),
}
