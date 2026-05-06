**The List**
Index as Address, Order as Law

Everything in the algorithm is organized in lists.

Points become arrays of coordinates. Colors become arrays of values. Vertices become arrays of positions. The world itself is an array of objects, each object an array of properties, each property an array of data.

**The list is the fundamental structure of computational organization.**

And every list imposes **order** - a sequence, a first and last, an index that addresses each element by position.

---

## The Array: Sequential Container

An array (or list) is a sequential collection of elements, each identified by an **index** - an integer position starting at 0.

**Code: The Indexed Sequence**

```
# A list of numbers
var numbers = [10, 20, 30, 40, 50]

# Access by index (position)
var first = numbers[0]   # 10
var third = numbers[2]   # 30
var last = numbers[4]    # 50

# Index is the address
# Every element has a position
# Position is mandatory, not optional
```

The array is not a set (unordered) or a bag (duplicates allowed randomly). It is an **ordered sequence** where:
- Element 0 comes before element 1
- Each element has exactly one position
- Position determines identity (numbers[2] is