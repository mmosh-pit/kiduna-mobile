# The Field Guide

The single document to read before touching the AEV. Written one section per
build phase, while the knowledge was fresh.

Companion documents: `../../AEV-UNDERSTANDING.md` (what the AEV is and why),
`../../AEV-BUILD-PHASES.md` (the plan), `../../contracts/README.md` (the seam).

---

## §1 · What the Field is

The **Advanced Ecosystem View** shows an entire Ecosystem — Kinship Duna — as a
single living star-map called *the Field*.

It is not a graph widget. A graph draws nodes and edges; the Field uses **space
itself** as the encoding. Where a Realm sits, how large it is, and how richly it
is drawn all say the same thing: how relevant it is to you, right now.

### The three laws

Break these and it stops being the AEV.

**1. Selection is inspection, never entry.**
Tapping a Realm highlights its existing paths and updates context. It does not
enter, join, grant, or imply membership, rank, or authority. This is why there
is no `RealmEntered` event.

**2. Distance carries meaning.**
Near / middle / far is not level-of-detail optimisation. Near carries a unique
high-fidelity Portrait; far carries a generic type glyph. Reading distance *is*
reading relevance.

**3. No connector without a real relationship.**
Selection brightens light already there. It never invents a line.

### Vocabulary — used exactly

- It is **Kiduna**. Never "Kidunaverse".
- **Members**, never "users". Members are **Sources**; a Source's visible
  identity is their **Ally**.
- **Realm**, not "node", in anything member-facing.
- **Gravity**, not "priority" or "weight".
- **Atlas** and **Scene** are two presentations of the same Field.

### Tokens — `lib/design/tokens.dart`

Eleven colours. `Enamel.deepField` `#0A0604` is the canonical ground; it is
never a gradient and never a wash.

Two type families: **Goudy Heavyface** for identity, Realm headings, thresholds
and significant figures; **Avenir** for body copy, controls and operational
information. A third bundled family, **Motif**, exists only to carry Realm
glyphs — see `fonts/README.md`.

Four materials: Lacquer · Enamel · Gold wire · Moon cream.

### The sky-blue Action rule — `lib/design/ground.dart`

White or cream content is **prohibited** on any sky-blue filled button. The ink
must match the exact local ground behind the button. `KidunaGround` carries that
ground down the tree and `SkyAction` reads it, so ink can never be passed in —
the canon is explicit that no general button-colour rule may override it. A
light ground trips an assertion in debug.

---

## §2 · The contract

Read `../../contracts/README.md` in full. The short version:

**The source sends meaning. The client derives geometry.** Cluster assignment,
Gravity and roles come over the wire; positions, bands, node sizes, connector
curves and every motion value are computed here. Law 2 lives in exactly one
place.

**`FieldSnapshot` in, six `FieldEvent`s out.** Only `GravityChanged` is a write.

**Gravity is per viewer, not per Realm.** Two members see the same Realm at
different distances. That is correct.

**Absence is the visibility mechanism.** A Realm the viewer may not see is
omitted from `realms[]`, never sent with a flag.

Four fixtures prove it: `alice` (the visual acceptance reference), `coverage`
(every field and enum), `empty` (the newly-created Ecosystem), `edge`
(everything that must degrade rather than throw). Load any of them in the
browser with `?fixture=edge`.

---

## §3 · Anatomy of a Realm node

### Render order — `lib/field/render/layers.dart`

The Design Lab canon hands this to us directly:

> **Ground → geometry → connection → object → signal**

| Priority | Layer | File |
|---|---|---|
| 0 | Ground — lacquer, arcs, glints, inset depth | `ground_layer.dart` |
| 10 | Geometry — cluster halos and labels | `cluster_layer.dart` |
| 20 | Connection — chains, bridges, current path | `connector_layer.dart` |
| 30 | Object — Realm nodes | `realm_node.dart` |
| 40 | Signal — *one* glint or pulse. Phase 4 | — |

Note the singular in layer 5. One active signal reveals change, not many.

### The node itself

```
        ╭───────────╮
        │  ◜ rim ◝  │      01 · enamel rim + reflected light
        │  ┌─────┐  │      02 · dark core + type emblem
        │  │ ✦   │  │
        │  └─────┘ ⬤│         · anchor stud carrying the Realm's motif
        ╰───────────╯
          Dunaversity        03 · attached label, NEVER floating
          ORGANIZATION
```

Sizes are **fixed pixels** and never stretch with the Field — only the camera
scales them, uniformly.

| Band | Node | Crest | Opacity | Identity |
|---|---|---|---|---|
| near | 152 × 142 | 84 | 1.00 | Unique enamel Portrait |
| middle | 118 × 105 | 64 | 1.00 | Simplified emblem |
| far | 72 × 65 | 40 | 0.62 | Generic type glyph, no type label |

A Realm's name is tinted toward its **cluster accent**, so colour carries
cluster membership before the label is even read. Type labels are uppercase and
letterspaced.

**A proposed entity (`fixture: true`) gets a broken rim** — visible as
structure, never presented as though it already exists.

### Positioning — `lib/field/placement.dart`

Percent-of-Field maps **non-uniformly**: `left` against width, `top` against
height, exactly as the reference positions absolute elements in its container.
Node sizes stay in pixels regardless.

Flame centres its viewfinder on world origin by default, which would push the
whole composition off the bottom-right; `camera.viewfinder.anchor` is set to
`topLeft` so the Field starts where the container does.

### The five clusters are orbits, and the ring is the structure

Realms are **grouped by interest into five elliptical orbits** and placed
*along* them. `placeRing()` is literally orbital arithmetic:

```
angle = startAngle + (arc × index) / count
left  = centre.x + cos(angle) × radiusX × bandMultiplier
top   = centre.y + sin(angle) × radiusY × bandMultiplier
```

Three things follow, and all three surprise people:

1. **There is no sun.** The centre of each ellipse is empty. The orbit *is* the
   interest; no parent body is being circled.
2. **Three nested rings per cluster, not one** — near `0.62`, middle `0.88`,
   far `1.10` of the cluster radius. Near sits inside, far outside.
3. **Gravity pulls inward.** Higher relevance means closer to the centre
   (`pull` 1.12 → 0.56). Inverted from planetary intuition, and correct here:
   nearness means relevance.

**Realms do not revolve, deliberately.** The canon is explicit in two places:

> Stable position matters more than decorative motion. — `DESIGN-SYSTEM.md`

> Orbit denotes membership, attention, or active containment — **not
> decoration**. Use one or two orbiting objects **per Realm** at routine scale.
> — `enamel/02-FIELD-GROUND-MOTION.md`

Canonical Orbit is 1–2 small objects circling *a Realm* — the role ring, 24s.
Not Realms circling a cluster. If Realms revolved, their angle would stop
meaning anything, and position is the encoding.

> **Draw the ring at full weight.** The reference uses
> `1px solid color-mix(accent 24%, transparent)`. An earlier version here used
> `0.6px at 10%` — under half — and the orbital grouping barely read at all.
> The rings are the structure, not decoration around it.

**The ring is what carries the ambient life.** Since Realms must hold position,
the orbit animates instead:

- the ring **breathes** between `.24` and `.28` alpha — well inside the 20%
  luminance ceiling — on a 7–9s period, staggered per cluster;
- **one phase node** travels it, per the canon's *"elliptical, object-centered ·
  one phase node brightens"*, lighting a 13% arc as it goes;
- **46–82s per revolution**, staggered — far slower than the 16s floor, because
  this is the Field breathing, not a carousel.

Under reduced motion the ring stays and the travelling light goes. That is a
deliberate branch, and the only one: the light carries **no information** — it
is the Field being alive, not a fact about any Realm — so removing it loses
nothing. Freezing it instead would leave a bright spot stuck at an arbitrary
angle, which reads as meaning something it doesn't.

### Connectors — `connector_layer.dart`

Three species, deliberately ranked:

1. **Within-cluster chains** — each placement links to the previous one in its
   cluster. A chain, not a mesh. **A cluster holding one Realm draws zero
   connectors** — correct, and it must not be special-cased away.
2. **Bridges** — cross-cluster, quieter and visually distinct. An endpoint may
   be invisible to this viewer; skip it and count it.
3. **Current path** — gold, to the Vital Realm, drawn *beneath* identity.

Bézier bend: `3.5` within a cluster · `7.0` across · `-5.0` for branch. A path
takes the band of its dimmest endpoint, so it fades with what it connects.

---

## §4 · Coordinate spaces and the camera

Three spaces, and most camera bugs are a confusion between two of them.

| Space | Units | Where |
|---|---|---|
| **Percent-of-Field** | 0–100 on each axis | The contract. `Realm.seed`, `Placement.position`, cluster geometry |
| **World** | pixels | What Flame components live in. Percent resolved against the viewport at layout time |
| **Screen** | pixels from the viewport's top-left | Pointer events, and where the camera transform lands |

Percent maps **non-uniformly** — `left` against width, `top` against height —
exactly as the reference positions absolute elements in its container. Node
*sizes* stay in fixed pixels and never stretch with it. Only the camera scales
them, and it scales uniformly.

### Layout versus transform

`_layout()` recomputes the base composition against the current viewport, and
runs on resize. Zoom and pan are a transform *on top* of it, mirroring the
reference's `transform: translate() scale()` over a percent-positioned
container. Resizing reflows the composition; it does not letterbox.

`camera.viewfinder.anchor` is `topLeft`, so `viewfinder.position` is the world
coordinate shown at the viewport's top-left corner. Flame's default centres the
viewfinder on world origin, which pushes the whole Field off the bottom-right.

The **ground lives in `camera.backdrop`**, not the world. It is the lacquer of
the display rather than an object in the Field, so it stays viewport-fixed: it
can never reveal an edge on zoom-out, and it cannot drift on its own — which the
canon prohibits.

### The maths — `camera_control.dart`

Pure functions, no Flame or Flutter, so behaviour is testable without a game
loop.

```
pan:    position -= screenDelta / zoom          // 1:1 with the pointer
zoom:   world = position + pointer / fromZoom   // anchored on the cursor
        position = world - pointer / toZoom
range:  0.7× – 2.4×,  one notch = ×1.12
```

**Bounds allow overscroll slack at every zoom, including 1×.** An earlier
version pinned the camera to centre whenever the Field fitted the viewport,
which silently swallowed every pan at rest zoom — the Field looked frozen and
read as broken. Pan must always respond; it just cannot run away.

### Input

| Gesture | Action |
|---|---|
| Drag | Pan, 1:1, no easing lag |
| Two-finger scroll | Pan |
| Ctrl/Cmd + scroll | Cursor-anchored zoom. Browsers report trackpad pinch this way, so pinch arrives here too |
| Arrows / WASD | Continuous pan while held, 620 px/s |
| `+` / `−` | Zoom on the viewport centre |
| `0` | Reset |
| `Escape` | Reserved — Phase 5 clears selection. It must never destroy the underlying Realm context |

Held keys are applied in `update(dt)` rather than on key repeat, so keyboard pan
is frame-rate independent and feels continuous.

**Labels resolve by distance.** Past 1.6× the far band earns the type label it
does not carry at rest.

---

## §5 · Motion

Five named verbs. These are **specification, not suggestion** — every number
below comes from `kit/enamel/02-FIELD-GROUND-MOTION.md` or the reference's own
keyframes, and they live as constants in `motion.dart`.

| Verb | State | Spec |
|---|---|---|
| **Breathe** | Open | scale `1 → 1.035 → 1`, **6–8s**, ease-in-out. Glow follows scale under a 20% luminance change |
| **Drift** | Dreaming | max **±8px**/axis, **14–18s**. Labels never move independently of their object |
| **Relate** | Engaged | Brighten an **existing** path, 3–5s cycle. *Phase 5* — relational motion stops when the relationship is not active |
| **Gather** | Focused | **900ms** settle, **120–150ms** sibling stagger. Slight overshoot in position only, never cartoon bounce |
| **Orbit** | — | **≥16s** per revolution. Membership, attention, containment — never decoration |

Nothing bounces. The Field reads as *alive*, not animated.

### What actually moves

| Element | Motion |
|---|---|
| Stars | Breathe (opacity .24 ↔ .82) and drift, in four phase groups |
| Nebula | 30s drift, alternate |
| Distant galaxy | 18s gather, scale .98 ↔ 1.03 |
| Comet | 24s — **dormant at .16 opacity for 72% of the cycle**, then it passes |
| Realm nodes | The reference's own slow orbit: `56 + (i%8)×7` seconds, phase `(i%9) × −7.3`, roughly ±3px |
| Realm crests | Breathe, but only where Gravity ≥ 2. A Quiet Realm is legitimate context; it rests |
| Role ring | 24s revolution, tilted −18° and flattened to 0.56, with one phase node brightening as it travels |
| Entry | 760ms resolve, staggered 130ms **within each cluster** so siblings gather together |

Node drift is far slower and smaller than the canon's ceiling. That is the
point: the Field is never still, but nothing ever appears to move.

### Reduced motion

> Stop breathe, drift, orbit, path pulse, parallax and stagger. **Retain**
> semantic glow, scale, labels, state sigils and hierarchy.
>
> *Never remove information because animation is disabled.*

`Motion.reduced` **freezes the clock at zero** rather than branching at each
drawing site. Every phase function then returns its resting value, and
`pingPong(0)` / `cycle(0)` are genuine points on those curves — not a special
case. Because nothing branches where the drawing happens, there is no path on
which a reduced-motion frame can quietly lose an object.

Entry is the exception: it skips to *completed*, never to hidden. A Realm must
never be invisible because motion is off.

Sourced from `MediaQuery.disableAnimationsOf(context)`. `?motion=off` forces it
on for review without changing an OS setting.

### Performance

Static work is recorded, not repeated. `ConnectorLayer` and `ClusterLayer` do
not animate in this phase, so each records to a `Picture` once per resize and
replays it. Realm labels are laid out once into cached `TextPainter`s —
`TextPaint.render` builds and lays out a fresh painter on every call, which
across the Field is around a hundred layouts per frame. Star glows use two soft
discs rather than a mask blur; at that radius the result is indistinguishable
and 32 animated blurs per frame is not affordable.

Ambient object count is capped by viewport area, so a phone draws fewer motes
and the Field reads the same.

**Measure on a real GPU.** Playwright's headless shell falls back to SwiftShader
software rendering and caps near 47fps at 34 nodes *regardless of what the code
does* — an empty Field runs at 120fps there while the populated one crawls. The
same build headed runs at 120fps throughout. A headless FPS number is a
property of the harness, not of the Field.

---

## §6 · Interaction and the event vocabulary

### What a member can do

| Gesture | Result |
|---|---|
| Hover | Identity facts: **type · your role · stationed Ally**. Standing, never private activity |
| Tap a Realm | `RealmSelected` → brightens **existing** paths → `RealmActivated` → the inspection alert |
| Tap empty Field | `RealmDeselected` |
| `Escape` | Clears Focus. It must never destroy the underlying Realm context |
| Gravity 1–5 | `GravityChanged` → re-resolve → **Gather** |

### Selection is inspection

Selection brightens paths that already exist and applies **Relate**: a gentle
luminance cycle on the touched paths, which stops the moment the relationship
is no longer contextually active. It never invents a line, and it never enters,
joins, or grants anything.

`ConnectorLayer` keeps the unselected paths in its recorded picture and draws
only the live ones each frame, so Relate animates without re-rasterising the
whole layer.

### Why tap is recognised inside the drag lifecycle

The game owns `DragCallbacks` for panning. A click is a **zero-distance drag**,
and the gesture never reaches a child's `TapCallbacks` — hover arrives, tap does
not. `FieldGame` therefore records the press position in `onDragStart`,
accumulates travel in `onDragUpdate`, and treats anything under 6px of travel in
`onDragEnd` as a tap, hit-testing the Realms in reverse draw order.

This is not a workaround to tidy away later: it is the reliable path, because
these are the events that actually fire.

### The alert

`inspect_dialog.dart` stands in for the Inspect Realm panel this build does not
implement. It reports name, type, purpose, your role, stationed Ally, cluster,
distance band, and — for `fixture: true` — a **PROPOSED** notice, because such a
Realm does not yet exist and must never be presented as real.

It carries exactly one control, Gravity, and states its own limit: *selection is
inspection; nothing here enters, joins, or grants anything.* **There is no Enter
action.**

Opening it emits `FieldFocusChanged(dimmed: true)` and dims the Field —
**opacity only**, never Ki context, visibility, authority, relationship truth,
or underlying data.

### Gather

A Gravity change re-resolves the whole Field and reseats every affected Realm
over **900ms** on `cubic-bezier(.2, .7, .2, 1)` — solved by Newton iteration in
`motion.dart`, not approximated, so a Realm lands where the reference lands.

Crossing a distance band mid-flight rebuilds that node's metrics and cached
paint: the crest resizes, fidelity changes, and the type label appears or
disappears. Under reduced motion the reseat is instant, never skipped.

### There is deliberately no `RealmEntered`

Entry is a **consequential Action** with its own authority, inspection,
confirmation, execution, settlement and recovery boundaries — none of which this
build performs. Leaving it out of the vocabulary is what prevents selection from
being wired to navigation by accident.

`events_test.dart` reads the schema and asserts the six declared types exactly.
If that test ever fails, the decision was reversed without the review it needs.

Only `GravityChanged` is a write. `CameraChanged` is emitted on a trailing edge
250ms after movement stops — a pan produces hundreds of intermediate positions
nobody needs.

### Testing interaction: freeze the Field first

Ambient motion makes **every** frame differ — around 48,000 pixels change
between two idle frames from stars alone. A "the screenshot changed" assertion
therefore proves nothing while motion is running, and will report success for an
interaction that never happened.

Drive interaction checks with `?motion=off`, where idle frames are pixel
identical and the only thing that can change a pixel is the interaction itself.
Check Gather separately with motion on, where it belongs.

---

## §7 · Ki

Ki is a **floating panel over** the Field, never a part of it. It does not enter
the Flame world, does not scale with the camera, and the Field never reaches
into it. On a viewport under 900px it becomes a draggable bottom sheet — peek,
then drag up — rather than trying to hold a column that does not fit.

`?ki=off` hides it for reviewing the Field alone.

### Ki speaks in the third person, never "I"

This is not a style preference. Ki is present and can prepare or explain work
*without absorbing the Source's authority*, and a first-person voice quietly
implies an actor with intentions of its own.

**The suggested questions are the exception, and not really an exception:** they
are the *Source's* voice, prompts the member is about to send. "What should I do
first?" is the member speaking, and the reference phrases them exactly that way.
`ki_test.dart` enforces third person on `KiLine.body` across every line Ki can
say about every fixture, and separately asserts the prompts *do* read as the
Source. It also asserts the detector catches a planted lapse, so it cannot rot
into a regex that matches nothing.

Ki reports standing and claims nothing: no line may say a consequential Action
has happened.

### Field focus is opacity, and only opacity

> Field focus changes Field opacity only; it never changes Ki, visibility,
> authority, relationship truth, or underlying data.

The Field is wrapped in a single `Opacity` widget in `main.dart`, and the
control reports a number between 0.2 and 1.0. **The rule is true by
construction**: this mechanism is structurally incapable of changing anything
else.

It is also true empirically. If focus is pure opacity then for every pixel

```
dim = rest × α + ground × (1 − α)
```

Measured across the whole Field at α = 0.2: **100.000% of pixels match that
composite, worst error 0.6/255**, and 100% of marks that stood out from the
ground still do. Anything that moved, vanished, or shifted hue would break the
identity.

> **Measuring this palette:** an earlier version of that check sampled only the
> red channel and reported failures. Sky blue is `#03CCD9` — red 3 — so
> compositing it toward a ground of red 10 legitimately *raises* red while green
> and blue collapse. Measure luminance or the whole triple; never one channel.

---

## §8 · The Field Catalog

`?view=catalog` opens the specimen board. Its gate is blunt: **a developer who
has never seen Kiduna should be able to open it and correctly name every
element.** A visual system is learned by scrubbing it, not by reading about it.

Every specimen is drawn by the **same code that draws the Field** — the real
`RealmNode`, the real motion clock, the real tokens. A catalogue that
reimplements its subject documents a fiction; this one cannot drift, because if
a specimen looks wrong here it is wrong in the Field too.

| Section | Shows |
|---|---|
| **A** | 7 Realm types × 3 distance bands — 21 live specimens |
| **B** | Gravity 1–5 with each pull multiplier and resulting band |
| **C** | Every degradation state: proposed · unknown type · overlong name · no motif · Guest · Ally stationed |
| **D** | The four connector species with their bend constants |
| **E** | All six cluster accents as the halos they actually draw |
| **F** | Eleven colour tokens, and the sky-blue ink rule on four grounds |
| **G** | Four materials, and an Ally in all four States |
| **H** | The motion table, read from the constants themselves |
| **I** | **Deferred canon** — what was left out, and that it was a decision |

Two controls: **REDUCED MOTION** freezes everything (and demonstrates that
nothing disappears), and **REPLAY GATHER** rewinds the staggered arrival so it
can be watched again.

The motion table renders its numbers *from* `Verb`, not from a copy of it. If
someone changes a timing, the documentation changes with it.

---

## §9 · Running the checks

```bash
cd aev_flutter && ./tool/check.sh
```

Analyze · test · build · asset budget · fixture parse. Three of the tests exist
to protect decisions rather than behaviour, and are worth knowing about before
someone "fixes" them:

- **`fixture_coverage_test`** asserts every schema field is populated by at
  least one fixture, *and* that the check still fails when a field is
  stripped — so it cannot rot into a no-op that always passes.
- **`events_test`** asserts the event vocabulary is exactly six types. If
  `RealmEntered` ever appears, that is a decision needing review, not a silent
  addition.
- **`ki_test`** asserts Ki never speaks in the first person, and that the
  detector catches a planted lapse.

The asset budget exists because the emblems shipped at 640px once, drawn at
84px. Art is easy to add and hard to notice.

### Verification habits this build earned

- **Freeze motion before testing interaction.** Ambient motion changes ~48,000
  pixels between two idle frames, so "the screenshot changed" proves nothing.
  Use `?motion=off`.
- **Measure FPS on a real GPU.** Playwright's headless shell falls back to
  SwiftShader and caps near 47fps at 34 nodes regardless of the code.
- **Never measure this palette on one channel.** Sky blue is `#03CCD9` — red 3.
  Dimming it toward a ground of red 10 *raises* red.
- **Derive coordinates from the fixture, not the eye.** A hand-guessed click
  target missed a hit box by 5px and read as a broken feature.

---

## Verified against the reference

The resolver was compared to the live page's own DOM coordinates across 33
Realms: **worst delta 0.000467%**. The ring-and-pull maths reproduces
kiduna.design exactly.

Phase 2 was reviewed by screenshotting our build and the live page at the same
viewport in Playwright, which caught three real defects: the camera anchor, the
motif tofu, and uncoloured labels.
