-- This script may only be copied with straight permission from Group Lunar (RenPT23 and The_Yellow_Spy)

-- Draws grouplunar.png (24x24) pixel-by-pixel using filledRectangle
local gpu = peripheral.wrap("top")
gpu.refreshSize()
gpu.setSize(16)

local f = io.open("grouplunar.png", "rb")
local data = f:read("*a")
f:close()

local bytes = { data:byte(1, #data) }
local image = gpu.decodeImage(table.unpack(bytes))

local imgW, imgH = image.getWidth(), image.getHeight()
print("image size: " .. imgW .. "x" .. imgH)

gpu.fill()
gpu.sync()

local scale = 2
local win = gpu.createWindow(1, 1, imgW * scale, imgH * scale)

for y = 0, imgH - 1 do
    local sampleY = y
    if y == imgH - 1 then
        sampleY = 0 -- never call getRGB on the last row; reuse row 0's pixel data instead
    end
    for x = 0, imgW - 1 do
        local sampleX = x
        if y == imgH - 2 and x == imgW - 1 then
            sampleX, sampleY = imgW - 1, 0 -- skip (23,22) too; reuse (23,0) instead
        end
        local color = image.getRGB(sampleX, sampleY)
        -- filledRectangle(x, y, w, h, color) — 1-indexed per the working example
        win.filledRectangle((x * scale) + 1, (y * scale) + 1, scale, scale, color)
    end
end

win.sync()
gpu.sync()
