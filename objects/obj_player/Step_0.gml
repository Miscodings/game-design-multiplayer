player_emit_light();
if (!game_is_playing()) exit;
player_move();
player_check_bounds();
player_check_enemies();
