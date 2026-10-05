"""Paired time: an application after the timing machines in Forces."""
REVIEW = '2026-10-02-gonzalez-torres-a-second-together'
HALL = 'Change_Choreography'
SPECS = [('paired_time','paired_time',HALL,'forces',19,19,0,
          'A second together','Felix Gonzalez-Torres',['loop','rate','transform'],
          'Halve the rate difference; compare the growing gap with an unchanged phase offset.',REVIEW)]
READINGS = {'paired_time': '''Two pale faces touch at their dark rims. Each carries a hand with a pink tip. Watch one pass the top, then watch the other. For a while, either could have told you where to look.

Press **DRIFT RIGHT**. At first the difference is small enough to miss. Stay for another turn. The right hand has gained something it keeps gaining.

Choose **SAME RATE**. The hands still disagree. They will carry this distance together for as long as the rule holds. Matching their speed has not recovered the time between them.

**ALIGN** brings the right hand to the left. If you leave the rates different, the agreement immediately begins to go. Try aligning once without first making the rates equal. How long do you need to watch before the difference belongs to what you see?

Gonzalez-Torres's paired clocks make shared time available through two ordinary objects. MoMA places the work in the context of his partner's AIDS diagnosis.[^paired-time] Here, both hands receive the same pulse from the game loop. Their disagreement has to be written in. Neither battery will fail; the program has given us an unusually easy power to bring them together again.

We can keep that power visible without pretending it is something we could have offered the lovers. The two rims remain in contact throughout.'''}
ANCHORS = {HALL:'Next, gravity.'}
EDITS = {'paired_time':('commons/artifacts/spine_studies/paired_time_score.gd',
                       'const DRIFT_RATIO := 1.02',
                       'Change DRIFT_RATIO from 1.04 to 1.02 in paired_time_score.gd. After RESET and DRIFT RIGHT, predict the gap after 30 seconds: 18° instead of 36°. Keep the 12-second base period. Then choose SAME RATE and observe that the gap stops growing without closing.')}
REFERENCES = [
    ('Whitney: Felix Gonzalez-Torres','https://whitney.org/artists/3454','The Whitney research led to this artist. This particular paired-clock reference is not presented as a Whitney collection work.'),
    ('Foundation: “Untitled” (Perfect Lovers), 1991','https://www.felixgonzalez-torresfoundation.org/works/untitled-perfect-lovers2','The Foundation records two wall clocks and wall paint, ideally installed above head height. Ada uses enlarged single-hand dials and explicit rate controls; it is an original application, not an authorized installation or reconstruction of that work.'),
    ('MoMA: “Untitled” (Perfect Lovers), 1991','https://www.moma.org/collection/works/81074','MoMA describes initially synchronized battery-powered clocks, possible drift or stoppage, resetting, and the context of the artist’s partner being diagnosed with AIDS. The digital study models none of that bodily or material vulnerability.')]
FOOTNOTE = '[^paired-time]: [MoMA, Felix Gonzalez-Torres, “Untitled” (Perfect Lovers), 1991](https://www.moma.org/collection/works/81074). Ada’s accelerated dials share one engine clock. Their programmed rate difference is a comparison, not a simulation of illness, battery failure or the historical work.'
