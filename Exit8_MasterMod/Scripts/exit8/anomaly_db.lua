-- ===================================================================
-- Exit8 MasterMod - 이상현상(이변) 클래스 → 한글/영문 이름 매핑
-- critical = true 인 항목은 HUD 에서 빨간색 긴급 경보로 표시
-- ===================================================================

local AnomalyDB = {}

local Entries = {
    -- [1. 통행인(아저씨) 관련 이변]
    BP_ChangeActor_Human_Smile_C = { kr = "기괴하게 미소 짓는 아저씨", en = "Smiling Man" },
    BP_ChangeActor_Human_Face_C = { kr = "얼굴 없는 / 일그러진 아저씨", en = "Faceless/Distorted Man" },
    BP_ChangeActor_Human_Fast_C = { kr = "초고속으로 걸어오는 아저씨", en = "Fast Walking Man" },
    BP_ChangeActor_Human_Large_C = { kr = "거대 통행인 (거인 아저씨)", en = "Giant Man" },
    BP_ChangeActor_Human_Look_C = { kr = "고개를 돌려 노려보는 아저씨", en = "Staring Man" },
    BP_ChangeActor_Human_Duo_C = { kr = "두 명의 아저씨 (도플갱어)", en = "Two Men (Doppelganger)" },
    BP_ChangeActor_Human_Stalker_Movie_C = { kr = "뒤쫓아오는 아저씨 (추격자)", en = "Stalker Man", critical = true },
    BP_ChangeActor_Human_C = { kr = "통행인 행동 이상", en = "Man Behavior Anomaly" },
    BP_ChangeCharacterBase_Smile_C = { kr = "미소 짓는 통행인", en = "Smiling Character" },
    BP_ChangeCharacterBase_Face_C = { kr = "얼굴 이상 통행인", en = "Faceless Character" },
    BP_ChangeCharacterBase_Duo_C = { kr = "도플갱어 통행인", en = "Doppelganger Character" },
    BP_ChangeCharacterBase_Attack_C = { kr = "돌진하는 통행인 (공격)", en = "Attacking Man", critical = true },
    BP_ChangeCharacterBase_Stalker_Movie_C = { kr = "추격자 통행인", en = "Stalker Character", critical = true },

    -- [2. 조명(전등) 관련 이변]
    BP_ChangeActor_Light_Off_C = { kr = "정전 (완전 암전 / 전등 꺼짐)", en = "Blackout (Lights Off)" },
    BP_ChangeActor_Light_Off_Movie_C = { kr = "정전 컷신 발생", en = "Blackout Cutscene" },
    BP_ChangeActor_Light_Flash_C = { kr = "깜빡거리는 조명", en = "Flickering Lights" },
    BP_ChangeActor_Light_Scatter_C = { kr = "어긋난 전등 배치 (지그재그)", en = "Scattered Lights" },
    BP_ChangeActor_Light_Yellow_Movie_C = { kr = "노란색 조명 / 이상 조명", en = "Yellow Lighting" },
    BP_ChangeActor_Light_C = { kr = "조명 이상", en = "Light Anomaly" },

    -- [3. 문(도어) 관련 이변]
    BP_ChangeActor_Door_Knock_C = { kr = "문을 두드리는 소리 (쿵쿵)", en = "Knocking Door" },
    BP_ChangeActor_Door_Open_C = { kr = "열려있는 문", en = "Opened Door" },
    BP_ChangeActor_Door_Look_C = { kr = "문틈 사이로 응시하는 시선", en = "Peeking Door" },
    BP_ChangeActor_Door_HandleHidden_C = { kr = "문손잡이가 사라짐", en = "Missing Doorknob" },
    BP_ChangeActor_Door_Hidden_C = { kr = "문이 사라지고 벽으로 막힘", en = "Missing Door" },
    BP_ChangeActor_Door_C = { kr = "문 이상", en = "Door Anomaly" },
    BP_ChangeActor_Door1_C = { kr = "1번 문 이상", en = "Door 1 Anomaly" },
    BP_ChangeActor_Door2_C = { kr = "2번 문 이상", en = "Door 2 Anomaly" },

    -- [4. 표지판 및 천장 이변]
    BP_ChangeActor_Sign_TurnBack_C = { kr = "'돌아가시오 (Turn Back)' 표지판", en = "Turn Back Sign" },
    BP_ChangeActor_Sign_Rotate_C = { kr = "뒤집히거나 회전된 표지판", en = "Inverted Sign" },
    BP_ChangeActor_Sign_C = { kr = "출구 표지판 이상", en = "Exit Sign Anomaly" },
    BP_ChangeActor_CeilingCenter_Smile_C = { kr = "천장에 나타난 거대 미소 얼굴", en = "Ceiling Smile Face" },
    BP_ChangeActor_CeilingCenter_C = { kr = "천장 중앙 변형 이상", en = "Ceiling Anomaly" },

    -- [5. 포스터 및 광고판 이변]
    BP_ChangeActor_CameraPoster_Chase_C = { kr = "시선을 따라 움직이는 감시 포스터", en = "Chasing Eye Poster" },
    BP_ChangeActor_CameraPoster_Look_C = { kr = "플레이어를 쳐다보는 포스터", en = "Staring Poster" },
    BP_ChangeActor_CameraPoster_C = { kr = "감시 포스터 이상", en = "Poster Camera Anomaly" },
    BP_ChangeActor_PosterSmok_Many_C = { kr = "벽면 가득 증식한 금연 포스터", en = "Multiple No-Smoking Posters" },
    BP_ChangeActor_Ad_Big_C = { kr = "거대해진 광고판 포스터", en = "Giant Ad Poster" },
    BP_ChangeActor_Ad_Change_C = { kr = "내용이 변형된 광고 포스터", en = "Changed Ad Poster" },
    BP_ChangeActor_Ad_Movie_C = { kr = "움직이는 동영상 광고판", en = "Moving Video Ad" },
    BP_ChangeActor_Ad_Part_C = { kr = "일부가 훼손된 광고", en = "Damaged Ad Poster" },
    BP_ChangeActor_Ad_Fes_C = { kr = "축제 포스터 이상", en = "Festival Poster Anomaly" },
    BP_ChangeActor_Ad_C = { kr = "광고판 이상", en = "Ad Anomaly" },

    -- [6. 기타 환경 / 치명적 이변]
    BP_ChangeActor_Water_C = { kr = "★ 붉은 홍수(바다) 밀려옴! ★", en = "★ Red Flood! ★", critical = true },
    BP_ChangeActor_Mimick_C = { kr = "벽면에 위장한 괴물 (미믹)", en = "Camouflaged Mimic", critical = true },
    BP_ChangeActor_Mimick2_Movie_C = { kr = "미믹 습격 컷신", en = "Mimic Attack Cutscene", critical = true },
    BP_ChangeActor_Vent_Blood_C = { kr = "환풍구에서 핏물이 흘러내림", en = "Blood Dripping Vent" },
    BP_ChangeActor_Vent_C = { kr = "환풍구 이상", en = "Vent Anomaly" },
    BP_ChangeActor_Block_Stop_C = { kr = "'STOP' 정지 점자블록", en = "STOP Braille Block" },
    BP_ChangeActor_Block_Strange_C = { kr = "물결치듯 뒤틀린 점자블록", en = "Distorted Braille Block" },
    BP_ChangeActor_Block_C = { kr = "점자블록 이상", en = "Braille Block Anomaly" },
    BP_ChangeActor_Camera_Look_C = { kr = "플레이어를 추적하는 CCTV", en = "Tracking CCTV Camera" },
    BP_ChangeActor_Camera_C = { kr = "CCTV 카메라 이상", en = "CCTV Camera Anomaly" },
    BP_ChangeActor_Exit_C = { kr = "비상구 표지판/출구 이상", en = "Exit Sign Anomaly" }
}

-- 부분 일치 검색용 키: "BP_ChangeActor_Human_Smile_C" → "Human_Smile"
local FuzzyKeys = {}
for className, info in pairs(Entries) do
    local base = className:gsub("^BP_Change%a+_", ""):gsub("_C$", "")
    FuzzyKeys[#FuzzyKeys + 1] = { base = base, info = info }
end
-- 가장 구체적인(긴) 키가 먼저 일치하도록 정렬 ("Human_Smile" 이 "Human" 보다 우선)
table.sort(FuzzyKeys, function(a, b) return #a.base > #b.base end)

-- 클래스 이름 또는 GameplayTag 이름으로 이변 정보 조회
function AnomalyDB.Lookup(rawName)
    if not rawName or rawName == "" then return nil end

    local exact = Entries[rawName] or Entries[rawName .. "_C"] or Entries[(rawName:gsub("_C$", ""))]
    if exact then return exact end

    -- 태그("Anomaly.Human.Smile")는 '.' 을 '_' 로 바꿔서 비교
    local normalized = rawName:gsub("%.", "_")
    for _, entry in ipairs(FuzzyKeys) do
        if normalized:find(entry.base, 1, true) then
            return entry.info
        end
    end
    return nil
end

-- 표시용으로 접두/접미사를 떼어낸 이름
function AnomalyDB.ShortName(rawName)
    if not rawName or rawName == "" then return "Unknown" end
    return (rawName:gsub("^BP_Change%a+_", ""):gsub("_C$", ""))
end

return AnomalyDB
