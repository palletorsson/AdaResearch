"""Draft source-grounded Randomness pages without changing any source chapter."""
from pathlib import Path
from hashlib import sha256
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
STYLE = HERE / 'columns.png'
base = '''Use case: illustration-story. Create a finished companion BOOK COMIC PAGE. Input image 1 is ONLY the established visual style and fictional-character reference: adult short dark wavy-haired student in burgundy knit, black trousers and shoulder bag; older grey-haired companion in navy. Any further input is museum-material reference only. Exactly SIX panels, two columns by three rows, portrait cream page, fine black borders, condensed serif title, smaller serif subtitle, black serif captions in white boxes, elegant painterly photorealism. Warm pale Endless Museum, polished floor, simple off-white plinths, light and shadow. Figures look, act and listen, no lectures or code cards. Quiet wonder, precise material relationships. Selected final.md encounters, not a tutorial or a historical reconstruction. Diagrams are small separately framed SCHEMATIC insets, never physical floating objects. No invented theory, new capabilities, historic portraits, perfect outcomes, extra captions or unreadable dashboards. Text supplied below verbatim. Distinguish view, record, procedure and bodily permission. Preserve causal invariants even if staging is simplified. '''
plates=[]
def add(slug,m,title,subtitle,summary,focus,panels,footer,note,refs=()):
    data=(ROOT/'commons/maps'/m/'final.md').read_bytes()
    norm=lambda s:' '.join(s.replace('*','').split())
    for q,_ in panels:
        assert norm(q) in norm(data.decode('utf-8')), (m,q)
    assert norm(footer) in norm(data.decode('utf-8')), (m,footer)
    snapshot=HERE/'sources'/(m+'.md')
    if snapshot.exists():assert snapshot.read_bytes()==data
    else:snapshot.write_bytes(data)
    prompt=base+f'\nTitle: "{title}". Subtitle: "{subtitle} · final text".\n'
    for i,(q,s) in enumerate(panels,1):prompt+=f'Panel {i}: Caption exactly "{q}". Scene: {s}\n'
    prompt+=f'Footer exactly: "{footer}".'
    plates.append(dict(slug='random-'+slug,map=m,sequence='randomness',source=f'commons/maps/{m}/final.md',title=title,subtitle=subtitle,summary=summary,focus=focus,panels=panels,footer=footer,prompt=prompt,reference=str(STYLE),references=[str(STYLE),*[str(ROOT/r) for r in refs]],source_sha256=sha256(data).hexdigest(),source_review=note))

add('seed','Random_Definition','THE PICTURE NEEDED MORE THAN A NAME','Definition',
    'Two coloured grids return together until one unused draw changes the right-hand palette. A seed needs its procedure.',
    'A generator starting state is distinct from call order and the role assigned to each draw.',[
    ('Choose a small patch you would not have thought to put together.','Student finds corresponding patch in two IDENTICAL 8-by-8 coloured cube grids above compact controls. Same cubes and positions in each.'),
    ('The colours stay where they were.','Press REPLAY. Matched BEFORE / AFTER cropped patch inset has exactly the same colours, not recoloured or shifted.'),
    ('The seed has not changed.','Press +1 DRAW. Left grid unchanged, right DIFFERENT colours but identical cube positions. Both seed readouts 41. Button toggles single discard.'),
    ('The right strip now starts with the second bar on the left.','Two SCHEMATIC strips show only first six bars. Left heights .2,.7,.4,.9,.3,.6. Right .7,.4,.9,.3,.6,.8. Match colours of bars to values, clear ONE offset, not permuted order.'),
    ('Nothing in a draw says that it is red.','Small schematic strips of labelled draws a b c d e f g: Left RGB groups (a b c),(d e f); Right RGB (b c d),(e f g). One discard a outside right groups. Visitor follows shifted grouping, no actual cubes moving.'),
    ('Chance has not chosen what a mark means.','Three static textile samples same binary cell decisions, different vocabularies diagonals / upright-horizontal / blocks. Student follows corresponding cell; no claim same visual forms.')],
    'Here, randomness varies what the program has made variable.',
    'Grids have fixed addresses. Draw strips and RGB assignment are cropped explanatory sequences, not measured output values. Textile decisions share a stream while mark vocabularies differ.')

add('shares','Random_Entropy','WHAT THE NUMBER DID NOT SEE','Entropy',
    'Tiles change neighbours while the tally stays. Another arrangement can hold the same inventory and another view.',
    'Categorical shares omit order; visible displacement and rubble are different accounts.',[
    ('Here, choose a pair of neighbouring colours before touching a button.','At long ledger desk, student points at adjacent different-coloured tiles; many coloured tiles in retained row, ten small count bars on panel.'),
    ('The tiles glide into ten blocks, one per symbol; the bars hold their places.','Matched temporal views AS DRAWN / SORTED, SAME colour quantities reordered into colour blocks. Ten histogram bars identical in both. A cropped enlarged old excerpt stays on desk front.'),
    ('It has stayed too.','Companion looks at SAME H in both views, label H same. Do not invent exact sample value. Student notices changed neighbours. Tiny inset two arrangements with equal red/blue counts, different adjacent pairs.'),
    ('The ruler has changed with the thing it measures.','CONTRAST weighted sample dominates first bar. Small inset counts2/4 and4/8 both scaled maximum to same displayheight, clearly SCHEMATIC separate example, not live sample. Numerical counts remain distinct.'),
    ('The fallen stone is still here.','Four-column pale lintel ruin, top capital removed and arranged in rubble below, other stones retained. No dust disappearance, no thermodynamic gauge. Person on permanent museum floor.'),
    ('What was a boundary now lets you see across it.','Museum wall top courses dismantled, stones on ground; low edgecourse and floor retain support. Visitor sees through opening, ruined gallery arrangement with no entropy meter measuring stones.')],
    'What does a count of stones tell us about what they can still hold?',
    'Tile drawings are cropped selections, not claims to show all 200. Sorting preserves categorical tallies; the ruin does not measure thermodynamic entropy. Contrast diagrams separate counts from display scaling.',
    ('doc/book/figures/randomness/ruin-waiting-museum.png',))

add('eligible','Random_Remove','THE SET BEFORE THE CHOICE','Remove',
    'Grey cubes remain unavailable. An empty slot keeps its address; a missing floor cell also withdraws support.',
    'Filter, draw and removal are separate; support is an additional instruction.',[
    ('Here, find a cube the process cannot choose.','Pedestal square board EXACTLY 8x8 cubes; central4x4 amber, outer48 grey. Adult points at outergrey. Clear topview inset may ensure counting, no perspective losing rows.'),
    ('the draw is made before the deletion.','Same board one amber cube red, rest amber/grey. Insets RED then EMPTY addressplate retained. Red not another cube arriving. REMOVE ONE pushbutton.'),
    ('The final shape was never in doubt: the square you counted at the start, emptied.','After16removals central4x4 slots EMPTY with pale slotplates visible, grey border unchanged. Address grid stays8x8. Visitor sees chosen square absence.'),
    ('An absence has become part of the next choice.','Two glass hoppers eight numberedslots each. LEFT selected2 returns, resultcopy2 retained beneath; RIGHT selected2 staysout, its slotempty. No extra physical2 inside right.'),
    ('The gap is now something your body can fall through.','Visitor ON permanent dark apron beside glass-framed amber floor over fire basin. One redcell about to disappear; separate AFTER cutaway gap through support. No floating ungrounded feet or collision barrier over hole.'),
    ('Walking makes a choice happen; it does not tell the choice where to land.','Another view apron and arena, removed cell far from visitor. Controloutside frame, othercells present. No draw targeting nearest foot.')],
    'Giving it back is an instruction too.',
    'Small board preserves its support and original addresses. Arena cutaway explains the extra collision change; not a runtime fall or safety demonstration. Hopper copies represent retained results.')

add('marks','Randomness_10_PRINT_Algorithm','WHEN A MARK BECOMES A WALL','10 PRINT',
    'Two diagonals become a plane, a floor and solid walls. An arrangement can close a figure and refuse a body.',
    'Layout, bias, material and crop decide what binary draws can become.',[
    ('Something that fits inside one character has acquired room for a body.','Student stands between tall diagonal slabs near entrance, diagonal printscreen farwall. Walls actualsolid, shoulder-scale passages.'),
    ('The maze has become stripes.','Printer two framed snapshots EVEN / ONE DIRECTION: mixeddiagonal small squaregrid vs allparallel diagonals. BIAS+ button near; no claim every unbiased sample has equalcount.'),
    ('The field becomes a single column.','SEMICOLON OFF makesonevertical column of same seeded diagonal signs. Paired inset planar4x4 / column16, exactly same row-major signs. No encloseddiamonds in column.'),
    ('One tiny character has given the other characters another way to meet.','Simple separate2x2 diagram four diagonals formingdiamond: top row / then backslash, lower row backslash then /. Endpoints at centres of outeredges. This is a possible configuration, not all marks.'),
    ('They give the eye a contour without giving the body a boundary.','Low halfmetre diagonalridges onfloor; visitorwalks among them. No huge solidfloorbarriers. Screen paused STEP button nearby.'),
    ('The same connection that completes a figure can keep a body outside it.','Tall slabs enclose small diamond room with NOentrance. Visitors outside. Separate nearby open corridor, not forced doorway in closeddiamond.')],
    'The marks alone cannot tell us which world we have made.',
    'Print diagrams select small possible streams. Low ridges have no collision; tall slabs retain a separate initial crop. No branch maze or climb implied.')

add('throws','Random_Cubes','WHAT A THROW LEAVES BEHIND','Cubes',
    'A hand throws a die. Its tally forgets landings; two colours recover ingredients a total would lose.',
    'Observed physical orientation, empirical summaries and authored continuation rules differ.',[
    ('How much can one throw tell you about a die?','Single white die ongreenfelt, studentreleases it. Companion watches. Sixpip top not8, anatomicallyplausiblehand no grabbingremoteobject.'),
    ('A six receives a small spectacle.','Die landed6, orangeballs rain onto table. Decorative amount NOT countedexact96. No RNGchoosing face diagram, rewarddistinctfromdie.'),
    ('It belongs to a distribution, while the observed mean belongs to the throws made so far.','Die besideglasssixbar ledger. Label MODEL3.50 separate OBSERVED. No side3.5 ondie. No convergence/fairnessbadge.'),
    ('Two columns can reach the same level without looking the same.','Exactlytwoequal7block workedexample columns: blue3+pink4 and blue5+pink2, clearly labelled WORKED EXAMPLES. Countsvisible. Traysbelowblue/pinkdice not assumedactualoutcomes.'),
    ('Nothing inside the cube knows that six means again:','Continuationdie with workedexample6,6,3 column15thinblocks separatedinto3bands, labels6/6/3. Raisedflag on6stage inset CLOSED on3stage. Not unlimitedlivecolumn.'),
    ('A history needs room; this one has been given twelve places.','Shelf12pair-record slots, smalltwo-coloured columns, leftoldest faint departure arrow separatediagram; livecolumnstays. Visitor looks back at single physical die.')],
    'Each view lets you call something different the same.',
    'Rewards do not certify fairness. Seven-height columns and continuation are explicitly worked examples, not visitor throws. The ledger loses order while paired columns retain limited history.')

add('turns','Random_Rotate_Random_XYZ','TURNING WITHOUT LEAVING','Rotation',
    'An edge moves out of alignment while its centre remains. Rust, a changing orientation and a still tilted field keep different histories.',
    'Accumulated angle differs from translation, wear and spatially prescribed rotation.',[
    ('Which part of an arrangement can change while its pieces remain?','20cubesin5x4block and120triangularprisms12x10 onlongdisplay, orderlybaseline. Can cropwideprismstack but donotclaim visiblecountwrong.'),
    ('Nothing else changes.','Closecrop3adjacentcubes samecentres, sizes,colours, one turned3degrees inplane. Faintseparatedschematic originalsquareoverlaysat samecentres. No drift/sink/shrink.'),
    ('Its angle has no limit: each small turn is added to the last.','Three TEMPORAL insets samecentre successiveorientation, littleturnarrows nottraveldisplacements. Shapeexampleangles illustrative nottesttimings.'),
    ('Their size never changes, and in this room neither does their place or their colour.','Companion examinesprismneighbours centres stillaligned whileedges differ, cubesandprismsnoncolliding, nocolourdecay.'),
    ('Nothing in the rig draws a random number.','Separatewearrigbox/sphere/cylinder with matchingrust/grime. Student moveshand, scratchesnearhand cue. No chancebutton; wear not physicalbreakdown.'),
    ('Rotation can be a rule about place as easily as a record of chance.','Low5x5cube staticfield, firstrowlevel, middlepitched upward, lastlevel. NO motionarrows, student walksalongside; matchesmaterialreference.')],
    'Here each piece shows only where its turns have added up to;',
    'In-plane turns preserve centres and sizes. Insets are schematic accumulated states, not calibrated elapsed-time results. Wear rig is motion-driven, and static sine tilts do not keep turning.',
    ('doc/book/figures/randomness/tilt-field-contained.png',))

add('trail','Random_Walk','THE LINE IS ALREADY BEHIND','Walk',
    'A bead steps beyond its retained line. A hand carries another wandering origin; keeping a trail does not mean consulting it.',
    'Current state, drawn history, boundary reflection and feedback are distinct.',[
    ('What does a trail remember that its next step does not use?','Glass tankdarkcabinet, redbeadwithredthintrail, fourdimbeads. Studentfollowsred. Trailendsonepositionshortofbead, notconnectedexacttoit.'),
    ('The code has room for three coordinates and has declined to change one.','2D mode horizontalflat trailinthree-dimensionaltank. Separate sideviewclearconstantheight. 3D insecondinsettrailrisesfalls, no beadescaping.'),
    ('The overshoot folds back.','SCHEMATIC1D slice wallx=.25, old=.24, PROPOSED dottedarrow to.27, ACCEPTED point.23. Solidretainedsegment.24to.23, notcontactbouncepath. Insetslabels .24 .25 .27 .23.'),
    ('The drawing is already behind the body, and the beginning has gone.','Closeupbeadcurrentpoint4, linejoinspositions1,2,3 only, 0fadedoutsidecroppedrecord. Separatepointslabels P1/P2/P3 CURRENT; no currentjoinedtoP3.'),
    ('Your hand carries the origin; the tip walks around it.','Studentholdsplainblackdrawingdot withgreenwanderingtipoffset, thinlinebehindtip. Faint25cmradiusSCHEMATICcirclearoundhandorigin, notphysicalforcefield.'),
    ('a visited cell rises.','Larger glass-framedfieldwithraisedsteppedvisitedcells. Studentwatchesfrombypass. Heightrecordnoattractingarrow, notpheromoneorplanneddestination.')],
    'What would its next step need to know for that reading to become a capability?',
    'Trail is prior-position history and does not steer this bead. Reflection diagram separates proposed endpoint from retained path. Hand-offset circle is explanatory; raised visits do not imply a guidance signal.')

add('bins','Random_Gaussian','THE VALUES STAY, THE ACCOUNT MOVES','Gaussian',
    'New draws stop while beads still fall. The retained sample acquires another shape when its bin intervals change.',
    'Sampling law, clipping, binning and display scale are separate operations.',[
    ('Look at the beads and the bars before letting that line finish the picture for you.','Darkcabinetbluehistogrambars, orangemodelcurve, yellowbeadsfalling; usemuseumreferenceform. Pale expectedcountbars behindblue. Adultlooksattwoactualbarheights.'),
    ('only the issuing of new draws has stopped.','StudentpressPAUSE, noNEWbeadatoutlet but alreadyreleasedyellowbeadscontinuetoland. IN FLIGHTlabelseparate. No freezed midair beads asserted.'),
    ('More evidence does not promise that every part of the picture will improve at the next press.','BATCH button, histogramafter100 then200counts; onegapcloses but anotherdisagreementincreases. Schematicnotclaim empiricalspecificrun. Paleexpectationnotphysicalgravitytarget.'),
    ('Nothing has been sampled again.','BINS matchedtwohistograms30then10, SAME N300inboth. Clearinset4retainedvalues .12,.18,.51,.89 groupedinto10 vs5intervals, valuesunchanged. Donotpretendpicture30binsexactifcannotdraw.'),
    ('Its distance beyond the edge is lost from the retained value.','SCHEMATIC numberline0..1 raw1.12arrowto1, raw-.08arrowto0. Keptedgepointsred; valuesnotreflected inward. Binintervaledgealsoincludesvalid.98.'),
    ('From the painting alone, could you tell a centre that was never reached from one that was refused?','Whitepaintplatewithcolourdotannulus and EMPTYcentraldisc, labelSafe Zone. Studentlooks, no paintinsidecentre. No discarded-drawcounter invented.')],
    'The values have stayed; the account of them has moved.',
    'Histogram illustrations are schematic records rather than claimed exact draws. Orange shape and live bars have separate scaling; rebinning keeps values and landed count. Clipping and centre rejection must not be conflated.',
    ('doc/book/figures/randomness/sampler-visible-record.png',))

add('wardrobe','Random_Mushrooms','A DIFFERENCE NEEDS ROOM IN THE RECIPE','Mushrooms',
    'Specimens share a construction while their scales differ. A new garment branch requires another instruction.',
    'Variation inside templates differs from changing repertoire, acceptance and permissions.',[
    ('Which differences can this recipe make?','Glass-enclosedbed, sixnumberedtemplates0..5onfrontdiscs. Tallwhite, redcap, puffballdistinguishable. Adult looks at relatedcopiesinbed.'),
    ('SHOW names a construction relationship; it cannot make every appearance identical.','Magenta ringonefronttemplate and twocorrespondingcopiesdifferentturnandscale, eachhighmagenta bead. No biologyspeciesclaim.'),
    ('They have not all become the same physical size: a tall template remains tall beside a low one.','SIZE OFF matchedbedlocations, talltemplateandlowtemplate retaindifferentheight, copiesofSAMEtemplateequalbasescale. caption notimply allsizeequal.'),
    ('They were never mushrooms that died.','Greycandidate markers inclearings amongbed; no corpses. LabelREJECTED. Magentaselectedactualbodies distinctgreyemptypositions.'),
    ('You did not need a luckier draw to find the branches.','Pairedsameflat silhouette dress41: FORMSOFFordinarypleatedhem, FORMSONgarmentbranchesextending. Exactdressnumber41both, same sixarrivalplaces. No livingmovingnew3Dbody.'),
    ('Which possibility would you want to add to this wardrobe?','Triohare-headedcouturefigures same seeds41/42/43 shownsheath thenseparate GARMENTcrinoline inset. Shapesbasedavailableconstruction, notsampledseventhtemplate. Companionandstudentlook.')],
    'The sampled sizes never grow a seventh template between two others.',
    'Recipes are not species. Size comparison preserves template proportions; grey marks are refused candidates. Flat arrival silhouettes acquire outlines, not walking or refusal capabilities. Couture construction change need not preserve all drawn details.')

add('neighbours','Random_Space_Geometry','WHAT A NEIGHBOUR CAN TELL YOU','Space Geometry',
    'Two height grids share a palette. Frequency reshapes the coherent field while independent heights stay.',
    'Independent and spatially related samples differ, even with comparable displays.',[
    ('What makes neighbouring random heights belong together?','SidebysidecolumnsgridsWHITE NOISE / PERLIN NOISE, sameheightscaleandbluegreenwhite ramp. Independentsharpheightsvscoherentbroadfeatures, museumcomparisonbench.'),
    ('Describe the difference before calling either one a landscape.','Studentlooksclosely3adjacentcolumns eachside, separate SCHEMATICheightprofiles withsameverticalscale. No realtreeswaterrockappearing.'),
    ('not one of its columns moves.','Matched BEFORE/AFTERFREQUENCY: whitegridexactlyunchanged, coherent broadhilltosmallerfeatures. SEED41same. Frequency slideronlycoherentresponse.'),
    ('OCTAVES, beside it, lays finer layers of Perlin noise over the broad shape; the white side ignores that slider too.','OCTAVES adjustment, coherent broadfeaturesgainfinervariation, leftunmoved. Tinyoverlays showlayerdetailnotseparatephysicalterrain.'),
    ('Independent draws can produce a chance run of similar heights,','Studentfindsthreechance-near-equalwhitecolumns, thenlooksfartherdifferentheights. No patternproofbadge, notallwhitesamplemaxjagged.'),
    ('These are height fields with a colour mapping, not miniature geological histories.','Wideviewbothexperiments onbenchinsidepalemuseum, studentawewithoutliteralminiaturegeology. Nearbyrandomshapeslinkednotallnearest-neighbourlinks.')],
    'You are changing a rule about relationships in space, rather than choosing every column individually.',
    'One fixed height scale and shared palette support comparison, not identical distributions. Frequency and octaves do not change independent grid at fixed seed. Diagrammed features are illustrative, not geological history.')

add('jobs','Randomness_Examples_of_Randomness','FOUR JOBS FOR CHANCE','Examples',
    'Paint marks, counted samples, permitted pipe turns and particle updates share a name while doing different work.',
    'Locate exactly where uncertainty enters each construction.',[
    ('Each gives chance a different job.','Museumfourbaysfloorpaintingrightdartboardleftpipestudyrearparticles. Adultsbetween, nohistoricalPollockportrait.'),
    ('It replays a procedure;','Floorcanvas2Dpaintmarks, small3DcursorretracealreadyPAINTEDline, nophysicalpaintdropsfromcursor nohandholdingbrush.'),
    ('Here chance chooses the evidence.','Squareboardinscribedcircle,dotsinsideoutside, THROWpushbuttonnotphysicaldart. SIMPLEinsetinside3total4estimate3, clearlyWORKED EXAMPLE. Counterupdates3/4not3/3.'),
    ('A growing sample does not require every new estimate to improve.','WORKED EXAMPLE nextpointINSIDE->4/5estimate3.2thenOUTSIDE->4/6estimate2.667; distancefrompi worsensatsecondstep, no monotonicconvergencearrow.'),
    ('It does not keep a list of occupied cells, so crossing an earlier route is allowed.','Cyanmagentaaxisalignedpipe180segmentrun cropped, later differentlycolouredroutecomesnearearlierrun withcrossingallowed. No selfavoidance prohibition.'),
    ('These are five sketches of different procedures, not five strengths of the same white noise.','Sameboundedparticlepopulationin separated CHAPTERinsets randomforces / sines / spiral / neighbours / target. No newbreedingbodies, fivechapterlabelsnotnoiseintensity.')],
    'In every case something decided what a random choice was permitted to change.',
    'Paint is a generative homage with a replaying cursor. Dartboard arithmetic is an explicitly worked example; marks and counts have different retention. Pipes do not avoid visited cells. Particle chapters are not breeding or five amounts of white noise.')

add('scent','Random_Pheromone','A VISIT HELPS CHOOSE A VISIT','Pheromone',
    'Four walkers leave a changing signal and a lasting ridge. Another rule reads the same kind of mark as something to avoid.',
    'A record becomes guidance, while scent and surface retain different histories.',[
    ('What changes when a walker helps make the evidence its next decision will read?','Fourcyanwalkermarkers onraisedterrain, compactATTRACT+1STEPconsole. Nofood,nest,deliveryants orrouteendpoints.'),
    ('A path can therefore become established partly because it has already been used.','Earlier andlaterlocalpatch views onevisitdeposit thenothercyanmarkerfavoursstrongerscent. SCHEMATIC scentoverlay translucent, clearlynot livevisiblecolour. Label signal-guided40% separate.'),
    ('The mark has become part of the mechanism.','Smallschematic cycle VISIT->SCENT->LATER CHOICE->VISIT arrowleftreturns, no circularclaim shortestpath. Studentlookingat actualpatch besideinset.'),
    ('Pheromone decays; the surface records accumulated visits in another form.','Matchedpatch earlierbrightSCHEMATICscent laterdim; ridgeheightremains. SeparateCURRENT SCENT / RETAINED HEIGHT insets, notterraincollapsingwithsignal.'),
    ('The procedure rewards a particular local signal,','Companionfollowsconcentratedridge, no optimalroutebadge. Equal-reading tiny8directioncompass marks FIRST listdirection withnonrandomtie; nofoodrewardobjects.'),
    ('this time the signal-guided choice favours the weakest scent.','AVOIDpressed, experimentresetpatchflat thenat SAMESTEPcountnewdispersedvisits comparedATTRACT. Nooriginalridgepersistinginthe newresettrial, not guaranteecompleteavoidance.')],
    'Distinguish what you can see from what the movement rule reads.',
    'Scent overlays are explanatory, not an invented runtime display. Forty percent signal-guided does not mean every movement follows scent. Ridge history differs from decaying signal; AVOID restarts comparison, no optimal-route claim.')

add('layers','Random_Space','LAYERS THAT LOOK LIKE LAND','Space',
    'A finite sum gains smaller variations. Violet independent heights and blue distance seams offer other neighbourhoods.',
    'A layered sine field, independent random corners and cellular distance differences are distinct.',[
    ('How much of a landscape can be made by repeating a rule at different scales?','Earth-tonedimageonmixerplinth, visitorleanscloser. Noactualmountainswater, warmmuseum, violetunevensurfacefloor fromreference.'),
    ('finer variations appear around it rather than assuming each new layer replaces the previous one.','SchematicOCT1thenOCT4samebroadfeatureadditionaldetail, matchingSEED,LAC,PER. Separateimageframesnotgeology.'),
    ('unlike the terrain in the last room, this field keeps no history of the settings you passed through.','OCTback1samepictureasfirstexactbroadfeature. Companionlooksfromwindowintomuseumnotweatherlandscape.'),
    ("one corner's height tells you nothing about the next.",'Close violetfloortriangles independentcornerheights, roomperspectivefromreference. Smallsolidtriangleverticesnotlegendedsmoothcorrelation; greyfloormarginstays.'),
    ('Along a seam those distances nearly agree.','Bluecellularfieldlowstandfromreference, separateinsettwoSCATTEREDsites andpointseam withtwoEQUAL distances. Use actualbisector: sites(-1,0),(1,0), witness(0,1), equallines. ValueF2-F1 zeroatwitness.'),
    ('It counts its own two hundred symbols; it is not measuring either field around it.','Separateentropyinstrumentfurtheralongroom; no arrowfromfloor/texturetogauge. Studentlooksfrommixerbacktogauge, fieldsstillavailable.')],
    'The picture remaps its range,',
    'Mixer is finite sine sum, not Perlin or geology. Each texture normalizes its own range. Violet corners are independent; blue seams compare nearest and next-nearest distances. Entropy gauge samples its own symbols.',
    ('doc/book/figures/randomness/cellular-field-violet-ground.png',))

add('time','Random_Game','DECIDED, OR NOT YET DRAWN?','Game',
    'A stone carries a sampled deadline. Three passages separate drawing, revealing and choosing; the consequence is made into walking.',
    'Known state, concealed assignment, future draws and bodily provision must remain separate.',[
    ('The order may already feel familiar while the pauses refuse to settle into a beat.','Threecyansteppingstonesacrossshallowrectangularpit, smallrampfirststone,gapssmall12cm, bed1m below,museumroutearound. Observerstaysonlip. Separatefourstateglyphs STANDS LEAVES GONE RETURNS.'),
    ('The current pause has already been chosen. The next one has not yet been drawn.','Tabletwithsampledwait3.6s, remaining1.0s. SAMEdrawnotnewdurationeachframe. Goldwarningringstone, smallnumbernotenormoustimeruniverse.'),
    ('This experiment changes the notice carried by the stones; it does not remove every way to anticipate them.','CUEOFF goldringgone,tabletstillthere; movingstonebeaconremains. No invisiblefloororblackout. Observerssafeonlip.'),
    ('Knowing does not prescribe what you must want.','SHOWN FIRST smallpassage withA DIRECT/B AROUNDalreadyrevealed. StudentchoosesBlongerroute,palesolidwallrequirescorner. Bothlanesreachfarend, notfiredoorsinthistrial.'),
    ('Your chosen letter stays chosen while its meaning arrives.','DRAWN AFTER bothA/Binitial?, footchoosesA. Separatechronology CHOOSE->DRAW->REVEAL aboveentrance. No actualdrawpriorchoiceinthispanel.'),
    ('Something has happened without becoming available to you.','HIDDEN FIRST bothsigns? beforefootstep; chronology DRAW alreadyfilled, then CHOOSE->REVEAL. Smallseparatepairdiagrams displaysame? butstates DRAWN AFTER notdrawn vs HIDDEN FIRST drawnconcealed. Actualtwoletterplates unchanged.')],
    'The draw did not make the distance. We built that consequence around it.',
    'Wait readout illustrates one permitted draw, not a runtime measurement. The passage trial has two routes and no fire; the distinct earlier three fire doors are outside this selected plate. A cue changes access, not timing. Bypasses and recovery bed remain available.',
    ('doc/book/figures/randomness/waiting-and-seeing.png',))

canonical=json.loads((ROOT/'commons/maps/sequences/randomness.json').read_text(encoding='utf-8'))['sequences']['randomness']['maps']
assert [p['map'] for p in plates]==canonical
(HERE/'randomness-plates.json').write_text(json.dumps(dict(date='2026-10-06',scope='Fourteen canonical Randomness halls, selected final-text encounters.',plates=plates),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Verified 84 panel excerpts and 14 footers against fourteen complete chapters; preserved source snapshots.')
