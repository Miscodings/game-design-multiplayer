t++;
if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) room_goto(rm_level_1);
if (keyboard_check_pressed(vk_escape)) game_end();
// dev aid: number keys jump between levels (LEVEL_JUMP_KEYS in scr_config)
debug_level_jump();
