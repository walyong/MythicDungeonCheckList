-- MythicDungeonCheckList.lua

-- 네임스페이스 생성
local MythicDungeonCheckList = {}

-- 네임스페이스에서 데이터 가져오기
local DefaultDungeonSettings = MythicDungeonCheckListData.DefaultDungeonSettings

-- 테이블 깊은 복사 함수 (지역 함수로 정의하고 이름 변경)
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

-- 체크리스트 항목 생성 함수 (지역 함수로 정의)
local function CreateCheckListItem(parent, text, index)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 20, -30 * index)
    check.text:SetText(text)
    check:Disable()
    return check
end

-- 근접 힐러 확인 함수 (지역 함수로 정의)
local function IsMeleeHealer(class, spec)
    return (class == "PALADIN" and spec == 65) or    -- 신성 성기사
           (class == "MONK" and spec == 270)         -- 운무 수도사
end

-- 원거리 힐러 확인 함수 (지역 함수로 정의)
local function IsRangedHealer(class, spec)
    return (class == "DRUID" and spec == 105) or           -- 회복 드루이드
           (class == "PRIEST" and (spec == 256 or spec == 257)) or  -- 수양 및 신성 사제
           (class == "SHAMAN" and spec == 264) or           -- 복원 주술사
           (class == "EVOKER" and spec == 1468)             -- Preservation Evoker
end

-- 근접 딜러 확인 함수 (지역 함수로 정의)
local function IsMeleeDPS(class, spec)
    local meleeClasses = {
        ["DEATHKNIGHT"] = {250, 251, 252}, -- 혈기, 냉기, 부정
        ["DEMONHUNTER"] = {577},           -- 파멸
        ["DRUID"] = {103},                 -- 야성
        ["HUNTER"] = {255},                -- 생존
        ["MONK"] = {269},                  -- 풍운
        ["PALADIN"] = {70},                -- 징벌
        ["ROGUE"] = {259, 260, 261},       -- 모든 특성
        ["SHAMAN"] = {263},                -- 고양
        ["WARRIOR"] = {71, 72}             -- 무기, 분노
    }
    return meleeClasses[class] and tContains(meleeClasses[class], spec)
end

-- 원거리 딜러 확인 함수 (지역 함수로 정의)
local function IsRangedDPS(class, spec)
    local rangedClasses = {
        ["DRUID"] = {102},                 -- 조화
        ["HUNTER"] = {253, 254},           -- 야수, 사격
        ["MAGE"] = {62, 63, 64},           -- 모든 특성
        ["PRIEST"] = {258},                -- 암흑
        ["SHAMAN"] = {262},                -- 정기
        ["WARLOCK"] = {265, 266, 267},     -- 모든 특성
        ["EVOKER"] = {1473}                -- Devastation
    }
    return rangedClasses[class] and tContains(rangedClasses[class], spec)
end

-- 격노 해제를 할 수 있는지 확인하는 함수 (지역 함수로 정의)
local function CanDispelEnrage(class)
    return (class == "HUNTER" and IsSpellKnown(19801)) or   -- 사냥꾼 - 평정의 사격
           (class == "DRUID" and IsSpellKnown(2908)) or     -- 드루이드 - 달래기
           (class == "ROGUE" and IsSpellKnown(5938)) or     -- 도적 - 마취의 일격
           (class == "EVOKER" and IsSpellKnown(374227))     -- 기원사 - 억제의 포효
end

-- 기본 던전 설정을 적용하는 함수
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

-- 기본 설정으로 재설정하는 함수
function MythicDungeonCheckList.ResetDungeonSettings()
    MythicDungeonDB = {}
    MythicDungeonCheckList.InitializeDungeonSettings()
    print("All dungeon settings have been reset to default values.")
end

-- 체크리스트 업데이트 함수
function MythicDungeonCheckList.UpdateCheckList(dungeonName)
    print("UpdateCheckList: Updating Checklist for", dungeonName)
    local settings = MythicDungeonDB[dungeonName]
    if not settings then
        print("UpdateCheckList: No settings found for dungeon", dungeonName)
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

    local index = 1  -- 항목 순서를 위한 변수

    -- 1. 영웅심과 전투부활 체크 (우선순위 1)
    local heroismCheck = CreateCheckListItem(checklist, "Heroism Required", index)
    local battleResCheck = CreateCheckListItem(checklist, "Battle Res Required", index + 1)

    -- 영웅심 및 전투부활 스킬 확인
    local hasHeroism, hasBattleRes = false, false
    for i = 1, GetNumGroupMembers() do
        local unit = (i == GetNumGroupMembers()) and "player" or "party"..i
        local _, class = UnitClass(unit)
        if class == "SHAMAN" or class == "MAGE" or class == "HUNTER" or class == "EVOKER" then
            hasHeroism = true
        end
        if class == "DRUID" or class == "DEATHKNIGHT" or class == "WARLOCK" or class == "EVOKER" then
            hasBattleRes = true
        end
    end

    heroismCheck:SetChecked(hasHeroism)
    battleResCheck:SetChecked(hasBattleRes)

    checklist.items[index] = heroismCheck
    checklist.items[index + 1] = battleResCheck

    index = index + 2  -- 다음 체크리스트 시작 지점 설정

    -- 2. 던전별 해제 직업 체크 (우선순위 2)

    -- 저주 해제 체크
    if settings.mustHaveCurse > 0 then
        local curseRemovalCheck = CreateCheckListItem(checklist, "Curse Removal (Must Have)", index)
        local curseRemovalCount = 0
        for i = 1, GetNumGroupMembers() do
            local unit = (i == GetNumGroupMembers()) and "player" or "party"..i
            local _, class = UnitClass(unit)
            if class == "MAGE" or class == "DRUID" or class == "SHAMAN" then
                curseRemovalCount = curseRemovalCount + 1
            end
        end
        -- 파티 내 해제 가능한 직업 수가 던전에서 요구하는 수를 만족하는지 확인
        curseRemovalCheck:SetChecked(curseRemovalCount >= settings.mustHaveCurse)
        checklist.items[index] = curseRemovalCheck
        index = index + 1
    end

    -- 마법 해제 체크
    if settings.mustHaveMagic > 0 then
        local magicRemovalCheck = CreateCheckListItem(checklist, "Magic Removal (Must Have)", index)
        local magicRemovalCount = 0
        for i = 1, GetNumGroupMembers() do
            local unit = (i == GetNumGroupMembers()) and "player" or "party"..i
            local _, class = UnitClass(unit)
            if class == "PRIEST" or class == "SHAMAN" or class == "DRUID" or class == "PALADIN" or class == "MONK" or class == "EVOKER" then
                magicRemovalCount = magicRemovalCount + 1
            end
        end
        magicRemovalCheck:SetChecked(magicRemovalCount >= settings.mustHaveMagic)
        checklist.items[index] = magicRemovalCheck
        index = index + 1
    end

    -- 독 해제 체크
    if settings.mustHavePoison > 0 then
        local poisonRemovalCheck = CreateCheckListItem(checklist, "Poison Removal (Must Have)", index)
        local poisonRemovalCount = 0
        for i = 1, GetNumGroupMembers() do
            local unit = (i == GetNumGroupMembers()) and "player" or "party"..i
            local _, class = UnitClass(unit)
            if class == "DRUID" or class == "SHAMAN" or class == "PALADIN" or class == "MONK" or class == "EVOKER" then
                poisonRemovalCount = poisonRemovalCount + 1
            end
        end
        poisonRemovalCheck:SetChecked(poisonRemovalCount >= settings.mustHavePoison)
        checklist.items[index] = poisonRemovalCheck
        index = index + 1
    end

    -- 질병 해제 체크
    if settings.mustHaveDisease > 0 then
        local diseaseRemovalCheck = CreateCheckListItem(checklist, "Disease Removal (Must Have)", index)
        local diseaseRemovalCount = 0
        for i = 1, GetNumGroupMembers() do
            local unit = (i == GetNumGroupMembers()) and "player" or "party"..i
            local _, class = UnitClass(unit)
            if class == "PRIEST" or class == "PALADIN" or class == "MONK" then
                diseaseRemovalCount = diseaseRemovalCount + 1
            end
        end
        diseaseRemovalCheck:SetChecked(diseaseRemovalCount >= settings.mustHaveDisease)
        checklist.items[index] = diseaseRemovalCheck
        index = index + 1
    end

    -- 격노 해제 체크
    if settings.mustHaveEnrage > 0 then
        local enrageRemovalCheck = CreateCheckListItem(checklist, "Enrage Dispel (Must Have)", index)
        local enrageRemovalCount = 0
        for i = 1, GetNumGroupMembers() do
            local unit = (i == GetNumGroupMembers()) and "player" or "party"..i
            local _, class = UnitClass(unit)
            if CanDispelEnrage(class) then
                enrageRemovalCount = enrageRemovalCount + 1
            end
        end
        enrageRemovalCheck:SetChecked(enrageRemovalCount >= settings.mustHaveEnrage)
        checklist.items[index] = enrageRemovalCheck
        index = index + 1
    end

    -- 3. 근거리/원거리 유닛 구성 체크 (우선순위 3)
    local meleeCount, rangedCount = 0, 0

    for i = 1, GetNumGroupMembers() do
        local unit = (i == GetNumGroupMembers()) and "player" or "party"..i
        local role = UnitGroupRolesAssigned(unit)
        local _, class = UnitClass(unit)
        local spec = GetInspectSpecialization(unit)

        if role == "TANK" then
            meleeCount = meleeCount + 1  -- 탱커는 근접으로 포함
        elseif role == "HEALER" then
            if IsMeleeHealer(class, spec) then
                meleeCount = meleeCount + 1  -- 근접 힐러
            elseif IsRangedHealer(class, spec) then
                rangedCount = rangedCount + 1  -- 원거리 힐러
            end
        elseif role == "DAMAGER" then
            if IsMeleeDPS(class, spec) then
                meleeCount = meleeCount + 1  -- 근접 딜러
            elseif IsRangedDPS(class, spec) then
                rangedCount = rangedCount + 1  -- 원거리 딜러
            end
        end
    end

    -- 근접 유닛 제한 체크
    if settings.maxMeleeUnits then
        local meleeLimitCheck = CreateCheckListItem(checklist, "Max Melee Units (incl. Tanks)", index)
        meleeLimitCheck:SetChecked(meleeCount <= settings.maxMeleeUnits)
        checklist.items[index] = meleeLimitCheck
        index = index + 1
    end

    -- 원거리 유닛 제한 체크
    if settings.maxRangedUnits then
        local rangedLimitCheck = CreateCheckListItem(checklist, "Max Ranged Units", index)
        rangedLimitCheck:SetChecked(rangedCount <= settings.maxRangedUnits)
        checklist.items[index] = rangedLimitCheck
        index = index + 1
    end
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

    print("OpenCheckListUI: Creating Checklist UI for", dungeonName)

    -- 체크리스트 UI 생성
    ChecklistUI = CreateFrame("Frame", "ChecklistUI", UIParent, "BasicFrameTemplate")
    ChecklistUI:SetSize(300, 600)
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
        print("ChecklistUI Event:", event)
        MythicDungeonCheckList.UpdateCheckList(dungeonName)
    end)

    -- 체크리스트 업데이트
    print("OpenCheckListUI: Updating Checklist for", dungeonName)
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
    print("Event Triggered:", event)
    if event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        MythicDungeonCheckList:OnPartyListed()
    end
end)

-- 활동 ID와 던전 이름 매핑 테이블 생성
local activityIDToDungeonName = {
    [1290] = "그림 바톨",
    -- 다른 던전의 활동 ID와 이름을 추가합니다.
    -- 예시:
    -- [activityID] = "던전 이름",
}

-- 파티 등록 시 호출되는 함수
function MythicDungeonCheckList:OnPartyListed()
    -- 파티 등록 정보 가져오기
    local entryInfo = C_LFGList.GetActiveEntryInfo()
    if not entryInfo then
        print("OnPartyListed: No active party listing.")
        return
    end

    -- 활동 ID 가져오기
    local activityID = entryInfo.activityID

    -- 활동 ID를 사용하여 던전 이름 가져오기
    local dungeonName = activityIDToDungeonName[activityID]
    if not dungeonName then
        print("MythicDungeonCheckList: Could not determine dungeon name from activity ID.")
        print("Activity ID:", activityID)
        return
    end

    print("OnPartyListed: Dungeon Name -", dungeonName)

    -- 던전 이름이 유효한지 확인
    if not MythicDungeonDB[dungeonName] then
        print("MythicDungeonCheckList: Unknown dungeon name in party listing.")
        return
    end

    print("OnPartyListed: Opening Checklist UI for", dungeonName)

    -- 체크리스트 UI 열기
    MythicDungeonCheckList.OpenCheckListUI(dungeonName)
end

-- 네임스페이스를 전역 변수로 설정 (다른 파일에서 접근할 수 있도록)
_G["MythicDungeonCheckList"] = MythicDungeonCheckList
print("MythicDungeonCheckList.lua loaded")
