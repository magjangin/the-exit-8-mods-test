# 8번 출구 (The Exit 8) - 통합 마스터 모드 (UE4SS)

[![Game](https://img.shields.io/badge/Game-The_Exit_8_(8번_출구)-orange.svg)](https://store.steampowered.com/app/2653790/)
[![Engine](https://img.shields.io/badge/Engine-Unreal_Engine_5-313131.svg?logo=unrealengine)](https://www.unrealengine.com/)
[![Framework](https://img.shields.io/badge/Modding_Framework-UE4SS_v3.0+-blue.svg)](https://github.com/UE4SS-RE/RE-UE4SS)
[![Script](https://img.shields.io/badge/Language-Lua-000080.svg?logo=lua)](https://www.lua.org/)
[![Version](https://img.shields.io/badge/Mod_Version-v2.3_(Auto--Sustaining)-brightgreen.svg)]()

스팀 인디 공포 명작 게임 **《8번 출구 (The Exit 8)》**의 UE4SS(Unreal Engine 4/5 Scripting System) 기반 통합 치트 및 세이브 관리 모드입니다.

단 1번의 키 입력으로 즉시 지상 탈출 복도를 개방하는 **즉시 8번 출구 생성 치트(1-Press Guaranteed Auto-Sustaining Mode)**와, 기존 세이브를 완전한 순정 새 게임 상태(0% 진행, 미발견 이변 35개)로 복원하는 **자동 세이브/해금 완전 초기화(Clean Vanilla Reset)** 기능을 제공합니다.

---

## 📌 주요 핵심 기능

### 1. 단 1회 입력으로 즉시 8번 출구 생성 (1-Press Guaranteed Exit 8)
* **단축키**: **`F8`** 또는 키보드 숫자 **`8`**
* **4연타 버그 완벽 해결**: 기존 모드들의 0 → 2 → 4 → 6 → 8 점진적 증가 현상(4번 눌러야 탈출 가능하던 문제)을 내부 블루프린트 로직 분석을 통해 단 1회 입력으로 즉시 8번 출구로 고정되도록 수정하였습니다.
* **300ms 초고속 가디언 엔진 (Auto-Sustaining Loop)**:
  * 1번만 키를 누르고 앞만 보고 걸어가면, 다음 통로가 동적으로 스폰되어도 지속적으로 '8번 출구'와 '8번 표지판'을 자동 유지합니다.
* **무(無)이변 청정 탈출 (`DisableAnomaliesAtExit8`)**:
  * 8번 출구 활성화 시 전역 이변 관리자(`BP_ChangeManager_C`) 및 통로 내부 모든 이변을 즉시 소멸(`SetNoChange()`)시켜 깨끗하고 안전한 탈출 복도를 보장합니다.
* **지상 탈출구(`BP_Exit`) 즉시 개방**:
  * 앞쪽 계단 출구 액터를 즉시 스폰하고 개방하며, 출구 상단 표지판도 '8'로 정확히 동기화됩니다.

### 2. 세이브 및 해금 데이터 완전 초기화 (Clean Vanilla Reset)
* **자동 실행 (`AutoReset = true`)**:
  * 게임 실행 시 자동으로 동작하여 100% 올클리어된 세이브 데이터를 최초 순정 상태(새 게임)로 되돌립니다.
  * 벽면 안내 포스터가 정상적으로 **"남은 이변: 35개"**를 표시하도록 게임 레벨과 UI를 완벽 동기화합니다.
* **초기화 범위**:
  * `Clear = false`, `AllAno = false`, `EndTutorial = false`
  * `All Anomaly`(전체 이변) 35개를 `Not Found Anomaly`(미발견 이변) 목록으로 100% 원복
  * 걸음 수(`WalkCount`) 0 초기화 및 `Save.sav` 슬롯 클린 저장
* **수동 즉시 초기화 단축키**:
  * 플레이 도중 언제든지 **`F7`** 키를 누르면 게임 진행 및 세이브 상태가 즉시 0%로 리셋됩니다.

### 3. 천장 노란색 출구 표지판 증발 방지 가디언
* 치트 발동 시나 통로 이동 시 천장의 노란색 출구 표지판(`Sign`, `Widget1`, `Sign_Number`)이 사라지는 현상을 실시간 감지하여 가시성을 강제로 복원 및 보호합니다.
* 단, 통로 번호가 8번이 아닐 때 게임 내 정규 '표지판 이변(`BP_ChangeActor_Sign`)'이 발생한 경우에는 이변 연출을 방해하지 않도록 정밀 예외 처리되어 있습니다.

---

## ⌨️ 단축키 안내 (Default Hotkeys)

| 단축키 | 기능 명칭 | 설명 |
| :--- | :--- | :--- |
| **`F8`** 또는 **`8`** | **즉시 8번 출구 생성** | 현재 통로와 연결 통로를 즉시 8번 출구로 고정하고 지상 계단을 개방 |
| **`F7`** | **수동 세이브 완전 초기화** | 세이브 파일 및 해금 상태를 순정 새 게임(미발견 35개)으로 완전 리셋 |

> 💡 단축키 및 동작 옵션은 [`Scripts/config.lua`](file:///H:/ue4ss%20mod%20test/the%20exit%208%20mods%20test/Exit8_MasterMod/Scripts/config.lua)에서 손쉽게 변경할 수 있습니다.

---

## 🛠️ 설치 및 적용 방법 (Installation)

### 1. 사전 필수 요구사항
1. 스팀 라이브러리에서 **《8번 출구 (The Exit 8)》** 게임을 설치합니다.
2. [UE4SS (Unreal Engine 4/5 Scripting System)](https://github.com/UE4SS-RE/RE-UE4SS/releases) 최신 릴리스(x64)를 다운로드하여 게임 실행 파일 디렉터리에 설치합니다.
   * 설치 경로: `<게임설치경로>\Exit8\Binaries\Win64\`
   * (`UE4SS.dll`, `dwmapi.dll` 또는 `dxgi.dll`, `Mods` 폴더 등이 위치해야 함)

### 2. 모드 파일 배치
본 저장소의 `Exit8_MasterMod` 폴더를 통째로 게임 내 UE4SS 모드 경로에 복사합니다.

```plaintext
<게임설치경로>\Exit8\Binaries\Win64\ue4ss\Mods\Exit8_MasterMod\
├── enabled.txt
├── README.md
└── Scripts/
    ├── config.lua
    └── main.lua
```

### 3. 모드 활성화 (mods.txt)
`<게임설치경로>\Exit8\Binaries\Win64\ue4ss\Mods\mods.txt` 파일을 열고 아래 라인을 추가하거나 확인합니다:

```ini
Exit8_MasterMod : 1
```

---

## ⚙️ 상세 환경 설정 (`config.lua`)

`Exit8_MasterMod/Scripts/config.lua` 파일을 텍스트 에디터로 열어 자유롭게 옵션을 조정할 수 있습니다.

```lua
local Config = {
    -- [기능 1] 게임 실행 시 세이브/해금 완전 초기화 여부 (true: 클린 새 게임 상태로 복원)
    AutoReset = true,

    -- [기능 2] 게임 시작하자마자 첫 번째 복도부터 즉시 8번 출구로 시작할지 여부
    AutoExit8OnStart = false,

    -- [기능 3] 8번 출구에서 이상현상(이변) 완전 차단 여부
    DisableAnomaliesAtExit8 = true,

    -- [단축키 설정] (UE4SS Key enum 이름)
    Key_Exit8 = "F8",
    Key_Exit8_Alt = "EIGHT",       -- 키보드 숫자 8 키도 지원
    Key_ManualReset = "F7",        -- 세이브 수동 리셋 키

    -- [표지판 보호] 통로 표지판 증발 방지 가디언 활성화 여부
    ProtectCorridorSign = true,

    -- UE4SS 콘솔 상세 디버그 로그 출력 여부
    DebugLogging = true
}

return Config
```

---

## 🔍 기술 분석 및 문제 해결 내역 (Technical Insights)

### Q. 왜 기존 모드들은 0 → 2 → 4 → 6 → 8로 4번 연타해야만 했는가?
1. 무한 루프 통로 구조상 언리얼 레벨에는 **2개의 통로 액터(`Path[1]`, `Path[2]`)가 상시 존재**합니다.
2. 기존 치트에서 표지판 번호 갱신을 위해 호출하던 블루프린트 함수 `path:NextPathNumber()`는 숫자를 강제 설정하는 함수가 아니라, **"다음 통로 번호로 +1 증가"**시키는 내부 카운터 함수였습니다.
3. 통로 액터 2개를 루프(`for ipairs(allPaths)`)로 순회하며 각각 `NextPathNumber()`를 1회씩 호출했기 때문에, **한 번 누를 때마다 번호가 +2씩 증가(0 → 2 → 4 → 6 → 8)**하여 탈출까지 정확히 4회의 키 입력이 필요했던 것입니다.
4. **해결 방법**: 점진적 가산 방식인 `NextPathNumber()` 호출을 제거하고, 통로 번호 변수(`path.Number = 8`)와 표지판 UI 텍스트 위젯(`SetNumberText(8)`), 지상 출구 액터(`BP_Exit`)를 멱등적 직접 대입(Idempotent Direct Assign) 방식으로 일괄 동기화하여 단 1회 입력으로 즉시 탈출이 가능하도록 설계했습니다.

---

## 📂 프로젝트 구조

```
the-exit-8-mods-test/
├── .gitignore
├── README.md                      # 저장소 종합 안내서 (본 파일)
└── Exit8_MasterMod/               # UE4SS 적용용 모드 패키지
    ├── enabled.txt                # UE4SS 모드 활성화 플래그
    ├── README.md                  # 모드 개발 및 패치 노트
    └── Scripts/
        ├── config.lua             # 모드 상세 설정 파일
        └── main.lua               # 모드 메인 Lua 스크립트 (v2.3)
```

---

## 📜 라이선스 및 주의사항

* 본 프로젝트는 개인 모딩 연구 및 테스트 목적으로 제작되었습니다.
* 게임 원본의 저작권은 원작자 **KOTAKE CREATE**에 있습니다.
