-- Simplest possible Playdate "Hello World".
-- The Playdate runtime calls playdate.update() once per frame (30 fps by default).

local gfx <const> = playdate.graphics

function playdate.update()
    gfx.clear()                              -- clear screen to white
    gfx.drawText("Hello, World!", 150, 116)  -- built-in; needs no CoreLibs import
end
