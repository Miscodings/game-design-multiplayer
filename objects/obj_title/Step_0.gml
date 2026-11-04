t++;
if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) room_goto(rm_level_1);
if (keyboard_check_pressed(vk_escape)) game_end();
// jump straight to a level while testing: hold Shift and press 1-8
if (keyboard_check(vk_shift)) {
    for (var i = 1; i <= 8; i++) {
        if (keyboard_check_pressed(ord(string(i)))) {
            var _rm = asset_get_index("rm_level_" + string(i));
            if (room_exists(_rm)) room_goto(_rm);
        }
    }
}
