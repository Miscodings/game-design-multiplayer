# tools/

The art, objects and levels in the GameMaker project are **generated** by these scripts, so they can be re-run after
changes. Run everything from the project root. Needs Python 3 with `pillow` and `numpy`.

| Script | What it does |
| --- | --- |
| `build_art.py` | Builds every sprite from `art_source/` (GandalfHardcore packs). The underworld set is the same sprites recoloured through a gradient map (HELL_* ramps). Writes sprite resources into `sprites/`. |
| `install_code.py` | Installs the GML in `tools/gml/` as scripts, patches the existing objects (draw events etc.) and creates `obj_art`, `obj_coin`, `obj_tip`. Idempotent. **Edit GML in `tools/gml/`, not in `scripts/`, for the files it manages** (`scr_art`, `scr_fx`, `scr_player_art`, `scr_props`, `scr_tips`, `scr_levels`, `scr_hud`, `scr_game_state`). |
| `install_title.py` | Creates `rm_title` and `obj_title` and puts the title first in the room order. The game title text is `GAME_TITLE_1/2` at the top. |
| `levels_data.py` | The eight levels, written as small layout programs (`L.ground`, `L.pit`, `L.rect`, `L.coins`, `L.tip` ...). |
| `build_levels.py` | Turns `levels_data.py` into `rooms/rm_level_N/`. `python tools/build_levels.py 3` rebuilds just level 3. Also writes a map to `tools/preview/level_N.png`. |
| `mock_render.py` | Approximate picture of what the game draws: `python tools/mock_render.py <level> <start_col>`. |
| `check_gml.py` | Crude bracket-balance check over every `.gml` file. |

Close the project in GameMaker before running any of these (GameMaker overwrites files it has open).

## How the art is scaled
Art is 32 px pixel art. The world runs on a 16-unit grid and every view is shown at 2x, so sprites are drawn at
`ART_S = 0.5`: exactly one texel per screen pixel. Keep new art at 32 px per tile.

## Licence
`art_source/` is the GandalfHardcore free pack. Its licence allows use and modification in games but not
redistribution, so keep this repository private.
