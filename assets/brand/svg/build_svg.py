"""Builds the earshot vector kit. Run: python3 -I build_svg.py"""
import math
cx, cy = 128, 108
def pt(r, deg): return (cx + r*math.cos(math.radians(deg)), cy + r*math.sin(math.radians(deg)))
def arc(r, a1=160, a2=60):
    x1,y1 = pt(r,a1); x2,y2 = pt(r,a2)
    return f"M{x1:.1f} {y1:.1f} A{r} {r} 0 1 1 {x2:.1f} {y2:.1f}"
ex, ey = pt(88, 60)                      # end of outer arc
k = 26; c1 = (ex - 0.866*k, ey + 0.5*k)   # tangent-continuous control point
outer = arc(88) + f" C{c1[0]:.1f} {c1[1]:.1f} 142 236 118 236 C102 236 92 226 92 212"
mid, inner = arc(60), arc(32)
def mark(color, sw=14):
    return (f'<g fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round">'
            f'<path d="{outer}"/><path d="{mid}"/><path d="{inner}"/></g>'
            f'<circle cx="{cx}" cy="{cy}" r="11" fill="{color}"/>')
TEAL, MINT, NAVY, SLATE, OFF = "#3A9A94", "#6FD3C8", "#0F1B2D", "#2E3A46", "#F6F3EE"
FONT = "font-family=\"'Nunito','Quicksand','Varela Round','Avenir Next Rounded','Helvetica Neue',sans-serif\""
W = lambda n, s: open(n, "w").write(s)
W("earshot_mark.svg", f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">{mark(TEAL)}</svg>')
W("earshot_mark_dark.svg", f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">{mark(MINT)}</svg>')
for name, bg, fg in [("earshot_icon_light", "#FFFFFF", TEAL), ("earshot_icon_dark", NAVY, MINT)]:
    W(name+".svg", f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><rect width="512" height="512" rx="112" fill="{bg}"/>'
      f'<g transform="translate(96 88) scale(1.25)">{mark(fg)}</g></svg>')
for name, bg, fg, txt, sub in [("earshot_banner_light", OFF, TEAL, SLATE, "#8A949E"), ("earshot_banner_dark", NAVY, MINT, OFF, "#8FA0B8")]:
    W(name+".svg", f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 640"><rect width="1280" height="640" fill="{bg}"/>'
      f'<g transform="translate(180 128) scale(1.5)">{mark(fg)}</g>'
      f'<text x="620" y="330" {FONT} font-size="150" font-weight="600" letter-spacing="4" fill="{txt}">earshot</text>'
      f'<text x="626" y="400" {FONT} font-size="36" fill="{sub}">on-device ambient listening for Flutter</text></svg>')
W("earshot_lockup_horizontal.svg", f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 256">{mark(TEAL)}'
  f'<text x="290" y="170" {FONT} font-size="150" font-weight="600" letter-spacing="4" fill="{SLATE}">earshot</text></svg>')
files=["earshot_mark","earshot_icon_light","earshot_icon_dark","earshot_lockup_horizontal","earshot_banner_light","earshot_banner_dark"]
W("preview.html", '<html><body style="margin:0;display:grid;grid-template-columns:1fr 1fr;gap:16px;padding:16px;background:#ddd">'
  + "".join(f'<div style="background:#fff;padding:8px">{open(f+".svg").read()}</div>' for f in files) + '</body></html>')
print("ok")
