# Louis: Joy Run — Project Plan

A Playdate game starring Louis, a boxer dog who wants nothing more than to escape
the yard and run the neighborhood.

> **Status:** Concept locked, pre-production. This document is the source of truth
> for the team and is meant to be read by both Figma (design + Figma Motion) and
> Claude Code (implementation).

---

## 1. Team & Roles

| Member | Role |
| --- | --- |
| **Alex** | Visionary, tech lead, owner of design intent. Has physical Playdate hardware for validation. |
| **Figma** (+ Figma Motion) | All design assets: character art, environments, UI, dialogue typography, and animation. |
| **Claude Code** | Application code — game logic, input handling, rendering, performance. |
| **Project Manager (Claude)** | Plan, brief, and keep design output inside the Playdate hardware constraints. |

A primary goal of this project is to **show off Figma's design abilities and the new
Figma Motion animation tooling**. Design and motion are not just a means to ship a
game — they are the thing being demonstrated. Decisions that give Figma more to show
(an animated star character, lavish dialogue motion, a parallax run cycle) are
favored where reasonable.

---

## 2. Concept

You are **Louis**, a boxer dog. You live in a house in **Livermore, California** and,
part-time, at an **off-grid cabin near Twain Harte, California**. Louis loves to
escape the yard and go on a "joy run" around the neighborhood.

The game alternates between two feels: a quiet, observational **prowl** inside the
house, and an explosive **joy run** outside once you slip free.

### Core loop

1. **Prowl** the house as Louis. Move around, listen to the humans, read the room.
2. **Read the opening.** Humans head for the front door, back door, or a gate. Work
   out how to get out — recognize their patterns, distract them, or tail another dog.
3. **Escape** through the opening before it closes.
4. **Joy Run.** Crank as fast as you can; the faster you crank, the faster Louis runs
   through the neighborhood.
5. Return home (caught, tired, or by choice) and the loop begins again, harder.

---

## 3. The Two Camera Modes

The two modes use **different cameras**, by design. This roughly doubles Figma's
character-perspective work (Louis must be animated in two render styles) but produces
a much better game and a stronger animation showcase.

### Prowl mode — top-down / three-quarter
You see the room: the floor plan, where each human is, which door is cracked, where
the other dogs are headed. This view is for *reading the situation* and solving the
escape puzzle.

### Joy Run mode — side-scroller
Pure speed. Louis runs left-to-right with a parallax neighborhood scrolling past.
This view is built for the run cycle and the sense of velocity the crank produces.

> **Camera framing note:** what we informally call "second-person" (seeing Louis
> rather than seeing through his eyes) is a follow-cam in both modes. We see the dog —
> that was the whole point of the camera decision.

---

## 4. Controls

| Mode | Input | Action |
| --- | --- | --- |
| Prowl | D-pad | Move Louis |
| Prowl | A | Primary action — sniff / listen / interact |
| Prowl | B | Secondary — distraction action (e.g. bark) / cancel |
| Joy Run | Crank | **Run speed.** Crank faster → run faster. |
| Joy Run | D-pad | Steer / dodge |
| Joy Run | A or D-pad (alt) | Accessibility alternative to cranking |
| Menus | A / B | A confirms, B cancels/back (system convention — do not reassign in housekeeping UI) |

Ergonomics follow Playdate guidance: during Joy Run the crank sits under the right
hand while the left thumb works the d-pad — the comfortable grip. Per accessibility
guidance, **every crank action must have a button alternative**.

---

## 5. Cast (Figma's character bible — job one)

All characters are designed in a single locked 1-bit style. Silhouettes must be
distinct, especially among the three dogs.

**Dogs**
- **Louis** — boxer. Our star. Stocky build, square head, short coat. Must read at
  ~32px and animate well (run cycle, ear flop, tail, idle tells, distraction action).
- **Moxy** — companion dog. Distinct silhouette from Louis.
- **Pepper** — companion dog. Distinct silhouette from Louis and Moxy.

**Humans** (seen in the prowl view; sources of dialogue)
- Ella, Walter, Mama, Tina, Alex, Austin, Gavin.

Each human should have a readable routine and a recognizable presence, since reading
their behavior is a core mechanic.

---

## 6. Dialogue & the Keyword Mechanic

Louis is a dog, so human speech mostly reads as noise — **"blah blah blah."** But
Louis understands a **modest vocabulary**, and recognized words surface out of the
noise:

> blah blah **leash** blah **walk** blah

This is not just flavor. **The recognized words are the puzzle signal.** Hearing
"...**leash** ... **walk**..." telegraphs that a human is about to go outside — an
opportunity. Reading these cues is how the player recognizes patterns.

**Design implications**
- Recognized keywords are visually emphasized against the muffled "blah" — a natural,
  high-visibility moment for **Figma Motion** (the word pops/reveals while the noise
  stays flat).
- Because keywords carry gameplay information, dialogue must stay **legible and
  consistently timed** regardless of the frame rate the prowl state is running at.
- Candidate vocabulary (starter set): *leash, walk, gate, out, car, vet, bath, treat,
  dinner, no, stay, good boy*, plus the dogs' names.

---

## 7. The Escape Puzzle

Escaping is **mostly a puzzle**, not a punishing stealth sequence. Three solution
vectors, each with an implementation requirement:

1. **Recognize patterns** — humans follow readable routines and give tells (including
   the dialogue keywords above). *Requires: human routine/behavior logic with
   observable cues.*
2. **Distract the humans** — Louis can do something (bark, knock something over) to
   move a human's attention or position and clear/open a path. *Requires: a
   distraction action + human responses to it.*
3. **Follow another dog** — Moxy and Pepper have their own pathing; tail them through
   an opening. *Requires: companion-dog NPC pathing the player can exploit.*

---

## 8. Progression & Scope

- **v1 vertical slice:** **Livermore** (the suburban house and neighborhood), built
  complete — all systems working end to end.
- **Act two / environment pack:** **Twain Harte** unlocks after modest progress in
  Livermore. It **reuses the v1 systems** with new art: rural, wooded, off-grid cabin
  rather than suburb. This keeps v1 scope contained and de-risked.

---

## 9. Hardware Constraints & Design Guardrails

These come from Playdate's official *Designing for Playdate* guidance and are the
rules Figma's output is checked against. The hardest one to hold is the palette.

### The box
- **Screen:** 400 × 240 px, **1-bit — pure black and pure white only.** No grays, no
  color, no gradients. Shading and texture come from **dithering**, not gray values.
- **No backlight;** the screen looks like newsprint. Art can run to the edges (a 3mm
  black bezel blends into black).
- If we ever need true physical centering, the screen's center line is at **x = 228**,
  not 200 (the panel is offset left).

### Sprites & tiles
- Player-scale sprites (Louis, dogs, humans): **~32px minimum**, **2px minimum stroke
  thickness**.
- Tiles: aim for 32×32, use powers of two (8/16/32).
- **Pre-render rotations/scales as sprite-sheet frames** rather than transforming in
  code — Playdate has **no GPU**, and code transforms are CPU-heavy and noisy.

### Text
- Cap-height minimums: dialogue **12–14px**, HUD **10px floor**, fine print **8px
  floor**. Strokes **≥ 2px**.

### Frame rate — **per game state**, not global
- **Joy Run:** target **30 fps**. 50 fps is possible and looks great on fast/curved
  motion but costs **~40% of the per-frame compute budget** and more battery — treat
  it as a deliberate, justified choice, not a default. *(Open decision — see §12.)*
- **Prowl / dialogue:** low movement, so we can **request a lower refresh rate** to
  save battery. Whatever rate a state runs at, **Figma must author its motion for that
  rate** (a reveal authored for 30fps will not look the same throttled).

### Dither flashing — the Joy Run hazard
A dithered pattern scrolled 1px at a time strobes (an accessibility hazard and just
ugly). Since Joy Run is a fast horizontal side-scroller, this is exactly where it
bites. **Rules for the running background:**
- Use **horizontal-line patterns** (don't shift when scrolled horizontally).
- Scroll by **multiples of 2px**.
- Or apply the dither **after** movement (mask + draw separately).

### Sound & accessibility
- Don't assume audio is audible (players are on buses, in quiet rooms). Provide
  **visual feedback for sound events**. The "blah blah" dialogue is already a visual
  representation of speech, which helps here.

---

## 10. Showcase Moments (where Figma + Figma Motion shine)

- **Launcher card:** Louis himself — ears perking, head tilt — animating into the
  first screen. First impression and a prime Figma Motion piece.
- **Wrapping paper pattern:** paw prints or bones, shown as the game is "unwrapped."
- **Crank indicator:** the standardized animated nudge that teaches Joy Run's crank
  control the first time.
- **Dialogue keyword reveals:** recognized words popping out of "blah" — cheap on
  compute (prowl is low-movement) so we can be lavish.
- **Joy Run run cycle + parallax:** Figma's frame-by-frame craft on full display.

---

## 11. Risks & Watch-outs

- **Figma Motion will fight 1-bit.** Its native vocabulary is color, gradients, and
  anti-aliased grays. **Mitigation:** lock a 1-bit + dither component library *before*
  any motion work, so the AI animates inside guardrails instead of drifting.
- **Dither flashing in Joy Run** — mitigated by the scroll rules in §9.
- **Simulator and Figma both render larger and cleaner than real hardware.** "Looks
  fine in the comp" is not the bar. **Mitigation:** Alex validates legibility on the
  physical Playdate. (Hardware dependency: resolved — Alex has the device.)
- **Auto-dithered color art looks noisy.** Plan **manual cleanup passes** on key
  assets.
- **Three dog silhouettes blurring together** — enforce distinct shapes at design
  time.

---

## 12. Open Decisions

These are not yet locked and should be resolved as production starts:

1. **Catch / fail state.** It's "mostly a puzzle" — is failing to slip out a soft
   setback (shooed back inside, try again) or is there a harder consequence?
2. **Joy Run structure.** Endless / score-based (run as far/fast as you can) or a
   fixed course with an end?
3. **Moxy & Pepper's role.** Always-present companions, or specific puzzle elements in
   particular layouts?
4. **Distraction action specifics.** Bark? Knock something over? Both, situationally?
5. **50 fps for the Joy Run climax** — worth the compute/battery cost, or hold at 30?

---

## 13. Validation

Alex has physical Playdate hardware. All legibility, dither, and motion decisions get
a **real-device check** before they're considered done — the Simulator and Figma are
both unreliable for final sizing and contrast.
