// Begin Step: forget last frame's lights, read both players' input, then global keys.
lights_clear();
deco_lights();
input_poll_all();
if (keyboard_check_pressed(ord("R"))) room_restart();
if (keyboard_check_pressed(vk_escape)) game_end();

// debug: jump straight to a level with the number keys
if (DEBUG) {
    for (var i = 1; i <= 8; i++) {
        if (keyboard_check_pressed(ord(string(i)))) {
            var _rm = asset_get_index("rm_level_" + string(i));
            if (room_exists(_rm)) room_goto(_rm);
        }
    }
}
