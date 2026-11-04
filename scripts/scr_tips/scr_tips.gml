// scr_tips: instructions floating in the world, in the style of the FirePlatformer tips: animated keycaps on a dark
// plate that fade in as the player of that dimension walks up to them. Drawn in GUI space (crisp text) at the
// on-screen position of an obj_tip. Each tip shows ITS OWN player's keys: WASD / Space above, arrow keys below.
//
// obj_tip has one property, kind. Kinds: move, jump, hold, stomp, plate, box, partner, coin, exit, tar, water, dark.

#macro TIP_NEAR  70
#macro TIP_FAR   140

/// @desc Tips teach each thing once: a tip that was shown in an earlier level stays hidden in later ones. The key is
/// the tip's kind plus the world it is in; the value is the level it was first read in (so restarting that level,
/// or coming back to it, still shows it).
function tip_seen_elsewhere(_kind, _dim) {
    if (!variable_global_exists("tips_seen")) global.tips_seen = {};
    var _key = _kind + string(_dim);
    return variable_struct_exists(global.tips_seen, _key) && global.tips_seen[$ _key] != level_index();
}

function tips_draw_gui() {
    if (!variable_global_exists("tips_seen")) global.tips_seen = {};
    with (obj_tip) {
        if (tip_seen_elsewhere(kind, dim)) continue;
        var _p = global.players[dim];
        if (!instance_exists(_p)) continue;
        var _d = point_distance(_p.x, _p.y - 12, x, y);
        var _alpha = clamp((TIP_FAR - _d) / (TIP_FAR - TIP_NEAR), 0, 1);
        if (_alpha > 0.6) {
            var _key = kind + string(dim);
            if (!variable_struct_exists(global.tips_seen, _key)) global.tips_seen[$ _key] = level_index();
        }
        if (global.game_state != GAME_STATE.PLAYING) _alpha *= 0.4;
        if (_alpha <= 0.01) continue;

        var _cam = global.cams[dim];
        // whole pixels, so the text and keycaps stay crisp
        var _sx = floor((x - camera_get_view_x(_cam)) * (PORT_W / VIEW_W));
        var _sy = floor(dim * PORT_H + (y - camera_get_view_y(_cam)) * (PORT_H / VIEW_H) + sin(global.frame * 0.05) * 3);
        if (_sx < -200 || _sx > PORT_W + 200) continue;
        draw_set_alpha(_alpha);
        tip_draw(kind, _sx, _sy, dim);
    }
    draw_set_alpha(1);
    draw_set_colour(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// ------------------------------------------------------------------ pieces

function tip_plate(_x, _y, _w, _h, _dim) {
    var _a = draw_get_alpha();
    draw_set_colour(c_black);
    draw_set_alpha(_a * 0.62);
    draw_roundrect_ext(_x - _w / 2, _y - _h / 2, _x + _w / 2, _y + _h / 2, 18, 18, false);
    draw_set_alpha(_a * 0.8);
    draw_set_colour(global.theme[_dim].accent);
    draw_roundrect_ext(_x - _w / 2, _y - _h / 2, _x + _w / 2, _y + _h / 2, 18, 18, true);
    draw_set_alpha(_a);
}

/// @desc A keycap. A pressed key sinks and lights up. _label "<" ">" "^" "v" draw an arrow.
function tip_key(_x, _y, _label, _w = 34, _pressed = false, _dim = 0) {
    var _a = draw_get_alpha();
    var _h = 32;
    var _dy = _pressed ? 3 : 0;
    var _l = _x - _w / 2;
    var _t = _y - _h / 2;
    var _acc = global.theme[_dim].accent;
    draw_set_colour(make_colour_rgb(8, 6, 14));
    draw_set_alpha(_a * 0.7);
    draw_roundrect_ext(_l, _t + 5, _l + _w, _t + _h + 5, 8, 8, false);
    draw_set_alpha(_a);
    draw_set_colour(_pressed ? _acc : make_colour_rgb(48, 50, 72));
    draw_roundrect_ext(_l, _t + _dy, _l + _w, _t + _h + _dy, 8, 8, false);
    draw_set_colour(_pressed ? c_white : make_colour_rgb(210, 218, 245));
    draw_roundrect_ext(_l, _t + _dy, _l + _w, _t + _h + _dy, 8, 8, true);
    draw_set_colour(_pressed ? make_colour_rgb(50, 30, 20) : c_white);
    var _cx = _x;
    var _cy = _y + _dy;
    if (_label == "<")      draw_triangle(_cx + 6, _cy - 8, _cx + 6, _cy + 8, _cx - 8, _cy, false);
    else if (_label == ">") draw_triangle(_cx - 6, _cy - 8, _cx - 6, _cy + 8, _cx + 8, _cy, false);
    else if (_label == "^") draw_triangle(_cx - 8, _cy + 6, _cx + 8, _cy + 6, _cx, _cy - 8, false);
    else if (_label == "v") draw_triangle(_cx - 8, _cy - 6, _cx + 8, _cy - 6, _cx, _cy + 8, false);
    else if (_label != "") {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        ui_text(_cx, _cy, _label);
    }
    draw_set_colour(c_white);
}

function tip_text(_x, _y, _str, _dim) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(make_colour_rgb(10, 8, 16));
    ui_text(_x + 1, _y + 1, _str);
    draw_set_colour(_dim == 0 ? make_colour_rgb(255, 236, 190) : make_colour_rgb(255, 190, 170));
    ui_text(_x, _y, _str);
    draw_set_colour(c_white);
}

/// @desc The keys of this dimension's player: [left, right, jump label].
function tip_keys(_dim) {
    return (_dim == 0) ? ["A", "D", "SPACE"] : ["<", ">", "^"];
}

// ------------------------------------------------------------------ the tips

/// @desc Width in GUI pixels of a line of tip text .
function tip_width(_str) {
    return ui_text_w(_str);
}

/// @desc A plate sized to fit its lines of text, with the lines drawn on it. _min_w / _extra_h leave room for keycaps above.
function tip_lines(_x, _y, _lines, _dim, _min_w = 0, _extra_h = 0) {
    var _n = array_length(_lines);
    var _w = _min_w;
    for (var i = 0; i < _n; i++) _w = max(_w, tip_width(_lines[i]) + 44);
    var _h = 38 + 18 * _n + _extra_h;
    tip_plate(_x, _y, _w, _h, _dim);
    // text block sits at the bottom of the plate
    var _area = 38 + 18 * _n;                    // the part of the plate the text uses (keycaps take the rest, above)
    var _mid = _y + _h / 2 - _area / 2;          // centre of the text block
    for (var i = 0; i < _n; i++) tip_text(_x, _mid + (i - (_n - 1) / 2) * 18 - 1, _lines[i], _dim);
}

function tip_draw(_kind, _x, _y, _dim) {
    var _t = global.frame / 60;
    var _k = tip_keys(_dim);
    var _jw = (_dim == 0) ? 84 : 34;

    switch (_kind) {
        case "move":
            tip_lines(_x, _y + 0, ["Move and jump"], _dim, 240, 44);
            var _p = _t mod 2.6;
            tip_key(_x - 80, _y - 26, _k[0], 36, _p > 1.5 && _p < 2.0, _dim);
            tip_key(_x - 38, _y - 26, _k[1], 36, _p > 0.1 && _p < 1.1, _dim);
            tip_key(_x + 36, _y - 26, _k[2], _jw, _p > 1.2 && _p < 1.45, _dim);
            break;

        case "jump":
            tip_lines(_x, _y, ["Hold jump to go higher"], _dim, 170, 44);
            var _q = _t mod 2.0;
            tip_key(_x, _y - 26, _k[2], _jw, _q < 0.5, _dim);
            break;

        case "stomp":   tip_lines(_x, _y, ["Stomp enemies from above"], _dim); break;
        case "plate":   tip_lines(_x, _y, ["Stand on the plate"], _dim); break;
        case "box":     tip_lines(_x, _y, ["Both players push the box", "from the same side"], _dim); break;
        case "partner": tip_lines(_x, _y, ["Your partner lights", "the way in the dark"], _dim); break;
        case "gate":    tip_lines(_x, _y, ["A plate in the other world", "opens this gate"], _dim); break;
        case "coin":    tip_lines(_x, _y, ["Coins add to your score"], _dim); break;
        case "exit":    tip_lines(_x, _y, ["Both players reach", "their portal"], _dim); break;
        case "tar":     tip_lines(_x, _y, ["Tar is deadly"], _dim); break;
        case "water":   tip_lines(_x, _y, ["Your partner standing here", "makes the way safe"], _dim); break;
        case "shared":  tip_lines(_x, _y, ["If one falls,", "you both fall"], _dim); break;
    }
}
