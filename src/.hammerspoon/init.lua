-- settings for iTerm
-- https://qiita.com/naoya@github/items/81027083aeb70b309c14

local function keyCode(key, modifiers)
   modifiers = modifiers or {}
   return function()
      hs.eventtap.event.newKeyEvent(modifiers, string.lower(key), true):post()
      hs.timer.usleep(1000)
      hs.eventtap.event.newKeyEvent(modifiers, string.lower(key), false):post()
   end
end

local function remapKey(modifiers, key, keyHandler)
   hs.hotkey.bind(modifiers, key, keyHandler, nil, keyHandler)
end

local function disableAllHotkeys()
   for _, v in pairs(hs.hotkey.getHotkeys()) do
      v['_hk']:disable()
   end
end

local function enableAllHotkeys()
   for _, v in pairs(hs.hotkey.getHotkeys()) do
      v['_hk']:enable()
   end
end

local function handleGlobalAppEvent(name, event, _app)
   if event == hs.application.watcher.activated then
      -- hs.alert.show(name)
      if name == "iTerm2" then
         disableAllHotkeys()
      else
         enableAllHotkeys()
      end
   end
end

appsWatcher = hs.application.watcher.new(handleGlobalAppEvent)
appsWatcher:start()

-- torabo-tsuki 向け。 layer5 (マウスモード) のときを判別可能にするため
-- https://github.com/kasutera/zmk-keyboard-torabo-tsuki-lp/pull/3
-- torabo-tsuki が Bluetooth 接続されているときだけメニューバーに表示する
local TORABO_TSUKI_NAME = "torabo-tsuki"
local BLUETOOTH_POLL_INTERVAL = 5

-- 表示 / 非表示を繰り返すので autosaveName を付けてメニューバー内の位置を保たせる
local layer5Menu = hs.menubar.new(true, "toraboTsukiLayer5")

layer5Watcher = hs.eventtap.new({
   hs.eventtap.event.types.keyDown,
   hs.eventtap.event.types.keyUp,
}, function(event)
   local eventKeyCode = event:getKeyCode()
   local eventType = event:getType()

   if eventKeyCode == hs.keycodes.map.f16 then
      if eventType == hs.eventtap.event.types.keyDown then
         layer5Menu:setTitle("🔴")
      end
      return true
   end

   if eventKeyCode == hs.keycodes.map.f17 then
      if eventType == hs.eventtap.event.types.keyDown then
         layer5Menu:setTitle("⚪️")
      end
      return true
   end

   return false
end)

-- 接続状態が変わったときだけメニューバーと eventtap を切り替える
local layer5Enabled = nil
local function setLayer5Enabled(enabled)
   if enabled == layer5Enabled then
      return
   end
   layer5Enabled = enabled

   if enabled then
      layer5Menu:setTitle("⚪️")
      layer5Menu:returnToMenuBar()
      layer5Watcher:start()
   else
      layer5Watcher:stop()
      layer5Menu:removeFromMenuBar()
   end
end

-- system_profiler の JSON は { device_connected = { { ["デバイス名"] = {...} }, ... } } という形
-- なので、接続中デバイスのキーに目的の名前があるか探す
local function isToraboTsukiConnected(output)
   local ok, parsed = pcall(hs.json.decode, output)
   if not ok or type(parsed) ~= "table" then
      return false
   end

   for _, block in ipairs(parsed.SPBluetoothDataType or {}) do
      for _, entry in ipairs(block.device_connected or {}) do
         for name in pairs(entry) do
            if name == TORABO_TSUKI_NAME then
               return true
            end
         end
      end
   end

   return false
end

-- system_profiler は 0.2 秒ほどかかるので hs.task で非同期に実行する
local bluetoothTask = nil
local function refreshLayer5Menu()
   if bluetoothTask and bluetoothTask:isRunning() then
      return
   end

   bluetoothTask = hs.task.new(
      "/usr/sbin/system_profiler",
      function(exitCode, stdOut, _stdErr)
         setLayer5Enabled(exitCode == 0 and isToraboTsukiConnected(stdOut))
      end,
      { "SPBluetoothDataType", "-json" }
   )
   bluetoothTask:start()
end

setLayer5Enabled(false)
refreshLayer5Menu()
bluetoothPollTimer = hs.timer.doEvery(BLUETOOTH_POLL_INTERVAL, refreshLayer5Menu)

-- スリープ復帰直後は接続状態が変わりやすいので、ポーリングを待たずに再判定する
caffeinateWatcher = hs.caffeinate.watcher.new(function(event)
   if event == hs.caffeinate.watcher.systemDidWake
      or event == hs.caffeinate.watcher.screensDidUnlock then
      refreshLayer5Menu()
   end
end)
caffeinateWatcher:start()

-- コマンド
remapKey({'ctrl'}, '[', keyCode('escape'))
remapKey({'ctrl'}, 'j', keyCode('escape'))
remapKey({'ctrl'}, 'm', keyCode('return'))
remapKey({'ctrl'}, 'h', keyCode('delete'))


-- HANDLE SCROLLING WITH TRACKBALL

local deferred = false

overrideRightMouseDown = hs.eventtap.new({ hs.eventtap.event.types.rightMouseDown }, function()
    --print("down"))
    deferred = true
    return true
end)

overrideRightMouseUp = hs.eventtap.new({ hs.eventtap.event.types.rightMouseUp }, function(e)
    -- print("up"))
    if (deferred) then
        overrideRightMouseDown:stop()
        overrideRightMouseUp:stop()
        hs.eventtap.rightClick(e:location())
        overrideRightMouseDown:start()
        overrideRightMouseUp:start()
        return true
    end

    return false
end)


local oldmousepos = {}
local scrollmult = -2   -- negative multiplier makes mouse work like traditional scrollwheel
dragRightToScroll = hs.eventtap.new({ hs.eventtap.event.types.rightMouseDragged }, function(e)
    -- print("scroll");

    deferred = false

    oldmousepos = hs.mouse.absolutePosition()

    local dx = e:getProperty(hs.eventtap.event.properties['mouseEventDeltaX'])
    local dy = e:getProperty(hs.eventtap.event.properties['mouseEventDeltaY'])
    local scroll = hs.eventtap.event.newScrollEvent({dx * scrollmult, dy * scrollmult},{},'pixel')

    -- put the mouse back
    hs.mouse.absolutePosition(oldmousepos)

    return true, {scroll}
end)

overrideRightMouseDown:start()
overrideRightMouseUp:start()
dragRightToScroll:start()
