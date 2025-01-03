-- DungeonData.lua

-- 네임스페이스 생성
MythicDungeonCheckListData = {}

-- 기본 던전 설정 (변경되지 않는 기본값)
MythicDungeonCheckListData.DefaultDungeonSettings = {
    ["메아리의 도시 아라카라"] = {
        maxMeleeUnits = 2,  -- 최대 근접 유닛을 2로 설정
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 0,
        mustHavePoison = 1,
        mustHaveDisease = 0,
        mustHaveEnrage = 0
    },
    ["실타래의 도시"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 0,
        mustHavePoison = 1,
        mustHaveDisease = 0,
        mustHaveEnrage = 0
    },
    ["바위금고"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 1,
        mustHaveMagic = 0,    -- 필요 마법 해제를 0으로 설정
        mustHavePoison = 0,
        mustHaveDisease = 0,  -- 필요 질병 해제를 0으로 설정
        mustHaveEnrage = 1    -- 필요 격노 해제를 1로 설정
    },
    ["새벽인도자호"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 1,
        mustHavePoison = 1,
        mustHaveDisease = 0,
        mustHaveEnrage = 1
    },
    ["티르너 사이드의 안개"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 1,
        mustHaveMagic = 0,
        mustHavePoison = 1,
        mustHaveDisease = 0,
        mustHaveEnrage = 0
    },
    ["죽음의 상흔"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 0,
        mustHavePoison = 0,
        mustHaveDisease = 0,
        mustHaveEnrage = 0
    },
    ["보랄러스 공성전"] = {
        maxMeleeUnits = 3,    -- 최대 근접 유닛을 3으로 설정
        maxRangedUnits = 5,
        mustHaveCurse = 0,
        mustHaveMagic = 2,    -- 필요 마법 해제를 2로 설정
        mustHavePoison = 1,
        mustHaveDisease = 0,
        mustHaveEnrage = 0
    },
    ["그림 바톨"] = {
        maxMeleeUnits = 5,
        maxRangedUnits = 5,
        mustHaveCurse = 1,
        mustHaveMagic = 0,
        mustHavePoison = 0,
        mustHaveDisease = 0,
        mustHaveEnrage = 1    -- 필요 격노 해제를 1로 설정
    }
}

-- 활동 ID와 던전 이름 매핑 테이블 생성
MythicDungeonCheckListData.activityIDToDungeonName = {
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