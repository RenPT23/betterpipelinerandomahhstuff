-- This script may only be copied with straight permission from Group Lunar (RenPT23 and The_Yellow_Spy)

-- Draws grouplunar.png (24x24) pixel-by-pixel using filledRectangle
local gpu = peripheral.wrap("top")
gpu.refreshSize()
gpu.setSize(64)

local f = io.open("image.png", "rb")
local data = f:read("*a")
f:close()

local bytes = { data:byte(1, #data) }
local image = gpu.decodeImage(table.unpack(bytes))

local imgW, imgH = image.getWidth(), image.getHeight()
print("image size: " .. imgW-2 .. "x" .. imgH-2)

gpu.fill()
gpu.sync()

local scale = 1 -- this needs to be modified based on the image
local win = gpu.createWindow(1, 1, imgW * scale - 2, imgH * scale - 2)

for y = 0, imgH - 3 do
    local sampleY = y
    for x = 0, imgW - 3 do
        local sampleX = x
        local color = image.getRGB(sampleX, sampleY)
        -- filledRectangle(x, y, w, h, color) — 1-indexed per the working example
        win.filledRectangle((x * scale) + 1, (y * scale) + 1, scale, scale, color)
    end
end

win.sync()
gpu.sync()
