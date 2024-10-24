-- DungeonSettingsUI.lua

-- 네임스페이스에서 데이터 가져오기
local DefaultDungeonSettings = MythicDungeonCheckListData.DefaultDungeonSettings

-- 네임스페이스 가져오기
local MythicDungeonCheckList = _G["MythicDungeonCheckList"]

-- 테이블 깊은 복사 함수 (MythicDungeonCheckList.lua에서 가져옴)
local function DeepCopyTable(t, seen)
    if type(t) ~= 'table' then return t end
    if seen and seen[t] then return seen[t] end
    local s = seen or {}
    local copy = {}
    s[t] = copy
    for k, v in pairs(t) do
        copy[DeepCopyTable(k, s)] = DeepCopyTable(v, s)
    end
    return setmetatable(copy, getmetatable(t))
end

-- 필요한 변수들을 저장할 테이블
local UIElements = {}

-- 설정 불러오기 함수 (네임스페이스에 추가)
function MythicDungeonCheckList.LoadDungeonSettings(dungeon)
    local settings = MythicDungeonDB[dungeon]
    if not settings then return end

    local mustHaveCurse = UIElements.mustHaveCurse
    local mustHaveMagic = UIElements.mustHaveMagic
    local mustHavePoison = UIElements.mustHavePoison
    local mustHaveDisease = UIElements.mustHaveDisease
    local mustHaveEnrage = UIElements.mustHaveEnrage
    local maxMeleeUnitsCheck = UIElements.maxMeleeUnitsCheck
    local maxMeleeUnitsInput = UIElements.maxMeleeUnitsInput
    local maxRangedUnitsCheck = UIElements.maxRangedUnitsCheck
    local maxRangedUnitsInput = UIElements.maxRangedUnitsInput

    mustHaveCurse:SetChecked(settings.mustHaveCurse == 1)
    mustHaveMagic:SetChecked(settings.mustHaveMagic == 1)
    mustHavePoison:SetChecked(settings.mustHavePoison == 1)
    mustHaveDisease:SetChecked(settings.mustHaveDisease == 1)
    mustHaveEnrage:SetChecked(settings.mustHaveEnrage == 1)

    if settings.maxMeleeUnits then
        maxMeleeUnitsCheck:SetChecked(true)
        maxMeleeUnitsInput:SetText(tostring(settings.maxMeleeUnits))
    else
        maxMeleeUnitsCheck:SetChecked(false)
        maxMeleeUnitsInput:SetText("")
    end

    if settings.maxRangedUnits then
        maxRangedUnitsCheck:SetChecked(true)
        maxRangedUnitsInput:SetText(tostring(settings.maxRangedUnits))
    else
        maxRangedUnitsCheck:SetChecked(false)
        maxRangedUnitsInput:SetText("")
    end
end

-- 프레임 위치 저장 함수 추가 (MythicDungeonCheckList 네임스페이스에 추가)
function MythicDungeonCheckList.SaveSettingsFramePosition()
    MythicDungeonCheckListPositions = MythicDungeonCheckListPositions or {}
    if MythicDungeonCheckListSettingsFrame then
        local point, relativeTo, relativePoint, xOfs, yOfs = MythicDungeonCheckListSettingsFrame:GetPoint()
        MythicDungeonCheckListPositions.SettingsFrame = { point, relativePoint, xOfs, yOfs }
    end
end

-- 프레임 위치 로드 함수 추가 (MythicDungeonCheckList 네임스페이스에 추가)
function MythicDungeonCheckList.LoadSettingsFramePosition()
    if MythicDungeonCheckListPositions and MythicDungeonCheckListPositions.SettingsFrame then
        local pos = MythicDungeonCheckListPositions.SettingsFrame
        if MythicDungeonCheckListSettingsFrame then
            MythicDungeonCheckListSettingsFrame:ClearAllPoints()
            MythicDungeonCheckListSettingsFrame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
        end
    end
end

-- 던전 설정 UI 생성 함수
function MythicDungeonCheckList.OpenDungeonSettingsUI()
    -- 이미 열려 있는 경우 포커스를 이동합니다.
    if MythicDungeonCheckListSettingsFrame and MythicDungeonCheckListSettingsFrame:IsShown() then
        MythicDungeonCheckListSettingsFrame:SetFrameLevel(100)  -- 가장 위로 가져오기
        return
    end

    local settingsFrame = CreateFrame("Frame", "MythicDungeonCheckListSettingsFrame", UIParent, "BasicFrameTemplate")
    settingsFrame:SetSize(400, 700)
    settingsFrame:SetPoint("CENTER")

    -- 프레임을 움직일 수 있도록 설정
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- 프레임 위치 저장
        MythicDungeonCheckList.SaveSettingsFramePosition()
    end)
    settingsFrame:SetClampedToScreen(true)

    -- 프레임의 Strata를 설정하여 다른 UI 위로 가져오기
    settingsFrame:SetFrameStrata("DIALOG")

    local title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", settingsFrame, "TOP", 0, -10)
    title:SetText("Dungeon Settings")

    -- 던전 선택 드롭다운
    local dungeonDropdown = CreateFrame("Frame", "DungeonDropdown", settingsFrame, "UIDropDownMenuTemplate")
    dungeonDropdown:SetPoint("TOPLEFT", 20, -50)

    UIDropDownMenu_SetWidth(dungeonDropdown, 180)
    UIDropDownMenu_SetText(dungeonDropdown, "Select Dungeon")

    -- 현재 선택된 던전 이름을 저장할 변수
    local selectedDungeon

    -- 던전 선택 리스트 업데이트
    local dungeonList = {}
    for dungeonName, _ in pairs(DefaultDungeonSettings) do
        table.insert(dungeonList, dungeonName)
    end

    table.sort(dungeonList)  -- 알파벳 순으로 정렬

    UIDropDownMenu_Initialize(dungeonDropdown, function(self, level, menuList)
        for i, dungeon in ipairs(dungeonList) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = dungeon
            info.func = function()
                UIDropDownMenu_SetSelectedID(dungeonDropdown, i)
                UIDropDownMenu_SetText(dungeonDropdown, dungeon)
                selectedDungeon = dungeon
                MythicDungeonCheckList.LoadDungeonSettings(dungeon)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- 필수 해제 체크박스
    local mustHaveCurse = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    mustHaveCurse:SetPoint("TOPLEFT", 20, -100)
    mustHaveCurse.text:SetText("저주 해제")

    local mustHaveMagic = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    mustHaveMagic:SetPoint("TOPLEFT", 20, -130)
    mustHaveMagic.text:SetText("마법 해제")

    local mustHavePoison = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    mustHavePoison:SetPoint("TOPLEFT", 20, -160)
    mustHavePoison.text:SetText("독 해제")

    local mustHaveDisease = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    mustHaveDisease:SetPoint("TOPLEFT", 20, -190)
    mustHaveDisease.text:SetText("질병 해제")

    -- 격노 해제 체크박스 추가
    local mustHaveEnrage = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    mustHaveEnrage:SetPoint("TOPLEFT", 20, -220)
    mustHaveEnrage.text:SetText("격노 해제")

    -- 근접 유닛 최대 수 (탱커 포함) 체크박스
    local maxMeleeUnitsCheck = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    maxMeleeUnitsCheck:SetPoint("TOPLEFT", 20, -250)
    maxMeleeUnitsCheck.text:SetText("최대 근접 유닛 (탱커 포함)")

    local maxMeleeUnitsInput = CreateFrame("EditBox", nil, settingsFrame, "InputBoxTemplate")
    maxMeleeUnitsInput:SetPoint("TOPLEFT", maxMeleeUnitsCheck, "TOPLEFT", 250, 0)
    maxMeleeUnitsInput:SetSize(30, 30)
    maxMeleeUnitsInput:SetNumeric(true)
    maxMeleeUnitsInput:SetAutoFocus(false)

    -- 원거리 유닛 최대 수 체크박스
    local maxRangedUnitsCheck = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    maxRangedUnitsCheck:SetPoint("TOPLEFT", 20, -280)
    maxRangedUnitsCheck.text:SetText("최대 원거리 유닛")

    local maxRangedUnitsInput = CreateFrame("EditBox", nil, settingsFrame, "InputBoxTemplate")
    maxRangedUnitsInput:SetPoint("TOPLEFT", maxRangedUnitsCheck, "TOPLEFT", 250, 0)
    maxRangedUnitsInput:SetSize(30, 30)
    maxRangedUnitsInput:SetNumeric(true)
    maxRangedUnitsInput:SetAutoFocus(false)

    -- UI 요소들을 저장
    UIElements.mustHaveCurse = mustHaveCurse
    UIElements.mustHaveMagic = mustHaveMagic
    UIElements.mustHavePoison = mustHavePoison
    UIElements.mustHaveDisease = mustHaveDisease
    UIElements.mustHaveEnrage = mustHaveEnrage
    UIElements.maxMeleeUnitsCheck = maxMeleeUnitsCheck
    UIElements.maxMeleeUnitsInput = maxMeleeUnitsInput
    UIElements.maxRangedUnitsCheck = maxRangedUnitsCheck
    UIElements.maxRangedUnitsInput = maxRangedUnitsInput

    -- 저장 버튼
    local saveButton = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    saveButton:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 20, 20)
    saveButton:SetSize(120, 30)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        if not selectedDungeon then
            print("Please select a dungeon.")
            return
        end

        local dungeonSettings = {
            mustHaveCurse = mustHaveCurse:GetChecked() and 1 or 0,
            mustHaveMagic = mustHaveMagic:GetChecked() and 1 or 0,
            mustHavePoison = mustHavePoison:GetChecked() and 1 or 0,
            mustHaveDisease = mustHaveDisease:GetChecked() and 1 or 0,
            mustHaveEnrage = mustHaveEnrage:GetChecked() and 1 or 0,
            maxMeleeUnits = maxMeleeUnitsCheck:GetChecked() and tonumber(maxMeleeUnitsInput:GetText()) or nil,
            maxRangedUnits = maxRangedUnitsCheck:GetChecked() and tonumber(maxRangedUnitsInput:GetText()) or nil
        }

        -- 설정 저장
        MythicDungeonDB[selectedDungeon] = dungeonSettings
        print("Settings saved for " .. selectedDungeon)
    end)

    -- 기본값으로 재설정 버튼
    local resetButton = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    resetButton:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -20, 20)
    resetButton:SetSize(120, 30)
    resetButton:SetText("Reset to Default")
    resetButton:SetScript("OnClick", function()
        if not selectedDungeon then
            print("Please select a dungeon.")
            return
        end

        -- 선택한 던전의 설정을 기본값으로 재설정
        MythicDungeonDB[selectedDungeon] = DeepCopyTable(DefaultDungeonSettings[selectedDungeon])
        MythicDungeonCheckList.LoadDungeonSettings(selectedDungeon)
        print(selectedDungeon .. " settings have been reset to default.")
    end)

    -- 전체 던전 설정을 기본값으로 재설정 버튼
    local resetAllButton = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    resetAllButton:SetPoint("BOTTOM", settingsFrame, "BOTTOM", 0, 60)
    resetAllButton:SetSize(160, 30)
    resetAllButton:SetText("Reset All to Default")
    resetAllButton:SetScript("OnClick", function()
        StaticPopupDialogs["RESET_ALL_CONFIRM"] = {
            text = "Are you sure you want to reset all dungeon settings to default values?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                MythicDungeonCheckList.ResetDungeonSettings()
                if selectedDungeon then
                    MythicDungeonCheckList.LoadDungeonSettings(selectedDungeon)
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("RESET_ALL_CONFIRM")
    end)

    -- 프레임 위치 로드
    MythicDungeonCheckList.LoadSettingsFramePosition()
end

-- 슬래시 명령어를 등록하여 설정 UI를 열 수 있도록 합니다.
SLASH_MYTHICDUNGEONCHECKLIST1 = '/mythicdungeonchecklist'
SLASH_MYTHICDUNGEONCHECKLIST2 = '/mdcl'
SlashCmdList['MYTHICDUNGEONCHECKLIST'] = function(msg)
    MythicDungeonCheckList.OpenDungeonSettingsUI()
end
