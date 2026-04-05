#!/usr/bin/env python3
"""
Generates a voice-waveform SVG from GitHub contribution data.
Each day's commits become a bar in a spectrum analyzer.
Your code literally speaks.
"""

import json
import math
import os
import subprocess
import sys
import colorsys

# --- Config ---
USERNAME = "Avikalp-Karrahe"
DAYS = 120
SVG_WIDTH = 1000
SVG_HEIGHT = 280
BAR_WIDTH = 5
BAR_GAP = 2.2
MAX_BAR_HEIGHT = 100
MIN_BAR_HEIGHT = 6
CORNER_RADIUS = 2.5
OUTPUT = os.path.join(os.path.dirname(os.path.dirname(__file__)), "images", "waveform.svg")


def fetch_contributions():
    query = """query {
      user(login: "%s") {
        contributionsCollection {
          contributionCalendar {
            weeks {
              contributionDays {
                contributionCount
                date
              }
            }
          }
        }
      }
    }""" % USERNAME

    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        import urllib.request
        req = urllib.request.Request(
            "https://api.github.com/graphql",
            data=json.dumps({"query": query}).encode(),
            headers={
                "Authorization": f"bearer {token}",
                "Content-Type": "application/json",
            },
        )
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
    else:
        result = subprocess.run(
            ["gh", "api", "graphql", "-f", f"query={query}"],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            print(f"Error: {result.stderr}", file=sys.stderr)
            sys.exit(1)
        data = json.loads(result.stdout)

    days = []
    for week in data["data"]["user"]["contributionsCollection"]["contributionCalendar"]["weeks"]:
        for day in week["contributionDays"]:
            days.append(day["contributionCount"])

    return days[-DAYS:]


def hsl_to_hex(h, s, l):
    r, g, b = colorsys.hls_to_rgb(h / 360, l / 100, s / 100)
    return f"#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}"


def generate_svg(counts):
    n = len(counts)
    max_count = max(counts) if max(counts) > 0 else 1

    total_bar_space = n * (BAR_WIDTH + BAR_GAP) - BAR_GAP
    x_offset = (SVG_WIDTH - total_bar_space) / 2
    center_y = SVG_HEIGHT / 2 + 10  # shift down slightly for name

    # Build gradient defs for each bar (vertical gradient: bright top → dim bottom)
    gradient_defs = []
    bars_svg = []
    reflection_svg = []
    glow_svg = []

    for i, c in enumerate(counts):
        ratio = c / max_count
        # Smooth out with neighbors for a less jagged look
        neighbors = counts[max(0,i-1):min(n,i+2)]
        smooth_ratio = (sum(n_c / max_count for n_c in neighbors)) / len(neighbors)
        blend = 0.6 * ratio + 0.4 * smooth_ratio

        h = MIN_BAR_HEIGHT + blend * (MAX_BAR_HEIGHT - MIN_BAR_HEIGHT)
        x = x_offset + i * (BAR_WIDTH + BAR_GAP)

        # Color: position-based hue shift (cyan → blue → purple → pink → orange)
        # Creates a spectrum across the waveform
        pos = i / max(n - 1, 1)
        hue = 200 - pos * 180  # 200 (cyan) → 20 (orange)
        if hue < 0:
            hue += 360

        # Intensity affects saturation and lightness
        sat = 60 + ratio * 35
        lit = 35 + ratio * 25

        color_top = hsl_to_hex(hue, min(sat + 15, 100), min(lit + 15, 80))
        color_bot = hsl_to_hex(hue, sat, lit)
        color_glow = hsl_to_hex(hue, 80, 55)

        grad_id = f"g{i}"
        gradient_defs.append(
            f'<linearGradient id="{grad_id}" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0%" stop-color="{color_top}"/>'
            f'<stop offset="100%" stop-color="{color_bot}"/>'
            f'</linearGradient>'
        )

        opacity = 0.35 + 0.65 * blend

        # Main bar (upward from center)
        bar_y = center_y - h
        bars_svg.append(
            f'<rect x="{x:.1f}" y="{bar_y:.1f}" width="{BAR_WIDTH}" height="{h:.1f}" '
            f'rx="{CORNER_RADIUS}" fill="url(#{grad_id})" opacity="{opacity:.2f}">'
            f'<animate attributeName="height" values="{h:.1f};{h*0.85:.1f};{h:.1f}" '
            f'dur="{1.5 + (i % 7) * 0.3:.1f}s" repeatCount="indefinite"/>'
            f'<animate attributeName="y" values="{bar_y:.1f};{bar_y + h*0.15:.1f};{bar_y:.1f}" '
            f'dur="{1.5 + (i % 7) * 0.3:.1f}s" repeatCount="indefinite"/>'
            f'</rect>'
        )

        # Reflection (downward from center, faded)
        ref_opacity = opacity * 0.25
        reflection_svg.append(
            f'<rect x="{x:.1f}" y="{center_y:.1f}" width="{BAR_WIDTH}" height="{h * 0.45:.1f}" '
            f'rx="{CORNER_RADIUS}" fill="url(#{grad_id})" opacity="{ref_opacity:.2f}">'
            f'<animate attributeName="height" values="{h*0.45:.1f};{h*0.35:.1f};{h*0.45:.1f}" '
            f'dur="{1.5 + (i % 7) * 0.3:.1f}s" repeatCount="indefinite"/>'
            f'</rect>'
        )

        # Glow on peaks
        if ratio > 0.5:
            glow_opacity = (ratio - 0.5) * 0.12
            glow_svg.append(
                f'<circle cx="{x + BAR_WIDTH/2:.1f}" cy="{bar_y:.1f}" r="{8 + ratio * 12:.1f}" '
                f'fill="{color_glow}" opacity="{glow_opacity:.2f}">'
                f'<animate attributeName="opacity" values="{glow_opacity:.2f};{glow_opacity*0.4:.2f};{glow_opacity:.2f}" '
                f'dur="{2 + (i % 5) * 0.4:.1f}s" repeatCount="indefinite"/>'
                f'</circle>'
            )

    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {SVG_WIDTH} {SVG_HEIGHT}" width="{SVG_WIDTH}" height="{SVG_HEIGHT}">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#0c0c14"/>
      <stop offset="100%" stop-color="#08080e"/>
    </linearGradient>
    <linearGradient id="centerFade" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#fff" stop-opacity="0"/>
      <stop offset="15%" stop-color="#fff" stop-opacity="0.04"/>
      <stop offset="50%" stop-color="#fff" stop-opacity="0.06"/>
      <stop offset="85%" stop-color="#fff" stop-opacity="0.04"/>
      <stop offset="100%" stop-color="#fff" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="reflectionMask" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#fff" stop-opacity="1"/>
      <stop offset="100%" stop-color="#fff" stop-opacity="0"/>
    </linearGradient>
    {"".join(gradient_defs)}
  </defs>

  <!-- background -->
  <rect width="{SVG_WIDTH}" height="{SVG_HEIGHT}" fill="url(#bg)"/>

  <!-- name -->
  <text x="{SVG_WIDTH/2}" y="30" text-anchor="middle"
        font-family="'SF Pro Display','Inter','Segoe UI',system-ui,sans-serif"
        font-size="15" font-weight="600" letter-spacing="8" fill="#ffffff" opacity="0.12">
    AVIKALP KARRAHE
  </text>

  <!-- center line -->
  <line x1="{x_offset - 10}" y1="{center_y}" x2="{x_offset + total_bar_space + 10}" y2="{center_y}"
        stroke="url(#centerFade)" stroke-width="1"/>

  <!-- glows -->
  {"".join(glow_svg)}

  <!-- bars -->
  {"".join(bars_svg)}

  <!-- reflection -->
  {"".join(reflection_svg)}

  <!-- bottom label -->
  <text x="{SVG_WIDTH/2}" y="{SVG_HEIGHT - 12}" text-anchor="middle"
        font-family="'SF Mono','JetBrains Mono','Fira Code',monospace"
        font-size="8" fill="#ffffff" opacity="0.08" letter-spacing="4">
    {DAYS} DAYS OF SIGNAL
  </text>
</svg>'''

    return svg


if __name__ == "__main__":
    counts = fetch_contributions()
    svg = generate_svg(counts)
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    with open(OUTPUT, "w") as f:
        f.write(svg)
    print(f"Generated waveform: {OUTPUT} ({len(counts)} days, peak {max(counts)})")
