// scr_signals: named channels that link emitters (plates) to receivers (gates, platforms).
//
// Double buffered: emitters write to sig_next, receivers read sig_now, and obj_game
// swaps them in End Step. Costs one frame of latency and removes any dependence on
// the order instances run their Step events in.
//
// Contract: only emitters call signal_emit(), only receivers call signal_is_active().
// An empty signal_id means "not wired" and is never active.

function signals_init() {
    global.sig_now  = {};
    global.sig_next = {};
}

function signal_emit(_id) {
    if (_id == "") return;
    global.sig_next[$ _id] = (global.sig_next[$ _id] ?? 0) + 1;
}

function signal_count(_id) {
    return global.sig_now[$ _id] ?? 0;
}

function signal_is_active(_id, _needed = 1) {
    if (_id == "") return false;
    return signal_count(_id) >= _needed;
}

/// @desc Call once per frame from obj_game (End Step).
function signals_swap() {
    global.sig_now  = global.sig_next;
    global.sig_next = {};
}
