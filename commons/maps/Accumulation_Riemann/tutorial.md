# Accumulation: one height represents an interval

Continue from Change_Intro with the same function, `0.5 + 0.4*sin(2*x) + 0.15*cos(5*x)`, on [0,5]. The earlier bench compared local rates; this bench adds height-times-width contributions. Its axis is position, not elapsed time.

1. Begin with four midpoint rectangles. Use CELL +/- to follow the selected sample and read its height, width and contribution.
2. HOLD the current picture and total. RULE cycles MID, RIGHT, LEFT. Compare equal counts before changing resolution.
3. Return to MID and move the existing count slider through 4, 8, 16, 32, 64, 128. The held panel remains unchanged until another HOLD or RESET.
4. Reveal REFERENCE after predicting which total is closer. It is a separate 4096-midpoint computation. Toggle it off to recover the contribution readout.
5. RESET restores four midpoint rectangles, hides the reference and clears the held comparison.

The calculation is `width=(b-a)/n`, `x=a+(i+fraction)*width`, `total+=f(x)*width`. The sample fractions are 0, 0.5 and 1. Selected samples, rectangle heights and total all use the same rule. The curve drawing stays fixed at 200 intervals. Held geometry copies vertex arrays so later live rebuilds cannot alter it.

At N=4, MID is about 2.23665, RIGHT about 3.26367 and LEFT about 3.53733. The reference is about 2.86384. RIGHT is closer than MID here, disproving the old claim that midpoint always wins. For this smooth function, fine partitions converge toward the integral; six finite slider stops are an experiment, not the limit itself.

The difference bar saturates at 0.05. Its numeric readout retains the signed difference. The function is positive throughout this encounter; signed cancellation and total distance are later experiments, not demonstrations already present here. The rectangles are a mounted plot, not walkable steps.

The next hall, Flow_Field, introduces trajectories whose sampling addresses depend on prior movement. Verify the actual field and update rule there before connecting it to forces.
