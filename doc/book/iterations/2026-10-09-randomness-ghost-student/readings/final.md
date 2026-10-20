# Randomness — complete reflection

Fourteen halls inside Endless Museum. This chapter follows Wavefunctions and leads to Noise Types. The existing museum supplies the player and environment. Biome Cage remains an unnumbered encounter after Mushrooms; the closing Biome Ladder is deferred.

Read REVIEWER.md for prerequisites, scope and evidence. This is one chapter of a longer course.



---

## 01 · Random_Definition

# A pattern that returns

In Synthesis Lab, five amounts could bring a familiar curve back. Cage had kept a score so that it could be heard again. Here, a number seems to offer another way back.

<!-- @seed_replay_demo -->

Here, two grids of coloured cubes stand above the controls. Choose a small patch you would not have thought to put together. Find it in the other grid.

Press REPLAY.

The colours stay where they were.

The program has coloured every cube again. The seed sets this generator's starting state; start it there again and make the same requests, and the same values return. Press RANDOM, find something in the arrangement it gives you, and replay that one. RANDOM can choose an earlier seed, including the one already here. A result can surprise us and still know the way back to itself.

The seed readout offers a tempting name for the picture. Remember it. Then press +1 DRAW.

The right-hand grid changes while the left keeps its arrangement. The seed has not changed. Look at the cube positions too: nothing has moved sideways to make this difference.

Above the grids, two strips turn the first twenty-four draws into bar heights. Switch the extra draw off, then on. The right strip now starts with the second bar on the left. Find the next two matches.

With the extra draw enabled, the right-hand grid requests one value before colouring its first cube, then leaves that value unused.

Each call requests a number between zero and one. A cube takes three: red, green, blue. One unused draw shifts where that grouping begins:

```text
Draws:       a  b  c  d  e  f  g ...
Left grid:  (a, b, c)  (d, e, f)
Right grid: (b, c, d)  (e, f, g)
```

Nothing in a draw says that it is red. Red is the use made of its place in these three calls.

Look back at your patch. Perhaps the misplaced beginning gives you a relation you want. There is no need to prefer the matched pair. The line that interrupts a demonstration of sameness can also be used to make another palette.

Press +1 DRAW again. The match returns. The button toggles one discarded draw; it does not keep adding more. REPLAY repeats whichever procedure is selected. We needed more than the seed's number: which generator, which calls, and which use of their results. The picture's name had left out part of its making.

Choose another seed, then wait. The room continues around you. Press REPLAY. The same patch returns; waiting has not spent another draw from this generator. Difficulty guessing from a picture and the ability to repeat its construction are different things we can encounter here.

Move the seed slider slowly. The handle travels smoothly; the readout chooses whole numbers. A neighbouring seed can give you a very different palette. At eight by eight, each grid still holds sixty-four cubes with three varying colour channels. Another seed cannot add a cube or let one leave its cell.

The MATRIX slider can change the count. Pull it toward sixteen: more, smaller cells fill the same panel. The seed stays, but the row ends later, and the familiar stream falls into another arrangement. Return to eight and the earlier picture returns. The two handles make different decisions available. Chance varies the colours; you can change how many places there are for them.

<!-- @textile_comparison -->

The three textile panels offer another comparison. Each begins with seed 41. Diagonals, upright and horizontal marks, then blocks: three pairs of signs receive the same draws. Follow one cell across the panels, then step back to see the larger figures those marks make. NEXT SEED changes the draws in all three; RESET returns to 41. These bolts are held still so their marks can be compared. Chance has not chosen what a mark means. The program supplied that vocabulary before drawing.

<!-- @random_number_book_page_1955 -->

Near the far end of the room, a page of five-digit numbers takes its look from a book of random digits published in 1955, a table anyone could open at the same line and read the same digits again.[^rand-1955] This page keeps the look and not the return. About once a second each column takes a new number at the top and lets its lowest one fall away. The page draws from the game's shared generator and keeps no record of a number once it has gone.

<!-- @prng_crank_machine -->

On your way back towards the entrance, stop at the crank. One press of its CRANK button, one state. It gives each request a gesture. We could follow every request at the colour grids too, but one picture has already asked for 192 of them. What can we leave unexamined and still recognise how it was made?

<!-- @ -->

The next room gathers a sequence into a histogram and an entropy reading. Carry one small patch with you. We are about to ask what a number can retain of an arrangement that was worth looking at.

[^rand-1955]: *A Million Random Digits with 100,000 Normal Deviates* (RAND Corporation, 1955). RAND's [introduction](https://www.rand.org/pubs/monograph_reports/MR1418.html) describes a basic table generated by an electronic roulette wheel in 1947, tested and transformed before publication. Choosing a starting place in a fixed table can help us imagine a repeatable beginning. The table retrieves stored digits; a seeded generator calculates its sequence. Repeatability in this room depends on the generator and procedure being kept with the seed.


---

## 02 · Random_Entropy

# What the gauge forgets

In the last room, one discarded draw changed which values became neighbours. Here, choose a pair of neighbouring colours before touching a button.

<!-- @shannon_entropy_meter -->

Two hundred coloured tiles stand on a desk beneath a glowing number. Each tile is one draw. Ten bars collect their occurrences, wherever they fell. Find a frequent colour, then a rare one. The bars keep how often; the row keeps where.

The first forty tiles also appear enlarged across the desk's front, labelled “as drawn.” Keep one pair in view and press SORT. Above it, the tiles glide into ten blocks. The bars stay. The number stays. Your pair remains together in the enlarged excerpt while its members acquire different neighbours above.

The plate prints the sorted copy's H beside the original reading: *equal*. Yet the row looks like another object. Finding every occurrence of a colour has become easier. Press SORT again and its former neighbours return. Which arrangement would you want to work with? The gauge cannot choose between these uses for you.

It makes one tally per symbol, then condenses those shares into an entropy reading. Neither operation asks which tile was next to which. A repeated pair, a rhythm or a message could pass unremarked. A high reading cannot certify meaninglessness; a low one cannot certify value.

Press CONTRAST. The same alphabet and number of draws now come from a source that favours the first symbols. One colour occupies much of the row. The reading falls. The shares changed; the apparatus did not lose any tiles.[^ledger]

Compare the smallest bars with their printed counts. A visible mark can stand for zero. The tallest bar reaches the same height in both samples, although it counts different numbers of tiles. The display fits its ruler to the sample. Read the counts before letting height settle the comparison.

Press DISCLOSE. The upper panel reveals its formula, then its source and expected counts; later it withholds the bars and strip while keeping the reading. Look down. The desk still carries the tiles. Information absent from one display remains within reach on another. How much would you know if you approached only the glowing number?

The tutorial makes this omission available to change. A perfectly regular cycle can give the same counts and H as its sorted copy. The student preserves both arrangements and lets a second calculation read their neighbours. What the first instrument missed becomes another question we can ask.

<!-- @entropy_jar -->

A few steps to the side, a glass jar holds red beads below and blue ones above. Its label reads S = 0.00. Lift it and shake it. As the colours come to share its layers, S climbs toward one bit.

Count the whole jar the ledger's way: forty red, forty blue, one bit throughout. The jar measures within six layers cut by height, then combines their readings, weighted by the beads each holds. It has given *where* a particular meaning. Beads sorted from the centre outward could still read to it as mixed. The partition helps make the result.

<!-- @entropy_axiom -->

Beyond the ledger, enter the square glass enclosure. At the blue end the points sit in rows; farther along they stray from their lattice addresses. Walk sideways as well as forward. The same field can look lined up from one direction and tangled from another.

Its random offset grows along z. Even this apparent loosening has a direction. These displaced points do not illustrate the ledger's number: one work counts symbol shares, the other changes positions. Putting them together gives us something to compare, and a reason to resist calling every visible irregularity the same entropy.

<!-- @entropy_ruin -->

Four pale columns carry a lintel. A lower brick wall runs behind them. The ruin waits intact. Choose a joint, then press RUN / PAUSE. For a moment it still holds. A piece drops out and comes to rest below. A capital loses its place; a shaft becomes a stump. The fallen stone is still here.

![The four columns and their lintel wait intact, with the brick wall behind them and the controls in front.](images/ruin-waiting-museum.png)

The counter keeps two accounts: 116 stones, and how many have moved. The first number stays. Does the building stay with it? Walk around the surviving columns. What was a boundary now lets you see across it.

The program chooses among exposed tops. The bottom two courses remain. RESTORE returns the pieces and their seeded order. The fall and landing places were arranged too; this was never centuries of weather compressed into a minute.

Turn toward the museum wall beside the columns. These pale courses belong to the hall itself. Let its top stones come down. Through the thinning edge, the view continues beyond the room. The floor stays; a low course keeps the edge. The structure that contained the demonstration has come under its rule.

RESTORE closes the openings with the stones and their collision. A written arrangement decides where a body can go. What else did we accept as background because it had not yet moved?

The ledger counted symbols without keeping their neighbours. These stones make that omission bodily: the same inventory can hold different views, gaps and forms. Nothing has calculated this ruin's thermodynamic entropy. What does a count of stones tell us about what they can still hold?

<!-- @ -->

<!-- study-spine:signal_room -->

<!-- @signal_room -->

The count returns as a room. Black and white continue from the floor onto the far wall and overhead. Choose ROWS, then CELLS. The bands loosen into another distribution. Both counts stay at 2,048.

The small four-by-four witness lets you inspect the same record at another scale. H stays at one bit per symbol while the number of unlike neighbours changes. In this response to Ikeda, immensity is made from a finite stored array. Its authority can be felt before its omissions are understood. The dark pixels never remove the floor; you can leave along either side.

<!-- @ -->

The last room asked how an arrangement could return. Here we asked what survives when we describe one. From H alone we cannot recover even the bars, let alone the neighbours we chose. The ruin withheld another decision: only exposed tops could be selected. In the next room that eligible set is laid out where we can count it. Before anything is removed at random, a rule has decided what can be chosen.

[^ledger]: The even source has ten symbols, giving a marginal entropy ceiling of log₂(10), about 3.32 bits per symbol. Its finite sample sits just below that ceiling. The contrast source assigns probabilities in a halving series and normalises them; its cached sample has 109 occurrences of the first symbol, four absent symbols and H of about 1.82. Each sample has its own seed. CONTRAST returns the cached samples; it does not change the first sample by sorting. Bars have a two-millimetre minimum and scale to the sample's largest count. DISCLOSE's pale bars show expected counts, not promised outcomes.


---

## 03 · Random_Remove

# The set before the choice

In the last room, sorting changed the neighbours while the count stayed. Here, find a cube the process cannot choose.

A board of sixty-four small cubes stands on a pedestal a few steps inside the entrance, on the hall's centre line, numbered along two edges. Its controls sit together on the console in front; a cased account of the set stands to the left. Sixteen of the cubes are amber; the other forty-eight are grey.

<!-- @remove_random -->

Before pressing anything, count the amber ones. Four rows by four columns, from column 2 to column 5 and row 2 to row 5: sixteen possible first choices. The grey cubes are present, numbered, and out of the question. The plate beside the board names the range, a seed, and the numbers eligible, remaining and removed.

Press REMOVE ONE. One amber cube turns red for a moment and is gone; its slot plate stays, so the address survives the cube. The line names it: last removed, column such, row such. Remaining: fifteen. While a cube is still red, the same line says *Choosing*, with the address already filled in: the draw is made before the deletion. Press again. Does the new gap touch the first? Either answer is possible. Watch the amber set rather than expecting the gaps to spread like a stain.

Now point to a cube you know cannot disappear, and press until the amber is gone. Sixteen completed removals. The final shape was never in doubt: the square you counted at the start, emptied. What the initial picture did not tell you was the order, and the plate under each gap keeps only the fact of absence, not the turn it was taken on.

The rule asks about each cube's position on its own board. Column 3 remains column 3 wherever the pedestal stands. The admitted addresses form a list, and only then does chance enter. It chooses a place in that remaining list. The draw never encounters a grey cube; there is no probability, however small, of its being chosen in this run.

Removal is a further decision. The model stops drawing one cube but retains how to put it back. Its entry leaves the candidate list, which only shrinks until a new run. Look into the gap. The small slot plate is still there. At this board, the surface your feet stand on belongs to the museum; these small disappearances make no holes in it.

Filter, draw, delete: three decisions that are easy to fold into one word, *random*, and only the middle one is.

Press RESET. All sixty-four cubes return, sixteen amber again, and the line shows the same seed. Watch the first few removals twice. Resetting has restored both the set and the generator. Waiting before your next press does not advance this order. The room goes on around the board; the next choice waits for the button. A press during the red highlight is ignored while the removal is busy.

Press NEW SEED and try again. The button selects a five-digit seed and restores the set. It may select one you have already used, and a different seed does not guarantee a different removal order. Compare the histories you get rather than requiring difference as proof of randomness.

Then keep a seed and change the rule. ROW admits eight cubes along row 3; COLUMN admits eight along column 3. Follow the first few removals in each. The same changing counts offer the generator corresponding places in the two lists, but those places point elsewhere on the board. Where ROW removes column 5, row 3, COLUMN removes column 3, row 5. The common cube at column 3, row 3 disappears on the same turn in both complete runs.

ALL admits sixty-four. The draw's bounds have changed too; retaining a seed alone no longer means retaining the same list positions. Equal counts can leave a spatial difference undescribed. A rule can offer the same number of choices while making different places available, and the seed cannot tell.

Stop before the set is empty. Keep this interrupted pattern for a moment. Perhaps the openings make an arrangement you want. Nothing requires another press. The final empty range would erase the distinction between the orders you have been comparing; halfway through, their different choices can still be seen. A slot remembers an absence. The visible account remembers the last removal. The program retains the full order until the next reset, but this plate does not show it. The comparison between your runs is kept only by you.

<!-- @sampling_hoppers -->

Beside the board, two glass cases hold the same eight numbered blocks. Each has a handle. Pull the one on the left. A block comes forward, leaves a small copy in the row below, and travels back into its place. Pull the one on the right. Its block stays out. Behind it, the numbered slot is empty.

Try to get the same number again. On the left you can wait for it; nothing promises how long. On the right, the number you have just drawn is no longer available. An absence has become part of the next choice. After seven completed pulls the right-hand case has one answer left, and the left still has eight. Can you name that last answer before pulling? Which number survives still depends on the earlier choices.

Here code chooses the member. The movement lets you follow what happens to it afterward. Both machines begin with the same seed, so their first choices match. Then their available sets part company. The left-hand row can contain repetitions and keeps its latest twelve draws, though its count continues. The right-hand row can fill with every number once, then stops.

REPLAY BOTH restores the blocks and begins the two orders again. Watch the returning block rejoin its neighbours. Giving it back is an instruction too. What looked like another chance depended on making it available again.

<!-- @random_removal_arena -->

Behind the board, the set becomes a floor. Ninety-nine cubes span a basin inside a glass frame. Pause on the dark edge before entering. That edge is permanent. The amber cells are not.

Entry asks for one removal. As you walk, accumulated horizontal movement asks for another after sixty centimetres, provided the pending removal has finished. One cell turns red for eight-tenths of a second. Then its mesh disappears and its collider is disabled. The gap is now something your body can fall through. Fire burns at the base of the basin.

The draw chooses from the remaining cells, not from the cube nearest your foot. Walking makes a choice happen; it does not tell the choice where to land. Try the permanent apron and look back. A disappearance becomes a fall only because the code also withdraws support.

REPLAY restores the cells and their colliders, and starts the same seeded order again. NEW SEED starts another run. The floor begins with a fixed seed when the hall is built. Different walking paths can bring on the same removals at different times; the order alone does not describe the encounter. Unlike the small board, the floor does not name its seed. After NEW SEED, the order cannot be identified from its plate.

<!-- @ -->

Ask now whether a random choice can be fair to a cube that was grey. Within the amber set the draw is even; the grey were decided before it ran, by a rule you can read and change. The seed that makes a run repeatable has no say in that exclusion.

In the next room, the available choice narrows to two diagonal marks. Follow what their neighbours make of them: when does a choice become a contour, and when can that contour become a passage?


---

## 04 · Randomness_10_PRINT_Algorithm

# A maze made of marks

In the previous hall, a draw removed a member from a set. Here each place receives a mark. When do independent marks begin to look like a maze?

Diagonals rise above the walls on three sides of the hall. Below them, a cluster of solid slabs leaves narrow openings between its edges. The same two marks recur on a screen at the far end. Something that fits inside one character has acquired room for a body.

<!-- @ten_print -->

The screen prints left to right, row under row. Beside it, the console carries one line of Commodore 64 BASIC:

```basic
10 PRINT CHR$(205.5+RND(1)); : GOTO 10
```

One line, famous enough to have a book named after it.[^10print] Read it from the middle outward. `RND(1)` gives a number from zero up to, but not including, one. Added to 205.5, it lands between 205.5 and 206.5. `CHR$` keeps the whole part: character 205 or 206, one diagonal or the other. `GOTO 10` returns to the beginning.

The constant 205.5 puts the two choices in balance. Each new mark can lean either way. Equal odds do not promise equal numbers in the field, or symmetry in their arrangement. Nothing in that choice asks whether a passage is needed beside it.

Yet the field on this screen seems to breathe. Bands favour one diagonal, then the other. The small print admits why: “bias breathing.” A sine wave changes the odds while the line above still displays 205.5. What looks like a texture of chance also carries a rhythm someone chose. The familiar line does not account for everything this installation does.

Press **BIAS +**. The breathing stops and the constant begins to change: 205.4, then 205.3. The next marks increasingly favour one direction. At 205, the new field fills with the same diagonal. What suggested a maze has become stripes. Use **BIAS −** to bring the constant back to 205.5; the odds are now fixed and even.

There is another small decision in the line. Press **SEMICOLON** and the trailing `;` disappears. Every mark now begins a row of its own. The field becomes a single column.

The semicolon tells `PRINT` to stay on the same line. Without it, each character is followed by a line break. This control starts the seeded stream again, so the column and the plane can receive the same choices. What differs is where a choice goes.

Down the column, marks can still meet at corners and zigzag. They cannot close around a room. Four marks in a two-by-two block can: their diagonals make a diamond. The grid gives neighbouring marks shared endpoints; the line break decides whether they have neighbours in a second direction.

Press **SEMICOLON** again. The plane returns. One tiny character has given the other characters another way to meet.

Even those meetings have been interpreted. The red and blue bars slowly lengthen and shorten, touching at a corner and parting again. Nothing in the BASIC line asks them to do that. A display can loosen a connection the grid appeared to guarantee.

<!-- @ -->

<!-- @composition_stochastique -->

Beside the printer, four square grids offer another use of the same diagonals. One direction fills each grid; the other occupies exactly one, five, thirty or fifty of its hundred cells. The plate names François and Vera Molnar, 1959.

Step along them. Where does a field of parallel lines become something else? There is no example between five and thirty. Your eye has to cross that interval.

**RESEED** changes the arrangement while keeping every count. The four grids come from one shuffled deal: the single turned cell in the first is turned in the other three too. Chance decides which cells turn. Their number was settled beforehand.

The printer leaves that number open. Giving a diagonal a thirty-percent chance does not reserve exactly thirty of a hundred cells for it. A probability and a count are different instruments. The small tutorial board keeps both in view: the odds we set and the count that actually arrived. Here they stand close enough to compare.

<!-- @ -->

<!-- @ten_print_structure -->

Look down. The newest seven rows of the screen are also under your feet. Each cell is enlarged to half a metre, each diagonal laid down as a low ridge. A bright tile waits where the next mark will land. When a row fills, the ridges shift towards the far wall and the oldest row leaves the floor.

**RUN** holds the printing; **STEP** adds one mark. The pause gives your eye time to follow a character from the screen to its place on the ground. Taking away the semicolon collapses this floor into a single file too. A change in the line reaches the room.

These ridges offer no resistance. You can stand among them and pass through their edges. They give the eye a contour without giving the body a boundary.

Now return to the taller slabs near the entrance.

They retain the first twelve characters printed when the hall was built, before any adjustment of the odds. Here the characters are wrapped four to a row and stood two metres forty high. The console leaves this arrangement alone. Where two slabs run parallel, the gap is about seventy centimetres wide.

Walk in. The mark you followed on the screen has become the face of a wall. Your route occupies the space beside it.

Four slabs meet corner to corner around a small room with no entrance. Joining the marks has closed the passage. The same connection that completes a figure can keep a body outside it.

Elsewhere the gaps lead back out. Some are shallow bays; one passage crosses the block. None forks. Between these diagonals, each small triangle of floor opens on two sides, so a corridor may turn but offers no branching choice. What looked like a maze from above becomes a different proposition at the width of your shoulders.

The way through also depends on the crop. These twelve characters leave it when wrapped four to a row. Wrapped three to a row, they would leave neither a crossing nor a closed room. One more row of this stream would close the crossing too. The rule did not choose where the block ends. Whoever placed it did.

Each cell was decided alone. Whether you can cross depends on their arrangement together. A body meets a consequence that no single draw contains.

<!-- @ -->

<!-- @ten_print_maze_3d -->

Look up again at the three fields towering above the hall. Their lines can be crossed by your body, but they provide no surface to carry you upwards. Height in the image has not become a climb.

A red ball stands for an ant in each field. It receives a different map: even parallel diagonals are treated as touching, so a channel you could walk between the slabs is closed to it. The ant stays around a corner until a cell turns and another move becomes possible. Every turn clears its record of where it has been.

Watch a diagonal change near it. One replacement can join a long contour or break it apart. The slabs held still long enough for you to learn a passage. Here the ground of the ant's small knowledge keeps changing.

<!-- @ -->

Two marks have supplied a printed field, a floor to stand among, walls that admit or refuse a body, and a changing world for an ant. The marks alone cannot tell us which world we have made. Their arrangement, their material and the body given to them all matter.

The printed floor lets its oldest row go. In the next room a die's record gathers outcomes instead, keeping how often each face appears while forgetting where it landed. After a passage made from independent choices, we meet a throw made by a hand.

[^10print]: Nick Montfort, Patsy Baudoin, John Bell, Ian Bogost, Jeremy Douglass, Mark C. Marino, Michael Mateas, Casey Reas, Mark Sample and Noah Vawter, *10 PRINT CHR$(205.5+RND(1)); : GOTO 10* (MIT Press, 2012). The whole book is freely available at [10print.org](https://10print.org/) under a Creative Commons BY-NC-SA 3.0 licence. Its chapters are numbered like program lines — 10, 20, 30 — with remarks between them, and its long argument concerns the interplay of randomness and regularity that this room lets you pull apart.


---

## 05 · Random_Cubes

# One throw and many throws

Two diagonal marks filled the previous room. Here six faces wait on a body you can lift. How much can one throw tell you about a die?

<!-- @dice_throw -->

A white die lies on green felt, six pips up. Pick it up and throw it. It may keep rocking after it lands. When one face holds the top, the glass records its number and orange balls rain onto the table: sixteen for each pip. A six receives a small spectacle.

The reward has a rule. It does not make the throw more earned. For a moment, though, its abundance can make this outcome feel like the one the room wanted.

No random number decides the face. The program draws random values to scatter and tint the reward, but reads the die from its orientation. How your hand let go, the cube's shape and its contact with the felt have already done their work.

Return it with **RESET** and let it fall level from just above the table. Six can come back without surprise. A tilted release can produce another face. A cube's symmetry is a reason to investigate fairness, not proof that every way of releasing it gives equal chances.

The glass keeps the throws after their little storms have passed. Each face has a bar and a percentage; the running mean stands beside the model's 3.50. A short sequence can repeat one face or miss another without settling whether the die is fair.

Follow one face's share through several throws. Another face makes that share fall. The mean answers a different question: an outcome above the current mean pulls it up; one below pulls it down. Neither movement alone tells us that the die became fairer.

If all six faces were equally likely, their mean would be 3.5. No side of the cube bears that number. It belongs to a distribution, while the observed mean belongs to the throws made so far.

The glass cannot tell you whether your last three throws were sixes. It keeps frequencies and loses order, along with every landing position. **RESET** returns the die while keeping this record; **CLEAR** empties it. The instrument has decided what a throw leaves behind.

<!-- @ -->

<!-- @paired_dice_column -->

Two more dice wait in separate trays, one blue, one pink. Throw each into its own tray. A column stands up behind them when both results have arrived. Count its blue blocks, then its pink ones. The faces have become parts of a height.

Three and four make seven. Five and two make seven too. Can you bring the column back with different ingredients? The dice need not give you the pair you want. On the shelf, small copies keep the last twelve pairs in order, each colour still carrying its share. Two columns can reach the same level without looking the same.

Look only at their tops. Now look at the join between the colours. Each view lets you call something different the same. A total keeps an answer and gives up how it was assembled; the colours let some of that difference return.

How many pairs could make two? How many could make seven? Keep the order of the dice: blue one and pink six is another pair from blue six and pink one. If every face were equally likely and the two throws independent, seven would have six routes out of thirty-six, while two would have one. The middle would occur more often without either die preferring it. Your throws may not yet make that shape. Their conditions still matter.

The shelf eventually lets its oldest pair go. The total count continues. A history needs room; this one has been given twelve places. The larger column waits while you begin again. Returning a loose die adds nothing to it.

<!-- @ -->

<!-- @continuing_die -->

## The six that does not finish

A single die waits beside another column base. Throw it into the felt tray. Its number becomes a section of the column, one thin block for each pip. A three leaves three blocks and closes the chain. A six leaves six, but the flag stays raised. Throw again.

This time the first section remains. Another six gives you twelve and another turn. A three after that makes fifteen and closes the chain. The small sculpture beside your tray keeps this example visible: six, six, three. Its label says WORKED EXAMPLE. It is there to show a possibility, not to tell you what you threw.

The first die in this hall made a six into a larger rain of rewards. Here the same face does something else. It keeps an instruction open. Nothing inside the cube knows that six means again. We add its value to the height, then use that same value to decide whether another throw is allowed.

The tutorial beside this encounter lets us change that permission while keeping a coded stream of outcomes. It cannot replay the movement of your hand.

The number enters twice: once as an amount, once as a condition. From the same six faces, the rule can build a body taller than any single throw. Look at the joins in the column. Its height has a history, and the sections still let you read it.

The amber lid marks this display's limit: five throws. If the fifth is another six, the case reads CHAIN UNFINISHED. The rule would permit more; this apparatus has run out of room. That is a different ending from a die landing three.

RETURN DIE recovers it without adding a throw. NEW CHAIN clears the live column. Until then, a closed or limited chain stays as it is even if you throw again. Before clearing it, walk around what those few landings have made. Where did the permission to keep growing reside?

<!-- @ -->

<!-- @coin_toss -->

Across from the first die, eight coins wait on a pedestal beside a dark felt pad. Toss one onto the pad. The console counts heads or tails and adds the result to a ribbon. Here the last thirty outcomes remain in order. A coin resting on its edge is left out. Read the ribbon as steps, heads forward and tails back: where would a walker be now, and how far has it been? The simplest random walk is a coin on a beam; two rooms on, a block on a rail takes it.

Three gauges name conditions of the latest release: SPIN, DROP and TILT. A gentle toss and a forceful one can leave different readings even when both land heads. Try a small run each way, using **REFILL** between them. Keep the two runs distinguishable. Combining them immediately would erase the intervention you are testing.

The gauges do not predict the next outcome. They let us see something the tally discards: every toss had conditions. Only the latest release keeps its measurements.

Beside the count stands 0.5000. In the last room, a number could set the printer's odds. This number sets nothing. It states the model's expectation, waiting beside what happened.

<!-- @ -->

<!-- @random_object_spawner -->

Further in, wooden cubes appear above a waist-high block, at two points side by side. Each arrival knocks against the growing heap. You can pick a cube up.

Each point keeps at most twenty. After that, a new arrival makes one of its cubes disappear, chosen at random—even the one in your hand. The heap keeps changing without a record. What you were holding is no exception to its rule.

<!-- @ -->

<!-- @random_edge_profile -->

Beyond the block, forty-eight red slabs form eight rows. Their top edges rise and fall, but each metre-wide slab returns to the same height at both ends. Only the three points between those ends are drawn at random, within narrow limits.

One slab offers one outcome. Along a row, a regularity becomes visible: however the middle wanders, the joins keep their level. The field lets us inspect many draws together, rather than wait for them one by one. What chance may touch was settled before it ran.

The ridges are drawn afresh when the hall is built. They do not stop your body. You can walk through an edge that the eye reads as a fence.

<!-- @ -->

The die and the coin gathered throws into different records. The paired dice let the same height keep different ingredients. The heap kept losing pieces. The field held one arrangement still. In the next room every piece remains, and what accumulates is its turning. We will have to look for a history that has left no trail.


---

## 06 · Random_Rotate_Random_XYZ

# What remains in a changing stack

The last room kept adding the results of a throw. Here a contribution can also take something back. Which part of an arrangement can change while its pieces remain?

<!-- @hardware_entropy_decay -->

Along the wall on your right as you come in, a rig holds three shapes that weather together: a box, a sphere and a cylinder, with the same wear pushed to all three at once. The rust rises slowly by itself and faster while you move. Swing your hands, squeeze a grip, turn your head. Scratches follow your hands and fade when you stop; the grime and the rust stay. Nothing in the rig draws a random number. In the headset, a surface can look worn by accident when its grime and rust are a record of how you moved in front of it.

<!-- @ -->

<!-- @random_decay_multimesh -->

Further in, a long display crosses the hall. On your right as you face it stand twenty cubes in a block five wide and four high; on your left, a hundred and twenty prisms in twelve columns of ten. Every piece is the same size. None of them has a body, and the way on passes through the prisms.

The pieces may already be turning when you arrive; after a **RESET** they stand in line for a few seconds before they begin. Each turns in the plane of its stack, a little at a time. Nothing else changes. Their size never changes, and in this room neither does their place or their colour. An arrangement can become less regular without any piece changing place, shrinking, disappearing or becoming a different kind of object.

The demonstration keeps a changing state for each instance. Every piece carries one hidden number that starts at zero and grows by itself, and now and then a random kick lands on a piece and adds to it. The larger the number, the harder that piece is shaken. Its angle has no limit: each small turn is added to the last. A small angular change repeated many times can produce a visibly altered orientation even though no single step seems dramatic. Give it time. The implementation takes a new update on each drawn frame, so how far it turns also depends on the machine drawing the room. Its apparent patience is partly a setting and partly a condition of its execution.

After a minute or two, find the piece that has turned furthest and lay its edge against the line of its neighbours. It has not moved, so its neighbours are still its neighbours. Then find one that has barely turned, and explain that one difference before judging the whole stack.

Left to its defaults, the hidden number also makes each piece drift, sink and darken, so one broad description of disorder can conceal different changes. Here the drift, the sinking and the darkening are switched off, and only turning is left to follow.

Both stacks now run at the same rate. Each piece in either stack follows the same rule: a stack receives kicks in proportion to its number of pieces, so every piece can expect the same share. Outside this room’s comparison, the default settings give the cubes a higher rate than the prisms. A difference produced by that setting would not establish a difference caused by shape. What still differs here is shape, colour, number and spacing, so a difference you think you see is not yet a difference of shape alone.

The panel in front of the display is labelled DECAY. The label names the model's presentation; it is not a measurement of thermodynamic entropy or a complete physical explanation of how a material deteriorates. **TOGGLE** pauses the turning and keeps the time already run; press it again and the turning resumes where it stopped. **RESET** puts every piece back in line and starts the delay over. The renewed view restores a reference for comparison, not the turning that followed it: RESET does not rewind the random draws, so the turns that come after it are new. Note which piece leads before a RESET; a minute or two after it, a different piece will usually lead.

<!-- @ -->

<!-- @RotateGridCubes -->

Behind the stacks, twenty-five cubes make a low square field. The first row lies level; the middle pitches upward; the last lies level again. Nothing keeps turning as you watch. The angle follows a row’s place along half a sine curve. Walk along its side. The same arrangement returns whenever the hall is built. Here your walk supplies the sequence: level, inclined, level again. Rotation can be a rule about place as easily as a record of chance.

![Twenty-five cubes, level at both ends and tilted through the middle, fit behind the changing stacks.](images/tilt-field-contained.png)

<!-- @ -->

The tutorial holds two cubes beside one another and gives them the same recorded turns. One takes the latest value; the other adds it to what came before. On the first step they agree. Later, the difference belongs to what each cube retains. To give two things the same input is not yet to give them the same history.

Here each piece shows only where its turns have added up to; the turns leave no trail, and RESET wipes even the sum. The random-walk room keeps a trail of one accumulated quantity, position, so there you can separate the next-step rule from the record of earlier steps.


---

## 07 · Random_Walk

# The trail is already elsewhere

What does a trail remember that its next step does not use?

<!-- @random_walk_terrarium -->

Five beads move inside a glass tank. One is bright red; the other four are dimmed, still moving. Follow the red one. A turn begins to look like hesitation; a curve seems to be taking it somewhere. Choose a place you think it will reach. Keep that expectation beside what happens.

Begin with 2D. The trail can take any heading, yet it never leaves its level. Move from the front to either side of the tank. The thin arrangement holds. Press 3D. Now the bead can rise and fall. Find an apparent crossing and change your viewpoint. Do the two stretches meet, or did you put them together by looking?

The last room let turns accumulate in a stack. Here a draw proposes movement from the position already reached. We have met the parts: a point, coordinates, an increment, a line made from samples, an array to keep them. In 2D, one number becomes a heading around a circle. The code has three coordinates and declines to change one. Flatness is a decision made at every step.

In 3D the proposed length stays the same. LONG STEP draws a length too. Try it, then return to 3D. Does a longer movement carry the bead out of a patch it has repeatedly crossed? The code calls this a Lévy flight, but even its longest proposal has a limit. The comparison does not establish a better search strategy.[^levy]

Near the glass, a bead approaches, turns and stays inside. The enclosure folds its proposed endpoint back. For a wall at x = 0.25, an attempted endpoint at 0.27 becomes 0.23. The drawn segment joins retained positions without visiting the contact point. A short stroke can stand for a longer proposal. The line has left something out again.

It also arrives late. The record stores the position before the bead moves, then gives up its oldest entries. At step 300 the trail holds positions 100 through 299; the bead has reached 300. Its beginning has gone, and its latest place has not entered the line. Neither absence means that movement did not happen.

Nothing in the heading rule reads the trail. Erasing its stored points in a controlled test leaves subsequent positions unchanged. There is still memory: current position, generator state, counter. To make the walker avoid its own drawing, another relation would have to be built.

<!-- @pixel_cloud -->

On your right, a sculpture of small cubes shows one way. Before each step, that walk sets aside the neighbouring cells it already occupies and chooses among the rest. It stops if none is available. The walk has finished by the time you arrive. What stands is its path; nothing marks the moves it refused.

<!-- @random_walk_terrarium -->

Back at the tank, ONE and ALL change which beads and trails are bright. All five keep stepping. Following one changed your access to the population without sending the others away.

Read the seed, then RESET. Compare the returning path at the same step count and in the same mode. Changing modes spends the draws differently; a number alone is not the whole recipe. The plate also carries two clocks, which can disagree when a frame stalls.[^walk-clock] Even the time offered as evidence has a procedure.

Below them, MSD measures the beads' average squared distance from their release point. A return toward the centre can lower it while adding more line. The gauge does not measure how far they travelled. Look back at the trail: which account answers the question you wanted to ask?

<!-- @random_position_rails -->

## Somewhere to start

Two rails each carry a block. Slide the white prediction marker to a place you think one will reach, then pull NEXT. Empty frames appear before either body moves. The machine has made its choices; for a moment you can see its destinations.

Blue can cross almost the whole rail. Pink stays near where it was. Both received the same number. Blue used it as a new position; pink used it as an increment. The small addition carries a past into the next move. What does knowing the last position give you now?

At the ends, an outward step folds back. The latest twelve landing pairs collect below; older marks disappear while pink keeps the position they helped it reach. The past can survive in a present state after its record is gone.

Watch the journeys between the empty frames. Both take one second with the same easing. Even blue's fresh destination arrives smoothly. Looking continuous is not enough to tell us what a process remembers.

HOLD lets the revealed move finish and stops the next draw. REPLAY returns the bodies and repeats their choices. Your marker can move elsewhere. A prediction has entered the room, but the machine has no obligation to meet it.

<!-- @random_draw_dot -->

Pick up the drawing dot. Move your hand slowly, then hold it still. The green tip keeps wandering. What part of this line belongs to you?

The Point Trace tool has acquired an offset that takes random steps. Your hand carries its origin. The tip walks around it, confined to a radius of twenty-five centimetres. At the boundary an outward proposal is shortened. Its freedom has a radius.

Press HAND / RANDOM to clear the line and draw with the hand alone. Switch back and repeat the gesture. The trail keeps samples of the movement, not every intermediate position.[^drawing-clock]

CLEAR / REPLAY restores the random seed. Those steps can repeat; your hand need not. Let go and the wandering stops. This encounter gives chance movement only while someone holds it.

<!-- @random_walk_128 -->

Cross the bridge over the narrow basin and enter the larger glass frame. The floors remain at the same level, but the gap separates gallery from experiment. Here a visited cell rises. Four directions are enough to change the ground.

A high place records returns; it was not chosen as a destination. Whether returning too often is a problem depends on what we wanted the walker to do. The count cannot supply that purpose. Movement has become a spatial obstacle through what the surface retained. Compare this ground with the cabinet's lines. Each gives part of a history a different body.[^walk-field]

<!-- @ -->

In the tutorial, the point leaves your hand and begins choosing steps. You have supplied its starting place. Its trail makes those choices available to you without making them available to the next heading.

Stay with a shape you had begun to read as a creature. What would its next step need to know for that reading to become a capability? For now, its history exceeds both its current position and the drawing we can still see. In Random Gaussian we gather draws another way and ask what shape appears when we count where they land.

[^levy]: The ordinary proposal is 0.015 metres. LONG STEP multiplies it by an inverse-square-root sample with offset 0.01, exponent −0.5 and cap ten, giving a maximum of 0.15 metres before boundary folding. This bounded implementation is not an unbounded Lévy process or evidence about animal foraging. The nearby self-avoiding pixel sculpture lays at most twenty-three cubes.

[^walk-clock]: The cabinet accepts thirty simulation steps per second, at most five per frame, discarding excess time. A two-second frame can therefore add two seconds to its frame clock but only a sixth of a second to its simulated walk. RESET restarts both accounts; the cabinet has no pause control. NEW SEED selects a five-digit number different from the current one, although an older one may recur.

[^drawing-clock]: While held, the random offset proposes 1.2-centimetre steps thirty times per second. The drawing process samples the visible trail separately, so a stalled frame can omit intermediate positions. Replay resets the random procedure, not a visitor's gesture.

[^walk-field]: The larger field is ten metres across with thirty-two cells per side, despite its older source name, `random_walk_128`. Its height records visits; that height does not guide the next step.


---

## 08 · Random_Gaussian

# The shape we counted

What changes when the values stay where they are, but we count them differently?

The two dice could reach the same height by different throws. Their coloured columns kept those ingredients visible. Here we gather values into groups. What will the new picture keep of their differences?

<!-- @distribution_sampler -->

Yellow beads fall toward a row of blue bars. Some bars grow; others wait. An orange line already knows the shape we have come to expect. Look at the beads and the bars before letting that line finish the picture for you.

The cabinet stands in the middle of the hall, its controls facing you as you approach. The other distribution studies stand around it. Its left panel offers UNIFORM, GAUSS, POISSON, EXPON and CLEAR. On the right are BATCH, PAUSE, NEW SEED, BINS and WIDTH. GAUSS is running when you arrive. New beads stop coming after a thousand draws, about twenty seconds; if nothing is falling when you get there, press CLEAR and they begin again.

Press PAUSE. Watch what keeps moving. The beads already released continue to fall. The plate beside the histogram counts them as “in flight” until they land; only the issuing of new draws has stopped. Wait for that count to reach zero. The histogram is now still enough to describe. Where is its highest bar? Where are its gaps? Which of those observations had the word “Gaussian” encouraged you to expect?

![The sampler’s numerical record stands beside its histogram, above the compact controls.](images/sampler-visible-record.png)

CLEAR empties the display and restarts its named seed. While paused, it stays empty. Press BATCH. One hundred values are counted immediately, without the falling animation. Describe this particular arrangement. Press twice more, reading the total each time. A gap may close; another bar may fall further short of the pale bar behind it. More evidence does not promise that every part of the picture will improve at the next press.

Those pale bars carry the model's expected counts at the current number of landed values. Blue and pale share a count scale. Their disagreement is available to examine; the pale shape does not instruct a blue bar to grow toward it. The disagreement is easiest to read where blue falls short, because the pale then shows above it; a blue bar that exceeds its expected count hides the pale top.

Now press UNIFORM. The bins clear, the seed stays, and three batches again give three hundred values. Keep the same thirty bins. Each pale bar now expects ten. Compare the two arrangements at equal count before deciding which looks more irregular. UNIFORM has used each number directly.

GAUSS has given two numbers another job.

A logarithm, a square root and the turning cosine give those draws their new relation. The mean is 0.5; the standard deviation is 0.15: under the ideal model, roughly two draws in three lie within 0.15 of the middle and nineteen in twenty within 0.30. A finite sample can differ; the model does not appoint which beads must arrive. Press WIDTH and the deviation cycles through 0.08, 0.15 and 0.25 with a cleared display, so the model's central band becomes narrower or wider; the actual proportion remains something to count. The code directly transforms draws into an approximation to a normal distribution. It does not wait for an arbitrary collection of values to become Gaussian. UNIFORM will keep its own law as more draws arrive.

The sampling recipe guards its first input. Zero cannot enter the logarithm. Values below 0.0001 share that lower bound, limiting the computed reach to about 4.29 standard deviations. Even before a value reaches the screen, the numerical procedure has made a boundary. The ideal orange model and this finite computation are close enough to compare, and still worth distinguishing.

There is another boundary at the screen itself.

The previous room's glass reflected an overshoot. Here a value past one is kept at one; a value below zero is kept at zero. Its distance beyond the edge is lost from the retained value. Look at the plate's clipped count and its two edge-bin counts. They need not agree: an edge bin also contains values that were inside the display all along.

Try EXPON, then press BATCH three times. More values gather near the left. Occasionally a draw from its long right tail is clamped at one. A finite run need not contain such a draw; the model's tail is a probability, not an appointment. NEW SEED lets another run take place. Its number differs from the current one, though an older number can return later.

Return to GAUSS or UNIFORM, stay paused (the plate's last line should read “paused”; press PAUSE only if it reads “running”), clear, and collect three batches. Now press BINS. Thirty become sixty, then ten, then thirty again. The landed count stays at three hundred. Nothing has been sampled again. The stored values are assigned to new intervals.

Watch the mean and the σ marked “binned.” They can change too. The plate estimates each value by the centre of its bin, so changing the intervals changes that estimate. The values have stayed; the account of them has moved. Return to thirty bins and the earlier account returns.

Look back at the height of the picture. Blue bars are scaled against the tallest blue bar, with a small visible baseline even for an empty bin. A handful of values can already occupy almost the whole height. The orange model shape has its own scale. Its curve cannot tell you how much evidence has arrived; the count can.

CLEAR and repeat the batches if you want to point at the same sample twice. That return depends on the seed and the procedure, including which law spends the random draws. It gives a discussion somewhere to stand while the surrounding museum continues.

<!-- @GaussianPaintSplatter -->

A few steps from the cabinet, a white plate collects coloured dots. Their positions come from the same guarded sampling recipe, yet no dot lands near the middle: a draw within one standard deviation of the centre is discarded, leaving no mark, and nothing on the plate counts it. That is about two draws in five, taken from the densest part of the model: on a line the same hole would swallow two draws in three, but on a plane it is a disc, and a disc with a radius of one deviation holds fewer. Its label calls the hole a “Safe Zone.” From the painting alone, could you tell a centre that was never reached from one that was refused?

<!-- @ -->

In the tutorial, your point calls for another batch or another partition. One action adds evidence; the other changes its account. You can make the bars look different without asking chance for anything new.

We have met a centre, but have not discovered a command to belong to it. Frequent under a chosen model does not mean preferable, healthy or correct. Before carrying this shape onto a body, ask what was measured, what the bins kept, and what the edges absorbed. In Random Mushrooms, sampled numbers become differences among forms. Which features of those bodies will be allowed to vary?


---

## 09 · Random_Mushrooms

# Which differences were invited?

In the previous room the numbers gathered into bars. Here they have caps and stems, and the sizes are drawn under the last room's UNIFORM law, not GAUSS. Which differences can this recipe make?

<!-- @mushrooms -->

The glass enclosure around the bed makes a population into a place you can enter. Its front opening leaves room beside the specimen table; another opening is opposite. Begin at the compact console, then walk round the mushroom bed inside the glass. The cage holds an experiment, not a claim that these bodies exhaust what a mushroom could be.

A bed fills the middle of the hall. Before it, six mushrooms stand on numbered discs. Look past the table and choose two in the bed that seem related. A cap bends out over a stem; another, smaller, repeats its proportions. Before pressing anything, decide what you are using to recognise their relation.

Press SHOW. A magenta ring moves to the next disc, and magenta rings on the ground mark its copies in the bed, each with a small bead floating high above it. Keep pressing until the plate names the template you were following. There may be many copies, or none in this particular population. The table still gives the absent form a place.

The discs run from 0 to 5: tan cap, red cap, flat brown cap, tall white mushroom, puffball, glowing cap. These are construction recipes rather than six biological species. Within this build, each recipe has become a template. A copy carries its template's details with it.

Look at two marked copies again. Their positions, turning and scale can differ. Their material situation can differ too: a cap lit by a neighbour need not look like the same cap in shadow. SHOW names a construction relationship; it cannot make every appearance identical.

Now press SIZE. The bed is rebuilt. Find your pair. Their places and orientations remain, but the extra scaling has gone. They have not all become the same physical size: a tall template remains tall beside a low one. The plate says “scale 1 · template sizes kept.” What did you think the button would remove?

A scattered mushroom receives an extra scale between 0.7 and 1.3. SIZE decides whether to use it.

The draw still happens when the scale rule is off. Only its use changes. If the program skipped the draw, the following decisions would receive different numbers and our comparison would slip away. Press SIZE again. The earlier scales return.

The seed on the plate makes this return possible under the same recipe. REGROW rebuilds the population and its ground. NEW SEED chooses a number different from the current one; it does not promise a number never used before. A new seed can also change one detail inside a template: where the puffball's bumps sit. Six available recipes do not mean six eternally identical objects.

Press KIND until the plate says “scattered.” Count what it calls accepted and rejected. Together they account for eighty candidate positions. The total mushroom count can be larger: two other routines add bodies later. First look at the spaces between the scattered ones. Which gaps seem intentional?

Continue to “rejected.” Grey markers appear at candidate positions that the placement rule refused. They were never mushrooms that died. At each proposed position, a noise field was consulted.

The scale at which positions are read in the field helps determine how nearby decisions resemble each other. A threshold then decides which candidates remain. Random Space Geometry will let you compare that relation with independently chosen values.

Even the source calls them “natural clearings.” The marks let us read what that phrase stands for here. A number crossed a threshold. The placement procedure proposes a position, tests it and keeps it only if the field passes the threshold. That is a rejection rule; it does not by itself establish a particular target probability distribution. The beads in the last hall took the other road, a formula that needs no rejection. In Gaussian, a value beyond the display was kept at its boundary. Here an unsuccessful candidate leaves a recorded position and no body.

Keep pressing KIND until it says “rings.” Green marks pick out the members added by the circle routine. One circle is requested at this bed's six-metre size. Find it. Usually only an arc fits; imagine the rest continuing beyond the boards. Its members were given equal angular intervals.

The radius helps set the requested count. Positions outside the bed are skipped. The plate's bracket counts the members actually placed; it does not show the missing ones. A partial circle can carry the trace of two decisions: draw the ring, then admit only what fits.

The next KIND is “clusters.” Two clusters each choose their own centre, spread and template. Their members receive random angles and distances. They do not pass through the scattered candidates' noise test. Bodies from different routines can overlap. Nothing here negotiates for room.

Walk round the west and south margins. Three spotted red-capped mushrooms, on taller stems than the red caps in the bed, stand just inside the boards. They come from a separate pickable scene and are counted separately. A similar cap has acquired another capability. Hold one and bring it close to your face: its eating rule starts a visual effect with a ten-second hold and a fade in and out and the mushroom dissolves. The garden has offered a way to change the looking, as well as the thing looked at.

<!-- @bubbles_random -->

Near the entrance, off to one side of the glass, a small bubble dish grows another population, with no plate and no seed of its own. Each bubble's place, size and rise are drawn as it appears, about ten a second, and each is gone after four seconds. This exhibit offers no control for returning to the same bubble population.

<!-- @silhouette_arrivals -->

At the smaller arrival stage, press REPLAY: the places empty. Wait for a silhouette. Another place is chosen from those still empty. Six arrivals fill it; the program does not keep producing bodies without somewhere to put them. Press REPLAY again and watch the places return in the same order.

Choose one figure and press DRESS. A hem may widen or narrow, a collar may appear or go, the pleats take another colour. Try again. How far can this wardrobe take the figure?

Now press FORMS. Branches extend from the garment. Read the dress number: it has stayed. Switch FORMS back and the earlier dress returns. You did not need a luckier draw to find the branches. They needed another instruction. DRESS samples within the available recipe; FORMS switches between two recipes, one of which adds branches. Neither button changes the six places or the arrival order.[^chance-repertoire]

These figures still turn towards you as flat images. Their new outlines give them no new way to walk, touch or refuse. A different appearance has not yet become a different permission. Which of those changes would you make next?

<!-- @couture_comparison -->

Beyond the garden, three couture bodies stand together. All begin with the hare head and sheath garment. Their seeds are 41, 42 and 43. Look for differences in proportion, print and pose before pressing NEXT SEED. Three more individuals appear under the same two named constructions.

Keep this trio and press GARMENT. The seeds stay while the sheath gives way to a crinoline, then quilting, bloom and fringe. The body generator receives another construction instruction. Some details may change with the construction too: a seed is not a promise that every branch of a program spends its draws in the same way. RESET restores the starting trio. The garment's possibilities were authored; chance finds individuals within them. Which possibility would you want to add to this wardrobe?

<!-- @ -->

On the tutorial table, you keep each body’s record and switch off only its scale. Nothing has asked chance to decide again. One difference has been withheld from view; it remains available to return.

The sampled sizes never grow a seventh template between two others. That would need another rule. Yet these rules could carry other forms, other ranges, other permissions. Which difference would you add first, and what would have to change to let it exist? Carry that question through the cage interlude. Then, in Random Space Geometry, compare values chosen independently with values related across neighbouring positions. The bed has already shown you both: each height of its jagged ground was drawn on its own, and its clearings came from a noise field in which nearby positions receive related values. What changes when difference acquires a neighbourhood?

[^chance-repertoire]: The “Randomness” chapter of *10 PRINT CHR$(205.5+RND(1)); : GOTO 10*, pp. 125–127, discusses chance operations in Cage, Kelly and Morellet: variation takes place within constructed parameters and arrangements. The distinction between sampling a wardrobe and changing its repertoire is this hall’s experiment, rather than a claim that chance abolishes authorship.


---

## 10 · Random_Space_Geometry

# What neighbours share

What makes neighbouring random heights belong together?

<!-- @perlin_noise_bridge -->

Through the connecting passage, the comparison bench stands among the shapes in the second room. Look closely at neighbouring columns in the two small grids. On the WHITE NOISE side, compare one height with the next. On the PERLIN NOISE side, follow a group of heights across several cells. Describe the difference before calling either one a landscape.

Keep SEED fixed and adjust FREQUENCY. Watch how the scale of features changes on the coherent side. Watch the WHITE NOISE side as you do: not one of its columns moves. With the seed and draw order kept, every redraw returns the same independent values. The frequency control belongs to the other construction: it changes where the grid samples the field. OCTAVES, beside it, lays finer layers of Perlin noise over the broad shape; the white side ignores that slider too. Then choose another seed or press RESAMPLE and repeat the comparison. The two kinds of field remain distinct even when their particular arrangements change.

Choose three neighbouring columns: rising, falling, or turning between the two? Move one place along and repeat. A chance run of similar heights can occur on the independent side too. Follow a longer stretch before letting a resemblance stand for the same procedure.

Independent samples supply each white-noise height separately. Perlin noise supplies related values at nearby positions through a spatial construction.[^perlin] Those local relationships make broader features possible. The two grids use comparable height displays, but they do not draw from identical distributions merely because their values fit within similar bounds.

You are changing a rule about relationships in space. The columns need not each be chosen by hand.

Look for something terrain-like in the independent grid, then for an unexpected edge in the coherent one. Perception is good at supplying landscapes, and this work prompts one: its subtitle reads “From chaos to terrain”, and both grids are painted on one ramp that runs from blue through green to white, like water, grass and snow. That skill can help you notice a structure, but it cannot establish that erosion, water or geological forces produced it. These are height fields with a colour mapping, not miniature geological histories.

<!-- @ -->

At the tutorial table, the columns keep one grey material. You retain the independent heights while changing the field. A number names the average gap between neighbours, but a row is still worth following with your eye. Two arrangements can contain the same numbers and ask you to cross very different surfaces.

One productive discipline is to keep withholding the landscape reading, despite the subtitle and the palette, and describe only local differences. On the installed bench, both grids share one height scale and one colour ramp, so differences in local spread can be read directly; the panel offers no other palette, so setting the landscape aside is left to you. Now look at the shapes scattered around the hall: each one's position was drawn on its own, uniformly inside a box, and the links between them join pairs picked at random, near or far; distance decides only what kind of link is drawn. In the next room, the dartboard uses random samples for estimation: where they land will matter, because its numerical answer depends on how the sampling rule covers the square. Each of its darts, from THROW, from AUTO or already on the board when you arrive, is placed by the same kind of draw as those shapes and the WHITE NOISE heights, uniform and with no neighbour consulted: do such draws cover a square evenly, or do they leave clumps and gaps?

[^perlin]: The bench uses Godot's FastNoiseLite Perlin mode with layered fractal noise. The tutorial uses the same mode with one layer. Perlin noise relates values through a lattice of gradients; this names a construction, not a claim that the present library reproduces the original implementation exactly. See [Godot: FastNoiseLite](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html). The mixer in Random Space is a sum of sines and is identified there as such.


---

## 11 · Randomness_Examples_of_Randomness

# What chance may change

Four works share the gallery. Walk toward the painting on the floor, then take either side around its frame. The dartboard and pipes wait farther along, and a changing particle study near the rear. Each gives chance a different job. The estimation the last room promised is the dartboard's job.

<!-- @pollock_painting_in_3d -->

Stand at the near edge of the canvas. Find a thin line, a broad mark and a cluster of small splatters. Wait for another layer, then follow the brush cursor as it traces a path. Walk around the frame. A mark that was distant is now close enough to inspect.

This is a Pollock-inspired generative homage, not a reconstruction of a particular painting. The program chooses positions, colours from a fixed palette, drip sizes and line widths. A line begins with a sampled direction, then turns by small sampled angles as it advances. At an edge, the direction reflects back toward the canvas. Chance can bend the route; it cannot enlarge the canvas or invent a colour outside the palette.

The marks are painted into a two-dimensional image shown on the floor. When a new layer appears, the small three-dimensional cursor retraces the path of one of its lines, which is already painted. It replays a procedure; it is not a brush whose movement you are controlling, and the drops are not a simulation of falling paint.

Choose a passage you like. Which part could have arrived differently? Which part was already decided by the palette, line rule, canvas and interval between additions? Calling the result random can make those authored choices disappear from view. The work becomes more interesting when we keep them visible.

<!-- @monte_carlo_dartboard -->

Move to the dartboard's console. Press REPLAY. Press THROW and find the new point. Compare its location with the circle, then check which counter changed. Add a few more points individually before using +100 or FILL to build a larger sample.

An inside point increases both the inside count and the total. An outside point increases the outside count and the total; the inside count stays where it was. Before requesting another point, predict what each possibility would do to the estimate. Check with THROW, and explain the change from the counters before looking at the distance from pi.

The circle is inscribed in a square. When points are sampled uniformly across that square, the fraction landing inside estimates the fraction of area occupied by the circle. This is a Monte Carlo estimate: a quantity approached through sampled trials. Multiplying that fraction by four gives the displayed estimate of pi:

`estimate = 4 × inside / total`

A growing sample does not require every new estimate to improve. Repeat the prediction when many points are already present: one addition usually changes the ratio less. A steadier number still depends on how the points were sampled.

THROW requests a generated sample. You are not aiming a physical dart with your hand. A sampler that favoured the centre would tend to count too many points inside; adding more of those points would not repair the bias. REPLAY clears the record and returns to the same seed. NEXT SEED begins a different run. Turn BUDGET to choose 100, 500, 2000 or 8000 samples, then FILL; changing the budget starts that seed again, so larger budgets extend the same opening sequence. The board itself shows only the newest 300 marks: past that, the picture forgets points the numbers still include. Press 8 SEEDS to compare several estimates without replacing your current run. A comparison gives you more evidence, not a promise that every increase in budget improves every result.

The small reconstruction lets you narrow the sample to a strip without moving the circle. The number can become steady while answering a different question. The failure is in the agreement between the places sampled and the area the number claims to describe.

Here chance chooses the evidence. The circle's boundary and the counting rule remain fixed. Who gets to decide that the sampling procedure covers the space fairly enough for the answer we want?

<!-- @pipe_dream -->

Cross to the pipe study. Follow a length to its next corner, then look for a place where the path doubles back near an earlier passage. If growth has finished by the time you arrive, the whole retained path is still available to inspect. The colour shifts gradually from one length to the next, swinging between cyan and magenta twice over the run, so two neighbouring passages in clearly different colours were not laid one after the other: the pipe came back to that place later in the run.

The pipe advances in one of six axis directions. A preference sometimes keeps it moving straight; otherwise the program shuffles possible turns and takes a direction that stays inside its bounds. It rejects an immediate reversal. It does not keep a list of occupied cells, so crossing an earlier route is allowed.

The default run stops after 180 segments. A dense tangle therefore does not certify that the volume has been filled, or that every corner was reached. The limit ends the run whether or not its shape looks complete to us.

Look across the empty spaces between pipes. The same local rules could have left different gaps. What would change if a previous visit made a place forbidden? That would add a memory and a new restriction, not merely turn up the amount of randomness.

<!-- @extreme_randomness -->

The particle study occupies the last bay. Stay through a full cycle. Its five chapters change about every ten seconds. Watch for a change in the particles' arrangement as well as their movement; the chapter transition restages them.

For this gallery, every chapter stays inside the same spherical boundary. A particle that would escape is brought back to the edge and its outward velocity reflected. This added limit keeps the changing study above the floor and within its bay.

In the first chapter, random forces change velocities that persist from one frame to the next. Damping slows them, and a boundary turns escaping particles back. Successive positions retain a history. They are not independent points redrawn across the whole volume.

The noise chapter follows a smooth field made from sine and cosine functions in this implementation. No random draw enters that motion, and its caption says it is not Perlin noise. The last room's coherent heights changed with SEED; this field has no seed to change. The pattern chapter adds spiral motion and oscillation to its opening arrangement. The emergence chapter combines separation, alignment and cohesion with small random nudges. The evolution chapter ranks particles by their distance from a moving target; the leading tenth influence the others.

These are five sketches of different procedures, not five strengths of the same white noise. Nor is the final chapter a population that breeds: the same fixed set of particles keeps moving under a selection rule. A title gives us a starting question; the update rule tells us what is actually happening.

<!-- @ -->

Look back toward the painting. In one work, chance chose marks; in another, samples to count. It chose permitted directions for the pipe and different kinds of variation within the particle study. In every case something decided what a random choice was permitted to change.

Carry that question into the pheromone terrain. The pipe did not remember which places it had passed; the next walkers will leave a signal that can enter a later decision. What changes when a visit helps recruit another visit? Random Game still waits ahead, where such distinctions will become questions of support and timing.


---

## 12 · Random_Pheromone

# A path that recruits its next visit

What changes when a walker helps make the evidence its next decision will read?

<!-- @pheromone_terrain -->

At the console, leave ATTRACT selected and press +1 STEP a few times. Follow one cyan marker from place to place. Use +20 STEPS to advance a batch, then choose a small patch of terrain and compare it with a quieter patch nearby. Watch where traces gather and where the surface begins to rise, then look for later walkers returning through those regions.

Keep one rising patch in view. Does traffic return, or shift elsewhere? Its height remains visible while its current scent can fade. To explain a return, we need to distinguish the history we see from the signal the walker reads.

Each visit away from the flat border band leaves pheromone and, until that patch reaches its height ceiling, raises the local surface. Later choices can favour a stronger pheromone signal, while most movement remains random (the label over the field reads signal-guided: 40%). A path can therefore become established partly because it has already been used. No walker needs a complete plan of the resulting network for this feedback to occur.

This differs from the terrarium's memoryless step rule. There, the trail helped the observer read the past without steering the next step. The last room's pipe could cross its own earlier route for a similar reason: no place it had passed entered its next choice. Here the environment keeps a signal that participates in future decisions. The mark has become part of the mechanism. In the small reconstruction, the same walker appears twice: beside its fading scent and beside the visits that remain counted. Two pictures can belong to one history without keeping the same part of it.

The signal and the raised terrain do not keep identical histories. In the reconstruction, let the scent disappear while retaining the visits. The columns still show where the point has been. What survives for us is no longer what can guide it. Pheromone decays; the surface records accumulated visits in another form. A visually prominent ridge and the strongest current scent therefore need not mean exactly the same thing. Distinguish what you can see from what the movement rule reads.

Try identifying a route that may have begun as an accident. Repeated use can reinforce it, but reinforcement does not establish that it is globally shortest, fairest or best. A clipboard in this hall claims more: that shortest paths get reinforced and that the collective finds the optimal route. Its ants carry food back to a nest; these walkers have no nest and no food, so a route here has no two ends to be shortest between. The procedure rewards a particular local signal, and that signal partly reflects its own earlier choices. Not every beginning is an accident, though: where all eight sensed directions read the same, as on fresh ground, a signal-guided walker takes the first direction on its list, and that direction always points the same way.

Could the same act of leaving marks help make a different world? Note the step count, press AVOID and advance to the same count. The terrain and scent clear, and the four walkers begin again from the same seeded positions; this time the signal-guided choice favours the weakest scent. Compare the resulting visits before deciding what the changed rule did. REPLAY restarts the selected rule. Both experiments use the same fixed decay interval per step, although their paths can cause later random draws to be used differently at the boundary.

<!-- @ -->

Next, the noise mixer returns to field construction: several contributions at different scales will combine without depending on a history of visits. Its picture is coloured like land, but no visit shaped it.


---

## 13 · Random_Space

# Layers that look like land

How much of a landscape can be made by repeating a rule at different scales?

<!-- @noise_mixer -->

Reduce OCT to one and follow the boundary between a light region and a dark one. Add layers while keeping LAC and PER fixed. Finer variations enter the sum. Step OCT back down and the earlier picture returns: this field keeps no history of the settings you passed through.

PER changes the layers' relative amplitudes; LAC changes their frequency ratio. Try each at one layer, then at two. Only with a later contribution can either ratio make a difference. SEED chooses another set of offsets.

Describe a change in feature size separately from a change in contrast. The picture stretches its own numerical range; its confidence of colour can survive a shrinking difference.

The field adds scaled versions of a base function. Each layer samples at another frequency and contributes another weighted value. In this display the base is made from several sine expressions, so the noise-like surface connects back to the synthesis lab's lesson: a complex appearance can come from adding simpler contributions.

Look down: a violet surface rises a little above the grey floor. You can follow its unevenness across the room. It is made of small triangles, and the height of every corner is drawn on its own, as each column was on the WHITE NOISE side in Random Space Geometry: one corner's height tells you nothing about the next. The colour separates this ground from its surroundings; it does not explain why one corner is high and the next is low. In the picture on the plinth, neighbouring pixels are samples of the same smooth sum taken a short distance apart, so they mostly agree, and a broad feature carries across many of them.

<!-- @worley_noise -->

Beside the mixer, a small blue cellular field on a low stand offers another way for neighbours to belong together. Here the value comes from a difference between distances: how far away are the nearest scattered point and the next nearest? Along a seam those distances nearly agree. Follow one seam, then look back at the mixer's broad layers. Both can suggest a landscape, but their neighbours have been related by different rules.

![A blue cellular field on its low stand above the violet random ground.](images/cellular-field-violet-ground.png)

<!-- @shannon_entropy_meter -->

Farther along, the entropy gauge returns from the second room. It counts its own two hundred symbols; it is not measuring either field around it. Recall what its number kept of an arrangement and what it lost. A count of symbol shares cannot tell you whether similar values lie together, make a seam, or have been scattered apart. Here the familiar instrument gives us a limit to carry back to the images.

<!-- @noise_mixer -->

Back at the plinth, colour supplies another part of the picture's reading. Low and high values are mapped through an earth-toned palette, encouraging you to see water, vegetation, rock or peaks. Those interpretations are useful associations, but the program has not thereby simulated water movement or the growth of plants.

Describe the picture once using landscape names and once using only high values, low values and spatial variation. Notice what the first description adds. The texture is also normalised to its own range, so a strong colour contrast need not indicate a large absolute numerical difference from another setting.

<!-- @ -->

The small reconstruction gives that comparison a place. Two screens show the same sum: one keeps a shared grey scale; the other stretches its own range. Make the values smaller and the second picture can remain just as emphatic. The landscape has not grown back. The display has spread a narrower difference across the same distance from black to white. The heights under your feet were drawn once and hold still while you stand on them. The cycling stones in the next room put uncertainty into timing instead of texture. You will know the order of their states. The pauses between them are drawn, and how much you can know about one depends on where you look.


---

## 14 · Random_Game

# Told, or finding out

In the mushroom bed, a draw helped decide which body appeared. In the gallery it became paint, an estimate and a path. Here it helps decide whether a body will still be there when yours arrives.

<!-- @r_c -->

Three cyan stones cross a rectangular pit. Their tops stand just above the museum floor. Beyond them, a lit prism stands on a plinth carrying a five-digit number. Watch the middle stone. When it leaves, what would you be standing on?

Orange, a sinking. The bed below remains. Then green, a rise, cyan again. A second cycle begins to feel familiar while its pauses refuse to settle into a beat.

The stele names four states: IT STANDS, IT LEAVES, IT IS GONE, IT RETURNS. Their order is fixed. A draw supplies a wait, held until its deadline. Look at the tablet: present state, last drawn wait, time remaining. The current pause has already been chosen. The next one has not yet been drawn.[^crossing-time]

The tutorial lets you pause a smaller stone and shorten its notice. Its wait stays the same while the time offered to you contracts. The deadline belongs to the event; the warning belongs to how it is made available.

Approach the first stone by its ramp. It can leave while you stand on it. The pit has a recovery bed and a ramp up its west side; the corridor to the east reaches the far lip too. Crossing is one way to investigate. Going around is another.

Watch the gold ring on the middle stone. It lights before the stone moves. Press CUE and observe without it. The movement beacon and the tablet remain. Neither asks for another wait. The same next event can be known through a ring before movement, a beacon during it, or a number you must turn toward. Before calling a missed step poor timing, ask where its warning was readable.

Appearance and support also have separate instructions. The collider remains through the sink, disappears while the stone is hidden, then returns before the rise. A shape below you need not be something the world will hold you on.

REPLAY returns the stones and their seeded waits. It must cancel their old movement and restore support too. Your knowledge survives the reset. A crossing can repeat while the person crossing it cannot return to not knowing.[^crossing-replay]

<!-- @random_removal_arena -->

The next glass enclosure brings Random Remove under your feet again. Entry selects a cell; walking asks for more. Red gives notice, then the cell and its support disappear. Fire burns below. The dark apron remains a route around the changing set, and the console can restore it. A choice among addresses has acquired a consequence for a body.

<!-- @random_doors -->

Beyond it, three doors face you. Stay behind the amber line and choose. One lifts and remains a passage. Another announces fire before sending a short jet toward the line. Watch before moving forward.

The passage was assigned at the start of the round. Pressing reveals that decision. It does not make another draw. One passage is guaranteed because we wrote that condition before choosing its index.

REPLAY restores the assignment. NEW SEED can choose the same passage again. After looking once, your next attempt is different even when the doors are not. Memory belongs to the player as well as the machine.[^fire-doors]

<!-- @door_timing_trials -->

Farther along, three small passages repeat the same plan. Two lettered plates lie before each entrance. One lane opens straight through; the other asks you to turn around a wall. Both reach the far side. The cost of a choice is a piece of walking.

At SHOWN FIRST, the letters already say DIRECT and AROUND. Step onto a plate. You can take the shorter passage or choose the longer one to see where it goes. Knowing does not prescribe what you must want.

At DRAWN AFTER, both letters carry a question mark. Your foot arrives before the shortcut is assigned. Watch the signs fill: CHOOSE, DRAW, REVEAL. The letter you chose stays chosen while its meaning arrives.

HIDDEN FIRST looks equally undecided, but DRAW is already lit. Something has happened without becoming available to you. Step onto a plate: CHOOSE, then REVEAL. Could the walk alone have told you whether the assignment came before your step or after it?

The walls and possible answers remain the same. What changes is the order: draw, reveal, choose; choose, draw, reveal; draw, choose, reveal. A question mark can stand for an undecided future or a decision withheld. On the door they look alike.

REPLAY restores that passage's seed. An answer withheld by the sign may remain in your memory. Take the longer way once. A letter becomes a turn of the body, a wall passing close to your shoulder, a few more steps. The draw did not make that distance. We built its consequence.[^passage-rounds]

<!-- @cube_projectile_spawner -->

After the doors, cubes arrive from above. Watch from the edge. Does their rhythm vary like the stones' pauses?

Press RUN / STOP. Some cubes keep moving. Press CLEAR. Stopping the source did not recall what it had released. Clearing the flights does not stop the source, either. The two controls act on different parts of the process.

Here a regular clock attempts a launch every half-second. Chance chooses the launch position and velocity. The lines on the floor mark the square from which initial centres are drawn; they cannot promise where a moving cube will end up. Its later motion has another generator, and collisions add their consequences.[^falling-field]

The crossing sampled a wait. This field samples a launch on a regular clock. The word *random* cannot tell us where to look. The last podium changes the rhythm again.

<!-- @waiting_profile -->

Wait for a small wooden cube to land. Another arrives at the other position. The places alternate; after the first wait, each delay is drawn afresh. The positions are dependable while the rhythm is not.

Pick one up. Arrivals wait while either cube is held. Release it and the clock continues. There are only two places: the next arrival replaces the cube in its slot. Your hand can suspend this small system. REPLAY restores its arrival sequence, not your gesture or an identical landing.

Beside the podium, five cutout profiles recede into the room. The nearest is dark; those behind grow lighter. Move sideways. One contour uncovers another, and a landscape appears between flat panels.

![The waiting podium and its five receding profiles, photographed from inside the museum.](images/waiting-and-seeing.png)

Before you change PROFILE, the nearest contour carries the first fifteen drawn waits from the podium's seed, flattened toward its fixed ends. Read from the end nearest the podium. A height above the level of those ends stands for a longer-than-middle wait. The panels behind it use other draws; changing PROFILE breaks this particular correspondence.[^waiting-shape]

Here you can look back and forth along the sequence. At the podium you had to wait through it. What did seeing the whole shape let you anticipate?

<!-- @ -->

At the continuing die, a six kept a chain open. Its face was already on the felt when an instruction gave it that power. The doors put assignment before choice and let disclosure wait. The passages let us separate those events and walk what follows.

Which decisions are already made, which are still to come, and what tells us the difference? Carry that question into Noise Types, between neighbouring places. A choice can be uncertain and still have a relation to the choice beside it.

[^crossing-time]: Standing waits are 2.4–4.6 seconds; hidden waits 1.1–2.2. Sinking, rising and collider delays take additional time. During movement the tablet retains the preceding draw with zero wait remaining. The advance ring covers the last 1.2 seconds of standing. CUE toggles the rings without removing the tablet or movement beacons. Stone tops are 22 cm above the floor, gaps 12 cm, and the recovery bed is 1.02 m below the floor. The complete support schedule is in the tutorial.

[^crossing-replay]: Each REPLAY returns the same first waits, though the middle stone initially enters the hall with a different opening wait. NEW SEED differs from the current number but can revisit an older one. Only this crossing is reset.

[^fire-doors]: The removal floor here has 81 cells. The fire doors begin each hall build with the same seed. A fire door warns for one second, sends a jet reaching 2.7 m, then closes; the passage stays open until reset.

[^passage-rounds]: Each disclosure trial has its own seed. NEW ROUND changes that seed but can still assign the same shortcut. One passage does not disclose another's answer.

[^falling-field]: Launches begin eight metres above an eight-metre square, with downward speed between 1.6 and 2.6 m/s plus small sideways velocities. Each cube lasts ten seconds. The 24-body limit does not bind at one launch every half-second. Repeating a launch seed alone does not reproduce the projectile's subsequent random changes or physical collisions.

[^waiting-shape]: The first wait is one second; later waits lie between 0.3 and 1.3 seconds. Cubes fall from three metres onto a two-metre-square podium. Each profile joins seventeen heights, with fixed ends and fifteen variable interior samples. On the nearest initial profile, the reference height corresponds to 0.8 seconds. Samples are flattened toward the ends. PROFILE draws new contours; the correspondence with replayed waits then ceases.
