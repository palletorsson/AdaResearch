**Translation**
Movement Through Indexed Space

Translation is the simplest transformation: moving an object from one position to another without rotating it, without scaling it, without changing anything about its internal structure.

Translation is pure displacement. The object remains identical to itself - only its address in space changes.

---

## Position as Mutable Property

Before transformation, we had static primitives - forms frozen in space. Translation reveals that position is not intrinsic to an object. The cube is still a cube whether it sits at (0,0,0) or (5,3,2).

**Code: The Translation Operation**

```
var cube_position = Vector3(0, 0, 0)
var displacement = Vector3(5, 0, 0)

# Translation is vector addition
var new_position = cube_position + displacement
# Result: Vector3(5, 0, 0)

# The cube has moved 5 units along X axis
# But the cube itself is unchanged
```

Translation is addition in vector space. The object