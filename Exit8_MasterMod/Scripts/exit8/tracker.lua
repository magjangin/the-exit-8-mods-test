-- ===================================================================
-- Exit8 MasterMod - 이상현상 실시간 감지 → HUD 표시 문구/색상 생성
-- ===================================================================

local Util = require("exit8.util")
local AnomalyDB = require("exit8.anomaly_db")

local Tracker = {}
local Config, Game

local COLOR = {
    Safe = { R = 0.2, G = 0.85, B = 1.0, A = 1.0 },     -- 하늘색: 정상 복도
    Exit = { R = 0.1, G = 1.0, B = 0.35, A = 1.0 },     -- 초록색: 8번 출구
    Anomaly = { R = 1.0, G = 0.65, B = 0.05, A = 1.0 }, -- 주황색: 일반 이변
    Critical = { R = 1.0, G = 0.15, B = 0.15, A = 1.0 },-- 빨간색: 치명적 이변
    Waiting = { R = 0.7, G = 0.7, B = 0.7, A = 1.0 },   -- 회색: 게임 로딩 대기
}

local MSG = {
    CorridorLabel = { kr = "[출구 #%d] ", en = "[CORRIDOR #%d] " },
    Waiting = { kr = "복도 정보를 기다리는 중...", en = "Waiting for corridor..." },
    WaitingAdvice = { kr = "게임이 시작되면 자동으로 표시됩니다.", en = "HUD will appear once the game starts." },
    StartTitle = { kr = "0번 시작 복도 (이상현상 없음)", en = "Corridor 0 - Start (No Anomaly)" },
    ExitTitle = { kr = "★ 8번 출구 도달 (지상 통로) ★", en = "★ Exit 8 Reached (Surface Path) ★" },
    NormalTitle = { kr = "이상현상 없음 (정상 복도)", en = "No Anomaly (Normal Corridor)" },
    SafeAdvice = { kr = "안전합니다. 앞으로 계속 직진하세요!", en = "Safe. Keep walking forward!" },
    ExitAdvice = { kr = "탈출 성공! 앞의 계단으로 나가세요!", en = "Escape! Go up the stairs ahead!" },
    AnomalyPrefix = { kr = "[이상현상 감지] ", en = "[ANOMALY] " },
    NewSpawnPrefix = { kr = "[★ 신규 이변 스폰! ★] ", en = "[★ NEW SPAWN! ★] " },
    AnomalyAdvice = { kr = "[이상현상 감지] 즉시 뒤로 돌아가세요! (U턴)", en = "[ANOMALY DETECTED] Turn back immediately!" },
    CriticalAdvice = { kr = "[긴급 경보] 치명적 이변! 즉시 뒤로 도망치세요! (U턴)", en = "[CRITICAL] Run back immediately!" },
}

local NEW_SPAWN_BANNER_MS = 2000

local lastAnomalyKey = ""
local newSpawnTicksLeft = 0
local lastDebugSignature = ""

function Tracker.Init(config, game)
    Config = config
    Game = game
end

local function IsEnglish()
    return Config.HUD_Language == "EN"
end

local function Text(msg)
    return IsEnglish() and msg.en or msg.kr
end

local function AnomalyName(info, rawName)
    if info then
        return IsEnglish() and info.en or info.kr
    end
    return AnomalyDB.ShortName(rawName)
end

-- 게임 내부 값이 바뀔 때만 한 줄 로그 (실제 게임에서 감지 동작 검증용)
local function DebugState(state)
    local signature = string.format("#%d change=%s actor=%s tag=%s",
        state.number, tostring(state.anomalyActive), state.anomalyClass, state.anomalyTag)
    if signature ~= lastDebugSignature then
        lastDebugSignature = signature
        Util.Log("[Tracker] %s", signature)
    end
end

-- 반환: { title, advice, color } (HUD 모듈이 그대로 그림)
function Tracker.Update()
    local state = Game.ReadCorridorState()
    DebugState(state)

    local label = string.format(Text(MSG.CorridorLabel), state.number)

    if not state.found then
        lastAnomalyKey = ""
        return { title = Text(MSG.Waiting), advice = Text(MSG.WaitingAdvice), color = COLOR.Waiting }
    end

    if state.anomalyActive then
        local rawName = state.anomalyClass ~= "" and state.anomalyClass or state.anomalyTag
        local info = AnomalyDB.Lookup(state.anomalyClass) or AnomalyDB.Lookup(state.anomalyTag)

        -- 신규 스폰 순간 감지 → 일정 시간 강조 배너
        if rawName ~= lastAnomalyKey then
            lastAnomalyKey = rawName
            newSpawnTicksLeft = math.ceil(NEW_SPAWN_BANNER_MS / Config.TickIntervalMs)
            Util.Log(">>> [ANOMALY SPAWN DETECTED] Corridor #%d: %s (%s) <<<",
                state.number, info and info.kr or AnomalyDB.ShortName(rawName), rawName)
        end

        local isNew = newSpawnTicksLeft > 0
        if isNew then newSpawnTicksLeft = newSpawnTicksLeft - 1 end

        local prefix = Text(isNew and MSG.NewSpawnPrefix or MSG.AnomalyPrefix)
        local critical = info and info.critical
        return {
            title = label .. prefix .. AnomalyName(info, rawName),
            advice = ">> " .. Text(critical and MSG.CriticalAdvice or MSG.AnomalyAdvice),
            color = critical and COLOR.Critical or COLOR.Anomaly,
        }
    end

    lastAnomalyKey = ""
    newSpawnTicksLeft = 0

    if state.number == 8 then
        return { title = label .. Text(MSG.ExitTitle), advice = ">> " .. Text(MSG.ExitAdvice), color = COLOR.Exit }
    elseif state.number == 0 then
        return { title = label .. Text(MSG.StartTitle), advice = ">> " .. Text(MSG.SafeAdvice), color = COLOR.Safe }
    end
    return { title = label .. Text(MSG.NormalTitle), advice = ">> " .. Text(MSG.SafeAdvice), color = COLOR.Safe }
end

return Tracker
