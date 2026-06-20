# Launcher assets

Drop your 1-bit PNG artwork **in this folder** (`source/launcher/`). `pdxinfo` has
`imagePath=launcher`, so `pdc` pulls launcher art from here. This README is excluded
from the build via `source/.pdcignore`.

Playdate is a 1-bit display: use pure black (#000000) and white (#FFFFFF) only.

## Required (minimum — per SDK docs)

| File | Exact size | Shown |
|------|-----------|-------|
| `card.png`        | 350 × 155 | Launcher **card** view (the big tile) |
| `icon.png`        | 32 × 32   | Launcher **list** view (the small icon) |
| `launchImage.png` | 400 × 240 | Loading screen while the game boots. **No transparency.** |

## Optional (polish)

| File / folder | Exact size | Purpose |
|---------------|-----------|---------|
| `card-pressed.png`      | 350 × 155 | Card shown on A-button press in card view |
| `card-highlighted/`     | 350 × 155 each | Animated card loop (`1.png`, `2.png`, …) + optional `animation.txt` |
| `icon-pressed.png`      | 32 × 32   | Icon shown on A-button press in list view |
| `icon-highlighted/`     | 32 × 32 each | Animated icon loop (`1.png`, `2.png`, …) + optional `animation.txt` |
| `launchImage-list.png`  | 400 × 240 | Loading screen specifically for list view (falls back to `launchImage.png`) |
| `launchImages/`         | 400 × 240 each | Launch transition animation, 20 fps (`1.png`, `2.png`, …); may use transparency |

### `animation.txt` format (for `card-highlighted/` and `icon-highlighted/`)

```
loopCount = 2
frames = 1, 2, 3x4, 4x2, 5, 5
introFrames = 1, 2x2, 3, 4x2
```

All three lines optional. `x#` repeats a frame for # animation frames.
`loopCount` defaults to infinite; `introFrames` plays once before the loop.

## Other appearance metadata (set in `source/pdxinfo`, not here)

- `launchSoundPath` — path to a short audio file played during the launch animation.
- `contentWarning` / `contentWarning2` — first-launch warning screens.
