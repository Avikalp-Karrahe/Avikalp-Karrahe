#!/usr/bin/env python3
"""
Generates a voice-waveform SVG from GitHub contribution data.
Each day's commits become a bar in a mirrored audio waveform.
Your code literally speaks.
"""

import json
import math
import os
import subprocess
import sys

# --- Config ---
USERNAME = "Avikalp-Karrahe"
DAYS = 180
SVG_WIDTH = 1200
SVG_HEIGHT = 320
BAR_WIDTH = 2.8
BAR_GAP = 3.2
MAX_BAR_HEIGHT = 110
MIN_BAR_HEIGHT = 3
CORNER_RADIUS = 1.4
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


def generate_svg(counts):
    n = len(counts)
    max_count = max(counts) if max(counts) > 0 else 1

    total_bar_space = n * (BAR_WIDTH + BAR_GAP) - BAR_GAP
    x_offset = (SVG_WIDTH - total_bar_space) / 2
    center_y = SVG_HEIGHT / 2

    bars_svg = []
    for i, c in enumerate(counts):
        ratio = c / max_count
        h = MIN_BAR_HEIGHT + ratio * (MAX_BAR_HEIGHT - MIN_BAR_HEIGHT)
        x = x_offset + i * (BAR_WIDTH + BAR_GAP)
        y = center_y - h

        # opacity: silent days are dim, active days glow
        opacity = 0.18 + 0.82 * ratio

        # color shifts from deep indigo (quiet) to bright violet (loud)
        r = int(99 + ratio * 68)   # 63 -> a7
        g = int(102 + ratio * 37)  # 66 -> 8b
        b = int(241 + ratio * 10)  # f1 -> fb
        color = f"#{r:02x}{g:02x}{b:02x}"

        # mirrored bar (top half + bottom half)
        bars_svg.append(
            f'<rect x="{x:.1f}" y="{y:.1f}" width="{BAR_WIDTH}" height="{h * 2:.1f}" '
            f'rx="{CORNER_RADIUS}" fill="{color}" opacity="{opacity:.2f}"/>'
        )

    # subtle glow circles behind the loudest bars (top 5)
    ranked = sorted(range(n), key=lambda i: counts[i], reverse=True)[:5]
    glows = []
    for i in ranked:
        if counts[i] == 0:
            continue
        ratio = counts[i] / max_count
        x = x_offset + i * (BAR_WIDTH + BAR_GAP) + BAR_WIDTH / 2
        h = MIN_BAR_HEIGHT + ratio * (MAX_BAR_HEIGHT - MIN_BAR_HEIGHT)
        glows.append(
            f'<circle cx="{x:.1f}" cy="{center_y:.1f}" r="{h * 0.6:.1f}" '
            f'fill="#8b5cf6" opacity="0.06"/>'
        )

    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {SVG_WIDTH} {SVG_HEIGHT}" width="{SVG_WIDTH}" height="{SVG_HEIGHT}">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#07070d"/>
      <stop offset="50%" stop-color="#0b0b16"/>
      <stop offset="100%" stop-color="#07070d"/>
    </linearGradient>
    <linearGradient id="centerLine" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#8b5cf6" stop-opacity="0"/>
      <stop offset="20%" stop-color="#8b5cf6" stop-opacity="0.15"/>
      <stop offset="50%" stop-color="#a78bfa" stop-opacity="0.25"/>
      <stop offset="80%" stop-color="#8b5cf6" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="#8b5cf6" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <!-- background -->
  <rect width="{SVG_WIDTH}" height="{SVG_HEIGHT}" fill="url(#bg)"/>

  <!-- center frequency line -->
  <line x1="0" y1="{center_y}" x2="{SVG_WIDTH}" y2="{center_y}" stroke="url(#centerLine)" stroke-width="0.5"/>

  <!-- glow behind peaks -->
  {"".join(glows)}

  <!-- waveform -->
  {"".join(bars_svg)}

  <!-- label: left -->
  <text x="24" y="{center_y - 2}" font-family="'SF Mono','JetBrains Mono','Fira Code',monospace" font-size="9" fill="#4b4b6b" letter-spacing="2" dominant-baseline="middle">
    SIGNAL
  </text>

  <!-- label: right -->
  <text x="{SVG_WIDTH - 24}" y="{center_y - 2}" font-family="'SF Mono','JetBrains Mono','Fira Code',monospace" font-size="9" fill="#4b4b6b" letter-spacing="2" text-anchor="end" dominant-baseline="middle">
    {DAYS}D
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
