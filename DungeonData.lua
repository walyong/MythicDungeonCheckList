-- DungeonData.lua

-- 네임스페이스 생성
MythicCheckListData = {}

-- 기본 던전 설정 (변경되지 않는 기본값)
MythicCheckListData.DefaultDungeonSettings = {
    ["메아리의 도시 아라카라"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 0,
        mustHavePoison = 0,
        mustHaveDisease = 0,
        mustHaveEnrage = 0
    },
    ["실타래의 도시"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 0,
        mustHavePoison = 0,
        mustHaveDisease = 0,
        mustHaveEnrage = 0
    },
    ["바위금고"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 1,    -- 마법 해제 필요
        mustHavePoison = 0,
        mustHaveDisease = 1,  -- 질병 해제 필요
        mustHaveEnrage = 0
    },
    ["새벽인도자호"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 1,    -- 마법 해제 필요
        mustHavePoison = 1,   -- 독 해제 필요
        mustHaveDisease = 0,
        mustHaveEnrage = 1    -- 격노 해제 필요
    },
    ["티르너 사이드의 안개"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 1,    -- 저주 해제 필요
        mustHaveMagic = 0,
        mustHavePoison = 1,   -- 독 해제 필요
        mustHaveDisease = 0,
        mustHaveEnrage = 0
    },
    ["죽음의 상흔"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 1,    -- 마법 해제 필요
        mustHavePoison = 0,
        mustHaveDisease = 1,  -- 질병 해제 필요
        mustHaveEnrage = 1    -- 격노 해제 필요
    },
    ["보랄러스 공성전"] = {
        maxMeleeUnits = 3,
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 2,    -- 마법 해제 2명 필요
        mustHavePoison = 0,
        mustHaveDisease = 0,
        mustHaveEnrage = 0
    },
    ["그림 바톨"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 0,
        mustHavePoison = 0,
        mustHaveDisease = 0,
        mustHaveEnrage = 1    -- 격노 해제 필요
    }
}
