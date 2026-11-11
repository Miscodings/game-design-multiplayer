// scr_plate: pressure plate. Emits its signal while pressed.
// activator picks what presses it: ACTIVATOR.PLAYER (a grounded player standing on it),
// ACTIVATOR.BOX (a box resting on it) or ACTIVATOR.ANY. With latch set, it keeps emitting once pressed.
// With pulse set (frames), it keeps emitting for that long after it is released (60 frames = 1 second).

function plate_update() {
    var _on = false;

    if (activator != ACTIVATOR.BOX) {
        var _p = instance_place(x, y, obj_player);
        if (_p != noone && _p.grounded) _on = true;
    }
    if (activator != ACTIVATOR.PLAYER && !_on) {
        if (place_meeting(x, y, obj_box)) _on = true;
    }

    pressed = _on;
    if (pressed && latch != 0) latched = true;

    if (pressed) pulse_timer = pulse;
    else if (pulse_timer > 0) pulse_timer--;

    if (pressed || latched) {
        signal_emit(signal_id);
    } else if (pulse_timer > 0) {
        signal_emit(signal_id);
        signal_note_left(signal_id, pulse_timer);
    }
}
