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
    return (class == "PALADIN" and spec == 65) or -- 신성 성기사
            (class == "MONK" and spec == 270) -- 운무 수도사
end

-- 원거리 힐러 확인 함수 (지역 함수로 정의)
local function IsRangedHealer(class, spec)
    return (class == "DRUID" and spec == 105) or -- 회복 드루이드
            (class == "PRIEST" and (spec == 256 or spec == 257)) or -- 수양 및 신성 사제
            (class == "SHAMAN" and spec == 264) or -- 복원 주술사
            (class == "EVOKER" and spec == 1468) -- Preservation Evoker
end

-- 근접 딜러 확인 함수 (지역 함수로 정의)
local function IsMeleeDPS(class, spec)
    local meleeClasses = {
        ["DEATHKNIGHT"] = { 250, 251, 252 }, -- 혈기, 냉기, 부정
        ["DEMONHUNTER"] = { 577 }, -- 파멸
        ["DRUID"] = { 103 }, -- 야성
        ["HUNTER"] = { 255 }, -- 생존
        ["MONK"] = { 269 }, -- 풍운
        ["PALADIN"] = { 70 }, -- 징벌
        ["ROGUE"] = { 259, 260, 261 }, -- 모든 특성
        ["SHAMAN"] = { 263 }, -- 고양
        ["WARRIOR"] = { 71, 72 } -- 무기, 분노
    }
    return meleeClasses[class] and tContains(meleeClasses[class], spec)
end

-- 원거리 딜러 확인 함수 (지역 함수로 정의)
local function IsRangedDPS(class, spec)
    local rangedClasses = {
        ["DRUID"] = { 102 }, -- 조화
        ["HUNTER"] = { 253, 254 }, -- 야수, 사격
        ["MAGE"] = { 62, 63, 64 }, -- 모든 특성
        ["PRIEST"] = { 258 }, -- 암흑
        ["SHAMAN"] = { 262 }, -- 정기
        ["WARLOCK"] = { 265, 266, 267 }, -- 모든 특성
        ["EVOKER"] = { 1473 } -- Devastation
    }
    return rangedClasses[class] and tContains(rangedClasses[class], spec)
end

-- 격노 해제를 할 수 있는지 확인하는 함수 (지역 함수로 정의)
local function CanDispelEnrage(class)
    return (class == "HUNTER" and IsSpellKnown(19801)) or -- 사냥꾼 - 평정의 사격
            (class == "DRUID" and IsSpellKnown(2908)) or -- 드루이드 - 달래기
            (class == "ROGUE" and IsSpellKnown(5938)) or -- 도적 - 마취의 일격
            (class == "EVOKER" and IsSpellKnown(374227)) -- 기원사 - 억제의 포효
end

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

-- 어픽스 목록을 가져오는 함수
local function GetActiveAffixes()
    local affixes = C_MythicPlus.GetCurrentAffixes()
    return affixes
end

-- 특정 해제 가능한 직업/스킬을 기반으로 점수 계산
local function GetDispelScoreForUnit(unit)
    local _, class = UnitClass(unit)

    -- 범위 해제 스킬 (3점)
    if class == "PRIEST" then
        -- 대규모 무효화
        return 3
    elseif class == "SHAMAN" then
        -- 독정화 토템
        return 3
    end

    -- 단일 해제 스킬 (1점)
    if class == "PRIEST" then
        -- 해악 무효화 (단일)
        return 1
    elseif class == "PALADIN" then
        -- 성기사 해제
        return 1
    elseif class == "DRUID" then
        -- 해독
        return 1
    elseif class == "SHAMAN" then
        -- 정화의 물결 (단일)
        return 1
    elseif class == "MONK" then
        -- 해독주
        return 1
    elseif class == "EVOKER" then
        -- 불안정한 기운 해제
        return 1
    elseif class == "EVOKER" then
        -- 불안정한 기운 해제
        return 1
    elseif class == "MAGE" then
        -- 저주 해제
        return 1
    end

    return 0  -- 해제 불가능한 경우 0점
end

-- 주간 어픽스에 따른 추가 체크리스트 항목 생성
local function CheckAffix160DispelRequirement(checklist, index)
    -- 총 해제 포인트를 계산할 변수
    local totalDispelPoints = 0

    -- 파티원 해제 점수 계산
    for i = 1, GetNumGroupMembers() do
        local unit = (i == GetNumGroupMembers()) and "player" or "party" .. i
        totalDispelPoints = totalDispelPoints + GetDispelScoreForUnit(unit)
    end

    -- 체크리스트 항목 생성
    local dispelCheck = CreateCheckListItem(checklist, "잘아타스의 제안: 탐식 해제 (" .. totalDispelPoints .. "/5점)", index)
    dispelCheck:SetChecked(totalDispelPoints >= 5)
    checklist.items[index] = dispelCheck
    return index + 1  -- 다음 항목을 위한 인덱스 증가
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

-- 신화+ 던전 입장 시 해제 특성 체크
local function CheckMythicPlusDispelTalents()
    local currentZoneID = C_Map.GetBestMapForUnit("player")
    if currentZoneID then
        local dungeonName = GetDungeonNameByMapID(currentZoneID)
        if dungeonName then
            -- 던전의 해제 요구사항을 가져와서 각 파티원의 특성 체크
            local settings = MythicDungeonDB[dungeonName]
            if settings then
                for i = 1, GetNumGroupMembers() do
                    local unit = (i == GetNumGroupMembers()) and "player" or "party" .. i
                    if settings.mustHaveCurse > 0 then
                        CheckDispelTalents(unit, "Curse")
                    end
                    if settings.mustHaveMagic > 0 then
                        CheckDispelTalents(unit, "Magic")
                    end
                    if settings.mustHavePoison > 0 then
                        CheckDispelTalents(unit, "Poison")
                    end
                    if settings.mustHaveDisease > 0 then
                        CheckDispelTalents(unit, "Disease")
                    end
                end
            end
        end
    end
end

-- 던전 이름을 맵 ID로 가져오는 함수
function GetDungeonNameByMapID(mapID)
    local dungeonMapToName = {
        [1337] = "보랄러스 공성전", -- Boralus map ID
        [1493] = "메아리의 도시 아라카라", -- Atal'Dazar map ID
        [1502] = "새벽인도자호", -- Dawn of the Proudmoore map ID
        [1515] = "바위금고", -- Vault of the Wardens map ID
        [1466] = "실타래의 도시", -- The Motherlode map ID
        [1762] = "티르너 사이드의 안개", -- Mist of Tirna Scithe map ID
        [1688] = "죽음의 상흔", -- Necrotic Wake map ID
        [1862] = "그림 바톨"              -- Grim Batol map ID
        -- 다른 던전의 맵 ID를 여기 추가하세요
    }
    return dungeonMapToName[mapID]
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

    local index = 1  -- 항목 순서를 위한 변수

    -- 1. 영웅심과 전투부활 체크 (우선순위 1)
    local heroismCheck = CreateCheckListItem(checklist, "영웅심 필요", index)
    local battleResCheck = CreateCheckListItem(checklist, "전투 부활 필요", index + 1)

    -- 영웅심 및 전투부활 스킬 확인
    local hasHeroism, hasBattleRes = false, false
    for i = 1, GetNumGroupMembers() do
        local unit = (i == GetNumGroupMembers()) and "player" or "party" .. i
        local _, class = UnitClass(unit)
        if class == "SHAMAN" or class == "MAGE" or class == "HUNTER" or class == "EVOKER" then
            hasHeroism = true
        end
        if class == "DRUID" or class == "DEATHKNIGHT" or class == "WARLOCK" or class == "PALADIN" then
            hasBattleRes = true
        end
    end

    heroismCheck:SetChecked(hasHeroism)
    battleResCheck:SetChecked(hasBattleRes)

    checklist.items[index] = heroismCheck
    checklist.items[index + 1] = battleResCheck

    index = index + 2  -- 다음 체크리스트 시작 지점 설정

    -- 2. 던전별 해제 직업 체크 (우선순위 2)
    -- 요구되는 해제 갯수도 함께 표기

    -- 저주 해제 체크
    if settings.mustHaveCurse > 0 then
        local curseRemovalCheck = CreateCheckListItem(checklist, "저주 해제 필요 (" .. settings.mustHaveCurse .. "명)", index)
        local curseRemovalCount = 0
        for i = 1, GetNumGroupMembers() do
            local unit = (i == GetNumGroupMembers()) and "player" or "party" .. i
            local _, class = UnitClass(unit)
            if class == "MAGE" or class == "DRUID" or class == "SHAMAN" or class == "EVOKER" then
                curseRemovalCount = curseRemovalCount + 1
            end
        end
        curseRemovalCheck:SetChecked(curseRemovalCount >= settings.mustHaveCurse)
        checklist.items[index] = curseRemovalCheck
        index = index + 1
    end

    -- 마법 해제 체크
    if settings.mustHaveMagic > 0 then
        local magicRemovalCheck = CreateCheckListItem(checklist, "마법 해제 필요 (" .. settings.mustHaveMagic .. "명)", index)
        local magicRemovalCount = 0
        for i = 1, GetNumGroupMembers() do
            local unit = (i == GetNumGroupMembers()) and "player" or "party" .. i
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
        local poisonRemovalCheck = CreateCheckListItem(checklist, "독 해제 필요 (" .. settings.mustHavePoison .. "명)", index)
        local poisonRemovalCount = 0
        for i = 1, GetNumGroupMembers() do
            local unit = (i == GetNumGroupMembers()) and "player" or "party" .. i
            local _, class = UnitClass(unit)
            if class == "SHAMAN" or class == "DRUID" or class == "PALADIN" or class == "MONK" or class == "EVOKER" then
                poisonRemovalCount = poisonRemovalCount + 1
            end
        end
        poisonRemovalCheck:SetChecked(poisonRemovalCount >= settings.mustHavePoison)
        checklist.items[index] = poisonRemovalCheck
        index = index + 1
    end

    -- 질병 해제 체크
    if settings.mustHaveDisease > 0 then
        local diseaseRemovalCheck = CreateCheckListItem(checklist, "질병 해제 필요 (" .. settings.mustHaveDisease .. "명)", index)
        local diseaseRemovalCount = 0
        for i = 1, GetNumGroupMembers() do
            local unit = (i == GetNumGroupMembers()) and "player" or "party" .. i
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
        local enrageRemovalCheck = CreateCheckListItem(checklist, "격노 해제 필요 (" .. settings.mustHaveEnrage .. "명)", index)
        local enrageRemovalCount = 0
        for i = 1, GetNumGroupMembers() do
            local unit = (i == GetNumGroupMembers()) and "player" or "party" .. i
            local _, class = UnitClass(unit)
            if CanDispelEnrage(class) then
                enrageRemovalCount = enrageRemovalCount + 1
            end
        end
        enrageRemovalCheck:SetChecked(enrageRemovalCount >= settings.mustHaveEnrage)
        checklist.items[index] = enrageRemovalCheck
        index = index + 1
    end

    -- 3. 주간 어픽스 160 체크리스트 추가 (우선순위 3)
    local activeAffixes = GetActiveAffixes()
    if activeAffixes then
        for _, affix in ipairs(activeAffixes) do
            if affix.id == 160 then
                -- 어픽스 160이 있을 경우 체크리스트에 추가
                index = CheckAffix160DispelRequirement(checklist, index)
            end
        end
    end

    -- 4. 근거리/원거리 유닛 구성 체크 (우선순위 4)
    local meleeCount, rangedCount = 0, 0

    for i = 1, GetNumGroupMembers() do
        local unit = (i == GetNumGroupMembers()) and "player" or "party" .. i
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
        local meleeLimitCheck = CreateCheckListItem(checklist, "최대 근접 유닛 (" .. settings.maxMeleeUnits .. "명)", index)
        meleeLimitCheck:SetChecked(meleeCount <= settings.maxMeleeUnits)
        checklist.items[index] = meleeLimitCheck
        index = index + 1
    end

    -- 원거리 유닛 제한 체크
    if settings.maxRangedUnits then
        local rangedLimitCheck = CreateCheckListItem(checklist, "최대 원거리 유닛 (" .. settings.maxRangedUnits .. "명)", index)
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
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- 신화 던전 입장 시 발생하는 이벤트 등록
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
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- 신화 던전 입장 시 특성 체크
        CheckMythicPlusDispelTalents()
    end
end)

-- 활동 ID와 던전 이름 매핑 테이블 생성
local activityIDToDungeonName = {
    [1290] = "그림 바톨",
    [1284] = "메아리의 도시 아라카라",
    [1285] = "새벽인도자호",
    [1287] = "바위금고",
    [1288] = "실타래의 도시",
    [703] = "티르너 사이드의 안개",
    [713] = "죽음의 상흔",
    [534] = "보랄러스 공성전"
    -- 다른 던전의 활동 ID와 이름을 추가합니다.
    -- 예시:
    -- [activityID] = "던전 이름",
}

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
    local dungeonName = activityIDToDungeonName[activityID]
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
