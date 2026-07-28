local speaker = peripheral.find("speaker")

if not speaker then
    error("No speaker found")
end

local function u16(data, pos)
    local a, b = string.byte(data, pos, pos + 1)
    return a + b * 256
end

local function u32(data, pos)
    local a, b, c, d = string.byte(data, pos, pos + 3)
    return a + b * 256 + c * 65536 + d * 16777216
end

local function s16(data, pos)
    local value = u16(data, pos)

    if value >= 32768 then
        value = value - 65536
    end

    return value
end

local function find_chunk(data, target)
    local pos = 13

    while pos <= #data do
        local id = data:sub(pos, pos + 3)
        local size = u32(data, pos + 4)

        if id == target then
            return pos, size
        end

        pos = pos + 8 + size

        -- RIFF chunks are padded to even sizes
        if size % 2 == 1 then
            pos = pos + 1
        end
    end

    return nil
end


local function decode_wav(path)

    local file = fs.open(path, "rb")
    if not file then
        error("Cannot open "..path)
    end

    local wav = file.readAll()
    file.close()


    if wav:sub(1,4) ~= "RIFF" or wav:sub(9,12) ~= "WAVE" then
        error("Not a WAV file")
    end


    local fmt_pos = find_chunk(wav, "fmt ")
    local data_pos, data_size = find_chunk(wav, "data")

    if not fmt_pos or not data_pos then
        error("Invalid WAV")
    end


    local audio_format = u16(wav, fmt_pos + 8)
    local channels = u16(wav, fmt_pos + 10)
    local sample_rate = u32(wav, fmt_pos + 12)
    local bits = u16(wav, fmt_pos + 22)


    if audio_format ~= 1 then
        error("Only PCM WAV supported")
    end

    if channels ~= 1 then
        error("Only mono supported")
    end

    if sample_rate ~= 48000 then
        error("Only 48000Hz supported")
    end

    if bits ~= 8 and bits ~= 16 then
        error("Only 8-bit PCM or S16LE supported")
    end


    local raw = wav:sub(data_pos + 8, data_pos + 7 + data_size)

    local samples = {}


    if bits == 8 then

        -- WAV 8-bit PCM is unsigned
        for i = 1, #raw do
            samples[#samples + 1] = string.byte(raw, i) - 128
        end


    elseif bits == 16 then

        -- PCM S16LE
        for i = 1, #raw, 2 do
            local sample = s16(raw, i)

            -- 16-bit -> 8-bit
            samples[#samples + 1] = math.floor(sample / 256)
        end
    end


    return samples
end


local samples = decode_wav("audio.wav")


local chunk_size = 128 * 1024

for i = 1, #samples, chunk_size do

    local chunk = {}

    for j = i, math.min(i + chunk_size - 1, #samples) do
        chunk[#chunk + 1] = samples[j]
    end


    while not speaker.playAudio(chunk) do
        os.pullEvent("speaker_audio_empty")
    end
end
