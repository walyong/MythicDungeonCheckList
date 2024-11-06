-- MythicDungeonCheckList.lua

-- 네임스페이스 생성
local MythicDungeonCheckList = {}

-- 네임스페이스에서 데이터 가져오기
local DefaultDungeonSettings = MythicDungeonCheckListData.DefaultDungeonSettings

-- 테이블 깊은 복사 함수 (지역 함수로 정의하고 이름 변경)
local function DeepCopyTable(t, seen)
    if type(t) ~= 'table' then
        return t
    end
    if seen and seen[t] then
        return seen[t]
    end
    local s = seen or {}
    local copy = {}
    s[t] = copy
    for k, v in pairs(t) do
        copy[DeepCopyTable(k, s)] = DeepCopyTable(v, s)
    end
    return setmetatable(copy, getmetatable(t))
end

-- 체크리스트 항목 생성 함수 (지역 함수로 정의하고 전역으로 노출)
function CreateCheckListItem(parent, text, index)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 20, -30 * index)
    check.text:SetText(text)
    check:Disable()
    return check
end
_G.CreateCheckListItem = CreateCheckListItem

function MythicDungeonCheckList.InitializeDungeonSettings()
    MythicDungeonDB = MythicDungeonDB or {}
    for dungeonName, settings in pairs(DefaultDungeonSettings) do
        if not MythicDungeonDB[dungeonName] then
            MythicDungeonDB[dungeonName] = DeepCopyTable(settings)
        else
            -- 기존 설정에 새로운 해제 유형이 없으면 기본값으로 추가
            for key, value in pairs(settings) do
                if MythicDungeonDB[dungeonName][key] == nil then
                    MythicDungeonDB[dungeonName][key] = value
                end
            end
        end
    end
end

-- 해제 특성 확인 함수
local function CheckDispelTalents(unit, dispelType)
    local _, class = UnitClass(unit)

    if dispelType == "Curse" then
        if class == "MAGE" and not IsSpellKnown(475, unit) then
            print(UnitName(unit) .. "님, 저주 해제를 위한 특성을 찍지 않았습니다.")
        elseif class == "DRUID" and not IsSpellKnown(2782, unit) then
            print(UnitName(unit) .. "님, 저주 해제를 위한 특성을 찍지 않았습니다.")
        elseif class == "SHAMAN" and not IsSpellKnown(51886, unit) then
            print(UnitName(unit) .. "님, 저주 해제를 위한 특성을 찍지 않았습니다.")
        end
    elseif dispelType == "Magic" then
        if class == "PRIEST" and not IsSpellKnown(527, unit) then
            print(UnitName(unit) .. "님, 마법 해제를 위한 특성을 찍지 않았습니다.")
        elseif class == "PALADIN" and not IsSpellKnown(4987, unit) then
            print(UnitName(unit) .. "님, 마법 해제를 위한 특성을 찍지 않았습니다.")
        elseif class == "DRUID" and not IsSpellKnown(2782, unit) then
            print(UnitName(unit) .. "님, 마법 해제를 위한 특성을 찍지 않았습니다.")
        end
    elseif dispelType == "Poison" then
        if class == "DRUID" and not IsSpellKnown(2782, unit) then
            print(UnitName(unit) .. "님, 독 해제를 위한 특성을 찍지 않았습니다.")
        elseif class == "SHAMAN" and not IsSpellKnown(51886, unit) then
            print(UnitName(unit) .. "님, 독 해제를 위한 특성을 찍지 않았습니다.")
        end
    elseif dispelType == "Disease" then
        if class == "PRIEST" and not IsSpellKnown(527, unit) then
            print(UnitName(unit) .. "님, 질병 해제를 위한 특성을 찍지 않았습니다.")
        elseif class == "PALADIN" and not IsSpellKnown(4987, unit) then
            print(UnitName(unit) .. "님, 질병 해제를 위한 특성을 찍지 않았습니다.")
        end
    end
end

-- 체크리스트 업데이트 함수
function MythicDungeonCheckList.UpdateCheckList(dungeonName)
    local settings = MythicDungeonDB[dungeonName]
    if not settings then
        return
    end

    local checklist = ChecklistUI

    -- 기존 체크리스트 항목 제거
    if checklist.items then
        for _, item in ipairs(checklist.items) do
            item:Hide()
        end
    end
    checklist.items = {}

    local index = 1

    index = MythicDungeonCheckListClassData.CheckHeroismAndBattleRes(checklist, index)
    index = MythicDungeonCheckListClassData.CheckCurseRemoval(checklist, index, settings)
    index = MythicDungeonCheckListClassData.CheckMagicRemoval(checklist, index, settings)
    index = MythicDungeonCheckListClassData.CheckPoisonRemoval(checklist, index, settings)
    index = MythicDungeonCheckListClassData.CheckDiseaseRemoval(checklist, index, settings)
    index = MythicDungeonCheckListClassData.CheckEnrageRemoval(checklist, index, settings)
    index = MythicDungeonCheckListClassData.CheckWeeklyAffix160(checklist, index)
    index = MythicDungeonCheckListClassData.CheckUnitComposition(checklist, index, settings)
end

-- 프레임 위치 저장 함수 추가
function MythicDungeonCheckList.SaveFramePositions()
    MythicDungeonCheckListPositions = MythicDungeonCheckListPositions or {}
    if ChecklistUI then
        local point, relativeTo, relativePoint, xOfs, yOfs = ChecklistUI:GetPoint()
        MythicDungeonCheckListPositions.ChecklistUI = { point, relativePoint, xOfs, yOfs }
    end
end

-- 프레임 위치 로드 함수 추가
function MythicDungeonCheckList.LoadFramePositions()
    if MythicDungeonCheckListPositions and MythicDungeonCheckListPositions.ChecklistUI then
        local pos = MythicDungeonCheckListPositions.ChecklistUI
        if ChecklistUI then
            ChecklistUI:ClearAllPoints()
            ChecklistUI:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
        end
    end
end

-- 체크리스트 UI 생성 함수
function MythicDungeonCheckList.OpenCheckListUI(dungeonName)
    if not dungeonName then
        print("MythicDungeonCheckList: Dungeon name is required to open checklist.")
        return
    end

    if ChecklistUI and ChecklistUI:IsShown() then
        -- 이미 열려 있는 경우 앞으로 가져오기
        ChecklistUI:SetFrameLevel(100)
        return
    end

    -- 체크리스트 UI 생성
    ChecklistUI = CreateFrame("Frame", "ChecklistUI", UIParent, "BasicFrameTemplate")
    ChecklistUI:SetSize(300, 500)
    ChecklistUI:SetPoint("CENTER")
    ChecklistUI.items = {}  -- 체크 항목을 저장할 테이블

    -- 프레임을 움직일 수 있도록 설정
    ChecklistUI:SetMovable(true)
    ChecklistUI:EnableMouse(true)
    ChecklistUI:RegisterForDrag("LeftButton")
    ChecklistUI:SetScript("OnDragStart", ChecklistUI.StartMoving)
    ChecklistUI:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- 프레임 위치 저장
        MythicDungeonCheckList.SaveFramePositions()
    end)
    ChecklistUI:SetClampedToScreen(true)

    -- 프레임의 Strata를 설정하여 다른 UI 위로 가져오기
    ChecklistUI:SetFrameStrata("DIALOG")

    local title = ChecklistUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", ChecklistUI, "TOP", 0, -10)
    title:SetText(dungeonName .. " Checklist")

    -- 이벤트 프레임 생성
    ChecklistUI.eventFrame = CreateFrame("Frame")
    ChecklistUI.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    ChecklistUI.eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    ChecklistUI.eventFrame:RegisterEvent("INSPECT_READY")
    ChecklistUI.eventFrame:SetScript("OnEvent", function(self, event, arg1)
        MythicDungeonCheckList.UpdateCheckList(dungeonName)
    end)

    -- 체크리스트 업데이트
    MythicDungeonCheckList.UpdateCheckList(dungeonName)

    -- 프레임 위치 로드
    MythicDungeonCheckList.LoadFramePositions()
end

-- 게임 시작 시 기본 던전 설정 초기화 및 프레임 위치 로드
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    MythicDungeonCheckList.InitializeDungeonSettings()  -- 던전 기본 설정 초기화
    MythicDungeonCheckList.LoadFramePositions()         -- 프레임 위치 로드
end)

-- 이벤트 프레임 생성
local eventFrame = CreateFrame("Frame")

-- 이벤트 등록
eventFrame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        local entryInfo = C_LFGList.GetActiveEntryInfo()
        if entryInfo then
            -- 파티가 등록되었으면 UI를 열기
            MythicDungeonCheckList:OnPartyListed()
        else
            -- 파티 모집이 중단된 경우 UI 닫기
            MythicDungeonCheckList.CloseCheckListUI()
        end
    end
end)

-- 파티 등록 시 호출되는 함수
function MythicDungeonCheckList:OnPartyListed()
    -- 파티 등록 정보 가져오기
    local entryInfo = C_LFGList.GetActiveEntryInfo()
    if not entryInfo then
        return
    end

    -- 활동 ID 가져오기
    local activityID = entryInfo.activityID

    -- 활동 ID를 사용하여 던전 이름 가져오기
    local dungeonName = MythicDungeonCheckListData.activityIDToDungeonName[activityID]
    if not dungeonName then
        return
    end

    -- 던전 이름이 유효한지 확인
    if not MythicDungeonDB[dungeonName] then
        return
    end

    -- 체크리스트 UI 열기
    MythicDungeonCheckList.OpenCheckListUI(dungeonName)
end

-- 체크리스트 UI 닫기 함수 추가
function MythicDungeonCheckList.CloseCheckListUI()
    if ChecklistUI and ChecklistUI:IsShown() then
        ChecklistUI:Hide()  -- UI 닫기
    end
end

-- 네임스페이스를 전역 변수로 설정 (다른 파일에서 접근할 수 있도록)
_G["MythicDungeonCheckList"] = MythicDungeonCheckList
print("MythicDungeonCheckList.lua loaded")
