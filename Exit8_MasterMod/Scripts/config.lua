-- ===================================================================
-- Exit8 MasterMod Configuration (v2.5)
-- 8번 출구 (The Exit 8) - 세이브 완전 초기화 & 8번 출구 치트 & 이상현상 HUD 설정
-- (여기에 없는 항목은 main.lua 의 기본값이 사용됩니다)
-- ===================================================================

local Config = {
    -- [기능 1] 키 입력 없는 자동 세이브/해금 완전 초기화 여부
    -- true: 게임 시작 시 기존 100% 해금 상태를 완전히 리셋하여 순정(클린 새 게임) 상태로 복원
    AutoReset = true,

    -- [기능 2] 게임 시작 시 즉시 8번 출구로 시작할지 여부
    -- false: 기본값. 원할 때 F8 또는 숫자 8 키를 눌러 8번 출구로 변경
    -- true: 게임 시작하자마자 첫 번째 복도부터 즉시 8번 출구로 생성
    AutoExit8OnStart = false,

    -- [기능 3] 8번 출구에서 이상현상(이변) 완전 차단 여부
    -- true: 8번 출구 활성화 시 모든 이변을 즉시 제거(SetNoChange)하고 정상 복도로 유지
    DisableAnomaliesAtExit8 = true,

    -- [기능 4] 화면 왼쪽 상단에 현재 이상현상 실시간 HUD 표시 여부
    ShowAnomalyHUD = true,

    -- [기능 4-1] HUD 언어 ("KR": 한국어, "EN": 영어)
    HUD_Language = "KR",

    -- [기능 4-2] HUD 위치(화면 왼쪽 위 기준)와 글자 크기
    HUD_PositionX = 25,
    HUD_PositionY = 25,
    HUD_TitleFontSize = 20,
    HUD_AdviceFontSize = 15,

    -- [기능 4-3] 한글 폰트 자동 선택 키워드 (게임에 로드된 폰트 이름에서 앞에서부터 찾음)
    -- 한글이 네모(□)로 깨지면 UE4SS.log 의 "Loaded fonts" 목록을 보고 키워드를 추가하세요.
    HUD_FontHints = { "Korean", "KR", "Noto", "CJK", "Nanum", "Gothic", "SourceHan" },

    -- [단축키 설정] (UE4SS Key enum 이름)
    -- 8번 출구 즉시 생성 치트 키
    Key_Exit8 = "F8",
    Key_Exit8_Alt = "EIGHT",       -- 키보드 숫자 8 키도 지원

    -- 수동 세이브 완전 초기화 키 (언제든 누르면 새 게임 상태로 완전 리셋)
    Key_ManualReset = "F7",

    -- 화면 좌측 상단 이상현상 실시간 HUD On/Off 토글 키
    Key_ToggleHUD = "F9",

    -- [표지판 보호] 통로 표지판 증발 방지 가디언 활성화 여부
    ProtectCorridorSign = true,

    -- 가디언/HUD 갱신 주기 (밀리초)
    TickIntervalMs = 150,

    -- UE4SS 콘솔 상세 디버그 로그 출력 여부
    DebugLogging = true
}

return Config
