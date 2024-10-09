-- DungeonSettingsUI.lua

-- 네임스페이스에서 데이터 가져오기
local DefaultDungeonSettings = MythicDungeonCheckListData.DefaultDungeonSettings

-- 네임스페이스 가져오기
local MythicDungeonCheckList = _G["MythicDungeonCheckList"]

-- ElvUI 통합을 위한 변수 선언
local E, L, V, P, G

if IsAddOnLoaded("ElvUI") then
    E, L, V, P, G = unpack(ElvUI)
end

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

-- 필수 해제 옵션 생성 함수
local function CreateMustHaveOption(name, yOffset, parent)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 20, yOffset)
    check.text:SetText(name .. " 해제 필요")

    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetPoint("TOPLEFT", check, "TOPLEFT", 250, 0)
    input:SetSize(30, 30)
    input:SetNumeric(true)
    input:SetAutoFocus(false)

    return check, input
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

    -- ElvUI 스킨 적용
    if E then
        local S = E:GetModule('Skins')
        S:HandleFrame(settingsFrame)
    end

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
    title:SetText("던전 설정")

    -- 던전 선택 드롭다운
    local dungeonDropdown = CreateFrame("Frame", "DungeonDropdown", settingsFrame, "UIDropDownMenuTemplate")
    dungeonDropdown:SetPoint("TOPLEFT", 20, -50)

    UIDropDownMenu_SetWidth(dungeonDropdown, 180)
    UIDropDownMenu_SetText(dungeonDropdown, "던전을 선택하세요")

    -- ElvUI 스킨 적용
    if E then
        local S = E:GetModule('Skins')
        S:HandleDropDownBox(dungeonDropdown)
    end

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

    -- 필수 해제 옵션 생성
    local mustHaveCurseCheck, mustHaveCurseInput = CreateMustHaveOption("저주", -100, settingsFrame)
    local mustHaveMagicCheck, mustHaveMagicInput = CreateMustHaveOption("마법", -130, settingsFrame)
    local mustHavePoisonCheck, mustHavePoisonInput = CreateMustHaveOption("독", -160, settingsFrame)
    local mustHaveDiseaseCheck, mustHaveDiseaseInput = CreateMustHaveOption("질병", -190, settingsFrame)
    local mustHaveEnrageCheck, mustHaveEnrageInput = CreateMustHaveOption("격노", -220, settingsFrame)

    -- 근접 유닛 최대 수 (탱커 포함) 체크박스
    local maxMeleeUnitsCheck = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    maxMeleeUnitsCheck:SetPoint("TOPLEFT", 20, -260)
    maxMeleeUnitsCheck.text:SetText("최대 근접 유닛 수 (탱커 포함)")

    local maxMeleeUnitsInput = CreateFrame("EditBox", nil, settingsFrame, "InputBoxTemplate")
    maxMeleeUnitsInput:SetPoint("TOPLEFT", maxMeleeUnitsCheck, "TOPLEFT", 250, 0)
    maxMeleeUnitsInput:SetSize(30, 30)
    maxMeleeUnitsInput:SetNumeric(true)
    maxMeleeUnitsInput:SetAutoFocus(false)

    -- 원거리 유닛 최대 수 체크박스
    local maxRangedUnitsCheck = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    maxRangedUnitsCheck:SetPoint("TOPLEFT", 20, -290)
    maxRangedUnitsCheck.text:SetText("최대 원거리 유닛 수")

    local maxRangedUnitsInput = CreateFrame("EditBox", nil, settingsFrame, "InputBoxTemplate")
    maxRangedUnitsInput:SetPoint("TOPLEFT", maxRangedUnitsCheck, "TOPLEFT", 250, 0)
    maxRangedUnitsInput:SetSize(30, 30)
    maxRangedUnitsInput:SetNumeric(true)
    maxRangedUnitsInput:SetAutoFocus(false)

    -- UI 요소들을 저장
    UIElements.mustHaveCurseCheck = mustHaveCurseCheck
    UIElements.mustHaveCurseInput = mustHaveCurseInput
    UIElements.mustHaveMagicCheck = mustHaveMagicCheck
    UIElements.mustHaveMagicInput = mustHaveMagicInput
    UIElements.mustHavePoisonCheck = mustHavePoisonCheck
    UIElements.mustHavePoisonInput = mustHavePoisonInput
    UIElements.mustHaveDiseaseCheck = mustHaveDiseaseCheck
    UIElements.mustHaveDiseaseInput = mustHaveDiseaseInput
    UIElements.mustHaveEnrageCheck = mustHaveEnrageCheck
    UIElements.mustHaveEnrageInput = mustHaveEnrageInput
    UIElements.maxMeleeUnitsCheck = maxMeleeUnitsCheck
    UIElements.maxMeleeUnitsInput = maxMeleeUnitsInput
    UIElements.maxRangedUnitsCheck = maxRangedUnitsCheck
    UIElements.maxRangedUnitsInput = maxRangedUnitsInput

    -- ElvUI 스킨 적용 함수
    local function SkinCheckBox(checkBox)
        if E then
            local S = E:GetModule('Skins')
            S:HandleCheckBox(checkBox)
        end
    end

    local function SkinEditBox(editBox)
        if E then
            local S = E:GetModule('Skins')
            S:HandleEditBox(editBox)
        end
    end

    -- 체크박스와 에디트 박스에 스킨 적용
    SkinCheckBox(mustHaveCurseCheck)
    SkinEditBox(mustHaveCurseInput)
    SkinCheckBox(mustHaveMagicCheck)
    SkinEditBox(mustHaveMagicInput)
    SkinCheckBox(mustHavePoisonCheck)
    SkinEditBox(mustHavePoisonInput)
    SkinCheckBox(mustHaveDiseaseCheck)
    SkinEditBox(mustHaveDiseaseInput)
    SkinCheckBox(mustHaveEnrageCheck)
    SkinEditBox(mustHaveEnrageInput)
    SkinCheckBox(maxMeleeUnitsCheck)
    SkinEditBox(maxMeleeUnitsInput)
    SkinCheckBox(maxRangedUnitsCheck)
    SkinEditBox(maxRangedUnitsInput)

    -- 설정 불러오기 함수
    function MythicDungeonCheckList.LoadDungeonSettings(dungeon)
        local settings = MythicDungeonDB[dungeon]
        if not settings then return end

        -- 필수 해제 설정 불러오기
        UIElements.mustHaveCurseCheck:SetChecked(settings.mustHaveCurse > 0)
        UIElements.mustHaveCurseInput:SetText(tostring(settings.mustHaveCurse or 0))

        UIElements.mustHaveMagicCheck:SetChecked(settings.mustHaveMagic > 0)
        UIElements.mustHaveMagicInput:SetText(tostring(settings.mustHaveMagic or 0))

        UIElements.mustHavePoisonCheck:SetChecked(settings.mustHavePoison > 0)
        UIElements.mustHavePoisonInput:SetText(tostring(settings.mustHavePoison or 0))

        UIElements.mustHaveDiseaseCheck:SetChecked(settings.mustHaveDisease > 0)
        UIElements.mustHaveDiseaseInput:SetText(tostring(settings.mustHaveDisease or 0))

        UIElements.mustHaveEnrageCheck:SetChecked(settings.mustHaveEnrage > 0)
        UIElements.mustHaveEnrageInput:SetText(tostring(settings.mustHaveEnrage or 0))

        -- 근접 유닛 설정 불러오기
        if settings.maxMeleeUnits then
            UIElements.maxMeleeUnitsCheck:SetChecked(true)
            UIElements.maxMeleeUnitsInput:SetText(tostring(settings.maxMeleeUnits))
        else
            UIElements.maxMeleeUnitsCheck:SetChecked(false)
            UIElements.maxMeleeUnitsInput:SetText("")
        end

        -- 원거리 유닛 설정 불러오기
        if settings.maxRangedUnits then
            UIElements.maxRangedUnitsCheck:SetChecked(true)
            UIElements.maxRangedUnitsInput:SetText(tostring(settings.maxRangedUnits))
        else
            UIElements.maxRangedUnitsCheck:SetChecked(false)
            UIElements.maxRangedUnitsInput:SetText("")
        end
    end

    -- 저장 버튼
    local saveButton = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    saveButton:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 20, 20)
    saveButton:SetSize(120, 30)
    saveButton:SetText("저장")

    -- ElvUI 스킨 적용
    if E then
        local S = E:GetModule('Skins')
        S:HandleButton(saveButton)
    end

    saveButton:SetScript("OnClick", function()
        if not selectedDungeon then
            print("던전을 선택해주세요.")
            return
        end

        local dungeonSettings = {
            mustHaveCurse = UIElements.mustHaveCurseCheck:GetChecked() and tonumber(UIElements.mustHaveCurseInput:GetText()) or 0,
            mustHaveMagic = UIElements.mustHaveMagicCheck:GetChecked() and tonumber(UIElements.mustHaveMagicInput:GetText()) or 0,
            mustHavePoison = UIElements.mustHavePoisonCheck:GetChecked() and tonumber(UIElements.mustHavePoisonInput:GetText()) or 0,
            mustHaveDisease = UIElements.mustHaveDiseaseCheck:GetChecked() and tonumber(UIElements.mustHaveDiseaseInput:GetText()) or 0,
            mustHaveEnrage = UIElements.mustHaveEnrageCheck:GetChecked() and tonumber(UIElements.mustHaveEnrageInput:GetText()) or 0,
            maxMeleeUnits = UIElements.maxMeleeUnitsCheck:GetChecked() and tonumber(UIElements.maxMeleeUnitsInput:GetText()) or nil,
            maxRangedUnits = UIElements.maxRangedUnitsCheck:GetChecked() and tonumber(UIElements.maxRangedUnitsInput:GetText()) or nil
        }

        -- 설정 저장
        MythicDungeonDB[selectedDungeon] = dungeonSettings
        print(selectedDungeon .. " 설정이 저장되었습니다.")
    end)

    -- 기본값으로 재설정 버튼
    local resetButton = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    resetButton:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -20, 20)
    resetButton:SetSize(120, 30)
    resetButton:SetText("기본값으로 재설정")

    -- ElvUI 스킨 적용
    if E then
        local S = E:GetModule('Skins')
        S:HandleButton(resetButton)
    end

    resetButton:SetScript("OnClick", function()
        if not selectedDungeon then
            print("던전을 선택해주세요.")
            return
        end

        -- 선택한 던전의 설정을 기본값으로 재설정
        MythicDungeonDB[selectedDungeon] = DeepCopyTable(DefaultDungeonSettings[selectedDungeon])
        MythicDungeonCheckList.LoadDungeonSettings(selectedDungeon)
        print(selectedDungeon .. " 설정이 기본값으로 재설정되었습니다.")
    end)

    -- 전체 던전 설정을 기본값으로 재설정 버튼
    local resetAllButton = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    resetAllButton:SetPoint("BOTTOM", settingsFrame, "BOTTOM", 0, 60)
    resetAllButton:SetSize(160, 30)
    resetAllButton:SetText("모두 기본값으로 재설정")

    -- ElvUI 스킨 적용
    if E then
        local S = E:GetModule('Skins')
        S:HandleButton(resetAllButton)
    end

    resetAllButton:SetScript("OnClick", function()
        StaticPopupDialogs["RESET_ALL_CONFIRM"] = {
            text = "모든 던전 설정을 기본값으로 재설정하시겠습니까?",
            button1 = "예",
            button2 = "아니오",
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

-- 프레임 위치 저장 함수 추가
function MythicDungeonCheckList.SaveSettingsFramePosition()
    MythicDungeonCheckListPositions = MythicDungeonCheckListPositions or {}
    if MythicDungeonCheckListSettingsFrame then
        local point, relativeTo, relativePoint, xOfs, yOfs = MythicDungeonCheckListSettingsFrame:GetPoint()
        MythicDungeonCheckListPositions.SettingsFrame = { point, relativePoint, xOfs, yOfs }
    end
end

-- 프레임 위치 로드 함수 추가
function MythicDungeonCheckList.LoadSettingsFramePosition()
    if MythicDungeonCheckListPositions and MythicDungeonCheckListPositions.SettingsFrame then
        local pos = MythicDungeonCheckListPositions.SettingsFrame
        if MythicDungeonCheckListSettingsFrame then
            MythicDungeonCheckListSettingsFrame:ClearAllPoints()
            MythicDungeonCheckListSettingsFrame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
        end
    end
end

-- 슬래시 명령어를 등록하여 설정 UI를 열 수 있도록 합니다.
SLASH_MYTHICDUNGEONCHECKLIST1 = '/mythicdungeonchecklist'
SLASH_MYTHICDUNGEONCHECKLIST2 = '/mdcl'
SlashCmdList['MYTHICDUNGEONCHECKLIST'] = function(msg)
    MythicDungeonCheckList.OpenDungeonSettingsUI()
end
