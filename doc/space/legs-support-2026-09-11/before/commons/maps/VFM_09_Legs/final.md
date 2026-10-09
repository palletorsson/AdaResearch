Count the legs, and the walk follows: not as a style, but as arithmetic.

Seven walkers stand in one row on the floor, one leg to eight, and nothing about them is on a plinth, because a thing that paces wants the ground. Every one of them is the same build: a small box body a hand above the floor, and long arching legs, taller than you are at the knee, reaching out to feet more than two metres from the centre. Every one glides at the same slow pace, turns when it likes, and turns for home when it has strayed a metre and a half. The only thing that changes from bay to bay is the count. That is the experiment.

## The rule

```gdscript
# a body is statically stable while its centre of mass sits inside the
# polygon formed by the feet that are currently planted
func can_lift(planted: Array[Vector3], com: Vector3) -> bool:
    if planted.size() < 3:
        return false          # two points make a line, and a line is a fall
    return _inside_polygon(planted, com)
```

Read it once and carry it down the row. Fewer than three feet on the ground is a fall. Three or more, and the body stands only while its centre is inside the shape they make. Nothing else is needed. Now the count decides.

## The row

<!-- @one_leg -->

One leg, and no step at all. A step needs another foot to stand on while this one is in the air, and there is no other. So the one foot does the only thing the rule leaves it: it stays down, and it is dragged along the floor beside the body as the body glides, swinging round when the body turns. The honest gait for one leg is a hop, and a hop needs the whole body to leave the ground. Nothing in this row leaves the ground.

<!-- @two_leg_critter -->

Two legs, and here is the rule that the next four walkers all share, so learn it once. A foot stays planted where it landed while the body glides on. When it has been left a metre and a half behind its shoulder, it steps: a quarter of a second, a metre high, landing a little ahead. One foot in the air at a time, never two, and always the foot that has been left furthest behind. With two legs, one foot up leaves one foot down. A single point is not a shape. By the rule, every step is a fall.

<!-- @three_leg_critter -->

Three legs, and one foot up leaves two, which is a line, which is a fall. Three is the smallest number that stands still by the rule, and the first number that cannot take a step by it. Watch the burst: after a turn the three feet find themselves stretched together, and they step one after another, a quarter of a second each, and then all three are down for a long while as the body slides on bent legs.

<!-- @four_leg_critter -->

Four legs, and now the rule gets interesting. One foot up leaves three, a triangle, and a triangle is a shape. But look where the centre sits: on the diagonal of the square the feet make, which is exactly the edge of the triangle that remains. On the line, and a line is a fall. A four-legged animal steps by leaning first, a hand's width off the diagonal, and then lifting. This one never leans. Its body is held level and slid forward, and its feet catch up.

<!-- @five_leg_critter -->

Five legs at equal angles, and the rule starts to pass. One foot up leaves four, and the centre is well inside. Five is also where a pattern appears that no even walker has: lift any two feet that are apart, and the animal stands; lift any two that are neighbours, and it falls. Five pairs pass, five fail, and no mirror maps the passing set onto itself.

<!-- @six_leg_critter -->

Six legs, and one foot up leaves five. The rule is satisfied with room to spare, and the same is true of any way of lifting three at once so long as they alternate: the other three make a triangle round the centre. This walker takes the cautious road and lifts one.

<!-- @octapod_ik -->

Eight legs, and a different animal. It is about half the size of the others, faster on its feet, and it is the only one in the row that lifts a group: four feet at once, every other leg, so that the four still down make a square round the centre, and then the other four. Four on the ground at every instant. Of the seven, it is the only one whose stepping passes the rule while it moves.

<!-- @ -->

## What the count buys

A gait is not a style. It is what is left once you know how many feet are on the ground and how many can be in the air at once.

Lay the row against the rule and it reads like a table. One cannot step. Two and three step and fall. Four steps and falls unless it leans, which it does not. Five and six step and stand. Eight lifts four and stands. None of them fall, because nothing in this hall is a body that gravity can catch: they are drawings of walkers, held at their height and slid along, and the rule on the wall is the exam gravity would set if it were here. Gravity was the last hall. Here it has been left outside, so that you can read the exam instead of watching it marked.

That is what a diagram is for. A fall you could only have felt; the reason for it you can see. Count the feet on the ground, subtract the ones in the air, and ask whether the centre is inside what is left. Everything a gait is comes out of that subtraction.

One teleport on, in the Arena, a small black crab on four long jointed legs is walking the only true plant-and-step gait in this museum, at a tenth of this size, and it is looking for you.
