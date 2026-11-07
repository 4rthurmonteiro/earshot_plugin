# earshot brand assets

The earshot mark is a stylized ear drawn as three concentric arcs that read
both as an ear and as spreading sound waves, with a dot at the centre for the
sound source. The palette is deliberately calm: teal sits between blue (trust,
quiet) and green (nature, rest), and nothing in the kit is red, orange or neon.

| Role          | Hex       |
| ------------- | --------- |
| Teal (light)  | `#3A9A94` |
| Mint (dark)   | `#6FD3C8` |
| Navy          | `#0F1B2D` |
| Slate text    | `#2E3A46` |
| Off-white     | `#F6F3EE` |

## Files

- `earshot_mark.png`, `earshot_icon_light.png`, `earshot_icon_dark.png`
- `earshot_banner_light.png`, `earshot_banner_dark.png` (1280×640, README / pub.dev)
- `svg/` — editable sources. `build_svg.py` generates every SVG; edit the
  script, not the SVGs. The wordmark uses Nunito with rounded-sans fallbacks,
  so the PNGs are the canonical rendered form.

Rasterize on macOS with `qlmanage -t -s 1280 -o out file.svg`.
