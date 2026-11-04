// scr_art: the look of the game. Parallax backgrounds, autotiled terrain, scenery props, sky details, vignette.
//
// The art packs are 32 px pixel art. The world runs on a 16-unit grid and each view is shown at 2x, so art drawn
// at ART_S (0.5) lands as exactly one texel per screen pixel: sharp, no filtering, no shimmer.
//
// Dimension 0 is the OVERWORLD (dusk sky, grass, gold light). Dimension 1 is the UNDERWORLD (ember sky, scorched
// earth, red light): the same sprites recoloured. Everything below picks its sprite from global.art[dim].

#macro ART_S      0.5
#macro ART_TILE   32

/// @desc Looks up every themed sprite once. Called from obj_game's Create.
function art_init() {
    global.frame = 0;
    global.art = [];
    for (var d = 0; d < 2; d++) {
        var _k = (d == 0) ? "o" : "u";
        var _a = {
            key:    _k,
            ground: asset_get_index("spr_ground_" + _k),
            hero:   asset_get_index(d == 0 ? "spr_hero_a" : "spr_hero_b"),
            crate:  asset_get_index("spr_crate_" + _k),
            portal: asset_get_index("spr_portal_" + _k),
            torch:  asset_get_index("spr_torch_" + _k),
            plank:  asset_get_index("spr_plank_" + _k),
            camp_off: asset_get_index("spr_camp_off_" + _k),
            camp_on:  asset_get_index("spr_camp_on_" + _k),
            slime:  asset_get_index("spr_slime_" + _k),
            coin:   asset_get_index("spr_coin_" + _k),
            dust:   (d == 0) ? make_colour_rgb(228, 214, 190) : make_colour_rgb(255, 120, 70),
            bg:     [],
            tufts:  [],
            bushes: [],
            rocks:  [],
            tall:   []
        };
        for (var i = 0; i < 5; i++) array_push(_a.bg, asset_get_index("spr_bg_" + _k + string(i)));
        var _t = ["grass_a", "grass_b", "grass_c"];
        for (var i = 0; i < array_length(_t); i++) array_push(_a.tufts, asset_get_index("spr_deco_" + _k + "_" + _t[i]));
        array_push(_a.bushes, asset_get_index("spr_deco_" + _k + "_bush_big"), asset_get_index("spr_deco_" + _k + "_bush_small"), asset_get_index("spr_deco_" + _k + "_fern"));
        array_push(_a.rocks,  asset_get_index("spr_deco_" + _k + "_rock_big"), asset_get_index("spr_deco_" + _k + "_rock_mid"), asset_get_index("spr_deco_" + _k + "_rock_small"));
        if (d == 0) {
            array_push(_a.tall, asset_get_index("spr_deco_o_scarecrow"), asset_get_index("spr_deco_o_statue"), asset_get_index("spr_deco_o_stump"), asset_get_index("spr_deco_o_barrel"));
        } else {
            array_push(_a.tall, asset_get_index("spr_deco_u_tomb_a"), asset_get_index("spr_deco_u_tomb_b"), asset_get_index("spr_deco_u_tomb_c"), asset_get_index("spr_deco_u_cross"), asset_get_index("spr_deco_u_pumpkin"), asset_get_index("spr_deco_u_statue"));
        }
        array_push(global.art, _a);
    }

    // drifting clouds for the overworld sky
    global.clouds = [];
    for (var i = 0; i < 7; i++) {
        array_push(global.clouds, {
            x: i * 150 + ((i * 53) mod 60), y: 0.08 + 0.32 * ((i * 37) mod 10) / 10,
            spd: 0.05 + 0.05 * ((i * 13) mod 5) / 5, spr: asset_get_index("spr_cloud" + string(1 + (i mod 6)))
        });
    }
}

// ------------------------------------------------------------------ terrain

/// @desc Marks every cell covered by a plain obj_solid. Gates, platforms and boxes are children of obj_solid and
/// draw themselves, so they are skipped here.
function terrain_build() {
    global.terr_cols = ceil(room_width / TILE);
    global.terr_rows = ceil(room_height / TILE);
    global.terr = array_create(global.terr_cols * global.terr_rows, false);
    global.haz  = array_create(global.terr_cols * global.terr_rows, false);
    // hazards (tar, water, lava) sit in pits; their cells count as solid for the tile edges so the bed under them
    // gets plain earth instead of a grass top
    with (obj_tar)  terrain_mark_hazard();
    with (obj_pool) terrain_mark_hazard();
    with (obj_solid) {
        if (object_index != obj_solid) continue;
        var _x1 = round(x / TILE);
        var _y1 = round(y / TILE);
        var _x2 = _x1 + max(1, round(image_xscale)) - 1;
        var _y2 = _y1 + max(1, round(image_yscale)) - 1;
        for (var cx = _x1; cx <= _x2; cx++) {
            for (var cy = _y1; cy <= _y2; cy++) {
                if (cx >= 0 && cx < global.terr_cols && cy >= 0 && cy < global.terr_rows) global.terr[cy * global.terr_cols + cx] = true;
            }
        }
    }
}

/// @desc Marks the cells under the calling hazard instance.
function terrain_mark_hazard() {
    var _x1 = round(x / TILE);
    var _y1 = round(y / TILE);
    var _x2 = _x1 + max(1, round(image_xscale)) - 1;
    var _y2 = _y1 + max(1, round(image_yscale)) - 1;
    for (var cx = _x1; cx <= _x2; cx++) {
        for (var cy = _y1; cy <= _y2; cy++) {
            if (cx >= 0 && cx < global.terr_cols && cy >= 0 && cy < global.terr_rows) global.haz[cy * global.terr_cols + cx] = true;
        }
    }
}

/// @desc Is this cell solid terrain? Anything beyond the sides of the room or beyond the band counts as solid, so
/// ground flows off the edges of the screen instead of ending in a rounded corner.
function terr_at(_cx, _cy, _dim) {
    var _band = DIM_H div TILE;
    if (_cx < 0 || _cx >= global.terr_cols) return true;
    if (_cy < _dim * _band || _cy >= (_dim + 1) * _band) return true;
    return global.terr[_cy * global.terr_cols + _cx] || global.haz[_cy * global.terr_cols + _cx];
}

/// @desc Which tile of the 9 x 6 ground sheet to use for a cell, from which of its neighbours are solid.
/// Returns col + row * 16 (decoded by the caller).
function terrain_pick(_u, _d, _l, _r, _ul, _ur) {
    var _c, _row;
    if (!_u && !_d) {                       // a one-tile-thick strip
        _c = (!_l && !_r) ? 6 : (!_l ? 6 : (!_r ? 8 : 7));
        return _c + 5 * 16;
    }
    if (!_l && !_r) {                       // a one-tile-wide pillar: top cap, bottom cap, or plain earth between
        if (!_d) return 6 + 4 * 16;
        if (!_u) return 6 + 3 * 16;
        return 1 + 1 * 16;
    }
    _c   = !_l ? 0 : (!_r ? 2 : 1);
    _row = !_u ? 0 : (!_d ? 2 : 1);
    return _c + _row * 16;
}

function terrain_draw(_dim) {
    var _cam = global.cams[_dim];
    var _vx = camera_get_view_x(_cam);
    var _spr = global.art[_dim].ground;
    if (!sprite_exists(_spr)) return;
    var _band = DIM_H div TILE;
    var _c1 = max(0, floor(_vx / TILE) - 1);
    var _c2 = min(global.terr_cols - 1, floor((_vx + VIEW_W) / TILE) + 1);
    for (var cy = _dim * _band; cy < (_dim + 1) * _band; cy++) {
        for (var cx = _c1; cx <= _c2; cx++) {
            if (!global.terr[cy * global.terr_cols + cx]) continue;
            var _t = terrain_pick(
                terr_at(cx, cy - 1, _dim), terr_at(cx, cy + 1, _dim),
                terr_at(cx - 1, cy, _dim), terr_at(cx + 1, cy, _dim),
                terr_at(cx - 1, cy - 1, _dim), terr_at(cx + 1, cy - 1, _dim));
            // plain earth comes in textured variants (row 6 of the sheet), picked by cell so a wall never repeats evenly
            if (_t == 17) {
                var _v = art_hash(cx, cy + _dim * 1000) mod 8;
                if (_v < 6) _t = _v + 6 * 16;
            }
            draw_sprite_part_ext(_spr, 0, (_t mod 16) * ART_TILE, (_t div 16) * ART_TILE, ART_TILE, ART_TILE,
                                 cx * TILE, cy * TILE, ART_S, ART_S, c_white, 1);
        }
    }
}

// ------------------------------------------------------------------ scenery props

/// @desc A small deterministic hash so scenery lands in the same place every time the room loads.
function art_hash(_a, _b) {
    var _h = ((_a * 73856093) ^ (_b * 19349663)) & 0x7fffffff;
    _h = ((_h ^ (_h >> 13)) * 1274126177) & 0x7fffffff;
    return (_h ^ (_h >> 16)) & 0xffffff;
}

/// @desc Scatters grass, bushes, rocks and a few big props over every ground surface.
function deco_build() {
    global.deco = [[], []];
    var _band = DIM_H div TILE;
    var _pumpkin = asset_get_index("spr_deco_u_pumpkin");
    for (var d = 0; d < 2; d++) {
        var _a = global.art[d];
        var _last_big = -99;
        for (var cx = 0; cx < global.terr_cols; cx++) {
            for (var cy = d * _band; cy < (d + 1) * _band; cy++) {
                if (!global.terr[cy * global.terr_cols + cx]) continue;
                if (cy > d * _band && (global.terr[(cy - 1) * global.terr_cols + cx] || global.haz[(cy - 1) * global.terr_cols + cx])) continue;   // not a surface
                var _h = art_hash(cx, cy + d * 1000);
                var _px = cx * TILE + 2 + ((_h >> 4) mod 12);
                var _roll = _h mod 100;
                var _spr = -1;
                if (_roll < 48) _spr = _a.tufts[(_h >> 8) mod array_length(_a.tufts)];
                else if (_roll < 58) _spr = _a.bushes[(_h >> 8) mod array_length(_a.bushes)];
                else if (_roll < 63) _spr = _a.rocks[(_h >> 8) mod array_length(_a.rocks)];
                else if (_roll < 68 && cx - _last_big > 5) {
                    _spr = _a.tall[(_h >> 8) mod array_length(_a.tall)];
                    _last_big = cx;
                }
                if (_spr != -1 && sprite_exists(_spr)) {
                    array_push(global.deco[d], { spr: _spr, x: _px, y: cy * TILE + 1, glow: (d == 1 && _spr == _pumpkin) });
                }
            }
        }
    }
}

function deco_draw(_dim) {
    var _cam = global.cams[_dim];
    var _vx = camera_get_view_x(_cam);
    var _list = global.deco[_dim];
    var _n = array_length(_list);
    for (var i = 0; i < _n; i++) {
        var _o = _list[i];
        if (_o.x < _vx - 40 || _o.x > _vx + VIEW_W + 40) continue;
        draw_sprite_ext(_o.spr, 0, _o.x, _o.y, ART_S, ART_S, 0, c_white, 1);
    }
}

/// @desc Pumpkins glow. Called from the Step so the light list is filled before the darkness is drawn.
function deco_lights() {
    for (var d = 0; d < 2; d++) {
        var _list = global.deco[d];
        for (var i = 0; i < array_length(_list); i++) {
            var _o = _list[i];
            if (_o.glow) light_add(_o.x, _o.y - 8, 34, 0.8);
        }
    }
}

// ------------------------------------------------------------------ backgrounds

/// @desc Sky + parallax layers for one dimension's view. Called from the back art object (far behind everything).
function bg_draw(_dim) {
    var _cam = global.cams[_dim];
    var _vx = camera_get_view_x(_cam);
    var _vy = camera_get_view_y(_cam);
    var _a  = global.art[_dim];
    if (!sprite_exists(_a.bg[0])) {
        draw_set_colour(global.theme[_dim].bg);
        draw_rectangle(_vx, _vy, _vx + VIEW_W, _vy + VIEW_H, false);
        draw_set_colour(c_white);
        return;
    }

    // sky: a plain gradient, stretched to fill
    draw_sprite_ext(_a.bg[0], 0, _vx, _vy, VIEW_W / sprite_get_width(_a.bg[0]), VIEW_H / sprite_get_height(_a.bg[0]), 0, c_white, 1);

    // sun / moon, slowly parallaxing
    var _sx = _vx + VIEW_W - 90 - ((_vx * 0.02) mod 40);
    var _sy = _vy + 34;
    gpu_set_blendmode(bm_add);
    if (_dim == 0) {
        draw_sprite_ext(spr_light, 0, _sx, _sy, 1.6, 1.6, 0, make_colour_rgb(255, 210, 130), 0.45);
        gpu_set_blendmode(bm_normal);
        draw_sprite_ext(spr_sun, 0, _sx, _sy, ART_S * 1.5, ART_S * 1.5, 0, c_white, 1);
    } else {
        draw_sprite_ext(spr_light, 0, _sx, _sy, 2.2, 2.2, 0, make_colour_rgb(255, 60, 40), 0.35);
        gpu_set_blendmode(bm_normal);
        draw_set_colour(make_colour_rgb(120, 14, 24));
        draw_circle(_sx, _sy, 17, false);
        draw_set_colour(make_colour_rgb(176, 30, 30));
        draw_circle(_sx - 2, _sy - 2, 14, false);
        draw_set_colour(c_white);
    }

    // clouds drift across the overworld sky
    if (_dim == 0) {
        for (var i = 0; i < array_length(global.clouds); i++) {
            var _c = global.clouds[i];
            var _span = 1100;
            var _cx = ((_c.x + global.frame * _c.spd - _vx * 0.06) mod _span + _span) mod _span - 120;
            draw_sprite_ext(_c.spr, 0, _vx + _cx, _vy + 8 + _c.y * 70, ART_S * 2, ART_S * 2, 0, c_white, 0.9);
        }
    }

    // parallax layers, far to near. Each is 1024 x 346 art = 512 x 173 units, standing on the bottom of the view.
    var _f = [0, 0.07, 0.14, 0.24, 0.38];
    var _lift = [0, 18, 8, 2, 0];
    for (var l = 1; l < 5; l++) {
        var _spr = _a.bg[l];
        if (!sprite_exists(_spr)) continue;
        var _w = sprite_get_width(_spr) * ART_S;
        var _x0 = _vx - ((_vx * _f[l]) mod _w);
        var _y0 = _vy + VIEW_H - sprite_get_height(_spr) * ART_S + _lift[l] + ((_dim == 1) ? 6 : 0);
        for (var xx = _x0 - _w; xx < _vx + VIEW_W; xx += _w) {
            draw_sprite_ext(_spr, 0, xx, _y0, ART_S, ART_S, 0, c_white, 1);
        }
    }
}

// ------------------------------------------------------------------ screen finishing

/// @desc A soft darkening around the edge of each view. Called in world space for one view.
function vignette_draw(_dim) {
    var _cam = global.cams[_dim];
    var _x1 = camera_get_view_x(_cam);
    var _y1 = camera_get_view_y(_cam);
    var _x2 = _x1 + VIEW_W;
    var _y2 = _y1 + VIEW_H;
    var _tint = (_dim == 0) ? make_colour_rgb(20, 12, 40) : make_colour_rgb(30, 0, 8);
    var _w = 72;
    var _h = 26;
    var _a = 0.55;
    gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex_colour(_x1, _y1, _tint, _a); draw_vertex_colour(_x1 + _w, _y1, _tint, 0);
    draw_vertex_colour(_x1, _y2, _tint, _a); draw_vertex_colour(_x1 + _w, _y2, _tint, 0);
    draw_primitive_end();
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex_colour(_x2, _y1, _tint, _a); draw_vertex_colour(_x2 - _w, _y1, _tint, 0);
    draw_vertex_colour(_x2, _y2, _tint, _a); draw_vertex_colour(_x2 - _w, _y2, _tint, 0);
    draw_primitive_end();
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex_colour(_x1, _y1, _tint, _a); draw_vertex_colour(_x2, _y1, _tint, _a);
    draw_vertex_colour(_x1, _y1 + _h, _tint, 0); draw_vertex_colour(_x2, _y1 + _h, _tint, 0);
    draw_primitive_end();
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex_colour(_x1, _y2, _tint, _a); draw_vertex_colour(_x2, _y2, _tint, _a);
    draw_vertex_colour(_x1, _y2 - _h, _tint, 0); draw_vertex_colour(_x2, _y2 - _h, _tint, 0);
    draw_primitive_end();
    gpu_set_blendmode(bm_normal);
}
