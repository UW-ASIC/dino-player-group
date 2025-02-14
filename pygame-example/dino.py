import pygame

from pygame.locals import *

PIXEL_DIVISION = 4
ACCELERATION = 1
INITIAL_JUMP_VELOCITY = -7
FAST_DROP_VELOCITY = 6

pygame.init()
screen = pygame.display.set_mode((640, 240))
clock = pygame.time.Clock()
game_running = True

player_position = 0
player_velocity = 0

jumping = False
update_velocity = True
fast_drop = False

obstacle_position = 640

max_vel = 0
min_vel = 0
max_pos = 0
min_pos = 0

while game_running:


    for event in pygame.event.get():
        # Check for QUIT event
        if event.type == pygame.QUIT:
            game_running = False

    screen.fill(Color(0x22, 0x22, 0x22))
    for i in range(0, 480, PIXEL_DIVISION*2):
        strip = pygame.Rect(0, i, 640, PIXEL_DIVISION)
        screen.fill(Color(0x44, 0x44, 0x44), rect=strip)

    render_position = player_position
    player_height = 8
    if not jumping and fast_drop:
        player_position += 4
        player_height = 4

    player = pygame.Rect(160, 120 + player_position*PIXEL_DIVISION, 8*PIXEL_DIVISION, player_height*PIXEL_DIVISION)
    pygame.draw.rect(screen, "white", player)

    obstacle = pygame.Rect(obstacle_position, 120 + 2*PIXEL_DIVISION, 4*PIXEL_DIVISION, 6*PIXEL_DIVISION)
    pygame.draw.rect(screen, "red", obstacle)

    fast_drop = False
    keys = pygame.key.get_pressed()
    if keys[pygame.K_DOWN]:
        fast_drop = True
        player_velocity = 0
    elif keys[pygame.K_UP] or keys[pygame.K_SPACE]:
        if not jumping:
            player_velocity = INITIAL_JUMP_VELOCITY
            jumping = True

    if player_velocity > max_vel:
        max_vel = player_velocity
    if player_velocity < min_vel:
        min_vel = player_velocity
    if player_position > max_pos:
        max_pos = player_position
    if player_position < min_pos:
        min_pos = player_position

    if update_velocity:
        player_velocity += ACCELERATION
    update_velocity = True

    player_position += FAST_DROP_VELOCITY if fast_drop else player_velocity
    if player_position > 0:
        player_position = 0
        player_velocity = 0
        jumping = False

    obstacle_position -= PIXEL_DIVISION * 3
    if obstacle_position <= 0:
        obstacle_position = 640

    pygame.display.flip()

    clock.tick(20)

print("max vel: ", max_vel)
print("min vel: ", min_vel)
print("max pos: ", max_pos)
print("min pos: ", min_pos)
