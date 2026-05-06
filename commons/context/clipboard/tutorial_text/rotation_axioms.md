**Rotation**
Spinning the Question of Which Way Is Up

If translation changed where an object is, rotation changes which way it faces. Position remains fixed - orientation spins. The object turns without traveling.

Rotation is the transformation that asks: which way is forward? Which way is up? And reveals: these are not absolute directions, but relative orientations.

---

## Orientation as Mutable Property

Before rotation, an object had a facing - a forward direction, an up direction, a local coordinate system aligned with the world. Rotation reveals that orientation is not intrinsic.

**Code: The Rotation Operation**

var cube = MeshInstance3D.new()
cube.position = Vector3(0, 0, 0)  # Stays here
cube.rotation = Vector3(0, 0, 0)  # Not rotated

# Rotate 90 degrees around Y axis
cube.rotation.y = deg_to_rad(90)

# Position unchanged: Vector3(0, 0, 0)
# Orientation changed: