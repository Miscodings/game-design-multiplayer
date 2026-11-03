// scr_player_move: horizontal control, gravity, jump (with coyote time, jump buffering and
// variable height), then pixel-accurate collision. Called from obj_player's Step.

function player_move() {
    var _dir = (input.right ? 1 : 0) - (input.left ? 1 : 0);

    // horizontal: brake first when reversing so turning feels snappy
    if (_dir != 0) {
        if (sign(xspd) == -_dir) xspd = approach(xspd, 0, decel);
        xspd = clamp(xspd + _dir * accel, -max_speed, max_speed);
        face = _dir;
        image_xscale = face;
    } else {
        xspd = approach(xspd, 0, decel);
    }

    // pushing a box holds you to the box's speed so you stay in contact with it
    if (push_timer > 0) {
        xspd = clamp(xspd, -PUSH_SPEED, PUSH_SPEED);
        push_timer--;
    }

    // ground state, coyote time and jump buffer
    grounded = solid_at(x, y + 1);
    coyote_timer      = grounded ? coyote_frames : max(coyote_timer - 1, 0);
    jump_buffer_timer = input.jump_pressed ? jump_buffer_frames : max(jump_buffer_timer - 1, 0);

    // gravity
    yspd = min(yspd + grav, max_fall);

    // jump
    if (jump_buffer_timer > 0 && coyote_timer > 0) {
        yspd = -jump_speed;
        coyote_timer = 0;
        jump_buffer_timer = 0;
    }

    // letting go of jump early cuts the jump short
    if (!input.jump_held && yspd < -jump_cut) yspd = -jump_cut;

    move_collide();
    grounded = solid_at(x, y + 1);
}

/// @desc Called by a box that this player is pushing. Lasts a few frames so contact flicker doesn't matter.
function player_mark_pushing() {
    push_timer = 3;
}
