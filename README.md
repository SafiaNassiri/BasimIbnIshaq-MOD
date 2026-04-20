# Basim Mod for The Binding of Isaac
**Play as Basim Ibn Ishaq from Assassin's Creed Mirage!**

---

## Overview

This mod introduces **Basim Ibn Ishaq** as a playable character in *The Binding of Isaac: Repentance*. Agile and deadly, Basim comes equipped with piercing attacks and a Smoke Bomb ability inspired by his Assassin's Creed skills.

- **High speed** – move quickly around rooms
- **Piercing tears** – deal damage through multiple enemies in a line
- **Smoke Bomb** – teleport a short distance and slow all nearby enemies

> **This release contains code only — no art assets are included.** You must supply your own sprites before the mod will run. See the [Art Assets](#art-assets) section below.

---

## Character Stats

| Stat | Value |
|------|-------|
| Speed | 1.2× normal |
| Damage | 3.5 |
| Health | 6 HP (3 red hearts) |
| Tear Type | Piercing |
| Fire Rate | Tears stat 2.73 |
| Range | 6.5 |
| Shot Speed | 1.0× |
| Special Ability | Smoke Bomb – teleport up to 200px, slow nearby enemies |

---

## Unlock

Basim is **locked by default**. To unlock him:

1. Start a run with **any character**
2. Clear **Basement I** (reach floor 2)
3. Basim will appear on the character select screen permanently

The unlock is saved automatically via the mod's save file and only needs to be triggered once.

---

## Installation

1. Ensure you have **The Binding of Isaac: Repentance** installed.
2. Place the `BasimMod` folder in:
   ```
   Documents/My Games/Binding of Isaac Afterbirth+ Mods/
   ```
3. Enable the mod in the game's **Mods** menu.
4. Start a new run and select **Basim** as your character.

### Required folder structure
```
BasimMod/
  main.lua
  metadata.xml
  content/
    players.xml
  gfx/
    characters/
      basim.png
      basim.anm2
    ui/
      playername_basim.png
      charactermenu/
        basim_portrait.png
```

---

## Controls

| Action | Input |
|--------|-------|
| Move | Arrow keys / WASD |
| Shoot | Arrow keys + Fire button |
| **Smoke Bomb** | Spacebar (Active Item button) |

### Smoke Bomb
- Teleports Basim up to **200px** in a random direction
- Slows all enemies within **180px** of the landing spot to **40% speed** for **3 seconds**
- Cooldown: **10 seconds** (shown on HUD)

---

## Configuration

All stats and ability values can be tuned at the top of `main.lua`:

```lua
local BASIM_STATS = {
    speed     = 1.2,
    damage    = 3.5,
    tears     = 2.73,
    range     = 6.5,
    shotspeed = 1.0,
}

local SMOKE_BOMB = {
    cooldown      = 300,   -- frames (~10s)
    slowRadius    = 180,   -- pixels
    slowTime      = 90,    -- frames (~3s)
    slowFactor    = 0.4,   -- 40% speed
    teleportRange = 200,   -- max pixels
}
```

---

## Art Assets

**No art is included in this mod.** You must create or generate the following files and place them in the `gfx/` folder before the mod will run:

| File | Size | Description |
|------|------|-------------|
| `gfx/characters/basim.png` | 128×64px | Character sprite sheet (4×2 frames) |
| `gfx/characters/basim.anm2` | — | Animation definition (copy from Isaac resources) |
| `gfx/ui/charactermenu/basim_portrait.png` | 202×308px | Character select portrait |
| `gfx/ui/playername_basim.png` | 115×16px | Name plate shown on select screen |

Once your art is ready, update the file paths in `content/players.xml` to match.

---

## Notes

- During testing, press **F1** to instantly reset the Smoke Bomb cooldown. Remove this before shipping.
- Stats are balanced for fun and can be freely adjusted in `main.lua`.

---

## Credits

- Mod Concept & Lua Scripting: **Your Name**
- Character Design Inspiration: *Assassin's Creed Mirage*
- Isaac Modding API & Community: [https://moddingofisaac.com](https://moddingofisaac.com)

---

## License

This mod is for **educational and personal use** only. Do not distribute commercially or claim ownership of Assassin's Creed IP.
