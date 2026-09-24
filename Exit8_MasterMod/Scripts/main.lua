-- ===================================================================
-- Exit8 MasterMod (v2.5 - UMG Anomaly HUD & Auto-Sustaining Exit 8)
-- 8번 출구 (The Exit 8) 세이브 완전 초기화 & 즉시 8번 출구 치트 & 이상현상 HUD
--
-- 파일 구성
--   main.lua              진입점: 설정 로드, 단축키/훅/틱 루프 연결
--   config.lua            사용자 설정
--   exit8/util.lua        로그, 안전한 프로퍼티/함수 접근
--   exit8/game.lua        세이브 리셋, 8번 출구 적용, 표지판 보호, 복도 상태 읽기
--   exit8/anomaly_db.lua  이변 클래스 → 한글/영문 이름
--   exit8/tracker.lua     이변 감지 → HUD 문구/색상
--   exit8/hud.lua         UMG 오버레이 위젯
-- ===================================================================

local MOD_VERSION = "2.5"

local DEFAULT_CONFIG = {
    AutoReset = true,
    AutoExit8OnStart = false,
    DisableAnomaliesAtExit8 = true,
    ShowAnomalyHUD = true,
    HUD_Language = "KR",
    HUD_PositionX = 25,
    HUD_PositionY = 25,
    HUD_TitleFontSize = 20,
    HUD_AdviceFontSize = 15,
    HUD_ZOrder = 100,
    HUD_FontHints = { "Korean", "KR", "Noto", "CJK", "Nanum", "Gothic", "SourceHan" },
    Key_Exit8 = "F8",
    Key_Exit8_Alt = "EIGHT",
    Key_ManualReset = "F7",
    Key_ToggleHUD = "F9",
    ProtectCorridorSign = true,
    TickIntervalMs = 150,
    DebugLogging = true,
}

-- config.lua 값으로 기본값을 덮어씀 (구버전 config 에 없는 키는 기본값 유지)
local function LoadConfig()
    local config = {}
    for key, value in pairs(DEFAULT_CONFIG) do config[key] = value end

    local ok, userConfig = pcall(require, "config")
    if ok and type(userConfig) == "table" then
        for key, value in pairs(userConfig) do config[key] = value end
        return config, true
    end
    return config, false
end

local Config, configLoaded = LoadConfig()

local Util = require("exit8.util")
Util.Init(Config)
local Game = require("exit8.game")
Game.Init(Config)
local Tracker = require("exit8.tracker")
Tracker.Init(Config, Game)
local Hud = require("exit8.hud")
Hud.Init(Config)

Util.Log("Initializing Exit8 MasterMod v%s... (config.lua %s)", MOD_VERSION, configLoaded and "loaded" or "NOT found, using defaults")

local State = {
    AutoResetDone = false,
    AutoExit8Done = false,
    Exit8CheatActive = false, -- 8번 출구 치트 지속 활성화 모드
}

-- ===================================================================
-- 1. 기능 동작
-- ===================================================================
local function ResetSave()
    if Game.ResetSaveData() then
        State.AutoResetDone = true
        State.Exit8CheatActive = false -- 리셋 시 8번 출구 치트 모드도 해제
    end
end

-- 8번 출구 치트 활성화 (단 1회 입력으로 엔딩까지 지속 유지)
local function ActivateExit8()
    Util.Log("Triggering Instant Exit 8 Cheat (Auto-Sustaining Direct 8 Mode)...")
    State.Exit8CheatActive = true

    local applied = Game.ApplyExit8(true)
    if applied then
        Util.Log(">>> DIRECT EXIT 8 ACTIVATED (AUTO-SUSTAIN)! Walk forward to escape! <<<")
    else
        Util.Log("Path actors not ready yet. Guardian will lock Exit 8 as soon as they load.")
    end
    return applied
end

local function ToggleHud()
    Config.ShowAnomalyHUD = not Config.ShowAnomalyHUD
    Hud.SetVisible(Config.ShowAnomalyHUD)
    Util.Log("Anomaly HUD toggled: %s", Config.ShowAnomalyHUD and "ON" or "OFF")
end

-- ===================================================================
-- 2. 단축키 등록 (F8/숫자8 치트, F7 수동 초기화, F9 HUD 토글)
-- ===================================================================
local function RegisterKeySafe(keyName, callback)
    if not keyName or keyName == "" then return end
    local keyValue = Key[keyName]
    if not keyValue then
        Util.Warn("Key '%s' not recognized in UE4SS Key enum.", keyName)
        return
    end
    local ok, err = pcall(RegisterKeyBind, keyValue, function()
        ExecuteInGameThread(callback)
    end)
    if ok then
        Util.Log("Registered hotkey: [%s]", keyName)
    else
        Util.Warn("Failed to register key [%s]: %s", keyName, tostring(err))
    end
end

RegisterKeySafe(Config.Key_Exit8, ActivateExit8)
if Config.Key_Exit8_Alt ~= Config.Key_Exit8 then
    RegisterKeySafe(Config.Key_Exit8_Alt, ActivateExit8)
end
RegisterKeySafe(Config.Key_ManualReset, ResetSave)
RegisterKeySafe(Config.Key_ToggleHUD, ToggleHud)

-- ===================================================================
-- 3. 키 입력 없는 자동 실행 (세이브 초기화 / 시작 시 8번 출구)
-- ===================================================================
local AUTO_RUN_INTERVAL_MS = 2000
local AUTO_RUN_MAX_ATTEMPTS = 5
local autoRunAttempts = 0

local function TryAutoRun()
    if Config.AutoReset and not State.AutoResetDone then
        ResetSave()
    end
    if Config.AutoExit8OnStart and not State.AutoExit8Done then
        State.AutoExit8Done = ActivateExit8()
    end
end

local function IsAutoRunFinished()
    return (not Config.AutoReset or State.AutoResetDone)
        and (not Config.AutoExit8OnStart or State.AutoExit8Done)
end

-- 플레이어 폰 생성 시점 (새 게임 시작 또는 리스폰)
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
    ExecuteInGameThread(function()
        State.Exit8CheatActive = false -- 새 맵/리스폰 시 이전 치트 상태 리셋
        TryAutoRun()
    end)
end)

-- ===================================================================
-- 4. 메인 틱 (가디언 + HUD)
-- ===================================================================
local tickCount = 0
local autoRunEveryTicks = math.max(1, math.floor(AUTO_RUN_INTERVAL_MS / Config.TickIntervalMs))

local function OnTick()
    tickCount = tickCount + 1
    Game.Tick()

    -- 게임 레벨 로드 대기 백업 폴링 (최대 5회)
    if autoRunAttempts < AUTO_RUN_MAX_ATTEMPTS and not IsAutoRunFinished()
        and tickCount % autoRunEveryTicks == 0 then
        autoRunAttempts = autoRunAttempts + 1
        TryAutoRun()
    end

    if State.Exit8CheatActive then
        -- 8번 출구 치트: 새 통로가 로드돼도 계속 8번 출구 유지 + 이변 차단
        Game.ApplyExit8()
    elseif Config.ProtectCorridorSign then
        Game.GuardSigns()
    end

    if Config.ShowAnomalyHUD then
        Hud.Render(Tracker.Update())
    end
end

-- LoopAsync 는 별도 스레드에서 돌기 때문에 실제 작업은 게임 스레드로 넘긴다.
-- 게임 스레드가 로딩 등으로 멈춰 있을 때 작업이 쌓이지 않도록 한 번에 하나만 예약.
local tickQueued = false
LoopAsync(Config.TickIntervalMs, function()
    if not tickQueued then
        tickQueued = true
        ExecuteInGameThread(function()
            local ok, err = pcall(OnTick)
            if not ok then
                Util.WarnOnce("Tick error: %s", tostring(err))
            end
            tickQueued = false
        end)
    end
    return false
end)

Util.Log("Exit8 MasterMod v%s loaded successfully! Ready.", MOD_VERSION)
