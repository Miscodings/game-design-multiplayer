t++;

if (keyboard_check_pressed(ord("R"))) {
	room_restart();
	exit;
}
if (keyboard_check_pressed(vk_escape)) {
	game_end();
	exit;
}

if (!won) {
	var d1 = keyboard_check(ord("D")) - keyboard_check(ord("A"));
	var d2 = keyboard_check(vk_right) - keyboard_check(vk_left);

	// the lever lives in the shadow world: only player 2 can pull it, but the bridge appears for player 1
	if (keyboard_check_pressed(vk_down) && p2.grounded && abs(p2.x - lever_x) < 40) lever_on = !lever_on;

	// the plate lives in the light world: only player 1 can press it, but the door opens for player 2
	plate_down = rects_overlap(p1.x - p1.w / 2, p1.y - p1.h, p1.w, p1.h, plate.x, plate.y - 4, plate.w, plate.h + 4);
	// the door never closes on someone already inside it, but it only stays open for a body that is actually in the doorway
	door_open = plate_down || (door_open && rects_overlap(p2.x - p2.w / 2, p2.y - p2.h, p2.w, p2.h, door.x, door.y, door.w, door.h));

	// balance: horizontal gap only, so standing at different heights (like at the exit) costs nothing
	var gap = abs(p1.x - p2.x);
	var target = 1 - clamp((gap - BALANCE_SAFE) / (BALANCE_FAR - BALANCE_SAFE), 0, 1);
	if (target > balance) balance += min(0.012, target - balance);
	else balance -= min(0.008, balance - target);

	// together: both get a small boost. apart: whoever is ahead is slowed so the other can catch up
	var m1 = lerp(1, 1.15, balance);
	var m2 = m1;
	if (p1.x > p2.x) m1 = lerp(0.55, 1.15, balance);
	if (p2.x > p1.x) m2 = lerp(0.55, 1.15, balance);

	crate_update();
	actor_update(p1, d1, keyboard_check_pressed(ord("W")), m1);
	actor_update(p2, d2, keyboard_check_pressed(vk_up), m2);

	p1.at_exit = p1.grounded && abs(p1.x - exit_x) < 28;
	p2.at_exit = p2.grounded && abs(p2.x - exit_x) < 28;
	if (p1.at_exit && p2.at_exit) won = true;
}

lever_ang = lerp(lever_ang, lever_on ? 1 : -1, 0.25);

ghost_step(0, p2);
ghost_step(1, p1);

cam[0] = lerp(cam[0], clamp(p1.x - SCREEN_W / 2, 0, WORLD_W - SCREEN_W), 0.12);
cam[1] = lerp(cam[1], clamp(p2.x - SCREEN_W / 2, 0, WORLD_W - SCREEN_W), 0.12);
