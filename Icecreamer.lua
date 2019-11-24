Icecreamer__locale = {}
local frame, events = CreateFrame("Frame"), {};
local icecreamName = "Tigule and Foror's Strawberry Ice Cream"
local icecreamID = 7228
local icecreamPresent = false
local tradeSessionStarted = false
local tradeSessionSuccess = false
local tradeSessionCanceled = false
local saveInitiated = false
local discoveryEnabled = false
local splitSessionStarted = false
local giveSessionStarted = false
local tradeRequestInitiated  = false
function events:TRADE_ACCEPT_UPDATE(playerAccepted, targetAccepted)
    -- print("trade accepted")
    if playerAccepted and targetAccepted then
        tradeSessionSuccess = truex
    end
end
function events:TRADE_SHOW()
    if tradeRequestInitiated then
        tradeRequestInitiated = false
    end
    tradeSessionStarted = true
end
function events:TRADE_CLOSED()
    -- print("trade closed")
    if not tradeSessionCanceled then
        tradeSessionSuccess = true
    end
    playerName, realmName = UnitName("target")
    -- print(playerName)
    -- print(realmName)
    if not saveInitiated then
        Icecreamer__wait(1, Icecreamer__saveTransaction, playerName, realmName)
        saveInitiated = true
    end
end
function events:TRADE_REQUEST_CANCEL()
    -- print("trade request canceled")
    tradeSessionCanceled = true
    tradeSessionSuccess = false
end
function events:TRADE_PLAYER_ITEM_CHANGED(itemIndex)
    -- print("trade item changed")
    name, icon, quantity = GetTradePlayerItemInfo(itemIndex)
    -- print(icecreamPresent)
    -- print(icecreamName)
    -- print(name)
    if name == icecreamName then
        icecreamPresent = true
    end
    -- print(icecreamPresent)
end
function events:PLAYER_TARGET_CHANGED()
    -- print("target changed")
    playerName, realmName = UnitName("target")
    if playerName == nil or discoveryEnabled == false then
        return
    end
    if realmName ~= nil then
        playerName = playerName .. "." .. realmName
    end
    if IcecreamedPlayers[playerName] ~= nil and IcecreamedPlayers[playerName] > 0 then
        Icecreamer__print("%s has been icecreamed %d times", playerName, IcecreamedPlayers[playerName])
    else
        Icecreamer__print("%s never been icecreamed", playerName)
    end
end
function events:ADDON_LOADED(addonName)
    if addonName == "Icecreamer" then
        if IcecreamedPlayers == nil then
            IcecreamedPlayers = {}
        end
    end
end

function events:BAG_UPDATE(containerID)
    if splitSessionStarted then
        Icecreamer__wait(1, Icecreamer__splitLoop)
    end
    if giveSessionStarted then
        Icecreamer__giveIcecream()
        giveSessionStarted = false
    end
end
frame:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...); -- call one of the functions above
end);
for k, v in pairs(events) do
    frame:RegisterEvent(k); -- Register all events for which handlers have been defined
end

local waitTable = {};
local waitFrame = nil;

function Icecreamer__saveTransaction(playerName, realmName)
    Icecreamer__print("Icecream attempt. Icecream present: %d, trade session started: %d, trade session success: %d", icecreamPresent, tradeSessionStarted, tradeSessionSuccess)
    if realmName ~= nil then
        playerName = playerName .. "." .. realmName
    end
    if IcecreamedPlayers[playerName] == nil then
        IcecreamedPlayers[playerName] = 0
    end
    if icecreamPresent and tradeSessionStarted and tradeSessionSuccess then
        IcecreamedPlayers[playerName] = IcecreamedPlayers[playerName] + 1
    end
    icecreamPresent = false
    tradeSessionStarted = false
    tradeSessionSuccess = false
    saveInitiated = false
    tradeSessionCanceled = false
end

function Icecreamer__wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end

local function MyAddonCommands(msg)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
    if cmd == "on" then
        Icecreamer__print("Icecreamed players discovery enabled")
      discoveryEnabled = true
    elseif cmd == "off" then
        Icecreamer__print("Icecreamed players discovery disabled")
        discoveryEnabled = false  
    elseif cmd == "split" then
        Icecreamer__splitIcecream() 
    else
        Icecreamer__giveIcecream()
    end
end

SLASH_ICECREAMER1 = '/ict'
  
SlashCmdList["ICECREAMER"] = MyAddonCommands

function Icecreamer__print(message, ...)
    locale = GetLocale()
    if locale ~= "ruRU" and locale ~= "enUS" then
        locale = "enUS"
    end
    if Icecreamer__locale[locale][message] ~= nil then
        print(string.format(Icecreamer__locale[locale][message], ...))
    end
end

function Icecreamer__splitIcecream()
    splitSessionStarted = true
    Icecreamer__splitLoop()
end

function Icecreamer__splitLoop()
    if not Icecreamer__splitOnce() then
        splitSessionStarted = false
    end 
end

function Icecreamer__giveIcecream()
    itemBagID = 0
    itemSlotID = 0
    for bag = 0,4 do
        numberOfSlots = GetContainerNumSlots(bag)
        for slot = 1,numberOfSlots do
            itemID = GetContainerItemID(bag, slot)
            if itemID == icecreamID then
                texture, itemCount, locked, quality, readable = GetContainerItemInfo(bag, slot)
                if itemCount == 1 then
                    PickupContainerItem(bag, slot)
                    DropItemOnUnit("target")
                    return
                else
                    itemBagID = bag
                    itemSlotID = slot
                end
            end
        end
    end 
    if itemBagID > 0 and itemSlotID > 0 then
        giveSessionStarted = true
        Icecreamer__splitOnce()
    end
end

function Icecreamer__splitOnce()
    icecreamSlot = 0
    freeSlot = 0
    icecreamBag = 0
    freeSlotBag = 0
    for bag = 0,4 do
        numberOfSlots = GetContainerNumSlots(bag)
        
        for slot = 1,numberOfSlots do
            itemID = GetContainerItemID(bag, slot)
            if itemID == icecreamID then
                texture, itemCount, locked, quality, readable = GetContainerItemInfo(bag, slot)
                if itemCount > 1 and icecreamSlot == 0 then
                    icecreamSlot = slot
                    icecreamBag =  bag
                end
            end
            if itemID == nil and freeSlot == 0 then
                freeSlot = slot
                freeSlotBag = bag
            end
        end
    end
    if icecreamSlot ~= 0 and freeSlot ~= 0 then
        SplitContainerItem(icecreamBag, icecreamSlot, 1)
        PickupContainerItem(freeSlotBag, freeSlot)
        return true
    end
    return false
end