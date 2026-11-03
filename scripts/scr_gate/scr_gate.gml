// scr_gate: a solid (child of obj_solid) that opens when its signal is active.
// signal_needed is how many emitters must be active (2 = both players' plates).
// inverted flips it: open by default, closed while the signal is active.
//
// An open gate is "parked" far above the room so every collision query ignores it.
// It draws itself at home_y regardless.

#macro GATE_PARK -100000

function gate_update() {
    var _want_open = signal_is_active(signal_id, signal_needed) != (inverted != 0);
    if (_want_open == is_open) return;

    if (_want_open) {
        is_open = true;
        y = home_y + GATE_PARK;
    } else {
        // never close on top of a player: test from the home position first
        var _parked_y = y;
        y = home_y;
        if (place_meeting(x, y, obj_player)) y = _parked_y;
        else is_open = false;
    }
}
