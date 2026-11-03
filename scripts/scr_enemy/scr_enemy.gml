// scr_enemy: the walker (dumb patrol, turns at walls and ledges) and how players react to enemies.

function walker_update() {
    // turn around at walls, and at ledges: no floor under the pixel just past the leading foot
    var _lead = (dir > 0) ? bbox_right + 1 : bbox_left - 1;
    var _wall = solid_at(x + dir, y);
    var _floor_ahead = collision_point(_lead, bbox_bottom + 1, obj_solid, false, true) != noone;
    if (grounded && (_wall || !_floor_ahead)) dir = -dir;
    image_xscale = dir;

    xspd = dir * walk_speed;
    yspd = min(yspd + grav, max_fall);
    move_collide();
    grounded = solid_at(x, y + 1);
}

/// @desc Called from the player's Step. Landing on a walker's head kills it and bounces the player;
/// touching it any other way is a shared fail.
function player_check_enemies() {
    var _e = instance_place(x, y, obj_walker);
    if (_e == noone) return;

    // a stomp: falling, and the feet were at or above the walker's head before this frame's move
    if (yspd > 0 && bbox_bottom - yspd <= _e.bbox_top + 6) {
        with (_e) instance_destroy();
        yspd = input.jump_held ? -jump_speed : -stomp_bounce;
        coyote_timer = 0;
    } else {
        game_fail(FAIL.ENEMY, id);
    }
}
