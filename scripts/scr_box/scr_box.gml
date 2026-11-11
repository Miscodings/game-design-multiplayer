// scr_box: linked pushable boxes. One box exists in each dimension and the pair shares a link_id.
// Neither moves unless BOTH players push their own box, from the same side, at the same time.
// The pair then moves together, and only if neither is blocked.

/// @desc Pairs each box with the box of the same link_id in the other dimension. Called at Room Start.
function boxes_link() {
    with (obj_box) {
        partner = noone;
        var _me = id;
        if (link_id != "") {
            with (obj_box) {
                if (id != _me && link_id == _me.link_id && dim != _me.dim) _me.partner = id;
            }
        }
    }
}

/// @desc -1 / 0 / 1: the direction this box's player is pushing it. They must be beside it, holding toward it.
function box_push_dir() {
    var _p = global.players[dim];
    if (!instance_exists(_p)) return 0;

    var _dir = (_p.input.right ? 1 : 0) - (_p.input.left ? 1 : 0);
    if (_dir == 0) return 0;

    var _self = id;
    var _centre = (bbox_left + bbox_right) / 2;
    var _beside = false;
    with (_p) {
        _beside = !place_meeting(x, y, _self)
               && place_meeting(x + _dir * 2, y, _self)
               && (_centre - x) * _dir > 0;
        if (_beside) player_mark_pushing();
    }
    return _beside ? _dir : 0;
}

/// @desc Run by the coordinator (the lower id of the pair): moves both boxes if both are being pushed the same way.
function box_pair_update() {
    var _a = box_push_dir();
    var _b = 0;
    with (partner) _b = box_push_dir();

    // remembered for drawing (the feedback glow)
    push_dir = _a;
    with (partner) push_dir = _b;

    if (_a == 0 || _a != _b) return;

    repeat (PUSH_SPEED) {
        var _free_a = !solid_at(x + _a, y);
        var _free_b = false;
        with (partner) _free_b = !solid_at(x + _a, y);
        if (!_free_a || !_free_b) break;
        solid_move_pixel(_a, 0);
        with (partner) solid_move_pixel(_a, 0);
    }
}

function box_update() {
    // safety net: a crate wedged inside a solid (a gate closing on it, a bad placement) is lifted out if it can be
    if (solid_at(x, y)) {
        var _y0 = y;
        var _n = 0;
        while (solid_at(x, y) && _n < 16) { y -= 1; _n++; }
        if (solid_at(x, y)) y = _y0;
        yspd = 0;
    }

    // gravity only: sideways motion comes from the pair push
    yspd = min(yspd + grav, max_fall);
    move_collide();

    if (partner != noone && instance_exists(partner)) {
        if (id < partner.id) box_pair_update();
    } else {
        push_dir = 0;
    }
}

/// @desc Visual feedback that a box needs both players. While the partner's player is pushing THEIR box and
/// this one isn't being pushed the same way, a faint glow pulses on this box's matching side, in the pusher's
/// colour: "push here too". It disappears once both push and the pair moves.
function box_glow_draw() {
    if (partner == noone || !instance_exists(partner)) return;
    var _dir = partner.push_dir;
    if (_dir == 0 || push_dir == _dir) return;

    var _col = global.theme[partner.dim].accent;
    var _a   = 0.28 + 0.12 * sin(current_time * 0.008);

    // the side the partner is pushing from: left edge when pushing right, right edge when pushing left
    var _edge = (_dir > 0) ? bbox_left : bbox_right + 1;
    var _out  = _edge - _dir * 14;

    // soft glow fading outward from the edge
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex_colour(_edge, bbox_top,        _col, _a);
    draw_vertex_colour(_out,  bbox_top,        _col, 0);
    draw_vertex_colour(_edge, bbox_bottom + 1, _col, _a);
    draw_vertex_colour(_out,  bbox_bottom + 1, _col, 0);
    draw_primitive_end();

    // and a thin lit line along the box's own edge
    draw_set_colour(_col);
    draw_set_alpha(_a + 0.15);
    if (_dir > 0) draw_rectangle(bbox_left, bbox_top, bbox_left + 1, bbox_bottom, false);
    else          draw_rectangle(bbox_right - 1, bbox_top, bbox_right, bbox_bottom, false);
    draw_set_alpha(1);
    draw_set_colour(c_white);
}
