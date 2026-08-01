-- lhs.lua - Lunar Hack Suite
-- Self-contained CC:Tweaked utility for modem channel mapping/tracing.
-- Uses peripheral.find("modem") automatically. No side input required.

local SUITE_NAME = "Lunar Hack Suite"
local VERSION = "1.0"

-- 35 reserved channels: 65500..65534
local RESERVED_START = 65500
local RESERVED_END   = 65534
local NON_RESERVED_MIN = 0
local NON_RESERVED_MAX = RESERVED_START - 1

local modem = peripheral.find("modem")
if not modem then
  error("No modem found. Attach a wireless or ender modem and try again.", 0)
end

local modemSide = peripheral.getName(modem) or "unknown"
local startedAt = os.clock()

local KNOWN_RESERVED = {
  [65534] = "GPS",
}

local function clear()
  term.clear()
  term.setCursorPos(1, 1)
end

local function now()
  return ("%.1fs"):format(os.clock() - startedAt)
end

local function pause(msg)
  write(msg or "Press Enter to continue...")
  read()
end

local function line()
  print(string.rep("-", 78))
end

local function center(text)
  local w = term.getSize()
  local x = math.max(1, math.floor((w - #text) / 2) + 1)
  term.setCursorPos(x, select(2, term.getCursorPos()))
  print(text)
end

local function short(v, maxLen)
  maxLen = maxLen or 80
  local t = type(v)
  local s
  if t == "string" then
    s = v
  elseif t == "number" or t == "boolean" then
    s = tostring(v)
  else
    local ok, ser = pcall(textutils.serialize, v)
    s = ok and ser or ("<" .. t .. ">")
  end

  s = s:gsub("\n", " ")
  if #s > maxLen then
    s = s:sub(1, maxLen - 3) .. "..."
  end
  return s
end

local function tonumber_safe(v)
  local n = tonumber((v or ""):match("^%s*(.-)%s*$"))
  return n
end

local function promptNumber(label, default, minV, maxV)
  while true do
    if default ~= nil then
      write(("%s [%s]: "):format(label, tostring(default)))
    else
      write(label .. ": ")
    end
    local s = read()
    if s == "" and default ~= nil then return default end
    local n = tonumber_safe(s)
    if n and (not minV or n >= minV) and (not maxV or n <= maxV) then
      return math.floor(n)
    end
    print("Invalid number.")
  end
end

local function promptText(label, default)
  if default and default ~= "" then
    write(("%s [%s]: "):format(label, default))
  else
    write(label .. ": ")
  end
  local s = read()
  if s == "" and default ~= nil then return default end
  return s
end

local function yesNo(label, defaultYes)
  local hint = defaultYes and "[Y/n]" or "[y/N]"
  while true do
    write(("%s %s: "):format(label, hint))
    local s = read()
    if s == "" then return defaultYes end
    s = s:lower()
    if s == "y" or s == "yes" then return true end
    if s == "n" or s == "no" then return false end
    print("Please answer y or n.")
  end
end

local function safeCloseAll()
  pcall(modem.closeAll, modem)
end

local function safeOpen(ch)
  return pcall(modem.open, ch)
end

local function openRange(a, b)
  for ch = a, b do
    safeOpen(ch)
  end
end

local function closeRange(a, b)
  for ch = a, b do
    pcall(modem.close, ch)
  end
end

local function packetRow(ch, info)
  local name = KNOWN_RESERVED[ch] or ("channel-" .. ch)
  local seen = info.lastSeen or "-"
  local cnt = info.count or 0
  local reply = info.lastReplyChannel ~= nil and tostring(info.lastReplyChannel) or "-"
  local msg = info.lastPreview or "-"
  print(("%5d  %-14s  %-7s  %-8d  %-8s  %s"):format(
    ch, name, info.active and "active" or "silent", cnt, reply, msg
  ))
end

local function monitorChannels(channels, duration, title, allowKeyExit)
  local info = {}
  for _, ch in ipairs(channels) do
    info[ch] = {
      count = 0,
      active = false,
      firstSeen = nil,
      lastSeen = nil,
      lastReplyChannel = nil,
      lastPreview = nil,
      lastSide = nil,
      lastDistance = nil,
    }
  end

  safeCloseAll()
  for _, ch in ipairs(channels) do
    safeOpen(ch)
  end

  clear()
  print(SUITE_NAME .. " v" .. VERSION)
  line()
  print(title)
  print(("Modem side: %s | Type: %s"):format(modemSide, tostring(modem.getType and modem.getType() or "modem")))
  print(("Watching %d channel(s) for %.1f second(s)."):format(#channels, duration))
  print("Press Q to stop early." )
  line()
  print(" CH    NAME            STATE    PACKETS   REPLY     LAST PACKET")
  line()

  local timer = os.startTimer(duration)
  local alive = true

  while alive do
    local e = { os.pullEvent() }

    if e[1] == "modem_message" then
      local side, channel, replyChannel, message, distance = e[2], e[3], e[4], e[5], e[6]
      local rec = info[channel]
      if rec then
        rec.count = rec.count + 1
        rec.active = true
        rec.lastSeen = now()
        rec.lastReplyChannel = replyChannel
        rec.lastPreview = short(message, 44)
        rec.lastSide = side
        rec.lastDistance = distance
        if not rec.firstSeen then rec.firstSeen = now() end
      end

      term.setCursorPos(1, 9)
      term.clearLine()
      print(("Packet on channel %d"):format(channel))
      term.clearLine()
      print(("Side=%s Reply=%s Dist=%s Msg=%s"):format(
        tostring(side),
        tostring(replyChannel),
        tostring(distance),
        short(message, 120)
      ))

      if info[channel] then
        term.setCursorPos(1, 12)
        term.clearLine()
        packetRow(channel, info[channel])
      end

    elseif e[1] == "timer" and e[2] == timer then
      alive = false

    elseif e[1] == "key" and allowKeyExit and e[2] == keys.q then
      alive = false
    end
  end

  clear()
  print(SUITE_NAME .. " v" .. VERSION)
  line()
  print(title .. " - Summary")
  line()
  print(" CH    NAME            STATE    PACKETS   REPLY     LAST PACKET")
  line()

  for _, ch in ipairs(channels) do
    packetRow(ch, info[ch])
  end

  line()
  pause("Done. Press Enter to return to menu...")
  safeCloseAll()
end

local function mmap()
  clear()
  print("mmap - non-reserved channel mapper")
  line()
  print("This scans channels in the non-reserved range and logs packets it can see.")
  print(("Range: %d..%d"):format(NON_RESERVED_MIN, NON_RESERVED_MAX))
  line()

  local startCh = promptNumber("Start channel", 0, NON_RESERVED_MIN, NON_RESERVED_MAX)
  local endCh = promptNumber("End channel", NON_RESERVED_MAX, NON_RESERVED_MIN, NON_RESERVED_MAX)
  if endCh < startCh then
    startCh, endCh = endCh, startCh
  end

  local duration = promptNumber("Listen duration (seconds)", 20, 1, 3600)
  local channels = {}
  for ch = startCh, endCh do
    channels[#channels + 1] = ch
  end

  monitorChannels(channels, duration, "mmap", true)
end

local function pmapt()
  clear()
  print("pmapt - reserved channel mapper")
  line()
  print("Reserved range: 65500..65534 (35 channels)")
  print("Known labels are shown when available; otherwise channels are generic.")
  line()

  local duration = promptNumber("Listen duration (seconds)", 20, 1, 3600)
  local channels = {}
  for ch = RESERVED_START, RESERVED_END do
    channels[#channels + 1] = ch
  end

  monitorChannels(channels, duration, "pmapt", true)
end

local function traceOne(channel, label, reserved)
  clear()
  print(label)
  line()
  print(("Channel: %d  |  %s"):format(channel, reserved and "reserved" or "non-reserved"))
  line()

  safeCloseAll()
  safeOpen(channel)

  local doSend = yesNo("Send a test packet before listening?", false)
  if doSend then
    local replyChannel = promptNumber("Reply channel", 0, 0, 65535)
    local payload = promptText("Payload", "hello from LHS")
    local ok, err = pcall(modem.transmit, channel, replyChannel, payload)
    if ok then
      print("Sent.")
    else
      print("Send failed: " .. tostring(err))
    end
  end

  local duration = promptNumber("Listen duration (seconds)", 30, 1, 3600)

  local info = {
    count = 0,
    active = false,
    firstSeen = nil,
    lastSeen = nil,
    lastReplyChannel = nil,
    lastPreview = nil,
    lastSide = nil,
    lastDistance = nil,
  }

  clear()
  print(SUITE_NAME .. " v" .. VERSION)
  line()
  print(label)
  print(("Watching channel %d for %.1f second(s)."):format(channel, duration))
  print("Press Q to stop early.")
  line()
  print(" TIME     SIDE         REPLY     DIST      MESSAGE")
  line()

  local timer = os.startTimer(duration)
  while true do
    local e = { os.pullEvent() }

    if e[1] == "modem_message" and e[3] == channel then
      local side, replyChannel, message, distance = e[2], e[4], e[5], e[6]
      info.count = info.count + 1
      info.active = true
      info.lastSeen = now()
      info.lastReplyChannel = replyChannel
      info.lastPreview = short(message, 120)
      info.lastSide = side
      info.lastDistance = distance
      if not info.firstSeen then info.firstSeen = now() end

      term.setCursorPos(1, 8)
      term.clearLine()
      print(("[%s]  %s  %s  %s  %s"):format(
        now(),
        tostring(side),
        tostring(replyChannel),
        tostring(distance),
        short(message, 120)
      ))

    elseif e[1] == "timer" and e[2] == timer then
      break

    elseif e[1] == "key" and e[2] == keys.q then
      break
    end
  end

  clear()
  print(label .. " - Summary")
  line()
  print(("Channel: %d"):format(channel))
  print(("Packets: %d"):format(info.count))
  print(("First seen: %s"):format(info.firstSeen or "-"))
  print(("Last seen : %s"):format(info.lastSeen or "-"))
  print(("Last reply: %s"):format(tostring(info.lastReplyChannel or "-")))
  print(("Last side  : %s"):format(tostring(info.lastSide or "-")))
  print(("Last dist  : %s"):format(tostring(info.lastDistance or "-")))
  print(("Last msg   : %s"):format(info.lastPreview or "-"))
  line()
  pause("Press Enter to return to menu...")
  safeCloseAll()
end

local function ptrace()
  clear()
  print("ptrace - non-reserved packet tracer")
  line()
  local ch = promptNumber("Channel to trace", 0, NON_RESERVED_MIN, NON_RESERVED_MAX)
  traceOne(ch, "ptrace", false)
end

local function rtrace()
  clear()
  print("rtrace - reserved packet tracer")
  line()
  local ch = promptNumber("Reserved channel to trace", 65534, RESERVED_START, RESERVED_END)
  traceOne(ch, "rtrace", true)
end

local function header()
  clear()
  if term.isColor() then
    term.setTextColor(colors.cyan)
  end
  center(SUITE_NAME .. " v" .. VERSION)
  if term.isColor() then
    term.setTextColor(colors.white)
  end
  center(("Modem: %s | Type: %s"):format(modemSide, tostring(modem.getType and modem.getType() or "modem")))
  line()
  print("1) mmap   - map non-reserved channels")
  print("2) pmapt  - map reserved channels")
  print("3) ptrace - trace one non-reserved channel")
  print("4) rtrace - trace one reserved channel")
  print("5) exit")
  line()
end

local function main()
  while true do
    header()
    write("Choose tool: ")
    local choice = read()
    choice = (choice or ""):lower():gsub("%s+", "")

    if choice == "1" or choice == "mmap" then
      mmap()
    elseif choice == "2" or choice == "pmapt" then
      pmapt()
    elseif choice == "3" or choice == "ptrace" then
      ptrace()
    elseif choice == "4" or choice == "rtrace" then
      rtrace()
    elseif choice == "5" or choice == "exit" or choice == "q" then
      clear()
      print("Goodbye.")
      safeCloseAll()
      return
    else
      print("Unknown option.")
      sleep(0.7)
    end
  end
end

local ok, err = pcall(main)
if not ok then
  safeCloseAll()
  clear()
  print("Lunar Hack Suite crashed:")
  print(err)
end
