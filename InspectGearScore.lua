local f = CreateFrame("Frame")

local EQUIP_SLOTS = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18}
local inspectIlvlText, inspectGsText
local charIlvlText, charGsText

local updateTimer = nil

local function GetAverageItemLevel(unit)
    local totalLevel, count = 0, 0
    for _, slotID in ipairs(EQUIP_SLOTS) do
        local itemLink = GetInventoryItemLink(unit, slotID)
        if itemLink then
            local _, _, _, itemLevel = GetItemInfo(itemLink)
            if itemLevel then
                totalLevel = totalLevel + itemLevel
                count = count + 1
            end
        end
    end
    local avg = count > 0 and totalLevel / count or 0
    return avg
end

local function UpdateFrame(frame, unit, iLvlText, gsText)
    if not frame:IsShown() or not UnitIsPlayer(unit) then
        iLvlText:SetText("")
        gsText:SetText("")
        return
    end

    local avgItemLevel = GetAverageItemLevel(unit)
    iLvlText:SetFormattedText("Average ilvl: %.1f", avgItemLevel)

    if GearScore_GetScore then
        local gearScore = GearScore_GetScore(UnitName(unit), unit)

        if not gearScore and GS_Data and GS_Data[GetRealmName()] then
            local playerData = GS_Data[GetRealmName()].Players[UnitName(unit)]
            if playerData then
                gearScore = playerData.GearScore
            end
        end

        if gearScore then
            local r, g, b = GearScore_GetQuality(gearScore)
            gsText:SetText("GearScore: " .. gearScore)
            gsText:SetTextColor(r, b, g)
            return
        end
    end

    gsText:SetText("GearScore: N/A")
    gsText:SetTextColor(1, 1, 1)
end

local function UpdateInspectFrame(unit)
    UpdateFrame(InspectFrame, unit, inspectIlvlText, inspectGsText)
end

local function UpdateCharacterFrame()
    UpdateFrame(CharacterFrame, "player", charIlvlText, charGsText)
end

local function ClearInspectInfo()
    inspectIlvlText:SetText("")
    inspectGsText:SetText("")
end

local function InitializeInspect()
    inspectIlvlText = InspectFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inspectIlvlText:SetPoint("TOPLEFT", InspectHeadSlot, "TOPLEFT", 0, 32)

    inspectGsText = InspectFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inspectGsText:SetPoint("TOPLEFT", inspectIlvlText, "BOTTOMLEFT", 0, -2)

    local originalInspectFrameShow = InspectFrame_Show
    InspectFrame_Show = function(unit)
        originalInspectFrameShow(unit)
        UpdateInspectFrame(unit)
    end

    InspectFrame:HookScript("OnHide", ClearInspectInfo)

    f:UnregisterEvent("ADDON_LOADED")
end

local function InitializePaperDoll()
    charIlvlText = CharacterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charIlvlText:SetPoint("TOP", CharacterLevelText, "BOTTOM", 0, -2)

    charGsText = CharacterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charGsText:SetPoint("TOP", charIlvlText, "BOTTOm", 0, -2)

    UpdateCharacterFrame()
end

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_InspectUI" then
        InitializeInspect()
    elseif event == "PLAYER_ENTERING_WORLD" then
        InitializePaperDoll()

    elseif event == "PLAYER_TARGET_CHANGED" then
        if InspectFrame and InspectFrame:IsShown() and UnitExists("target") then
            if updateTimer then
                updateTimer:Cancel()
            end

            updateTimer = C_Timer.NewTimer(0.2, function()
                UpdateInspectFrame("target")
            end)
        end
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        UpdateCharacterFrame()
    end
end)

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")

CharacterFrame:HookScript("OnShow", UpdateCharacterFrame)