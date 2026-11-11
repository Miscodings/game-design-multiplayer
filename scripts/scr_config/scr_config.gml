// scr_config: layout constants and enums. Change the layout here, not in the objects.

// Draws debug helpers (hazard zones, etc.)
#macro DEBUG        false
// Dev aid: number keys jump between levels (1-9 = levels 1-9, 0 = level 10, hold Shift to add 10). Set false before shipping.
#macro LEVEL_JUMP_KEYS true

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

// Height of one dimension band. The room is 2 * DIM_H tall, so every level picks its own band height.
// 192 (12 tiles) is the original size: the camera stays locked to the bottom of the band (the top 12 px are cropped).
// Anything taller scrolls vertically (see camera_y_for in scr_view).
#macro DIM_H        (room_height div 2)

// Vertical camera (levels taller than the view): where on the view the player's feet sit (0 = top, 1 = bottom),
// how far the player can move before the view follows (pixels), and the fastest the view moves (pixels per frame).
#macro CAM_FOCUS     0.6
#macro CAM_DEADZONE  20
#macro CAM_MAX_STEP  7

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
#macro POOL_GRACE   36   // frames the partner window survives after the partner leaves the ground (36 covers a 3-tile gap jump)

// Pixels per frame a linked box pair moves. A player pushing a box is held to this speed.
#macro PUSH_SPEED   1

enum ACTIVATOR { PLAYER, BOX, ANY }
