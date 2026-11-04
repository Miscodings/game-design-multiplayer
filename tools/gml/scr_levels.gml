// scr_levels: level names, par times, scoring and the save file (best time and best score per level).
//
// Score = 100 per coin + 10 per second under par. Both players' coins count.

#macro COIN_SCORE    100
#macro TIME_SCORE    10

function level_index() {
    var _n = room_get_name(room);
    var _p = string_pos("rm_level_", _n);
    if (_p == 0) return 0;
    return real(string_delete(_n, 1, 9));
}

function level_count() {
    var _n = 0;
    while (room_exists(asset_get_index("rm_level_" + string(_n + 1)))) _n++;
    return _n;
}

/// @desc Name, par time in seconds and a one-line hint for the current level.
function level_meta(_i = level_index()) {
    switch (_i) {
        case 1: return { name: "First Steps",     par: 45,  hint: "Walk to your portals. Your partner's glow shows where they are." };
        case 2: return { name: "Hold the Line",   par: 60,  hint: "A plate in one world opens a gate in the other." };
        case 3: return { name: "Sticky Situation", par: 70, hint: "Tar kills. Slimes can be stomped." };
        case 4: return { name: "Heavy Lifting",   par: 75,  hint: "One box in each world. Push them together." };
        case 5: return { name: "Into the Dark",   par: 80,  hint: "Your partner is your lantern." };
        case 6: return { name: "Tide Turner",     par: 85,  hint: "Where one of you stands, the other is safe." };
        case 7: return { name: "Crossed Paths",   par: 100, hint: "Plates, platforms and a long way down." };
        case 8: return { name: "The Gauntlet",    par: 130, hint: "Everything you have learned." };
    }
    return { name: "Level " + string(_i), par: 90, hint: "" };
}

function save_open() { ini_open("save.ini"); }

/// @desc Records a finished level: score, time and coins. Returns true if the score is a new best.
function level_record(_time_s, _score) {
    var _sec = "level" + string(level_index());
    ini_open("save.ini");
    var _best_t = ini_read_real(_sec, "time", 99999);
    var _best_s = ini_read_real(_sec, "score", -1);
    var _new = _score > _best_s;
    if (_new) ini_write_real(_sec, "score", _score);
    if (_time_s < _best_t) ini_write_real(_sec, "time", _time_s);
    ini_close();
    return { new_best: _new, best_score: max(_best_s, _score), best_time: min(_best_t, _time_s) };
}

function level_best_text() {
    var _sec = "level" + string(level_index());
    ini_open("save.ini");
    var _s = ini_read_real(_sec, "score", -1);
    ini_close();
    return _s;
}
