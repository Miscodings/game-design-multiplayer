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

    var _p = instance_place(x, y, obj_player);
    if (_p != noone && !pool_is_safe_at(_p.x)) game_fail(FAIL.HAZARD, _p);
}

/// @desc Is a body at this x safe inside the pool right now?
function pool_is_safe_at(_px) {
    if (drained) return true;
    return window_timer > 0 && abs(_px - window_cx) <= safe_radius;
}

function pool_draw() {
    var _l = bbox_left;
    var _r = bbox_right;
    var _t = bbox_top;
    var _b = bbox_bottom;
    var _water = make_colour_rgb(56, 124, 214);
    var _foam  = make_colour_rgb(170, 210, 250);

    draw_set_alpha(0.8);
    draw_set_colour(_water);
    if (drained) {
        draw_rectangle(_l, _b - 2, _r, _b, false);
    } else if (window_timer > 0) {
        var _a = clamp(window_cx - safe_radius, _l, _r);
        var _c = clamp(window_cx + safe_radius, _l, _r);
        if (_a > _l) draw_rectangle(_l, _t, _a - 1, _b, false);
        if (_c < _r) draw_rectangle(_c + 1, _t, _r, _b, false);
        draw_rectangle(_a, _b - 2, _c, _b, false);
        draw_set_colour(_foam);
        if (_a > _l) draw_rectangle(_l, _t, _a - 1, _t, false);
        if (_c < _r) draw_rectangle(_c + 1, _t, _r, _t, false);
    } else {
        draw_rectangle(_l, _t, _r, _b, false);
        draw_set_colour(_foam);
        draw_rectangle(_l, _t, _r, _t, false);
    }
    draw_set_alpha(1);
    draw_set_colour(c_white);
}
