"""Editorial matches, not keyword scores. Artist descriptions come from SOURCE-INDEX.txt."""

PROFILES = {}
def profile(key, title, artifacts, capabilities, home, operation, limit, probe):
    PROFILES[key] = dict(id=key, title=title, artifacts=artifacts.split(), capabilities=capabilities.split(),
                         proposed_home=home, operation=operation, limit=limit, probe=probe)

profile('hinge','Articulate joined planes','bicho_hinge','face rotation constraint','Transformation → Form Finding',
        'Nested plate transforms, bounded hinge angles and XR hinge/handle wiring.',
        'An articulated construction with a fixed root. The hinge-and-return companion now tests desktop dragging and release. No physical XR trial, gravity settling or plate-collision rejection is established.',
        'Change one hinge limit; release a plate and check which poses remain reachable.')
profile('bend','Bend a surface without changing its connections','fold_wall','mesh rotation','Primitives mesh → Transformation; return in Form Finding',
        'Fixed triangle connectivity; vertex positions rotate in a cascade with an authored sine billow.',
        'The inspected fold wall is a set of built stages. Its drape is a formula, not cloth settling under force.',
        'Hold vertices and faces fixed; vary fold amount and compare the silhouette and passage.')
profile('cloth','Hang and settle a connected sheet','cloth_simulation cloth_loom cloth_straps','array force constraint soft','Soft Bodies',
        'Spring-grid cloth, pinned points, gravity, wind and hanging SoftBody strips.',
        'Different solvers and collision models. Self-contact, tearing and material accuracy require separate checks.',
        'Move one pin or change stiffness; compare the settled shape with the same gravity.')
profile('soft','Let a body deform or retain a settled form','rounded_softbody frozen_glass_vessel','mesh force constraint soft','Soft Bodies / Form Finding',
        'Deformation with pressure/strain readouts; a vessel built by a finite settling pass.',
        'A bounding-box volume proxy is not enclosed volume. A frozen settled mesh is not a continuously live body.',
        'Keep the mesh and loading fixed; compare pressure feedback on and off.')
profile('repeat','Repeat an element and expose a small deviation','molnar_cube_study agnes_martin_grid_painting','array transform','Arrays / Tiling',
        'Fixed indexed frame sites with repeatable deviations; a separate low-contrast procedural line grid.',
        'A resemblance to a grid does not establish the historical work’s actual score or material procedure.',
        'Hold every address fixed; change one offset or the line contrast.')
profile('suspend','Keep addresses while fragments change','reference_suspension','array mesh','Arrays → a return through Randomness',
        '75 generated fragments at retained positions, with vertical rods and a variation control.',
        'A verified standalone geometry study; no fracture history, dynamic suspension or installed spine placement.',
        'Change the fragments and verify that every centre stays put.')
profile('assemble','Pick up parts and compose an arrangement','found_object_assembler','instances transform xr','Colour / composition',
        'XR-pickable primitive offcuts and an assembly table that claims and snaps resting fragments.',
        'Parts are generated offcuts, not an arbitrary archive importer or automatic Boolean union.',
        'Place the same seven pieces twice; change only one placement constraint.')
profile('network','Grow or reconnect a spatial graph','rhizomatic_structure','line array growth graph','Procedural Generation / Graphs',
        'Seeded node positions, branching and optional lateral reconnections drawn as branches.',
        'Drawn edges do not provide tensile mechanics, knots, provenance or navigable clearance by themselves.',
        'Keep the nodes; remove lateral links and compare connected routes.')
profile('void','Use one void to make a room and a positive','facade_room_cast','enclosure boolean','Boolean Surfaces',
        'One interior definition feeds CSG subtraction and intersection, with collision enabled.',
        'A digital positive from a shared volume; physical casting, demolition and the history of a dwelling are not simulated.',
        'Move one opening and check that both the room and positive retain its trace.')
profile('reflection','Return the actual viewer through a surface','super_drag_mirror mirror','transform light shader','Colour for appearance; Shaders for the rendering apparatus',
        'The wardrobe mirror uses a reflected camera and off-axis frustum in a shared-world viewport.',
        'The generic mirror prop only assigns a metallic material. The working planar camera does not supply curved or recursive mirrors, or stereo-per-eye XR reflections.',
        'Move the actual camera sideways and check reflected parallax before multiplying mirrors.')
profile('planes','Make overlap and passage through coloured planes','color_constellation_office','colour light transform','Colour / Color_Walls',
        'The planes layout separates coloured sheets, routes and work positions; filter/opaque comparison retains geometry.',
        'Layered alpha tint, not spectral transmission or an optically accurate two-way mirror.',
        'Take one sideways step, then switch opacity without moving the partitions.')
profile('light','Build a room around changing illumination','colour_light_rooms','light colour_space','Colour',
        'A white chamber with a central changing light; connected apertures with luminous rims, lights and a ramp.',
        'Rendered illumination and open geometry, not a measured psychophysical Ganzfeld or a volumetric mist model.',
        'Hold surface colour fixed while changing the source; compare at two eye heights.')
profile('trace','Retain the movement of a specific input','head_trace_projection','coordinates trace','Primitives / Point Trace',
        'Headset or labelled desktop-camera samples retained as a spatial path and floor projection.',
        'Head/camera position includes locomotion. It is not foot tracking, mocap, biometric sensing or evidence of lived experience.',
        'Repeat a walk; distinguish measured position, projection and the gaps in sampling.')
profile('passage','Make a dimension into a condition of passage','reference_passage scale_me','scale threshold xr','Transformation / Scale and Body',
        'A variable opening tested against a fixed capsule; scaling an authored furnished room.',
        'One chosen collider is not a universal body. An opening-width test cannot stand in for a real social border.',
        'Keep the visitor collider fixed; find the smallest opening it can cross.')
profile('body','Assemble a synthetic body and change its pose','reference_plural_body super_drag_mirror','instances transform shader_body','Primitives as parts → Shaders / Queer Rubber',
        'A six-arm, three-head primitive construction with an unfolding parameter; a separate actual-player wardrobe.',
        'The plural body is a geometric pose, not a rigged avatar, face scan, soft-body solver or authored choreography.',
        'Keep the parts; alter their attachment or pose and identify what must become jointed.')
profile('surface','Let a rule move across surfaces','reference_pattern_garden glitch_mirror','pattern shader shader_body','Shaders',
        'Shared pattern coordinates across room and flowers; a procedural RGB-triad/banding display.',
        'A generated glitch image is not actual codec corruption; a surface effect need not change collision.',
        'Freeze geometry; move the shared pattern and follow one boundary between objects.')
profile('agents','Let local state continue to change a world','ecosystem_simulation boid_manager','motion array agent','Swarm Intelligence; broader ecology in Procedural Generation',
        'Predator/prey/food updates and local flocking rules, with authored configuration and population controls.',
        'Simplified agent rules and sometimes a stabilising restock policy; not an open-ended trained-agent world.',
        'Hold the seed; disable one stabiliser or local rule and compare population history.')
profile('learning','Distinguish a learning diagram from a trained model','neural_networks_vr generative_adversarial_networks_gans_vr','learning network learned_memory','Machine Learning',
        'Spatial network and GAN-role diagrams are present; their construction and animated metrics can be inspected.',
        'The inspected GAN code advances illustrative losses with time and trains no model. A dataset-to-generative-image pipeline is not established by these artifacts.',
        'Demand a real input, saved weights, a computed loss and a held-out output before calling it training.')
profile('signals','Put a retained record or live view on displays','signal_room monitorsystem','array tile clock_pattern random','Arrays → Randomness; monitor rendering is borrowed',
        'A verified whole-room binary-array study; a separate multi-camera viewport monitor system.',
        'The signal room contains a synthetic balanced inventory, not Ikeda’s encoded source data. Neither is a video editor or a biometric input device.',
        'Keep the inventory, change neighbours, then state which display pixels came from which source.')
profile('inscribe','Make a mark or a text field persist','ball_painting_demo running_text_display','trace inscription','Primitives trace → Colour / Paint',
        'A paint surface with explicit world-to-UV mapping and spray marks; a scrolling text viewport.',
        'A visible mark is not an authenticated archive, and a scrolling string is not a spatial narrative editor.',
        'Retain one mark; move the surface or viewer and check what coordinate system owns it.')
profile('sound','Play a spatial sound and inspect a captured signal','soundboxes sound_timeline','loop sound trace','Wave Functions / Sound',
        'SoundBox requests a stream from SoundBank and plays it through AudioStreamPlayer3D. The timeline separately captures the Master bus and draws a retained sample buffer.',
        'SoundBox needs the SoundBank autoload and a valid collection. The timeline playback flag only advances its display: no captured-audio replay is wired. Its function named FFT averages time-domain samples, not spectral bins. Recording provenance and testimony are additional work.',
        'Trigger a known SoundBank sound and compare its spatial playback with captured samples; implement and verify replay before describing the timeline as a recorder.')
profile('power','Expose an authored rule of seeing or refusal','surveillance_panopticon refusal_booth','threshold proxy situation','Critical returns; main placement must follow verified hosts',
        'An asymmetrical tower/cell arrangement with changing cone emphasis; a refusal record display.',
        'The inspected cones are visual apparatus, not proof of actual surveillance detection. A staged rule does not recreate labour, violence, ownership or collective politics.',
        'Name the actual rule, the person or object it acts on, and the evidence the apparatus records.')
profile('terrain','Turn a sampled field into a surface','noise_terrain','noise field_body','Noise → Procedural Generation',
        'Seeded noise is sampled as mesh height with a terrain-collision construction path.',
        'Generated topography is not a surveyed site or a landscape’s social/ecological history.',
        'Change one field parameter while retaining the seed and compare visible height with support.')
profile('gravity','Make a force assumption visible','gravity_well cloth_simulation','force motion constraint','Forces → Form Finding → Soft Bodies',
        'Particles accelerate along an authored surface gradient; cloth has explicit gravity and constraints.',
        'The well is a force analogy, not general relativity. Buoyancy, tensile architecture and a traversable slide need their own mechanics and tests.',
        'Hold initial state; vary one force and record both motion and its retained path.')

# Each source occurrence is retained. Dan Graham legitimately appears twice.
# category | artist | capacity profiles | judgement | smallest useful next work | what the match must keep open
ROWS = '''
01|Lygia Clark|hinge|reuse|Use the hinge-and-return companion: compare retained and restored poses, then two corner paths to the same pose.|The fixed support and kinematic angles remain our decisions; physical weight and contact are the next investigation.
01|Susan Weil|bend inscribe|compose|Place one image on a deformable plane and retain the same UV coordinates through a fold.|A fold must act on the image as well as its supporting geometry.
01|Ulla Viotti|bend soft|compose|Compare an authored curved sheet with a frozen settled mesh.|A rigid result can suggest bending without claiming ceramic behaviour.
01|Martin Puryear|bend network|compose|Make a curved frame from connected segments and expose its joins.|Keep construction and material labour visible; a spline alone is insufficient.
01|Dan Graham|planes reflection|develop|Add a verified reflected view to one transparent partition before curving it.|Alpha overlap is not simultaneous optical reflection and transmission.
01|Richard Serra|bend passage|compose|Enlarge an authored bent surface and test the walking clearance around it.|Navigation requires a matching collider; steel weight is not supplied by a grey material.
02|Claes Oldenburg|soft|compose|Give a familiar rigid prop a matched deformable version under the same load.|The translation depends on recognising the original object as well as seeing softness.
02|Eva Hesse|cloth|reuse|Change one suspension point in a row of hanging sheets.|Use sag and relation; do not claim the solver reproduces the work’s materials or ageing.
02|Magdalena Abakanowicz|cloth passage|compose|Scale a hanging sheet around a walking route and compare two support arrangements.|Body scale, enclosure and fibre thickness need more than a flag preset.
02|El Anatsui|cloth repeat|compose|Attach repeated small plates to a simulated supporting sheet.|A sheet solver supplies motion, not the construction or history of assembled metal units.
02|Do Ho Suh|cloth planes|develop|Sew a translucent room from panels with explicit seam constraints.|The project has sheets and transparency; architectural cloth seams and room-specific memory still need development.
02|Jeanne Silverthorne|soft body|compose|Compare the same synthetic body under different stiffness and damping.|Material response should be felt, not inferred from a rubber shader.
02|Jessica Stockholder|assemble cloth|compose|Let a found part rest against one support and hang another from a pin.|Balance must arise from the tested attachments rather than a frozen screenshot.
02|Sheila Hicks|network cloth|develop|Start with a small bundle whose strands share a support and collide.|Drawn tubes are available; knotting, strand contact and pile behaviour are not established here.
03|Yayoi Kusama|repeat reflection inscribe|develop|Make a repeated field with accumulating marks before attempting recursive mirrors.|A single planar reflection does not supply an Infinity Room; bodily scale and participation remain separate questions.
03|Mona Hatoum|suspend|reuse|Use the existing fragment variation at fixed grid addresses.|Keep the fragments and support relations legible; repetition does not explain their material associations.
03|Tara Donovan|assemble repeat|compose|Accumulate one ordinary unit and change only the local packing rule.|An authored pile is not yet an emergent packing process.
03|Agnes Martin|repeat|reuse|Use the existing line grid and vary only opacity, spacing or line width.|The current grid is exact and procedural; material irregularity and sustained looking need a separate choice.
03|Ryoji Ikeda|signals|reuse|Use the whole-room repeat/row-shuffle/cell-shuffle comparison.|The current values are synthetic; source-data encoding is a later, distinct operation.
03|Casey Reas|agents repeat|compose|Expose one local decision and its accumulating field.|Choose a declared rule and state; do not label arbitrary particle motion an implementation of a supplied artwork.
03|Vera Molnar|repeat|reuse|Reuse the nested-frame study’s translation, rotation and scale controls.|Preserve the distinction between a retained deviation and fresh random sampling.
03|TeamLab|inscribe agents light|develop|Connect one measured visitor input to one retained mark and one response.|Whole-room multi-person sensing and long-lived interaction still need explicit input and persistence design.
04|Robert Rauschenberg|assemble inscribe|compose|Attach a retained image surface to an assembled group of offcuts.|The source and previous use of a found object cannot be replaced by a generic primitive without saying so.
04|Jason Rhoades|assemble network|compose|Let a cable network and a dense arrangement compete for a walking route.|Increase density while measuring access; clutter is not itself a social account of objects.
04|Sarah Sze|assemble network trace|compose|Keep small parts fixed while one connection or sightline changes.|The apparatus must make relations inspectable instead of adding arbitrary detail.
04|Cornelia Parker|suspend assemble|compose|Suspend a selected set of fragments and vary one outward displacement.|Current fragments are generated shapes, not remains of a simulated or historical explosion.
04|Chiharu Shiota|network passage|compose|Stretch a declared connection graph across a room and keep a route through it.|Drawn edges need their own collision, textile character and object associations.
04|Thomas Hirschhorn|assemble inscribe|research|Stage one actual document and its supporting structure before multiplying material.|The social and political address of information must be authored; density alone is a weak match.
04|Bill Woodrow|assemble void|develop|Keep an object’s source mesh alongside the piece cut from it.|Arbitrary-mesh cutting and a retained cut lineage are not supplied by the current offcut table.
04|Laris Strunke|repeat inscribe|compose|Break the continuity of one drawn grid while retaining its earlier state.|Identify the particular work before claiming which pictorial operation is being translated.
05|Rachel Whiteread|void|reuse|Reuse the room/positive pair and alter the same opening in both.|The digital volume is available; casting process, dwelling and loss remain outside that calculation.
05|Anish Kapoor|void reflection|develop|Compare a real cavity with an apparent depth made by a surface.|Curved live reflections and a calibrated depth illusion are not furnished by the flat mirror.
05|Antony Gormley|body passage repeat|compose|Repeat a chosen body volume, then test the intervals it leaves.|The chosen volume must be declared; one capsule cannot represent every body.
05|James Turrell|light|reuse|Use the changing white chamber and open ceiling levels with two fixed viewpoints.|The light and geometry are available; perceptual effects require viewing tests rather than an artist label.
05|Olafur Eliasson|light reflection|compose|Hold a visible light source fixed while changing the receiving atmosphere or view.|A mist field is additional work; illumination is not a physical weather model.
05|Dan Graham|planes reflection|develop|Compare seeing through a pane with seeing a reflected camera on it.|The two mechanisms exist separately; optical integration and curved geometry remain unbuilt.
05|Liz Deschenes|surface reflection|research|Make one surface change with viewpoint and disclose its rendering rule.|Choose a specific photographic operation; a shiny shader is not photographic materiality.
06|Marina Abramović|trace sound|research|Retain duration and one measured action without scoring endurance.|A timeline cannot substitute for a performer’s body, risk or relation to an audience.
06|Janine Antoni|soft inscribe|develop|Let one bodily input permanently deform or mark a material proxy.|Persistent contact-driven sculpting needs more than a returning soft-body animation.
06|Stelarc|body trace|develop|Drive one added limb from a declared controller channel.|A procedural limb is not yet a controlled extension or a distributed agency experiment.
06|ORLAN|body surface|research|Compare an avatar’s chosen surface with its recorded source and authoring decisions.|A material switch does not reproduce surgical performance or its stakes.
06|Nick Cave|body sound|compose|Attach an authored costume to the real player and map motion to sound.|The wardrobe supplies attachment, not a Soundsuit’s materials or cultural account.
06|Pope.L|passage trace|research|Document ground contact and route constraints for a declared virtual body.|Do not turn a crawl work into a low-height obstacle course and call its politics reproduced.
06|Lena Cronqvist|body assemble|research|Arrange a small set of figures whose scale and gaze can be changed.|Identify the specific work and relation before treating a doll-like mesh as an adequate translation.
06|Nathalie Djurberg|soft body|develop|Author one consequential transformation and retain its stages.|Deforming a mesh supplies no stop-motion timing, character or narrative by itself.
07|Pipilotti Rist|light signals|compose|Project an authored moving-image surface into a coloured room.|Live camera monitors are available; licensed source imagery and projection mapping need their own workflow.
07|Ann Hamilton|cloth sound inscribe|compose|Link one repeating action to a cloth response, a sound and a line of text.|Keep the action and its timing meaningful; synchronised effects alone are insufficient.
07|Carsten Höller|gravity passage|develop|Build one slope with a matching collider and compare descent under a fixed body.|A gravity demonstration is not yet a comfortable, traversable VR slide.
07|Jaume Plensa|inscribe body sound|compose|Arrange legible letter forms around a declared body volume and listening position.|Scrolling text exists; a letter-built envelope and authored sound/silence must be constructed.
07|Laurie Anderson|sound signals trace|develop|Keep one voice passage, viewpoint and event on a replayable timeline.|The inspected audio apparatus is not a complete spatial narrative authoring system.
07|Nam June Paik|signals|compose|Arrange existing camera monitors so the recording apparatus is part of the scene.|A camera feedback loop needs a bounded render design and an explicit relation between subject and image.
07|Zach Lieberman|trace inscribe light|compose|Map one measured gesture to one visible or audible response.|First disclose what the input really measures; camera motion is not full gesture recognition.
07|Daniel Rozin|signals reflection|develop|Sample a live camera image and drive a coarse array of moving elements.|The viewport and array exist; luminance-to-actuator mapping and physical response remain to be built.
07|Jim Campbell|signals repeat|compose|Map a retained image to a sparse array of light sources.|A flat texture is available; the spatial light arrangement and image reconstruction task are new.
08|Ian Cheng|agents|compose|Make a small world that keeps a state history while the viewer leaves and returns.|Current local rules are available; narrative agents and persistent world history are separate work.
08|Refik Anadol|learning signals|develop|Start with an explicit dataset manifest and a real inference output sent to a display.|The GAN diagram is not a dataset-trained visual model.
08|Mario Klingemann|learning signals|develop|Connect a documented model to a retained sequence of generated outputs.|Continuous production requires actual inference and provenance, not animated loss labels.
08|Sofia Crespo|learning body|develop|Compare a procedural organism with an output from a declared image model.|Do not relabel procedural morphology as neural generation.
08|Anna Ridler|learning inscribe|develop|Build an inspectable dataset-selection table before connecting a model.|Training data, annotation decisions and source permissions are not present in the inspected learning diagram.
08|Marina Zurkow|agents surface|compose|Let one ecological relation change a visible state that persists over time.|Name restocking and boundary policies; the simulator is a chosen ecology.
08|Tabor Robak|surface agents signals|compose|Combine a live procedural world with its visible rendering and timing controls.|Visual polish and game-engine behaviour are different capacities and should remain inspectable.
08|Rafael Lozano-Hemmer|trace signals|develop|Begin with a labelled simulated pulse input, then design a real sensor adapter.|Headset position is not a heartbeat; biometric acquisition and consent need their own implementation.
09|Jacolby Satterwhite|trace body assemble|develop|Keep a drawn source alongside one figure generated from its geometry.|Drawing-to-form lineage and authored choreography are not delivered by the generic body assembly.
09|Jonathan Monaghan|body surface planes|compose|Arrange familiar synthetic objects with one precise architectural rule.|A material library does not itself supply the narrative carried by the reference’s objects.
09|Jesse Kanda|soft body|develop|Make one connected body deform through a deliberately authored sequence.|The current multi-part pose is not a continuous anatomical mesh or finished animation system.
09|LuYang|body signals|develop|Bind an avatar’s pose, movement and selected state to explicit controls.|A controllable rig and sourced iconography must be authored; the plural-body study does not provide them.
09|Jon Rafman|signals passage|research|Study one chosen virtual-world convention through a room and a retained view.|Specific subcultures, sources and simulated subjectivity cannot be inferred from a generic VR room.
09|Eva Papamargariti|body surface agents|compose|Let a procedural organism and its material respond to the same state.|Name the state and response rather than using hybrid appearance as the whole argument.
09|Mike Pelletier|body soft|develop|Drive deformation with a retained motion sequence and compare two interpretations.|A motion source, rig correspondence and deformation mapping are still required.
09|Kouhei Nakama|body surface agents|develop|Move from a posed body to one growth rule with retained state.|A surface shader does not implement morphogenesis.
09|Cool 3D World|body soft gravity|compose|Give a simple body a collision-driven event with an authored recovery.|Slapstick needs timing and consequential contact, not only a distorted mesh.
09|Pussykrew|body surface|reuse|Reuse the existing plural-body study and vary the attachments or skin rule.|This is an original geometric companion, not a rigged reconstruction of the reference.
09|Morehshin Allahyari|assemble inscribe|research|Pair one sourced object with a visible record of who supplied and interpreted it.|An arbitrary archive importer and a political counter-archive are not established by an assembly table.
09|Rosa Menkman|surface|compose|Expose a quantisation or channel operation and preserve its unprocessed input.|The current glitch panel is synthetic; actual format failure must be implemented and named separately.
10|Rirkrit Tiravanija|assemble passage|research|Define what visitors can do together before placing any furniture.|A single-player arrangement cannot certify a relational social situation.
10|Suzanne Lacy|trace agents|research|Begin with a participant-authored score and compare it with any simulated agent version.|Boids are not human collective participation or public choreography.
10|Santiago Sierra|power passage|research|Make one stated exclusion rule and its record inspectable.|A collider is not labour, payment or institutional power; these require an authored situation.
10|Hans Haacke|power inscribe|research|Show a sourced ownership or institutional relation as an inspectable record.|A provenance claim needs actual external evidence; a procedural graph alone is insufficient.
10|Lawrence Abu Hamdan|sound trace|develop|Link one recording to a spatial listening test with retained source metadata.|The audio timeline is not a forensic evidence chain or a testimony interface.
10|Teresa Margolles|inscribe soft|research|Define the material trace and its source before choosing a visual proxy.|A generic stain would erase the specificity the supplied index asks us to retain.
10|David Hammons|assemble repeat|research|Stage a declared exchange around an ordinary object rather than only its arrangement.|An object’s social code and circulation need context, actors and authorship.
10|Amanda Williams|planes inscribe|compose|Attach one chosen colour to a documented place and keep that relation visible.|Colour coordinates do not supply the architectural and territorial account.
10|Ronald Rael + Virginia San Fratello|hinge passage|develop|Couple two sides of a barrier through one shared mechanical action.|The project has joints and thresholds; two-person coupling and the border situation are additional requirements.
10|Chto Delat|power sound inscribe|research|Start from a collective script with room for disagreement and revision.|A sequence of prompts is not collective political pedagogy by itself.
11|William Kentridge|trace signals sound|develop|Retain drawn states and synchronise their replay with one mechanical or sound event.|A mark recorder is not yet a multi-channel staged montage system.
11|Hito Steyerl|signals power|research|Let a visibility rule affect a retained image and disclose who set the rule.|Camera views and opacity do not by themselves account for surveillance or image circulation.
11|Harun Farocki|signals trace power|research|Record the same simulated action from participant and observer views.|The training apparatus, task and consequences must be specified; generic game footage is insufficient.
11|Camille Henrot|signals inscribe|develop|Build an authored set of image/text sources with visible montage decisions.|A viewport does not supply archive selection, sequencing or source provenance.
11|Arthur Jafa|signals sound|research|Define the licensed image sequence and temporal relationships before choosing displays.|Image intensity and Black visual culture cannot be reduced to a contrast or playback parameter.
11|Ryan Trecartin|body signals sound|develop|Synchronise one authored avatar event, voice track and camera cut.|The required performance and editing system exceeds the current monitor apparatus.
11|Kara Walker|inscribe body light|research|Construct one legible silhouette and state the narrative and source it carries.|Monumental scale or shadow alone does not recreate the work’s historical address.
11|Mary Reid Kelley|body inscribe signals|develop|Bind a figure, graphic set and authored text to the same timed event.|A complete performance, language and scene-sequencing system is still required.
11|Peter Greenaway|assemble signals light|compose|Arrange a fixed tableau with two authored views and an explicit timing relation.|The components exist; a sustained image architecture requires editorial sequencing.
12|Tomás Saraceno|network cloth gravity|develop|Test one tensioned network before adding flotation or a room-scale enclosure.|Drawn webs do not establish load paths; buoyancy and coupled air/structure behaviour need new mechanics.
12|Maya Lin|terrain inscribe|compose|Cut or inscribe a declared path into a sampled landscape.|Use a real site dataset if the work depends on one; procedural terrain is not a survey.
12|Mirosław Bałka|passage assemble light|reuse|Reuse the passage study and give one threshold a precise relation to the body.|It is a new width experiment; memory and the specific reference are not contained in that dimension.
12|Cildo Meireles|sound passage assemble|compose|Make two sound fields and an obstructed sightline share a navigable room.|A multisensory arrangement needs actual source, scale and overlap tests.
12|Superstudio|repeat terrain|compose|Carry one grid across several surfaces and expose what it overrides.|A continuous pattern is only the starting point; the speculative claim must be written and spatially tested.
12|Monika Bielskyte|agents passage assemble|research|Choose one worldbuilding assumption and give participants a way to change it.|Protopian futures are not a visual style or a procedural-biome preset.
12|Keiichi Matsuda|signals inscribe passage|develop|Attach competing information layers to the viewer and the room, then test occlusion.|A registered AR/interface layer and its attention rules are not supplied by fixed monitor screens.
'''.strip()

STATUS = {
    'reuse': ('Existing operation', 'A specific operation already exists in source. Reuse it for a new study; this is not a claim to reproduce the artwork.'),
    'compose': ('Combine / adapt', 'Useful components exist, but their arrangement, input or relation needs to be authored and tested.'),
    'develop': ('New capability needed', 'Available parts do not supply an essential mechanism named in this proposed translation.'),
    'research': ('Define the encounter first', 'Technical parts exist, but a specific source, situated relation or artistic question must guide their use.')
}

# Attach the implementing source, including nested scenes or inherited scripts.
EVIDENCE_OVERRIDES = {
    'signal_room': [('commons/artifacts/signal_room/score.gd','static func make_values')],
    'agnes_martin_grid_painting': [('commons/context/agnesnatringrid/agnes_grid.gd','func _draw')],
    'cloth_loom': [('commons/soft_body/soft_body_shapes.gd','static func make_cloth')],
    'sound_timeline': [('algorithms/wavefunctions/soundtimeline/SoundTimelineVisualizer.gd','func setup_audio_system')],
    'color_constellation_office': [('algorithms/color/color_mixing/office_planes.gd','func ')],
}

PRIORITY = [
    ('hinge','A pose left after release','Lygia Clark','The hinge-and-return desktop study now compares Leave it and Return it.','Release a plate, then follow two corner paths to the same final pose.'),
    ('cloth','One pin changes the hanging body','Eva Hesse / El Anatsui / Do Ho Suh','Use the cloth solver; begin with pins, then distinguish metal units and sewn rooms as later work.','Same sheet, gravity and initial state; compare one moved pin.'),
    ('void','The empty room becomes the solid','Rachel Whiteread','Reuse facade_room_cast and its shared interior.','Alter one opening; compare both corresponding results.'),
    ('signals','Same counts, different neighbours','Ryoji Ikeda','Use the finished standalone signal-room study after Random_Entropy.','Compare all three permutations; inspect the same 4 × 4 window.'),
    ('planes','A pane becomes a relation between viewers','Dan Graham','Combine the office’s clear routes with one proven planar reflection.','First prove parallax; then test transparency and two viewer positions.'),
    ('assemble','A fragment keeps a record of its source','Rauschenberg / Parker / Allahyari','Use the real offcut assembler; add a source ledger before introducing archive claims.','Move a part and retain its identity, source and changed relation.')
]
