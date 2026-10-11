# Draws the one floor picture of the world: a checkerboard with studs, ready to upload.
# Writes assets/textures/floor-tile.png (512x512, transparent background).
#
# Run from the project folder:
#   python tools/textures/make_floor_tile.py
# Needs Python with Pillow, numpy and scipy.
#
# How the picture is used in the game (see Config/Ui, world):
#   It lies as a tiled texture on a big floor part. The part has the darker of the two tones.
#   The picture is tinted with the lighter tone. So one picture works for every floor color.
#
# What is in the picture:
#   * 2 x 2 checkerboard fields. Two of them are solid white (they become the lighter tone),
#     the other two are see-through (the darker tone of the part shows).
#   * On every field 4 x 4 studs. A stud is drawn only with soft dark shading (a thin ring and a
#     shadow at its lower right), which works the same on both tones.
#   Invisible pixels are white, not black. Otherwise a thin dark line would appear between the
#   fields when Roblox scales the picture.

import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

PROJECT = Path.cwd()
TARGET = PROJECT / "assets" / "textures" / "floor-tile.png"

SIZE = 512
# Drawn this many times bigger and then scaled down, so edges come out smooth.
OVERSAMPLE = 4
FIELDS = 2
STUDS_PER_FIELD = 4

# All of these as a share of the distance between two studs.
STUD_RADIUS = 0.3
RING_WIDTH = 0.035
SHADOW_OFFSET = 0.075
SHADOW_BLUR = 0.03

# How dark the shading is (0 = invisible, 1 = black).
RING_DARKNESS = 0.1
SHADOW_DARKNESS = 0.26


def main():
    if not (PROJECT / "assets").is_dir():
        sys.exit("Folder 'assets' not found. Run this from the project folder.")

    big = SIZE * OVERSAMPLE
    studs = FIELDS * STUDS_PER_FIELD
    cell = big / studs
    y, x = np.mgrid[0:big, 0:big].astype(np.float32) + 0.5

    # Position inside the own stud cell, measured from the cell's middle, in cells.
    inside_x = (x % cell) / cell - 0.5
    inside_y = (y % cell) / cell - 0.5
    distance = np.hypot(inside_x, inside_y)
    stud = distance <= STUD_RADIUS
    ring = (distance <= STUD_RADIUS) & (distance >= STUD_RADIUS - RING_WIDTH)
    # The shadow is the stud's shape moved to the lower right, minus the stud itself.
    moved = np.hypot(inside_x - SHADOW_OFFSET, inside_y - SHADOW_OFFSET) <= STUD_RADIUS
    shadow = ndimage.gaussian_filter((moved & ~stud).astype(np.float32), SHADOW_BLUR * cell)
    shadow[stud] = 0

    darkness = np.maximum(shadow * SHADOW_DARKNESS / max(float(shadow.max()), 1e-6), ring * RING_DARKNESS)

    # Which fields are the light ones: top left and bottom right.
    field = big / FIELDS
    light = ((x // field) + (y // field)) % 2 == 0

    # Light fields: solid, white, darkened by the shading.
    # Dark fields: see-through, only the shading is there, as black with its own strength.
    alpha = np.where(light, 1.0, darkness)
    value = np.where(light, 1.0 - darkness, 0.0)

    # Scale down. Colors are weighted by how visible they are, so the edges stay clean.
    def shrink(values):
        return values.reshape(SIZE, OVERSAMPLE, SIZE, OVERSAMPLE).mean(axis=(1, 3))

    small_alpha = shrink(alpha)
    small_value = shrink(value * alpha)
    visible = small_alpha > 1e-4
    color = np.ones_like(small_alpha)
    color[visible] = small_value[visible] / small_alpha[visible]

    pixels = np.round(np.clip(np.dstack([color, color, color, small_alpha]), 0, 1) * 255).astype(np.uint8)
    # Pixels that end up fully invisible are white (see the note at the top).
    pixels[pixels[..., 3] == 0, :3] = 255
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(pixels, mode="RGBA").save(TARGET, optimize=True)

    print(f"{TARGET.relative_to(PROJECT)}: {SIZE} x {SIZE} pixels")
    print(f"   {FIELDS} x {FIELDS} fields, {STUDS_PER_FIELD} x {STUDS_PER_FIELD} studs on each")
    print(f"   solid (light fields): {(small_alpha > 0.99).mean() * 100:.0f} % of the picture")
    print(f"   darkest shading: {(1 - color[small_alpha > 0.99].min()) * 100:.0f} % on light fields, "
          f"{small_alpha[small_alpha < 0.99].max() * 100:.0f} % on dark fields")


if __name__ == "__main__":
    main()
