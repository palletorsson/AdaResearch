**Noise Layers**
The Symphony of Frequencies

## One Note vs. A Chord

A single layer of noise is like a sine wave—smooth, predictable, lacking texture.
To get the complexity of nature (mountains, bark, clouds), we need **Octaves**.

---

## Fractal Summation

We add multiple layers of noise together, each with:
1. **Higher Frequency** (closer together)
2. **Lower Amplitude** (less influence)

**The Recipe:**

```
Total = Noise(x) * 1.0        # Octave 1: Mountains
      + Noise(x*2) * 0.5      # Octave 2: Boulders
      + Noise(x*4) * 0.25     # Octave 3: Rocks
      + Noise(x*8) * 0.125    # Octave 4: Pebbles
```

---

## Interactable: The Noise Torus

This torus is displaced by noise.
- **Use the sliders** to change:
  - **Frequency:** How