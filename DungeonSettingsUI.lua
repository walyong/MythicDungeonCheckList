-- DungeonSettingsUI.lua

-- 네임스페이스에서 데이터 가져오기
local DefaultDungeonSettings = MythicDungeonCheckListData.DefaultDungeonSettings

-- 네임스페이스 가져오기
local MythicDungeonCheckList = _G["MythicDungeonCheckList"]

-- 테이블 깊은 복사 함수 (MythicDungeonCheckList.lua에서 가져옴)
local function DeepCopyTable(t, seen)
    if type(t) ~= 'table' then return t end
    if not seen then seen = {} end
    if seen[t] then return seen[t] end
    local copy = {}
    seen[t] = copy
    for k, v in pairs(t) do
        copy[DeepCopyTable(k, seen)] = DeepCopyTable(v, seen)
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

-- 던전 설정 UI 생성 함수
function MythicDungeonCheckList.OpenDungeonSettingsUI()
    local settingsFrame = CreateFrame("Frame", "DungeonSettingsUI", UIParent, "BasicFrameTemplate")
    settingsFrame:SetSize(400, 700)
    settingsFrame:SetPoint("CENTER")

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
    mustHaveCurse.text:SetText("Must have Curse Removal")

    local mustHaveMagic = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    mustHaveMagic:SetPoint("TOPLEFT", 20, -130)
    mustHaveMagic.text:SetText("Must have Magic Removal")

    local mustHavePoison = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    mustHavePoison:SetPoint("TOPLEFT", 20, -160)
    mustHavePoison.text:SetText("Must have Poison Removal")

    local mustHaveDisease = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    mustHaveDisease:SetPoint("TOPLEFT", 20, -190)
    mustHaveDisease.text:SetText("Must have Disease Removal")

    -- 격노 해제 체크박스 추가
    local mustHaveEnrage = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    mustHaveEnrage:SetPoint("TOPLEFT", 20, -220)
    mustHaveEnrage.text:SetText("Must have Enrage Dispel")

    -- 근접 유닛 최대 수 (탱커 포함) 체크박스
    local maxMeleeUnitsCheck = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    maxMeleeUnitsCheck:SetPoint("TOPLEFT", 20, -250)
    maxMeleeUnitsCheck.text:SetText("Max Melee Units (including Tanks)")

    local maxMeleeUnitsInput = CreateFrame("EditBox", nil, settingsFrame, "InputBoxTemplate")
    maxMeleeUnitsInput:SetPoint("TOPLEFT", maxMeleeUnitsCheck, "TOPLEFT", 250, 0)
    maxMeleeUnitsInput:SetSize(30, 30)
    maxMeleeUnitsInput:SetNumeric(true)
    maxMeleeUnitsInput:SetAutoFocus(false)

    -- 원거리 유닛 최대 수 체크박스
    local maxRangedUnitsCheck = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    maxRangedUnitsCheck:SetPoint("TOPLEFT", 20, -280)
    maxRangedUnitsCheck.text:SetText("Max Ranged Units")

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
end

-- 네임스페이스를 전역 변수로 설정 (다른 파일에서 접근할 수 있도록)
_G["MythicDungeonCheckList"] = MythicDungeonCheckList
