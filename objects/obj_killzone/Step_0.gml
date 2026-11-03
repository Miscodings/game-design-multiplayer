if (!game_is_playing()) exit;
var _p = instance_place(x, y, obj_player);
if (_p != noone) game_fail(FAIL.HAZARD, _p);
