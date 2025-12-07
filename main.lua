io.stdout:setvbuf("no")

if arg[#arg] == "-debug" then
    require("mobdebug").start()
end

-- Constants
local WINDOW_WIDTH = 800
local WINDOW_HEIGHT = 600
local GRAVITY = 50
local THRUST_POWER = 200
local ROTATION_SPEED = 100
local MAX_SAFE_VELOCITY = 50
local MAX_SAFE_ANGLE = 15
local GROUND_HEIGHT = 50
local LANDING_PAD_WIDTH = 100
local INITIAL_FUEL = 1000
local FUEL_CONSUMPTION_RATE = 100
local STAR_COUNT = 100
local HUD_FONT_SIZE = 14
local MESSAGE_FONT_SIZE = 32
local SUBTITLE_FONT_SIZE = 16
local LANDING_PAD_HEIGHT = 5
local FLAME_BASE_SIZE = 10
local FLAME_VARIANCE = 5

-- Game state
local game_state = {
    current = "playing",
    stars = {}
}

-- Lander entity
local lander = {
    x = 400,
    y = 50,
    velocity_x = 0,
    velocity_y = 0,
    fuel = INITIAL_FUEL,
    angle = 0,
    thrust = 0,
    width = 20,
    height = 40
}

-- Landing pad entity
local landing_pad = {
    x = 0,
    y = 0,
    width = LANDING_PAD_WIDTH
}

-- Initialize stars for background
local function initialize_stars()
    for i = 1, STAR_COUNT do
        game_state.stars[i] = {
            x = math.random(0, WINDOW_WIDTH),
            y = math.random(0, WINDOW_HEIGHT),
            size = math.random(1, 2)
        }
    end
end

-- Reset lander to starting position
local function reset_lander()
    lander.x = math.random(100, WINDOW_WIDTH - 100)
    lander.y = 50
    lander.velocity_x = 0
    lander.velocity_y = 0
    lander.fuel = INITIAL_FUEL
    lander.angle = 0
    lander.thrust = 0
end

-- Initialize landing pad position
local function initialize_landing_pad()
    landing_pad.x = math.random(100, WINDOW_WIDTH - LANDING_PAD_WIDTH - 100)
    landing_pad.y = WINDOW_HEIGHT - GROUND_HEIGHT
end

-- Handle game restart
local function handle_restart()
    if love.keyboard.isDown("r") then
        game_state.current = "playing"
        reset_lander()
        initialize_landing_pad()
    end
end

-- Update lander rotation
local function update_rotation(dt)
    if love.keyboard.isDown("left") then
        lander.angle = lander.angle - ROTATION_SPEED * dt
    end
    if love.keyboard.isDown("right") then
        lander.angle = lander.angle + ROTATION_SPEED * dt
    end
end

-- Update lander thrust
local function update_thrust(dt)
    local is_thrusting = love.keyboard.isDown("up") and lander.fuel > 0
    
    if is_thrusting then
        local angle_radians = math.rad(lander.angle)
        lander.velocity_x = lander.velocity_x + math.sin(angle_radians) * THRUST_POWER * dt
        lander.velocity_y = lander.velocity_y - math.cos(angle_radians) * THRUST_POWER * dt
        lander.thrust = THRUST_POWER
        lander.fuel = math.max(0, lander.fuel - FUEL_CONSUMPTION_RATE * dt)
    else
        lander.thrust = 0
    end
end

-- Update lander position
local function update_position(dt)
    lander.velocity_y = lander.velocity_y + GRAVITY * dt
    lander.x = lander.x + lander.velocity_x * dt
    lander.y = lander.y + lander.velocity_y * dt
end

-- Constrain lander to screen boundaries
local function constrain_to_screen()
    lander.x = math.max(0, math.min(WINDOW_WIDTH - lander.width, lander.x))
    
    if lander.y < 0 then
        lander.y = 0
        lander.velocity_y = 0
    end
end

-- Calculate current speed
local function calculate_speed()
    return math.sqrt(lander.velocity_x * lander.velocity_x + lander.velocity_y * lander.velocity_y)
end

-- Check if lander is on landing pad
local function is_on_landing_pad()
    local lander_center_x = lander.x + lander.width / 2
    local pad_left = landing_pad.x
    local pad_right = landing_pad.x + landing_pad.width
    return lander_center_x >= pad_left and lander_center_x <= pad_right
end

-- Check if landing is safe
local function is_safe_landing()
    local speed = calculate_speed()
    local angle = math.abs(lander.angle)
    return speed <= MAX_SAFE_VELOCITY and angle <= MAX_SAFE_ANGLE
end

-- Handle landing collision
local function handle_landing()
    local lander_bottom = lander.y + lander.height
    
    if lander_bottom >= landing_pad.y then
        if is_on_landing_pad() then
            if is_safe_landing() then
                game_state.current = "won"
            else
                game_state.current = "lost"
            end
        else
            game_state.current = "lost"
        end
        
        lander.y = landing_pad.y - lander.height
        lander.velocity_y = 0
        lander.velocity_x = 0
    end
end

-- Draw background
local function draw_background()
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    
    love.graphics.setColor(1, 1, 1)
    for _, star in ipairs(game_state.stars) do
        love.graphics.circle("fill", star.x, star.y, star.size)
    end
end

-- Draw ground and landing pad
local function draw_ground()
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", 0, WINDOW_HEIGHT - GROUND_HEIGHT, WINDOW_WIDTH, GROUND_HEIGHT)
    
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", landing_pad.x, landing_pad.y, landing_pad.width, LANDING_PAD_HEIGHT)
    love.graphics.setColor(0, 0.7, 0)
    love.graphics.rectangle("line", landing_pad.x, landing_pad.y, landing_pad.width, LANDING_PAD_HEIGHT)
end

-- Draw lander
local function draw_lander()
    love.graphics.push()
    love.graphics.translate(lander.x + lander.width / 2, lander.y + lander.height / 2)
    love.graphics.rotate(math.rad(lander.angle))
    
    love.graphics.setColor(0.8, 0.8, 0.8)
    local points = {
        -lander.width / 2, -lander.height / 2,
        lander.width / 2, -lander.height / 2,
        0, lander.height / 2
    }
    love.graphics.polygon("fill", points)
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("line", points)
    
    if lander.thrust > 0 and lander.fuel > 0 then
        local flame_size = FLAME_BASE_SIZE + math.random(0, FLAME_VARIANCE)
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.circle("fill", 0, lander.height / 2 + 5, flame_size)
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", 0, lander.height / 2 + 5, flame_size * 0.6)
    end
    
    love.graphics.pop()
end

-- Draw HUD
local function draw_hud()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(HUD_FONT_SIZE))
    
    local hud_y = 10
    love.graphics.print("Fuel: " .. math.floor(lander.fuel), 10, hud_y)
    hud_y = hud_y + 20
    love.graphics.print("Velocity: " .. math.floor(calculate_speed()), 10, hud_y)
    hud_y = hud_y + 20
    love.graphics.print("Altitude: " .. math.floor(landing_pad.y - (lander.y + lander.height)), 10, hud_y)
    hud_y = hud_y + 20
    love.graphics.print("Angle: " .. math.floor(lander.angle) .. "°", 10, hud_y)
    
    love.graphics.print("Controls: Arrow Keys", 10, WINDOW_HEIGHT - 40)
    love.graphics.print("Left/Right: Rotate | Up: Thrust", 10, WINDOW_HEIGHT - 20)
end

-- Draw game state messages
local function draw_game_messages()
    if game_state.current == "won" then
        love.graphics.setColor(0, 1, 0)
        love.graphics.setFont(love.graphics.newFont(MESSAGE_FONT_SIZE))
        love.graphics.printf("SUCCESSFUL LANDING!", 0, WINDOW_HEIGHT / 2 - 50, WINDOW_WIDTH, "center")
        love.graphics.setFont(love.graphics.newFont(SUBTITLE_FONT_SIZE))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press R to restart", 0, WINDOW_HEIGHT / 2 + 20, WINDOW_WIDTH, "center")
    elseif game_state.current == "lost" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.setFont(love.graphics.newFont(MESSAGE_FONT_SIZE))
        love.graphics.printf("CRASHED!", 0, WINDOW_HEIGHT / 2 - 50, WINDOW_WIDTH, "center")
        love.graphics.setFont(love.graphics.newFont(SUBTITLE_FONT_SIZE))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press R to restart", 0, WINDOW_HEIGHT / 2 + 20, WINDOW_WIDTH, "center")
    end
end

function love.load()
    love.window.setTitle("Lunar Lander")
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    math.randomseed(os.time())
    
    initialize_stars()
    reset_lander()
    initialize_landing_pad()
end

function love.update(dt)
    if game_state.current ~= "playing" then
        handle_restart()
        return
    end
    
    update_rotation(dt)
    update_thrust(dt)
    update_position(dt)
    constrain_to_screen()
    handle_landing()
end

function love.draw()
    draw_background()
    draw_ground()
    draw_lander()
    draw_hud()
    draw_game_messages()
end
