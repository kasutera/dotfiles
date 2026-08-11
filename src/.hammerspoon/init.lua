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
local layer5Menu = hs.menubar.new()
layer5Menu:setTitle("⚪️")

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
layer5Watcher:start()

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
