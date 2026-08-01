local songDir = "songs"

if not fs.exists(songDir) then
    fs.makeDir(songDir)
end

local cursor = "list"
local selected = 1
local scroll = 0
local search = ""

local function getSongs()
    local songs = {}

    for _, name in ipairs(fs.list(songDir)) do
        local path = songDir .. "/" .. name
        local f = fs.open(path, "r")

        local title = f.readLine()

        f.close()

        songs[#songs + 1] = {
            title = title,
            file = path
        }
    end

    table.sort(songs, function(a, b)
        return a.title < b.title
    end)

    return songs
end

local function filteredSongs()
    local result = {}

    for _, song in ipairs(getSongs()) do
        if string.find(
            string.lower(song.title),
            string.lower(search),
            1,
            true
        ) then
            result[#result + 1] = song
        end
    end

    return result
end

local function loadSong(song)
    local f = fs.open(song.file, "r")

    f.readLine()

    local args = {}

    while true do
        local line = f.readLine()

        if not line then
            break
        end

        args[#args + 1] = line
    end

    f.close()

    return args
end

local function playSong(song)
    term.clear()
    term.setCursorPos(1, 1)

    print("Playing:")
    print(song.title)

    local args = loadSong(song)

    shell.run(
        "wavplayer",
        table.unpack(args)
    )

    print("Finished")
    sleep(1)
end

local function draw()
    term.clear()
    term.setCursorPos(1, 1)

    local searchText = "Search: " .. search

    if cursor == "search" then
        searchText = ">" .. searchText
    end

    write(searchText)

    local songs = filteredSongs()

    for i = 1, 10 do
        local index = i + scroll
        local song = songs[index]

        if song then
            term.setCursorPos(1, i + 3)

            if cursor == "list" and index == selected then
                write("> ")
            else
                write("  ")
            end

            write(song.title)
        end
    end
end

while true do
    draw()

    local _, key = os.pullEvent("key")

    if key == keys.left then
        if cursor == "list" then
            cursor = "search"
        end

    elseif key == keys.right then
        if cursor == "search" then
            cursor = "list"
        end

    elseif key == keys.up then
        if cursor == "list" then
            selected = math.max(
                1,
                selected - 1
            )

            if selected <= scroll then
                scroll = math.max(0, scroll - 1)
            end
        end

    elseif key == keys.down then
        if cursor == "list" then
            local count = #filteredSongs()

            selected = math.min(
                count,
                selected + 1
            )

            if selected > scroll + 10 then
                scroll = scroll + 1
            end
        end

    elseif key == keys.enter then
        if cursor == "list" then
            local songs = filteredSongs()

            if songs[selected] then
                playSong(songs[selected])
            end

        elseif cursor == "search" then
            term.setCursorPos(9, 1)

            search = read()

            selected = 1
            scroll = 0
        end

    elseif key == keys.space then
        cursor = "list"
    end
end
