io.stdout:setvbuf("no")

if arg[#arg] == "-debug" then
    require("mobdebug").start()
end

local WINDOW_WIDTH = 800
local WINDOW_HEIGHT = 600
local GRAVITY = 50
local THRUST_POWER = 200
local ROTATION_SPEED = 100
local MAX_SAFE_VELOCITY = 50
local MAX_SAFE_ANGLE = 15
local GROUND_HEIGHT = 50
local LANDING_PAD_WIDTH = 100

local gameState = "playing" -- "playing", "won", "lost"
local stars = {}

local Lander = {
    x = 400,
    y = 50,
    vx = 0,
    vy = 0,
    fuel = 1000,
    angle = 0,
    thrust = 0,
    width = 20,
    height = 40
}

local LandingPad = {
    x = 0,
    y = 0,
    width = LANDING_PAD_WIDTH
}

function love.load()
    love.window.setTitle("Lunar Lander")
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    math.randomseed(os.time())
    
    for i = 1, 100 do
        stars[i] = {
            x = math.random(0, WINDOW_WIDTH),
            y = math.random(0, WINDOW_HEIGHT),
            size = math.random(1, 2)
        }
    end
    
    Lander.x = math.random(100, WINDOW_WIDTH - 100)
    Lander.y = 50
    
    LandingPad.x = math.random(100, WINDOW_WIDTH - LANDING_PAD_WIDTH - 100)
    LandingPad.y = WINDOW_HEIGHT - GROUND_HEIGHT
end

function love.update(dt)
    if gameState ~= "playing" then
        if love.keyboard.isDown("r") then
            gameState = "playing"
            Lander.x = math.random(100, WINDOW_WIDTH - 100)
            Lander.y = 50
            Lander.vx = 0
            Lander.vy = 0
            Lander.fuel = 1000
            Lander.angle = 0
            Lander.thrust = 0
        end
        return
    end
    
    if love.keyboard.isDown("left") then
        Lander.angle = Lander.angle - ROTATION_SPEED * dt
    end
    if love.keyboard.isDown("right") then
        Lander.angle = Lander.angle + ROTATION_SPEED * dt
    end
    
    if love.keyboard.isDown("up") and Lander.fuel > 0 then
        local angle_rad = math.rad(Lander.angle)
        Lander.vx = Lander.vx + math.sin(angle_rad) * THRUST_POWER * dt
        Lander.vy = Lander.vy - math.cos(angle_rad) * THRUST_POWER * dt
        Lander.thrust = THRUST_POWER
        Lander.fuel = math.max(0, Lander.fuel - 100 * dt)
    else
        Lander.thrust = 0
    end
    
    Lander.vy = Lander.vy + GRAVITY * dt
    
    Lander.x = Lander.x + Lander.vx * dt
    Lander.y = Lander.y + Lander.vy * dt
    
    Lander.x = math.max(0, math.min(WINDOW_WIDTH - Lander.width, Lander.x))
    
    local landerBottom = Lander.y + Lander.height
    if landerBottom >= LandingPad.y then
        local landerCenterX = Lander.x + Lander.width / 2
        local padLeft = LandingPad.x
        local padRight = LandingPad.x + LandingPad.width
        
        if landerCenterX >= padLeft and landerCenterX <= padRight then
            local speed = math.sqrt(Lander.vx * Lander.vx + Lander.vy * Lander.vy)
            local angle = math.abs(Lander.angle)
            
            if speed <= MAX_SAFE_VELOCITY and angle <= MAX_SAFE_ANGLE then
                gameState = "won"
            else
                gameState = "lost"
            end
        else
            gameState = "lost"
        end
        
        Lander.y = LandingPad.y - Lander.height
        Lander.vy = 0
        Lander.vx = 0
    end
    
    if Lander.y < 0 then
        Lander.y = 0
        Lander.vy = 0
    end
end

function love.draw()
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    
    love.graphics.setColor(1, 1, 1)
    for _, star in ipairs(stars) do
        love.graphics.circle("fill", star.x, star.y, star.size)
    end
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", 0, WINDOW_HEIGHT - GROUND_HEIGHT, WINDOW_WIDTH, GROUND_HEIGHT)
    
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", LandingPad.x, LandingPad.y, LandingPad.width, 5)
    love.graphics.setColor(0, 0.7, 0)
    love.graphics.rectangle("line", LandingPad.x, LandingPad.y, LandingPad.width, 5)
    
    love.graphics.push()
    love.graphics.translate(Lander.x + Lander.width / 2, Lander.y + Lander.height / 2)
    love.graphics.rotate(math.rad(Lander.angle))
    
    love.graphics.setColor(0.8, 0.8, 0.8)
    local points = {
        -Lander.width / 2, -Lander.height / 2,
        Lander.width / 2, -Lander.height / 2,
        0, Lander.height / 2
    }
    love.graphics.polygon("fill", points)
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("line", points)
    
    if Lander.thrust > 0 and Lander.fuel > 0 then
        local flameSize = 10 + math.random(0, 5)
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.circle("fill", 0, Lander.height / 2 + 5, flameSize)
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", 0, Lander.height / 2 + 5, flameSize * 0.6)
    end
    
    love.graphics.pop()
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    
    local hudY = 10
    love.graphics.print("Fuel: " .. math.floor(Lander.fuel), 10, hudY)
    hudY = hudY + 20
    love.graphics.print("Velocity: " .. math.floor(math.sqrt(Lander.vx * Lander.vx + Lander.vy * Lander.vy)), 10, hudY)
    hudY = hudY + 20
    love.graphics.print("Altitude: " .. math.floor(LandingPad.y - (Lander.y + Lander.height)), 10, hudY)
    hudY = hudY + 20
    love.graphics.print("Angle: " .. math.floor(Lander.angle) .. "°", 10, hudY)
    
    love.graphics.print("Controls: Arrow Keys", 10, WINDOW_HEIGHT - 40)
    love.graphics.print("Left/Right: Rotate | Up: Thrust", 10, WINDOW_HEIGHT - 20)
    
    if gameState == "won" then
        love.graphics.setColor(0, 1, 0)
        love.graphics.setFont(love.graphics.newFont(32))
        love.graphics.printf("SUCCESSFUL LANDING!", 0, WINDOW_HEIGHT / 2 - 50, WINDOW_WIDTH, "center")
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press R to restart", 0, WINDOW_HEIGHT / 2 + 20, WINDOW_WIDTH, "center")
    elseif gameState == "lost" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.setFont(love.graphics.newFont(32))
        love.graphics.printf("CRASHED!", 0, WINDOW_HEIGHT / 2 - 50, WINDOW_WIDTH, "center")
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press R to restart", 0, WINDOW_HEIGHT / 2 + 20, WINDOW_WIDTH, "center")
    end
end
