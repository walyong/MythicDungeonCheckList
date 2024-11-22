-- 네임스페이스 생성
MythicDungeonCheckListClassData = {}

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
    return (class == "HUNTER") or -- 사냥꾼 - 평정의 사격
            (class == "DRUID") or -- 드루이드 - 달래기
            (class == "ROGUE") or -- 도적 - 마취의 일격
            (class == "EVOKER") -- 기원사 - 억제의 포효
end

function MythicDungeonCheckListClassData.CheckHeroismAndBattleRes(checklist, index)
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
    local heroismCheck = CreateCheckListItem(checklist, "영웅심 필요", index)
    heroismCheck:SetChecked(hasHeroism)
    checklist.items[index] = heroismCheck
    index = index + 1
    local battleResCheck = CreateCheckListItem(checklist, "전투 부활 필요", index)
    battleResCheck:SetChecked(hasBattleRes)
    checklist.items[index] = battleResCheck
    return index + 1
end

function MythicDungeonCheckListClassData.CheckCurseRemoval(checklist, index, settings)
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
        return index + 1
    end
    return index
end

function MythicDungeonCheckListClassData.CheckMagicRemoval(checklist, index, settings)
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
        return index + 1
    end
    return index
end

function MythicDungeonCheckListClassData.CheckPoisonRemoval(checklist, index, settings)
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
        return index + 1
    end
    return index
end

function MythicDungeonCheckListClassData.CheckDiseaseRemoval(checklist, index, settings)
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
        return index + 1
    end
    return index
end

function MythicDungeonCheckListClassData.CheckEnrageRemoval(checklist, index, settings)
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
        return index + 1
    end
    return index
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

function MythicDungeonCheckListClassData.CheckWeeklyAffix160(checklist, index)
    local activeAffixes = GetActiveAffixes()
    if activeAffixes then
        for _, affix in ipairs(activeAffixes) do
            if affix.id == 160 then
                index = CheckAffix160DispelRequirement(checklist, index)
            end
        end
    end
    return index
end

function MythicDungeonCheckListClassData.CheckUnitComposition(checklist, index, settings)
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

    return index
end

