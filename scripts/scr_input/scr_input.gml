// scr_input: one input struct per player, polled once per frame from obj_game (Begin Step).
// Player 0: A / D to move, W or Space to jump, gamepad 0.
// Player 1: Left / Right to move, Up to jump, gamepad 1.
// Gamepads work alongside the keyboard, so a controller can drive either player.

function input_init() {
    global.input = [];
    for (var i = 0; i < 2; i++) {
        global.input[i] = { pad: i, left: false, right: false, jump_held: false, jump_pressed: false };
    }
}

function input_poll_all() {
    for (var i = 0; i < 2; i++) input_poll(i);
}

function input_poll(_pid) {
    var _in = global.input[_pid];
    var _left, _right, _jump_held, _jump_pressed;

    if (_pid == 0) {
        _left         = keyboard_check(ord("A"));
        _right        = keyboard_check(ord("D"));
        _jump_held    = keyboard_check(ord("W")) || keyboard_check(vk_space);
        _jump_pressed = keyboard_check_pressed(ord("W")) || keyboard_check_pressed(vk_space);
    } else {
        _left         = keyboard_check(vk_left);
        _right        = keyboard_check(vk_right);
        _jump_held    = keyboard_check(vk_up);
        _jump_pressed = keyboard_check_pressed(vk_up);
    }

    if (gamepad_is_connected(_in.pad)) {
        var _ax = gamepad_axis_value(_in.pad, gp_axislh);
        _left         = _left  || (_ax < -0.4) || gamepad_button_check(_in.pad, gp_padl);
        _right        = _right || (_ax > 0.4)  || gamepad_button_check(_in.pad, gp_padr);
        _jump_held    = _jump_held    || gamepad_button_check(_in.pad, gp_face1);
        _jump_pressed = _jump_pressed || gamepad_button_check_pressed(_in.pad, gp_face1);
    }

    _in.left = _left;
    _in.right = _right;
    _in.jump_held = _jump_held;
    _in.jump_pressed = _jump_pressed;
}
