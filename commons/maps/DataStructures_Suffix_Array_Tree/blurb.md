A long corridor with regular side alcoves. Each alcove holds a suffix — the string from some position to the end. The alcoves are sorted, not by position in the original string, but by lexicographic order of the suffixes themselves.

A suffix array takes every possible ending of a string and sorts them alphabetically. "banana" yields: a, ana, anana, banana, na, nana. Sorted. Now binary search finds any substring in log-n time. The suffix tree achieves the same with a more complex branching structure, but the array is simpler — just indices, sorted by what they point to.

The corridor enforces linear traversal. The alcoves enforce sorted order. Position in the original string is forgotten; what matters is the alphabetic rank of each ending. The structure reindexes a sequence by its own suffixes — a text that becomes its own search index.
