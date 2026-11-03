// Game controller. Exactly one per level room.
game_init();
input_init();
signals_init();
theme_init();
lights_init();
global.players = [noone, noone];
window_setup();
cameras_init();
