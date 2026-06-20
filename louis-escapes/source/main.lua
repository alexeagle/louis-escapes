-- Louis: Joy Run — vertical slice.
-- One mechanic: move Louis around with the D-pad. Three states: splash, title, play.

import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

playdate.display.setRefreshRate(30)

-- Assets (loaded once). Paths are relative to source/, no extension needed.
local splashImage <const> = assert(gfx.image.new("images/launchImage"), "missing images/launchImage")
local cardImage   <const> = assert(gfx.image.new("images/card"),        "missing images/card")
local louisImage  <const> = assert(gfx.image.new("images/icon"),        "missing images/icon")

-- Screen / sprite constants
local SCREEN_W <const> = 400
local SCREEN_H <const> = 240
local LOUIS_SIZE <const> = 32
local MAX_X <const> = SCREEN_W - LOUIS_SIZE  -- 368
local MAX_Y <const> = SCREEN_H - LOUIS_SIZE  -- 208
local SPEED <const> = 3                      -- pixels per frame
local SPLASH_AUTO_FRAMES <const> = 45        -- ~1.5s at 30 fps

-- State machine
local kSplash <const>, kTitle <const>, kPlay <const> = 1, 2, 3
local state = kSplash
local splashFrames = 0

-- Louis position (starts centered)
local louisX, louisY = 184, 104

local function clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

local function startPlay()
    louisX, louisY = 184, 104
    state = kPlay
end

function playdate.update()
    gfx.clear(gfx.kColorWhite)

    if state == kSplash then
        splashImage:draw(0, 0)
        splashFrames += 1
        if playdate.buttonJustPressed(playdate.kButtonA) or splashFrames >= SPLASH_AUTO_FRAMES then
            state = kTitle
        end

    elseif state == kTitle then
        -- White background; card carries the title, centered.
        local cw, ch = cardImage:getSize()
        cardImage:draw((SCREEN_W - cw) // 2, (SCREEN_H - ch) // 2)
        gfx.drawTextAligned("Press A to start", SCREEN_W // 2, SCREEN_H - 24, kTextAlignment.center)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            startPlay()
        end

    elseif state == kPlay then
        -- Plain white background so the dark sprite reads clearly.
        if playdate.buttonIsPressed(playdate.kButtonUp)    then louisY -= SPEED end
        if playdate.buttonIsPressed(playdate.kButtonDown)  then louisY += SPEED end
        if playdate.buttonIsPressed(playdate.kButtonLeft)  then louisX -= SPEED end
        if playdate.buttonIsPressed(playdate.kButtonRight) then louisX += SPEED end
        louisX = clamp(louisX, 0, MAX_X)
        louisY = clamp(louisY, 0, MAX_Y)
        louisImage:draw(louisX, louisY)

        if playdate.buttonJustPressed(playdate.kButtonB) then
            state = kTitle  -- B = back (A=confirm / B=back convention)
        end
    end
end
