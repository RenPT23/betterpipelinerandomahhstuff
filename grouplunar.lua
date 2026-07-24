local gpu = peripheral.wrap("top")
gpu.refreshSize()
gpu.setSize(16)

local gl = gpu.createWindow3D(0, 0, 48, 48)

gl.glFrustum(90, 1, 4)
gl.glDirLight(0, 0, -1)

local f = io.open("grouplunar.png", "rb")
local data = f:read("*a")
f:close()

local bytes = { data:byte(1, #data) }
local image = gpu.decodeImage(table.unpack(bytes))

local tex = gl.glGenTextures()
gl.glBindTexture(tex)
gl.glTexImage(image.ref())

local glc = {}
local c = { gl.getConstants() }
for i = 1, #c, 2 do
    glc[c[i]] = c[i + 1]
end

for k, v in pairs(glc) do
    print(tostring(k), tostring(v))
end

gl.glEnable(3553)

-- quad distance from camera and FOV-matched half-extent so it fills the screen
local dist = 3
local halfSize = dist * math.tan(math.rad(90 / 2)) -- 90 fov -> tan(45) = 1, so halfSize = dist

while true do
    gl.clear()

    gl.glLoadIdentity()
    gl.glTranslate(0, 0, dist)

    gl.glColor(255, 255, 255)

    gl.glBegin(4) -- GL_TRIANGLES

    -- Triangle 1
    gl.glTexCoord(0, 0)
    gl.glVertex(-halfSize, -halfSize, 0)

    gl.glTexCoord(0, 1)
    gl.glVertex(-halfSize,  halfSize, 0)

    gl.glTexCoord(1, 1)
    gl.glVertex( halfSize,  halfSize, 0)

    -- Triangle 2
    gl.glTexCoord(0, 0)
    gl.glVertex(-halfSize, -halfSize, 0)

    gl.glTexCoord(1, 1)
    gl.glVertex( halfSize,  halfSize, 0)

    gl.glTexCoord(1, 0)
    gl.glVertex( halfSize, -halfSize, 0)

    gl.glEnd()

    gl.render()
    gl.sync()
    gpu.sync()

    sleep(0)
end
