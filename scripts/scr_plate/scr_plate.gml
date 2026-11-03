// scr_plate: pressure plate. Emits its signal while pressed.
// activator picks what presses it: ACTIVATOR.PLAYER (a grounded player standing on it),
// ACTIVATOR.BOX (a box resting on it) or ACTIVATOR.ANY. With latch set, it keeps emitting once pressed.

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
    if (pressed || latched) signal_emit(signal_id);
}
