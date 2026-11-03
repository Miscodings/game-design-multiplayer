// scr_platform: a solid (child of obj_solid) that slides to (home + travel) while its signal
// is active and back to home when it is not. It moves with solid_move_pixel(), so riders stay
// attached and anything it moves into is pushed, or crushed if it has nowhere to go.

function platform_update() {
    var _on = signal_is_active(signal_id, signal_needed);
    var _tx = home_x + (_on ? travel_x : 0);
    var _ty = home_y + (_on ? travel_y : 0);

    repeat (move_speed) {
        var _sx = sign(_tx - x);
        var _sy = sign(_ty - y);
        if (_sx == 0 && _sy == 0) break;
        if (_sx != 0) solid_move_pixel(_sx, 0);
        if (_sy != 0) solid_move_pixel(0, _sy);
    }
}
