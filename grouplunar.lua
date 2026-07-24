local gpu = peripheral.wrap("top")
gpu.refreshSize()
gpu.setSize(8)

local gl = gpu.createWindow3D(1, 1, 24, 24)

gl.glFrustum(90, 1, 4)
gl.glDirLight(0, 0, -1)

local f = io.open("grouplunar.png", "rb")
local bytes = {}

local b = f._handle.read(1)
while b do
    bytes[#bytes + 1] = ("<I1"):unpack(b)
    b = f._handle.read(1)
end
f:close()

local image = gpu.decodeImage(table.unpack(bytes))

local tex = gl.glGenTextures()
gl.glBindTexture(tex)
gl.glTexImage(image.ref())

local glc = {}
local c = { gl.getConstants() }
for i = 1, #c, 2 do
    glc[c[i]] = c[i + 1]
end

gl.glEnable(glc.GL_TEXTURE_2D)

while true do
    gl.clear()

    gl.glLoadIdentity()
    gl.glTranslate(0, 0, 3)

    gl.glColor(255, 255, 255)

    gl.glBegin(glc.GL_TRIANGLES)

    -- Triangle 1
    gl.glTexCoord(0, 1)
    gl.glVertex(-1.5, -1.5, 0)

    gl.glTexCoord(0, 0)
    gl.glVertex(-1.5,  1.5, 0)

    gl.glTexCoord(1, 0)
    gl.glVertex( 1.5,  1.5, 0)

    -- Triangle 2
    gl.glTexCoord(0, 1)
    gl.glVertex(-1.5, -1.5, 0)

    gl.glTexCoord(1, 0)
    gl.glVertex( 1.5,  1.5, 0)

    gl.glTexCoord(1, 1)
    gl.glVertex( 1.5, -1.5, 0)

    gl.glEnd()

    gl.render()
    gl.sync()
    gpu.sync()

    sleep(0)
end
