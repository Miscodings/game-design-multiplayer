// Begin Step: forget last frame's lights, read both players' input, then global keys.
lights_clear();
deco_lights();
input_poll_all();
if (keyboard_check_pressed(ord("R"))) { cp_reset(); room_restart(); }
if (keyboard_check_pressed(vk_escape)) game_end();

// dev aid: number keys jump between levels (see debug_level_jump in scr_levels; LEVEL_JUMP_KEYS in scr_config)
debug_level_jump();
