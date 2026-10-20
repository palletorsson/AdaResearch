"""Bake the rooftop's metre grid as flat, transparent floor markings."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
image = Image.new("RGBA", (2048, 2048))
draw = ImageDraw.Draw(image)
font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 48)
small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 38)
chalk = (237, 234, 215, 235)
x_ink = (239, 163, 106, 255)
z_ink = (117, 201, 222, 255)

def p(x, z):
    return ((x / 5.2 + .5) * 2048, (z / 5.2 + .5) * 2048)

def line(a, b, ink, width):
    draw.line([p(*a), p(*b)], fill=ink, width=width)

def label(text, x, z, ink=chalk, face=font):
    draw.text(p(x, z), text, fill=ink, font=face, anchor="mm")

for i in [-2, -1, 0, 1, 2]:
    if i:
        line((i, -2), (i, 2), chalk, 5)
        line((-2, i), (2, i), chalk, 5)
        label(f"{i:+d}", i, .20, x_ink)
        label(f"{i:+d}", -.20, i, z_ink)
line((-2.2, 0), (2.22, 0), x_ink, 10)
line((0, -2.2), (0, 2.22), z_ink, 10)
draw.polygon([p(2.28, 0), p(2.13, -.07), p(2.13, .07)], fill=x_ink)
draw.polygon([p(0, 2.28), p(-.07, 2.13), p(.07, 2.13)], fill=z_ink)
label("+X", 2.3, -.22, x_ink)
label("+Z", .27, 2.26, z_ink)
label("-X", -2.3, -.22, x_ink)
label("-Z", .27, -2.26, z_ink)
draw.ellipse([p(-.15, -.15), p(.15, .15)], outline=chalk, width=7)
label("(0, 0, 0)", .58, .35)
label("WORLD X / Z    •    FLOOR Y = 0", 0, -2.48, face=small)
label("1 SQUARE = 1 METRE", 0, 2.48, face=small)
image.save(ROOT / "commons/void/textures/origin-floor-grid.png")
