// scr_config: layout constants and enums. Change the layout here, not in the objects.

// Draws debug helpers (hazard zones, etc.)
#macro DEBUG        false

// Grid size in pixels
#macro TILE         16

// One view per dimension: dimension 0 on top, dimension 1 below. The window is 16:9 (1280 x 720),
// two ports of 1280 x 360 stacked, the same layout as the GameDesignMultiplayer project.
// VIEW_* are world pixels. PORT_* are window pixels (2x scale).
#macro VIEW_W       640
#macro VIEW_H       180
#macro PORT_W       1280
#macro PORT_H       360
#macro WIN_W        1280
#macro WIN_H        720

// Height of one dimension band in the room (the room is 2 * DIM_H tall), 12 tiles.
// The view is 12 pixels shorter than the band, so each camera shows the bottom of its band and the
// top 12 pixels (empty sky) are cropped. Keep levels free of anything important in that strip.
#macro DIM_H        192

// Frames after a fail before the "press Enter" prompt appears (and Enter starts working)
#macro FAIL_DELAY   50

// Frames the dead player's red highlight takes to settle from its strong flash to its steady tint
#macro FAIL_FLASH   36

enum GAME_STATE { PLAYING, FAILED, CLEARED }
enum FAIL { NONE, HAZARD, ENEMY, FALL, CRUSH }

// Radius of the small glow around each player, so they can always see themselves in the dark
#macro PLAYER_GLOW  20

// Radius of the light your partner's echo casts in your dimension
#macro ECHO_RADIUS  56

// Most presence particles one echo keeps alive
#macro ECHO_MOTES   150

// Frames a pool's safe window lingers after the partner leaves the ground
#macro POOL_GRACE   10

// Pixels per frame a linked box pair moves. A player pushing a box is held to this speed.
#macro PUSH_SPEED   1

enum ACTIVATOR { PLAYER, BOX, ANY }
