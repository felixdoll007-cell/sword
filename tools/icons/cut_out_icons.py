# Cuts the menu icons out of their magenta background.
# Reads every picture in assets/icons/roh (only read, never changed) and writes
#   assets/icons/<name>.png    512x512, transparent background, cropped square around the drawing
#   assets/icons/vorschau.png  all icons side by side on dark blue-grey, large and in 64x64
#
# Run from the project folder:
#   python tools/icons/cut_out_icons.py
# Needs Python with Pillow, numpy and scipy.
#
# What it does with each picture:
#   1. Measures the background colour at the border of the picture.
#   2. Every pixel close to that colour becomes transparent, wherever it is. So the gaps inside the
#      drawing (under a handle, inside a grip) go as well, not only the area around it.
#   3. The soft edge between the black outline and the background is a mix of both. There the
#      magenta share is taken out: it becomes transparency, what is left is the outline's colour.
#      That removes the pink fringe. Pixels that are not next to background are never touched,
#      so the outline and the colours of the drawing stay as they are.
#   4. Crops to the drawing, square with a small margin, scales to 512x512.
#   5. Gives the invisible pixels the colour of the nearest visible one. Otherwise Roblox would
#      blend a little of the old background colour into the edge when it scales the picture.

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

PROJECT = Path.cwd()
SOURCE_FOLDER = PROJECT / "assets" / "icons" / "roh"
TARGET_FOLDER = PROJECT / "assets" / "icons"
PREVIEW_NAME = "vorschau.png"
# Order in the preview. Pictures not named here follow in alphabetical order.
PREVIEW_ORDER = ["shop", "rebirth", "pets", "trails", "inventory", "gifts"]
SOURCE_TYPES = {".jpg", ".jpeg", ".png", ".webp"}

OUTPUT_SIZE = 512
# Empty margin around the drawing, as a share of the picture's side.
MARGIN_SHARE = 0.04

# Width of the frame at the border of the picture from which the background colour is measured.
BORDER_PIXELS = 8
# Tolerance: a pixel this close to the background colour (distance in RGB, 0 to 441) is
# background. The background itself stays below 20. The hot pink inside the rebirth icon starts
# at about 90 and must stay, so do not raise this beyond 80.
BACKGROUND_DISTANCE = 60
# A mix of background and drawing has red and blue almost equal, like the background itself.
# Drawn pink (much more red than blue) is told apart by this and never made transparent.
RED_BLUE_TOLERANCE = 40
# Background share from which a mixed pixel counts as "mostly background". Such pixels are
# followed as far as they reach from the background, so narrow darkened gaps are removed too.
# With 0.3 the pointed end of the gap in the backpack (inventory) stayed dark purple.
STRONG_SHARE = 0.2
# Smaller background shares are only removed this close (pixels) to background or to mostly
# background pixels. The measured soft edge is about 6 pixels wide.
EDGE_PIXELS = 7
# Shares below this are noise of the picture and are ignored.
MIN_SHARE = 0.06
# Edge pixels less visible than this take their colour from the nearest clearer pixel, because
# their own colour cannot be worked out reliably any more.
TRUSTED_ALPHA = 0.6
# Pixels more visible than this count as part of the drawing when cropping.
VISIBLE_ALPHA = 0.05

PREVIEW_BACKGROUND = (43, 52, 66)
PREVIEW_LARGE = 256
PREVIEW_SMALL = 64
PREVIEW_GAP = 32
PREVIEW_LABEL_SIZE = 18
PREVIEW_LABEL_COLOR = (200, 208, 220)

# Limits for the warnings in the report.
WARN_LEFTOVER_PIXELS = 40
WARN_LEFTOVER_EXCESS = 50
WARN_LEFTOVER_REACH = 8
WARN_DEEP_PIXELS = 400
WARN_SMALL_PART_PIXELS = 30


def magenta_excess(rgb):
    # How much more red and blue than green a colour has. High for magenta, 0 for grey tones.
    return np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1]


def cut_out(rgb):
    """rgb: float array (height, width, 3), 0 to 255. Returns colour, alpha (0 to 1) and notes."""
    height, width, _ = rgb.shape
    frame = np.concatenate(
        [
            rgb[:BORDER_PIXELS].reshape(-1, 3),
            rgb[-BORDER_PIXELS:].reshape(-1, 3),
            rgb[:, :BORDER_PIXELS].reshape(-1, 3),
            rgb[:, -BORDER_PIXELS:].reshape(-1, 3),
        ]
    )
    background = np.median(frame, axis=0)
    background_excess = float(magenta_excess(background))
    notes = {"background": background.round().astype(int).tolist(), "warnings": []}
    if background_excess < 150 or abs(background[0] - background[2]) > RED_BLUE_TOLERANCE:
        notes["warnings"].append("the border of the picture is not magenta")

    distance = np.sqrt(((rgb - background) ** 2).sum(axis=2))
    clear = distance < BACKGROUND_DISTANCE

    # Share of background in every pixel, assuming the drawing itself has no magenta in it there.
    share = np.clip(magenta_excess(rgb) / background_excess, 0, 1)
    balanced = np.abs(rgb[..., 0] - rgb[..., 2]) <= RED_BLUE_TOLERANCE
    mixed = balanced & ~clear & (share > MIN_SHARE)

    # Mostly-background pixels, as far as they hang together with clear background.
    everywhere = np.ones((3, 3), dtype=bool)
    labels, _ = ndimage.label(clear | (mixed & (share >= STRONG_SHARE)), structure=everywhere)
    with_background = np.unique(labels[clear])
    strong = np.isin(labels, with_background[with_background > 0]) & ~clear
    # Weaker tints only right next to them.
    reach = ndimage.distance_transform_edt(~(clear | strong))
    edge = strong | (mixed & (reach <= EDGE_PIXELS))

    alpha = np.ones((height, width), dtype=np.float32)
    alpha[clear] = 0
    alpha[edge] = 1 - share[edge]

    # Take the background out of the edge pixels' colour.
    color = rgb.copy()
    safe = np.maximum(alpha, 0.01)[..., None]
    unmixed = np.clip((rgb - share[..., None] * background) / safe, 0, 255)
    color[edge] = unmixed[edge]
    # Faint pixels: colour of the nearest clearer pixel.
    faint = alpha < TRUSTED_ALPHA
    if faint.all():
        notes["warnings"].append("nothing is left of the picture")
        return color, alpha, notes
    nearest = ndimage.distance_transform_edt(faint, return_distances=False, return_indices=True)
    color = color[nearest[0], nearest[1]]

    from_clear = ndimage.distance_transform_edt(~clear)
    notes["deep_pixels"] = int((strong & (from_clear > EDGE_PIXELS)).sum())
    notes["transparent_share"] = float((alpha < 0.5).mean())
    return color, alpha, notes


def describe(color, alpha, notes):
    """Adds counts to the notes that tell whether something went wrong."""
    height, width = alpha.shape
    everywhere = np.ones((3, 3), dtype=bool)

    hidden = alpha < 0.5
    labels, count = ndimage.label(hidden)
    outside = np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))
    sizes = ndimage.sum(hidden, labels, range(1, count + 1)).astype(int)
    notes["gaps"] = sorted((int(s) for i, s in enumerate(sizes) if (i + 1) not in outside), reverse=True)

    shown = alpha >= 0.5
    labels, count = ndimage.label(shown, structure=everywhere)
    notes["parts"] = sorted(ndimage.sum(shown, labels, range(1, count + 1)).astype(int).tolist(), reverse=True)

    visible = alpha > VISIBLE_ALPHA
    rows = np.flatnonzero(visible.any(axis=1))
    columns = np.flatnonzero(visible.any(axis=0))
    notes["box"] = (int(columns[0]), int(rows[0]), int(columns[-1]) + 1, int(rows[-1]) + 1)
    if columns[0] == 0 or rows[0] == 0 or columns[-1] == width - 1 or rows[-1] == height - 1:
        notes["warnings"].append("the drawing touches the border of the raw picture, it is cut off there")

    # Magenta tint that is still visible close to the transparent area.
    near_hidden = ndimage.distance_transform_edt(~hidden) <= WARN_LEFTOVER_REACH
    excess = magenta_excess(color)
    balanced = np.abs(color[..., 0] - color[..., 2]) <= RED_BLUE_TOLERANCE
    notes["leftover"] = int((shown & near_hidden & balanced & (excess > WARN_LEFTOVER_EXCESS)).sum())
    # Drawn pink or purple close to the edge. Kept on purpose, listed so it can be looked at.
    notes["pink_at_edge"] = int((shown & near_hidden & ~balanced & (excess > WARN_LEFTOVER_EXCESS)).sum())

    if notes["leftover"] > WARN_LEFTOVER_PIXELS:
        notes["warnings"].append(f"{notes['leftover']} pixels at the edge still look magenta")
    if notes["deep_pixels"] > WARN_DEEP_PIXELS:
        notes["warnings"].append(
            f"{notes['deep_pixels']} pixels far from the clear background were removed as darkened "
            "background. If the drawing has purple areas there, they are gone"
        )
    small = [size for size in notes["parts"][1:] if size < WARN_SMALL_PART_PIXELS]
    if small:
        notes["warnings"].append(f"{len(small)} tiny loose specks (under {WARN_SMALL_PART_PIXELS} pixels) are kept")


def scale(values, size):
    picture = Image.fromarray(values.astype(np.float32), mode="F")
    return np.asarray(picture.resize((size, size), Image.Resampling.LANCZOS))


def resize(color, alpha, size):
    """Scales a square picture. Colours are weighted by visibility so the edge stays clean."""
    new_alpha = np.clip(scale(alpha, size), 0, 1)
    new_color = np.empty((size, size, 3), dtype=np.float32)
    for channel in range(3):
        new_color[..., channel] = scale(color[..., channel] * alpha, size)
    seen = new_alpha > 1 / 255
    new_color[seen] = new_color[seen] / new_alpha[seen][:, None]
    new_color = np.clip(new_color, 0, 255)
    # Invisible pixels take the colour of the nearest visible one.
    if seen.any():
        nearest = ndimage.distance_transform_edt(~seen, return_distances=False, return_indices=True)
        new_color = new_color[nearest[0], nearest[1]]
    new_alpha[~seen] = 0
    return new_color, new_alpha


def crop_square(color, alpha, box):
    left, top, right, bottom = box
    side = max(right - left, bottom - top)
    side = int(round(side / (1 - 2 * MARGIN_SHARE)))
    start_x = (left + right) // 2 - side // 2
    start_y = (top + bottom) // 2 - side // 2

    height, width = alpha.shape
    square_color = np.zeros((side, side, 3), dtype=np.float32)
    square_alpha = np.zeros((side, side), dtype=np.float32)
    from_x, to_x = max(start_x, 0), min(start_x + side, width)
    from_y, to_y = max(start_y, 0), min(start_y + side, height)
    into = (slice(from_y - start_y, to_y - start_y), slice(from_x - start_x, to_x - start_x))
    square_color[into] = color[from_y:to_y, from_x:to_x]
    square_alpha[into] = alpha[from_y:to_y, from_x:to_x]
    return square_color, square_alpha


def to_picture(color, alpha):
    pixels = np.dstack([color, alpha * 255])
    return Image.fromarray(np.round(pixels).astype(np.uint8), mode="RGBA")


def build_preview(icons):
    font = ImageFont.load_default(PREVIEW_LABEL_SIZE)
    label_height = PREVIEW_LABEL_SIZE + PREVIEW_GAP // 2
    width = PREVIEW_GAP + len(icons) * (PREVIEW_LARGE + PREVIEW_GAP)
    height = PREVIEW_GAP + PREVIEW_LARGE + label_height + PREVIEW_GAP + PREVIEW_SMALL + PREVIEW_GAP
    preview = Image.new("RGBA", (width, height), PREVIEW_BACKGROUND + (255,))
    draw = ImageDraw.Draw(preview)
    for index, (name, color, alpha) in enumerate(icons):
        x = PREVIEW_GAP + index * (PREVIEW_LARGE + PREVIEW_GAP)
        y = PREVIEW_GAP
        preview.alpha_composite(to_picture(*resize(color, alpha, PREVIEW_LARGE)), (x, y))
        y += PREVIEW_LARGE + PREVIEW_GAP // 4
        draw.text((x + PREVIEW_LARGE // 2, y), name, font=font, fill=PREVIEW_LABEL_COLOR, anchor="ma")
        y += label_height - PREVIEW_GAP // 4 + PREVIEW_GAP
        small_x = x + (PREVIEW_LARGE - PREVIEW_SMALL) // 2
        preview.alpha_composite(to_picture(*resize(color, alpha, PREVIEW_SMALL)), (small_x, y))
    return preview.convert("RGB")


def preview_position(name):
    return (PREVIEW_ORDER.index(name) if name in PREVIEW_ORDER else len(PREVIEW_ORDER), name)


def main():
    if not SOURCE_FOLDER.is_dir():
        sys.exit(f"Folder not found: {SOURCE_FOLDER}. Run this from the project folder.")
    sources = sorted(path for path in SOURCE_FOLDER.iterdir() if path.suffix.lower() in SOURCE_TYPES)
    if not sources:
        sys.exit(f"No pictures in {SOURCE_FOLDER}.")

    icons = []
    problems = 0
    for source in sources:
        rgb = np.asarray(Image.open(source).convert("RGB")).astype(np.float32)
        color, alpha, notes = cut_out(rgb)
        if "the border of the picture is not magenta" in notes["warnings"] or (alpha < TRUSTED_ALPHA).all():
            print(f"{source.name}: SKIPPED, " + "; ".join(notes["warnings"]))
            problems += 1
            continue
        describe(color, alpha, notes)
        square_color, square_alpha = crop_square(color, alpha, notes["box"])
        final_color, final_alpha = resize(square_color, square_alpha, OUTPUT_SIZE)
        target = TARGET_FOLDER / (source.stem + ".png")
        to_picture(final_color, final_alpha).save(target, optimize=True)
        icons.append((source.stem, final_color, final_alpha))

        left, top, right, bottom = notes["box"]
        print(f"{source.name} -> {target.relative_to(PROJECT)}")
        print(f"   background colour {notes['background']}, {notes['transparent_share'] * 100:.0f} % of the picture removed")
        print(f"   drawing {right - left} x {bottom - top} pixels, scaled by {OUTPUT_SIZE / square_alpha.shape[0]:.2f}")
        print(f"   gaps inside the drawing made transparent: {len(notes['gaps'])} (pixels: {notes['gaps'][:8]})")
        print(f"   separate parts of the drawing: {len(notes['parts'])} (pixels: {notes['parts'][:8]})")
        print(
            f"   darkened background removed far from clear background: {notes['deep_pixels']} pixels, "
            f"magenta left at the edge: {notes['leftover']} pixels, drawn pink at the edge (kept): {notes['pink_at_edge']} pixels"
        )
        for warning in notes["warnings"]:
            print(f"   WARNING: {warning}")
        problems += len(notes["warnings"])

    if icons:
        icons.sort(key=lambda icon: preview_position(icon[0]))
        preview = build_preview(icons)
        preview.save(TARGET_FOLDER / PREVIEW_NAME, optimize=True)
        print(f"preview -> {(TARGET_FOLDER / PREVIEW_NAME).relative_to(PROJECT)} ({preview.width} x {preview.height})")
    print(f"{len(icons)} of {len(sources)} pictures written, {problems} warnings")


if __name__ == "__main__":
    main()
