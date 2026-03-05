# Suffix Array Corridor

A suffix array is every ending of a string, sorted. Take any text, generate all suffixes, alphabetize them, store only the indices. That's it — a sorted list of integers that encodes the entire substring structure of a sequence. Binary search finds any pattern in logarithmic time. No tree overhead, no pointer chasing. Just sorted positions.

The corridor stretches long and narrow — fourteen cells deep, five wide, alcoves branching at regular intervals. Walk it linearly but search it logarithmically. Each alcove holds a suffix, ordered not by where it appears but by what it says. Position yields to lexicography. The original sequence dissolves into alphabetical rank.

Suffix trees store the same information with explicit branching. Suffix arrays flatten that tree into a single sorted column — trading structure for compression, pointers for positions. Less memory, same power. The redundancy was always optional. Identity is just an index into every way something can end.