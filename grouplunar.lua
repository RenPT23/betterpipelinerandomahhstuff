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

local win = gpu.createWindow(1, 1, imgW, imgH)

for y = 0, imgH - 1 do
    local sampleY = y
    if y == imgH - 1 then
        sampleY = 0 -- never call getRGB on the last row; reuse row 0's pixel data instead
    end
    for x = 0, imgW - 1 do
        local color = image.getRGB(x, sampleY)
        -- filledRectangle(x, y, w, h, color) — 1-indexed per the working example
        win.filledRectangle(x + 1, y + 1, 1, 1, color)
    end
end

win.sync()
gpu.sync()
