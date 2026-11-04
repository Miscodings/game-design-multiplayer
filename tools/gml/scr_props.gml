// scr_props: how the gameplay objects look. Each object's Draw event calls one function from here. All of them take
// their colours from the dimension the object sits in (overworld = gold and green, underworld = ember and crimson).

// ------------------------------------------------------------------ coins

/// @desc Coins are collected by the player of their own dimension. They bob, spin and sparkle.
function coin_update() {
    var _p = global.players[dim];
    if (!instance_exists(_p)) return;
    if (point_distance(_p.x, _p.y - 11, x, y) < 13) {
        global.coins_got[dim]++;
        array_push(global.coins_taken, [x, y]);
        global.coin_flash = 12;
        fx_burst(x, y, 12, global.theme[dim].accent, 1.8, 26, 1.6, 0.03, true);
        fx_emit(x, y, 0, -0.6, 22, 3, c_white, 0, true);
        instance_destroy();
        return;
    }
    light_add(x, y, 26, 0.55);
}

function coin_draw() {
    var _spr = global.art[dim].coin;
    var _bob = sin((global.frame + phase) * 0.07) * 2;
    var _f = floor((global.frame + phase) * 0.18) mod 8;
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(spr_light, 0, x, y + _bob, 0.16, 0.16, 0, global.theme[dim].accent, 0.4);
    gpu_set_blendmode(bm_normal);
    if (sprite_exists(_spr)) draw_sprite_ext(_spr, _f, x, y + _bob, ART_S, ART_S, 0, c_white, 1);
}

// ------------------------------------------------------------------ enemies

function walker_draw() {
    var _spr = global.art[dim].slime;
    var _f = floor(global.frame * 0.12 + x * 0.05) mod 4;
    if (sprite_exists(_spr)) draw_sprite_ext(_spr, _f, x, y, ART_S * dir, ART_S, 0, c_white, 1);
    else draw_self();
    if (dim == 1) light_add(x, y - 8, 22, 0.55);
}

// ------------------------------------------------------------------ hazards

function tar_draw() {
    var _l = bbox_left;
    var _r = bbox_right + 1;
    var _t = bbox_top;
    var _b = bbox_bottom + 1;
    var _base = (dim == 0) ? make_colour_rgb(22, 16, 30) : make_colour_rgb(10, 4, 8);
    var _hi   = (dim == 0) ? make_colour_rgb(96, 80, 130) : make_colour_rgb(140, 40, 40);
    draw_set_colour(_base);
    draw_rectangle(_l, _t + 1, _r, _b, false);
    // a rolling surface
    draw_set_colour(_hi);
    for (var xx = _l; xx < _r; xx += 2) {
        var _w = round(sin((xx + global.frame * 0.7) * 0.35));
        draw_rectangle(xx, _t + _w, xx + 1, _t + _w, false);
    }
    // bubbles rising and popping
    var _n = max(1, (_r - _l) div 10);
    for (var i = 0; i < _n; i++) {
        var _cyc = (global.frame * 0.5 + i * 37) mod 60;
        var _bx = _l + 4 + ((i * 53) mod max(1, (_r - _l - 8)));
        var _by = _b - 2 - _cyc * (_b - _t - 3) / 60;
        draw_set_colour(_hi);
        draw_circle(_bx, _by, (_cyc < 52) ? 1 : 2, true);
    }
    draw_set_colour(c_white);
}

// ------------------------------------------------------------------ level furniture

function gate_draw() {
    var _c = global.theme[dim].accent;
    var _w = 16 * image_xscale;
    var _h = 16 * image_yscale;
    var _l = home_x;
    var _t = home_y;
    var _a = is_open ? 0.18 : 1;
    draw_set_alpha(_a);
    // iron frame and bars
    draw_set_colour(make_colour_rgb(30, 26, 38));
    draw_rectangle(_l, _t, _l + _w - 1, _t + _h - 1, false);
    draw_set_colour(make_colour_rgb(74, 66, 90));
    draw_rectangle(_l + 1, _t, _l + 3, _t + _h - 1, false);
    draw_rectangle(_l + _w - 4, _t, _l + _w - 2, _t + _h - 1, false);
    draw_rectangle(_l + 6, _t, _l + 9, _t + _h - 1, false);
    // rivets, glowing in the dimension's colour
    draw_set_colour(_c);
    for (var yy = _t + 4; yy < _t + _h - 2; yy += 16) {
        draw_rectangle(_l + 2, yy, _l + 2, yy, false);
        draw_rectangle(_l + _w - 3, yy, _l + _w - 3, yy, false);
        draw_rectangle(_l + 7, yy + 1, _l + 8, yy + 2, false);
    }
    draw_rectangle(_l, _t, _l + _w - 1, _t, false);
    draw_set_alpha(1);
    draw_set_colour(c_white);
}

function plate_draw() {
    var _on = pressed || latched;
    var _c = global.theme[dim].accent;
    var _dy = pressed ? 2 : 0;
    var _l = bbox_left;
    var _r = bbox_right + 1;
    var _t = bbox_top + _dy;
    // stone slab
    draw_set_colour(make_colour_rgb(58, 52, 66));
    draw_rectangle(_l, _t, _r - 1, bbox_bottom, false);
    draw_set_colour(make_colour_rgb(110, 102, 126));
    draw_rectangle(_l, _t, _r - 1, _t, false);
    // the rune on it lights up while pressed
    draw_set_colour(_on ? _c : merge_colour(_c, c_black, 0.65));
    draw_rectangle(_l + 5, _t + 1, _r - 6, _t + 1, false);
    if (_on) {
        gpu_set_blendmode(bm_add);
        draw_sprite_ext(spr_light, 0, (_l + _r) / 2, _t, 0.2, 0.1, 0, _c, 0.5);
        gpu_set_blendmode(bm_normal);
    }
    draw_set_colour(c_white);
}

function platform_draw() {
    var _spr = global.art[dim].plank;
    var _l = bbox_left;
    var _r = bbox_right + 1;
    if (!sprite_exists(_spr)) { draw_self(); return; }
    // three boards stacked (each 3 units tall), darker towards the underside, tiled one board per tile
    var _tints = [c_white, make_colour_rgb(205, 190, 190), make_colour_rgb(150, 136, 142)];
    for (var xx = _l; xx < _r; xx += 16) {
        for (var i = 0; i < 3; i++) {
            draw_sprite_ext(_spr, 0, xx, y + i * 3, ART_S, ART_S, 0, _tints[i], 1);
        }
    }
    // a lit edge on top so a moving platform reads as "alive"
    draw_set_colour(global.theme[dim].accent);
    draw_set_alpha(0.55);
    draw_rectangle(_l + 1, y, _r - 2, y, false);
    draw_set_alpha(1);
    draw_set_colour(c_white);
}

function box_draw() {
    var _spr = global.art[dim].crate;
    var _cx = (bbox_left + bbox_right + 1) / 2;
    if (sprite_exists(_spr)) draw_sprite_ext(_spr, 0, _cx, bbox_bottom + 1, ART_S, ART_S, 0, c_white, 1);
    else draw_self();
    box_glow_draw();
    // a lit rune in the corner shows the box has found its partner in the other world
    if (partner != noone) {
        draw_set_colour(global.theme[dim].accent);
        draw_rectangle(bbox_left + 2, bbox_top + 2, bbox_left + 3, bbox_top + 3, false);
        draw_set_colour(c_white);
    }
}

function exit_update() {
    var _cx = (bbox_left + bbox_right + 1) / 2;
    light_add(_cx, bbox_bottom - 12, 48 + 4 * sin(global.frame * 0.1), 1);
    // sparks curl up out of the portal
    if (irandom(7) == 0) {
        fx_emit(_cx + random_range(-8, 8), bbox_bottom - 2, random_range(-0.1, 0.1), random_range(-0.6, -0.25), irandom_range(30, 60),
                random_range(1, 2), global.theme[dim].accent, 0, true);
    }
}

function exit_draw() {
    var _spr = global.art[dim].portal;
    var _cx = (bbox_left + bbox_right + 1) / 2;
    var _c = global.theme[dim].accent;
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(spr_light, 0, _cx, bbox_bottom - 14, 0.9, 0.9, 0, _c, 0.28 + 0.05 * sin(global.frame * 0.1));
    gpu_set_blendmode(bm_normal);
    if (sprite_exists(_spr)) draw_sprite_ext(_spr, floor(global.frame * 0.2) mod 10, _cx, bbox_bottom + 1, ART_S, ART_S, 0, c_white, 1);
}

function lamp_update() {
    var _r = light_radius * (1 + 0.05 * sin(global.frame * 0.21 + x));
    light_add(x, y, _r, 1);
    if (irandom(10) == 0) {
        fx_emit(x + random_range(-2, 2), y - 6, random_range(-0.1, 0.1), random_range(-0.5, -0.25), irandom_range(25, 45),
                random_range(0.8, 1.4), global.theme[dim].accent, 0, true);
    }
}

function lamp_draw() {
    var _spr = global.art[dim].torch;
    var _f = (floor(global.frame * 0.2) + floor(x)) mod 6;
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(spr_light, 0, x, y, 0.4, 0.4, 0, global.theme[dim].accent, 0.28);
    gpu_set_blendmode(bm_normal);
    if (sprite_exists(_spr)) draw_sprite_ext(_spr, _f, x, y + 8, ART_S, ART_S, 0, c_white, 1);
}
