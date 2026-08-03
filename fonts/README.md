# Fonts

| File | Family | Source | Licence |
|---|---|---|---|
| `goudy_heavyface_bt.ttf` | GoudyHeavyface | Kiduna Studio Design Kit v1.7 | **Commercial — confirm before distribution** |
| `avenir-book.ttf`<br>`avenir-regular.ttf`<br>`avenir-heavy.ttf` | Avenir | Kiduna Studio Design Kit v1.7 | **Commercial — confirm before distribution** |
| `MotifSymbols.ttf` | Motif | DejaVu Sans 2.37, subset | DejaVu / Bitstream Vera — permissive, free to bundle |

## Goudy Heavyface and Avenir

Identity and body type respectively, per
`design-kit/studio-v1.7/DESIGN-SYSTEM.md`. Both are **commercial typefaces**.
The TTFs ship inside the Studio Design Kit, which is fine for prototyping —
**confirm distribution licensing before any store release.**

## Motif

Realm motif glyphs — `⌑ ✦ ◌ ◆ ♨ ≋ ⌘ ☯ ⚘` — appear on the anchor stud of each
Realm crest. Neither Goudy Heavyface nor Avenir covers them, and Flutter web
cannot fall back to a system font: CanvasKit renders text itself and only knows
the fonts we bundle. Without this, every stud renders as tofu.

Subset from DejaVu Sans to the 29 codepoints the fixtures actually use, which
takes it from ~750 KB to 8 KB. Regenerate after adding motifs:

```bash
pyftsubset DejaVuSans.ttf \
  --unicodes="$(python3 -c "
import json, glob
need=set()
for f in glob.glob('assets/fixtures/*.json'):
    for r in json.load(open(f))['realms']:
        need |= {ord(c) for c in r.get('motif','')}
print(','.join(f'U+{c:04X}' for c in sorted(need)))
")" \
  --output-file=fonts/MotifSymbols.ttf --no-hinting
```

Candidates checked: Noto Sans Symbols 2 covered only 19 of 27 — the motifs span
Math Operators, Misc Technical, Geometric Shapes, Dingbats and Misc Symbols, and
DejaVu Sans was the single font covering all of them.
