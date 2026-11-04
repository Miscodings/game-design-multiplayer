// scr_pool: the influenced hazard. A pool of water kills a player standing in it unless it is safe:
//   - drained: its signal_id is active (a plate somewhere drained it), or
//   - safe window: use_partner_x is on and the partner is standing in this pool's x range. The water
//     drains into the ground around the partner's x, leaving a walkable bed there.
// The pool sits in a pit with a bed of obj_solid under it, so a drained stretch is a safe path.
// The window follows the partner, so the two players have to walk across in step.

function pool_update() {
    drained = signal_is_active(signal_id, 1);

    if (use_partner_x != 0) {
        var _partner = player_partner(dim);
        if (instance_exists(_partner)) {
            if (_partner.grounded) {
                window_cx    = _partner.x;
                window_timer = POOL_GRACE;
            } else {
                window_timer = max(window_timer - 1, 0);
            }
        }
    }

    if (dim == 1 && !drained) light_add((bbox_left + bbox_right) / 2, bbox_top, (bbox_right - bbox_left) / 2 + 30, 0.55);

    var _p = instance_place(x, y, obj_player);
    if (_p != noone && !pool_is_safe_at(_p.x)) game_fail(FAIL.HAZARD, _p);
}

/// @desc Is a body at this x safe inside the pool right now?
function pool_is_safe_at(_px) {
    if (drained) return true;
    return window_timer > 0 && abs(_px - window_cx) <= safe_radius;
}

/// @desc One stretch of liquid. Water in the overworld, lava in the underworld; both have a rippling lit surface.
function pool_fill(_x1, _x2, _top, _bot, _surface) {
    if (_x2 <= _x1) return;
    var _lava = (dim == 1);
    var _body = _lava ? make_colour_rgb(214, 70, 28)  : make_colour_rgb(44, 112, 200);
    var _deep = _lava ? make_colour_rgb(150, 32, 24)  : make_colour_rgb(28, 78, 160);
    var _foam = _lava ? make_colour_rgb(255, 196, 90) : make_colour_rgb(176, 220, 255);
    draw_set_alpha(_lava ? 1 : 0.88);
    draw_set_colour(_body);
    draw_rectangle(_x1, _top, _x2, _bot, false);
    draw_set_colour(_deep);
    draw_rectangle(_x1, (_top + _bot) div 2 + 1, _x2, _bot, false);
    if (_surface) {
        draw_set_colour(_foam);
        for (var xx = _x1; xx <= _x2; xx += 2) {
            var _w = round(sin((xx + global.frame * 0.6) * 0.4));
            draw_rectangle(xx, _top + _w, min(xx + 1, _x2), _top + _w, false);
        }
    }
    draw_set_alpha(1);
}

function pool_draw() {
    var _l = bbox_left;
    var _r = bbox_right;
    var _t = bbox_top;
    var _b = bbox_bottom;
    if (drained) {
        pool_fill(_l, _r, _b - 1, _b, false);
    } else if (window_timer > 0) {
        var _a = clamp(window_cx - safe_radius, _l, _r);
        var _c = clamp(window_cx + safe_radius, _l, _r);
        if (_a > _l) pool_fill(_l, _a - 1, _t, _b, true);
        if (_c < _r) pool_fill(_c + 1, _r, _t, _b, true);
        pool_fill(_a, _c, _b - 1, _b, false);
    } else {
        pool_fill(_l, _r, _t, _b, true);
    }
    draw_set_colour(c_white);
}
