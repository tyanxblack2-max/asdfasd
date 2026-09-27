# Self-Hosted UI Libraries

Push this folder to the root of `tyanxblack2-max/asdfasd` under `ui-libs/` so the
structure is:

```
ui-libs/
├── obsidian-ultra/
│   ├── Library.lua            (EDITED - icon module fetch points below)
│   ├── addons/SaveManager.lua (unmodified)
│   ├── LICENSE                (MIT, deividcomsono - keep with the copy)
│   └── README.md
└── lucide-icons/
    ├── source.lua             (EDITED - spritesheet fetch points below)
    ├── 1.png                  (1024x1024 spritesheet, downloaded from upstream)
    ├── 2.png                  (512x512 spritesheet, downloaded from upstream)
    └── LICENSE                (MIT, mstudio45 - keep with the copy)
```

## What was changed vs the archive

### obsidian-ultra/Library.lua — one block at line ~2031

The old single-URL fetch of `mstudio45/lucide-roblox-direct` was replaced with a
3-source loop:

1. `raw.githubusercontent.com/tyanxblack2-max/asdfasd/.../ui-libs/lucide-icons/source.lua`
2. `cdn.jsdelivr.net/gh/tyanxblack2-max/asdfasd@main/...` (CDN mirror)
3. the original upstream URL (last resort)

A `?nocache=` query busts GitHub's 5-minute raw cache on each load. Everything
else in the file is byte-identical to the archived copy (verified by diff).

### lucide-icons/source.lua — spritesheet block at line ~22

The two PNG spritesheets the module writes to disk (and `getcustomasset`s for
icons) now come from the same 3-source list as above. If all three fail, the
existing `IS_GETCUSTOMASSET_BROKEN` fallback rbxassetid icons take over.

## If you move or rename the repo

Edit these two spots:

- `Library.lua` — the `ICON_MODULE_SOURCES` table (line ~2035)
- `lucide-icons/source.lua` — the `SPRITESHEET_SOURCES` table (line ~28)

Both use `{spritesheet}` interpolation for the PNG names, so only the base URL
needs changing.

## Licence note

Both upstream libraries are MIT. The `LICENSE` files sit next to each copy —
keep them there and keep the original copyright lines intact if you publish.
