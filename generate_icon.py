#!/usr/bin/env python3
"""Generate Gata luxury app icon — deep plum background with champagne gold A+S monogram."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, os

SIZE = 1024
CENTER = SIZE // 2

# Colors
BG = (13, 10, 20)          # Deep plum-black
GOLD = (212, 168, 82)       # Champagne gold
GOLD_LIGHT = (245, 230, 200)
GOLD_DARK = (184, 134, 11)
GLOW = (212, 168, 82, 40)

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(len(c1)))

def draw_icon():
    img = Image.new('RGBA', (SIZE, SIZE), (*BG, 255))
    draw = ImageDraw.Draw(img)

    # Radial gradient background (subtle gold center glow)
    glow_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    for r in range(350, 0, -2):
        alpha = int(25 * (1 - r / 350))
        glow_draw.ellipse(
            [CENTER - r, CENTER - r, CENTER + r, CENTER + r],
            fill=(*GOLD, alpha)
        )
    img = Image.alpha_composite(img, glow_layer)
    draw = ImageDraw.Draw(img)

    # Outer decorative ring
    ring_r = 420
    for w in range(3):
        alpha = 80 - w * 20
        draw.ellipse(
            [CENTER - ring_r - w, CENTER - ring_r - w, CENTER + ring_r + w, CENTER + ring_r + w],
            outline=(*GOLD, alpha), width=2
        )

    # Inner decorative ring
    inner_r = 360
    draw.ellipse(
        [CENTER - inner_r, CENTER - inner_r, CENTER + inner_r, CENTER + inner_r],
        outline=(*GOLD, 40), width=1
    )

    # Draw the A letter
    a_width = 180
    a_height = 240
    a_top = CENTER - 140
    a_bottom = a_top + a_height
    a_left = CENTER - a_width // 2
    a_right = CENTER + a_width // 2
    stroke_w = 12

    # Left leg of A
    for i in range(-stroke_w//2, stroke_w//2 + 1):
        draw.line([(a_left + i, a_bottom), (CENTER + i//2, a_top)], fill=(*GOLD_LIGHT, 255), width=2)

    # Right leg of A
    for i in range(-stroke_w//2, stroke_w//2 + 1):
        draw.line([(CENTER + i//2, a_top), (a_right + i, a_bottom)], fill=(*GOLD, 255), width=2)

    # A crossbar + S curve
    cross_y = CENTER + 20

    # Draw S curve using bezier approximation
    s_points = []
    for t_val in range(101):
        t = t_val / 100.0
        if t < 0.5:
            # Upper curve
            tt = t * 2
            x = a_left + 60 + tt * (a_right - a_left - 40)
            y = cross_y - 80 * math.sin(tt * math.pi)
        else:
            # Lower curve
            tt = (t - 0.5) * 2
            x = a_right - 60 - tt * (a_right - a_left - 80)
            y = cross_y + 60 * math.sin(tt * math.pi)
        s_points.append((x, y))

    # Draw S with thickness
    for i in range(len(s_points) - 1):
        draw.line([s_points[i], s_points[i + 1]], fill=(*GOLD, 255), width=stroke_w)

    # Crossbar connecting A to S
    draw.line([(a_left + 50, cross_y), (a_right - 50, cross_y)], fill=(*GOLD, 200), width=stroke_w - 2)

    # Center glow dot
    glow2 = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    glow2_draw = ImageDraw.Draw(glow2)
    for r in range(30, 0, -1):
        alpha = int(120 * (1 - r / 30))
        glow2_draw.ellipse(
            [CENTER - r, CENTER - 10 - r, CENTER + r, CENTER - 10 + r],
            fill=(*GOLD_LIGHT, alpha)
        )
    img = Image.alpha_composite(img, glow2)
    draw = ImageDraw.Draw(img)

    # GATA text at bottom
    text_y = CENTER + 180
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Times New Roman.ttf", 72)
        small_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 28)
    except:
        font = ImageFont.load_default()
        small_font = font

    # Draw GATA with letter spacing
    gata_text = "G  A  T  A"
    bbox = draw.textbbox((0, 0), gata_text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text((CENTER - tw // 2, text_y), gata_text, fill=GOLD_LIGHT, font=font)

    # Gold divider
    div_y = text_y + 85
    for x in range(CENTER - 140, CENTER + 140):
        dist = abs(x - CENTER)
        alpha = int(180 * (1 - dist / 140))
        draw.point((x, div_y), fill=(*GOLD, max(0, alpha)))
        draw.point((x, div_y + 1), fill=(*GOLD, max(0, alpha // 2)))

    # Tagline
    tagline = "PRIVATE  ·  EXCLUSIVE"
    bbox2 = draw.textbbox((0, 0), tagline, font=small_font)
    tw2 = bbox2[2] - bbox2[0]
    draw.text((CENTER - tw2 // 2, div_y + 14), tagline, fill=(*GOLD, 150), font=small_font)

    # Corner accents (small gold dots)
    for corner in [(80, 80), (SIZE - 80, 80), (80, SIZE - 80), (SIZE - 80, SIZE - 80)]:
        draw.ellipse([corner[0]-4, corner[1]-4, corner[0]+4, corner[1]+4], fill=(*GOLD, 60))

    # Convert to RGB for final output
    final = Image.new('RGB', (SIZE, SIZE), BG)
    final.paste(img, mask=img.split()[3])
    return final

if __name__ == '__main__':
    out_dir = os.path.dirname(os.path.abspath(__file__))
    icon = draw_icon()
    icon_path = os.path.join(out_dir, 'app_icon.png')
    icon.save(icon_path, 'PNG')
    print(f'Icon saved to {icon_path}')
