// scr_tips: instructions floating in the world, in the style of the FirePlatformer tips: animated keycaps on a dark
// plate that fade in as the player of that dimension walks up to them. Drawn in GUI space (crisp text) at the
// on-screen position of an obj_tip. Each tip shows ITS OWN player's keys: WASD / Space above, arrow keys below.
//
// obj_tip has one property, kind. Kinds: move, jump, hold, stomp, plate, box, partner, coin, exit, tar, water, dark.

#macro TIP_NEAR  110
#macro TIP_FAR   200

function tips_draw_gui() {
    with (obj_tip) {
        var _p = global.players[dim];
        if (!instance_exists(_p)) continue;
        var _d = point_distance(_p.x, _p.y - 12, x, y);
        var _alpha = clamp((TIP_FAR - _d) / (TIP_FAR - TIP_NEAR), 0, 1);
        if (global.game_state != GAME_STATE.PLAYING) _alpha *= 0.4;
        if (_alpha <= 0.01) continue;

        var _cam = global.cams[dim];
        var _sx = (x - camera_get_view_x(_cam)) * (PORT_W / VIEW_W);
        var _sy = dim * PORT_H + (y - camera_get_view_y(_cam)) * (PORT_H / VIEW_H) + sin(global.frame * 0.05) * 3;
        if (_sx < -200 || _sx > PORT_W + 200) continue;
        draw_set_alpha(_alpha);
        tip_draw(kind, _sx, _sy, dim);
    }
    draw_set_alpha(1);
    draw_set_colour(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(-1);
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

function tip_draw(_kind, _x, _y, _dim) {
    var _t = global.frame / 60;
    var _k = tip_keys(_dim);
    var _jw = (_dim == 0) ? 84 : 34;

    switch (_kind) {
        case "move":
            tip_plate(_x, _y, 230, 84, _dim);
            var _p = _t mod 2.6;
            tip_key(_x - 80, _y - 8, _k[0], 36, _p > 1.5 && _p < 2.0, _dim);
            tip_key(_x - 38, _y - 8, _k[1], 36, _p > 0.1 && _p < 1.1, _dim);
            tip_key(_x + 36, _y - 8, _k[2], _jw, _p > 1.2 && _p < 1.45, _dim);
            tip_text(_x, _y + 24, "move  and  jump", _dim);
            break;

        case "jump":
            tip_plate(_x, _y, 170, 84, _dim);
            var _q = _t mod 2.0;
            tip_key(_x, _y - 8, _k[2], _jw, _q < 0.5, _dim);
            tip_text(_x, _y + 24, "hold  for  a  higher  jump", _dim);
            break;

        case "stomp":
            tip_plate(_x, _y, 230, 56, _dim);
            tip_text(_x, _y, "jump  on  its  head", _dim);
            break;

        case "plate":
            tip_plate(_x, _y, 250, 56, _dim);
            tip_text(_x, _y, "stand  on  the  plate", _dim);
            break;

        case "box":
            tip_plate(_x, _y, 290, 74, _dim);
            tip_text(_x, _y - 12, "both  players  push  the  box", _dim);
            tip_text(_x, _y + 14, "from  the  same  side", _dim);
            break;

        case "partner":
            tip_plate(_x, _y, 290, 74, _dim);
            tip_text(_x, _y - 12, "your  partner  lights", _dim);
            tip_text(_x, _y + 14, "your  way  in  the  dark", _dim);
            break;

        case "gate":
            tip_plate(_x, _y, 300, 74, _dim);
            tip_text(_x, _y - 12, "a  plate  in  the  other  world", _dim);
            tip_text(_x, _y + 14, "opens  this  gate", _dim);
            break;

        case "coin":
            tip_plate(_x, _y, 190, 56, _dim);
            tip_text(_x, _y, "coins  count  for  score", _dim);
            break;

        case "exit":
            tip_plate(_x, _y, 260, 74, _dim);
            tip_text(_x, _y - 12, "both  players  reach", _dim);
            tip_text(_x, _y + 14, "their  portal", _dim);
            break;

        case "tar":
            tip_plate(_x, _y, 190, 56, _dim);
            tip_text(_x, _y, "tar  is  deadly", _dim);
            break;

        case "water":
            tip_plate(_x, _y, 310, 74, _dim);
            tip_text(_x, _y - 12, "your  partner  standing  here", _dim);
            tip_text(_x, _y + 14, "makes  the  way  safe", _dim);
            break;

        case "shared":
            tip_plate(_x, _y, 280, 74, _dim);
            tip_text(_x, _y - 12, "if  one  falls", _dim);
            tip_text(_x, _y + 14, "you  both  fall", _dim);
            break;
    }
}
