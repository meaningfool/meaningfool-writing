#!/usr/bin/env python3
"""Generate an Excalidraw-ish bar chart from _draft/detecting-bounding-boxes.md.

Chart:
  - One bar per mode: weighted average IoU across datasets
    (weights: 59 single-factor cases, 31 combined-factors cases).

Outputs:
  images/bbox-results-excalidraw.png

No third-party deps beyond Pillow.
"""

from __future__ import annotations

import math
import random
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "_draft" / "detecting-bounding-boxes.md"
OUT_PNG = ROOT / "images" / "bbox-results-excalidraw.png"


@dataclass(frozen=True)
class Row:
    mode: str
    single_iou: Optional[float]
    combined_iou: Optional[float]
    failure_rate: Optional[float]  # 0..1


def _parse_float(s: str) -> Optional[float]:
    s = s.strip()
    if s in {"—", "-", ""}:
        return None
    try:
        return float(s)
    except ValueError:
        return None


def _parse_pct(s: str) -> Optional[float]:
    s = s.strip()
    if s in {"—", "-", ""}:
        return None
    m = re.match(r"^([0-9]+(?:\.[0-9]+)?)%$", s)
    if not m:
        return None
    return float(m.group(1)) / 100.0


def parse_results(md: str) -> dict[str, Row]:
    rows: dict[str, Row] = {}

    for line in md.splitlines():
        line = line.strip()
        if not (line.startswith("|") and line.endswith("|")):
            continue

        # Ignore header/separator rows.
        if set(line.replace("|", "").strip()) <= {":", "-", " "}:
            continue

        parts = [p.strip() for p in line.strip("|").split("|")]
        if len(parts) < 4:
            continue

        mode, c1, c2, c3 = parts[0], parts[1], parts[2], parts[3]

        # Heuristic: rows in the doc either have Failure(s) as pct, or Failure rate.
        single = _parse_float(c1)
        combined = _parse_float(c2)
        failure = _parse_pct(c3)

        if single is None and combined is None and failure is None:
            continue

        # Prefer rows that provide more info, and prefer later rows (doc refines numbers).
        prev = rows.get(mode)
        if prev is None:
            rows[mode] = Row(mode=mode, single_iou=single, combined_iou=combined, failure_rate=failure)
        else:
            def score(r: Row) -> int:
                return sum(v is not None for v in (r.single_iou, r.combined_iou, r.failure_rate))

            cand = Row(mode=mode,
                       single_iou=single if single is not None else prev.single_iou,
                       combined_iou=combined if combined is not None else prev.combined_iou,
                       failure_rate=failure if failure is not None else prev.failure_rate)
            # If cand fills more fields, take it. Otherwise keep existing.
            if score(cand) >= score(prev):
                rows[mode] = cand

    return rows


def _try_load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    # Excalidraw uses "Virgil"; on macOS we can approximate with Comic Sans.
    candidates = [
        "/System/Library/Fonts/Supplemental/Comic Sans MS.ttf",
        "/System/Library/Fonts/Supplemental/Comic Sans MS Bold.ttf",
        "/System/Library/Fonts/Supplemental/Chalkduster.ttf",
        "/System/Library/Fonts/Supplemental/Bradley Hand Bold.ttf",
        "/System/Library/Fonts/MarkerFelt.ttc",
    ]
    for p in candidates:
        try:
            return ImageFont.truetype(p, size=size)
        except Exception:
            pass
    return ImageFont.load_default()


def _jitter(rng: random.Random, x: float, amt: float) -> float:
    return x + rng.uniform(-amt, amt)


def _rough_polyline(draw: ImageDraw.ImageDraw, pts, *, fill, width: int, rng: random.Random, passes: int = 2, jitter: float = 1.5):
    for _ in range(passes):
        j = [( _jitter(rng, x, jitter), _jitter(rng, y, jitter)) for x, y in pts]
        draw.line(j, fill=fill, width=width, joint="curve")


def _rough_rect(draw: ImageDraw.ImageDraw, x0, y0, x1, y1, *, outline, width: int, rng: random.Random, fill=None):
    # Build a slightly wobbly rectangle path.
    pts = [
        (x0, y0),
        (x1, y0),
        (x1, y1),
        (x0, y1),
        (x0, y0),
    ]

    if fill is not None:
        # Fill with a slightly inset polygon to avoid bleeding outside the rough stroke.
        inset = max(1, width)
        fill_pts = [
            (x0 + inset, y0 + inset),
            (x1 - inset, y0 + inset),
            (x1 - inset, y1 - inset),
            (x0 + inset, y1 - inset),
        ]
        draw.polygon(fill_pts, fill=fill)

    _rough_polyline(draw, pts, fill=outline, width=width, rng=rng, passes=3, jitter=2.0)


def _hatch_fill(img: Image.Image, x0, y0, x1, y1, *, color, rng: random.Random, spacing: int = 10, jitter: float = 1.0, alpha: int = 110):
    # Diagonal hatching like Excalidraw's rough fill, clipped to the target box.
    # We render into a small transparent overlay and alpha-composite it in place.
    x0i, y0i, x1i, y1i = map(int, (x0, y0, x1, y1))
    w = max(1, x1i - x0i)
    h = max(1, y1i - y0i)

    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)

    start = -h
    end = w
    for t in range(int(start), int(end) + spacing, spacing):
        x_start = t
        y_start = h
        x_end = t + h
        y_end = 0
        x_start_j = _jitter(rng, x_start, jitter)
        y_start_j = _jitter(rng, y_start, jitter)
        x_end_j = _jitter(rng, x_end, jitter)
        y_end_j = _jitter(rng, y_end, jitter)
        od.line([(x_start_j, y_start_j), (x_end_j, y_end_j)], fill=(*color, alpha), width=1)

    if img.mode != "RGBA":
        base = img.convert("RGBA")
        base.alpha_composite(overlay, dest=(x0i, y0i))
        img.paste(base.convert(img.mode))
    else:
        img.alpha_composite(overlay, dest=(x0i, y0i))


def _text(draw: ImageDraw.ImageDraw, xy, text, font, fill, anchor=None):
    # Pillow doesn't support anchors for multiline text; render those manually.
    if "\n" not in text:
        draw.text(xy, text, font=font, fill=fill, anchor=anchor)
        return

    x, y = xy
    lines = text.splitlines()
    line_gap = 6

    # Measure each line.
    bboxes = [draw.textbbox((0, 0), ln, font=font) for ln in lines]
    widths = [bb[2] - bb[0] for bb in bboxes]
    heights = [bb[3] - bb[1] for bb in bboxes]
    total_h = sum(heights) + line_gap * (len(lines) - 1)

    if anchor is None:
        start_y = y
        start_x = x
        for ln, w, h in zip(lines, widths, heights):
            draw.text((start_x, start_y), ln, font=font, fill=fill)
            start_y += h + line_gap
        return

    # Supported anchors for multiline labels in this script:
    # mt: middle x, top y; mb: middle x, bottom y; mm: middle x, middle y.
    if anchor == "mt":
        start_y = y
    elif anchor == "mb":
        start_y = y - total_h
    elif anchor == "mm":
        start_y = y - total_h / 2
    else:
        # Fallback: draw without anchor logic.
        start_y = y

    for ln, w, h in zip(lines, widths, heights):
        draw.text((x - w / 2, start_y), ln, font=font, fill=fill)
        start_y += h + line_gap


def _add_paper_texture(img: Image.Image, rng: random.Random) -> Image.Image:
    # Apply texture to RGB, then keep alpha if present.
    alpha = None
    if img.mode == "RGBA":
        alpha = img.split()[-1]
        base = img.convert("RGB")
    else:
        base = img

    w, h = base.size
    noise = Image.new("L", (w, h))
    px = noise.load()
    for y in range(h):
        for x in range(w):
            px[x, y] = int(128 + rng.uniform(-18, 18))
    noise = ImageEnhance.Contrast(noise).enhance(0.6)
    noise = ImageEnhance.Brightness(noise).enhance(1.0)

    # Convert to RGB and blend very lightly.
    noise_rgb = Image.merge("RGB", (noise, noise, noise))
    # Multiply-like effect but gentle.
    blended = ImageChops.multiply(base, ImageEnhance.Brightness(noise_rgb).enhance(1.08))
    out = Image.blend(base, blended, alpha=0.08)
    if alpha is not None:
        out = out.convert("RGBA")
        out.putalpha(alpha)
    return out


def main() -> int:
    md = SRC.read_text(encoding="utf-8")
    parsed = parse_results(md)

    # Canonical modes to plot + labels.
    # Keep this stable and tweet-friendly.
    modes = [
        ("Claude Sonnet (direct API)", "Sonnet 4.6"),
        ("Gemini Flash (direct API)", "Gemini Flash 3.0"),
        ("Claude Code harness (baseline)", "CC Sonnet 4.6"),
        ("Grounding DINO (top-1)", "DINO"),
        ("Harness + skill", "DINO + Skill"),
        ("SAM-3 (overall)", "SAM-3"),
    ]

    # Required row check (fail fast with a clear message).
    missing = [k for k, _ in modes if k not in parsed]
    if missing:
        raise SystemExit(f"Missing rows in parsed results: {missing}")

    rows = [parsed[k] for k, _ in modes]

    # Weighted average IoU across datasets. The markdown reports:
    # - single-factor: 59 cases
    # - combined-factors: 31 cases (after filtering ambiguous ones)
    w_single = 59
    w_combined = 31
    w_total = w_single + w_combined

    def weighted_iou(r: Row) -> float:
        if r.single_iou is None and r.combined_iou is None:
            return 0.0
        if r.single_iou is None:
            return float(r.combined_iou)
        if r.combined_iou is None:
            return float(r.single_iou)
        return (r.single_iou * w_single + r.combined_iou * w_combined) / w_total

    vals = [weighted_iou(r) for r in rows]

    # Canvas.
    W, H = 2000, 1050
    bg = (251, 247, 240)
    img = Image.new("RGBA", (W, H), (*bg, 255))
    draw = ImageDraw.Draw(img)

    rng = random.Random(1337)

    # Typography.
    title_font = _try_load_font(56)
    sub_font = _try_load_font(34)
    label_font = _try_load_font(30)
    tiny_font = _try_load_font(26)

    ink = (20, 20, 20)
    grid = (70, 70, 70)

    # Layout.
    # Add extra padding so the plot doesn't crowd the title or the bottom edge.
    pad_l, pad_r, pad_t, pad_b = 120, 80, 90, 130
    title_y = 30

    top_chart_top = pad_t + 110
    top_chart_bottom = H - pad_b

    x0 = pad_l
    x1 = W - pad_r

    # Title.
    _text(draw, (pad_l, title_y), "Bounding Box Selection: Weighted Avg IoU", title_font, ink)

    # Top chart axes.
    chart_h = top_chart_bottom - top_chart_top
    chart_w = x1 - x0

    # Rough axes lines.
    _rough_polyline(draw, [(x0, top_chart_bottom), (x1, top_chart_bottom)], fill=ink, width=4, rng=rng, passes=2, jitter=1.2)
    _rough_polyline(draw, [(x0, top_chart_top), (x0, top_chart_bottom)], fill=ink, width=4, rng=rng, passes=2, jitter=1.2)

    # Grid + y labels.
    for v in [0.0, 0.25, 0.5, 0.75, 1.0]:
        y = top_chart_bottom - v * chart_h
        # Grid line (light).
        _rough_polyline(draw, [(x0, y), (x1, y)], fill=(180, 180, 180), width=2, rng=rng, passes=1, jitter=1.6)
        _text(draw, (x0 - 18, y), f"{v:.2f}", tiny_font, (60, 60, 60), anchor="rm")

    _text(draw, (x0 + 10, top_chart_top - 42), "IoU", label_font, ink)

    # Bars.
    n = len(rows)
    group_w = chart_w / n
    bar_w = min(90, int(group_w * 0.42))

    # Color.
    fill_col = (163, 210, 255)  # light blue
    hatch_col = (120, 170, 220)

    for i, (val, (_, disp)) in enumerate(zip(vals, modes)):
        gx = x0 + i * group_w
        group_center = gx + group_w / 2
        bx0 = group_center - bar_w / 2
        bx1 = bx0 + bar_w
        by1 = top_chart_bottom
        by0 = top_chart_bottom - val * chart_h

        _rough_rect(draw, bx0, by0, bx1, by1, outline=ink, width=4, rng=rng, fill=fill_col)
        _hatch_fill(img, bx0 + 6, by0 + 6, bx1 - 6, by1 - 6, color=hatch_col, rng=rng, spacing=12)

        # Value label.
        _text(draw, (group_center, by0 - 12), f"{val:.2f}", tiny_font, ink, anchor="mb")

        # X label.
        _text(draw, (group_center, top_chart_bottom + 38), disp, label_font, ink, anchor="mt")

    # Subtle paper texture to sell the "hand-drawn" look.
    img = _add_paper_texture(img, rng)

    OUT_PNG.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT_PNG, format="PNG", optimize=True)
    print(f"Wrote {OUT_PNG}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
