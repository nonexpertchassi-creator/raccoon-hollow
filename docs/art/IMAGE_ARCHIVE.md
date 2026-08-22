# 너구리 만물상 — Visual Image Archive

파일명만 기록하지 않고 **실제 이미지를 나란히 보며** 생성 이력과 승인 상태를 확인하는 갤러리다.

> 브라우저에서 실제 이미지와 필수 170장 + 선택 110장 카드를 함께 보려면
> [image-archive.html](./image-archive.html)을 연다. 이 문서는 판단 근거와 텍스트 기록을 보존한다.

## 상태 언어

| 상태 | 뜻 |
|---|---|
| `없음` | 제작·검수할 PNG가 아직 없다 |
| `초안` | 이미지가 있거나 게임에 연결됐지만 규격·화면 검수·사용자 승인을 모두 통과하지 않았다 |
| `확정` | 최신 규격을 지키고 실제 Godot 화면 검수와 명시적 사용자 승인을 마쳤다 |

**파일 존재와 Godot 연결은 상태의 근거일 뿐, 그 자체가 `확정`은 아니다.**

## 현재 기준 — Godot 전환 감사

- 확인 날짜: `2026-08-22`
- 게임 기준 브랜치: `origin/claude/read-this-yyycmm`
- 확인 커밋: `5dacb82`
- 화면 기준: Godot `430×932`, 아이소메트릭 격자 `96×48`, 줌 `0.45~1.80`
- 필수 이미지: 자동 목록 기준 `170장`
- 선택 이미지: 성장 카드 `90장` + 가게별 점장 `20장`
- 필수 상태: `확정 0장 / 초안 66장 / 없음 104장`
- 전체 관리 대상: `280장` (`초안 66장 / 없음 214장`)

### 중요한 현재 상태

최신 브랜치에는 가게 10채, 30종 손님, 카드 뽑기, 룰렛과 움직임 계약이 추가됐다. 기존 점장
`make/sell`과 토끼는 실제 Godot 화면에 표시되지만 새 제작 규격의 절반 크기인 구규격이다.
직원 8장, 점장 걷기·수면·촌장 4장, 손님 29장, 뽑기·룰렛 2장과 손님 카드 1단 20장은 새 규격으로 생성했다. 예순여섯 장 모두
실제 화면 검수와 사용자 승인을 마치지 않았으므로 `초안`으로 분류한다.

| 구분 | 상태 | 최신 Godot 처리 |
|---|---|---|
| 점장·촌장 | 초안 6장 | make/sell은 구규격, 걷기·수면·촌장은 새 규격 |
| 직원 | 초안 8장 | 머리띠·초립·패랭이·백립의 작업·수면이 모두 연결·화면 검수 대기 |
| 손님 | 토끼와 새 규격 29종 초안 | 필드용 30종이 모두 채워짐 |
| 손님 카드 | 1단 초안 20장, 1단 없음 10장 + 선택 90장 | 1단이 필수, 2~4단은 선택 성장 그림 |
| 물건 | 없음 80장 | 이모지로 대체 |
| 나쁜 놈 | 없음 3장 | 이모지로 대체 |
| 좌판 | 없음 10장 | 가게별 PNG가 없으면 공통 나무 상자로 대체 |
| 뽑기·룰렛 | 초안 2장, 없음 1장 | 카드 뒷면과 12칸 원판 초안, 바늘 없음 |

---

## 승인된 세계관 기준 이미지

<table>
  <tr>
    <td align="center">
      <img src="./generated/BP-V0.1-P01.png" width="330" alt="승인된 Art Concept Blueprint V0.1">
    </td>
  </tr>
  <tr>
    <td><strong>BP-V0.1-P01 · Approved</strong><br>따뜻한 조선 서민 마을, 폐허와 복구의 대비, 한국 생활소품과 재료감의 기준. 현재 Godot 격자 배치를 확정하는 화면 설계도는 아니다.</td>
  </tr>
</table>

---

## 점장 너구리 디자인 변천

### 제작 포즈 · make

<table>
  <tr>
    <th>V0.1 · 전신 서민복</th>
    <th>V0.2 · 무복식</th>
    <th>V0.3 · 짧은 앞치마</th>
  </tr>
  <tr>
    <td align="center"><img src="./generated/hero/HERO-V0.1-make-master.png" width="220" alt="V0.1 제작 포즈"></td>
    <td align="center"><img src="./generated/hero/HERO-V0.2-make-master.png" width="220" alt="V0.2 제작 포즈"></td>
    <td align="center"><img src="./generated/hero/HERO-V0.3-make-master.png" width="220" alt="V0.3 제작 포즈"></td>
  </tr>
  <tr>
    <td><strong>Revision</strong><br>작은 캐릭터에 전신 복식이 과함.</td>
    <td><strong>Revision</strong><br>실루엣은 좋아졌지만 점장 표식이 부족함.</td>
    <td><strong>Current candidate</strong><br>털 실루엣을 살리고 앞치마만 남김.</td>
  </tr>
</table>

### 판매 포즈 · sell

<table>
  <tr>
    <th>V0.1 · 전신 서민복</th>
    <th>V0.2 · 무복식</th>
    <th>V0.3 · 짧은 앞치마</th>
  </tr>
  <tr>
    <td align="center"><img src="./generated/hero/HERO-V0.1-sell-master.png" width="220" alt="V0.1 판매 포즈"></td>
    <td align="center"><img src="./generated/hero/HERO-V0.2-sell-master.png" width="220" alt="V0.2 판매 포즈"></td>
    <td align="center"><img src="./generated/hero/HERO-V0.3-sell-master.png" width="220" alt="V0.3 판매 포즈"></td>
  </tr>
  <tr>
    <td><strong>Revision</strong><br>복식 세부가 플레이 크기에서 사라짐.</td>
    <td><strong>Revision</strong><br>역할 표식 추가 필요.</td>
    <td><strong>Current candidate</strong><br>몸 밖으로 내민 앞발과 앞치마가 읽힘.</td>
  </tr>
</table>

---

## 실제 게임용 초안 파일

아래 투명 PNG 세 장은 최신 Godot 화면에 연결됐다. 다만 현재 파일은 예전 1배 규격이고
새 주문 규격은 2배 원본이므로 `확정`이 아니라 `초안`이다.

<table>
  <tr>
    <th>제작 · 초안 72×72</th>
    <th>판매 · 초안 72×72</th>
    <th>토끼 · 초안 64×64</th>
  </tr>
  <tr>
    <td align="center"><img src="../../godot/art/hero/raccoon-make.png" width="144" alt="현재 제작 포즈 런타임 PNG"></td>
    <td align="center"><img src="../../godot/art/hero/raccoon-sell.png" width="144" alt="현재 판매 포즈 런타임 PNG"></td>
    <td align="center"><img src="../../godot/art/guests/rabbit.png" width="128" alt="토끼 앵커 PNG"></td>
  </tr>
  <tr>
    <td><code>godot/art/hero/raccoon-make.png</code><br>목표 144×144</td>
    <td><code>godot/art/hero/raccoon-sell.png</code><br>목표 144×144</td>
    <td><code>godot/art/guests/rabbit.png</code><br>목표 128×128</td>
  </tr>
</table>

### 직원 4등급 · 작업/수면 초안

<table>
  <tr>
    <th>머리띠 · 작업/수면</th>
    <th>초립 · 작업/수면</th>
  </tr>
  <tr>
    <td align="center"><img src="../../godot/art/staff/band-work.png" width="112" alt="머리띠 알바 작업 포즈 초안"><img src="../../godot/art/staff/band-sleep.png" width="112" alt="머리띠 알바 수면 포즈 초안"></td>
    <td align="center"><img src="../../godot/art/staff/chorip-work.png" width="112" alt="초립 일꾼 작업 포즈 초안"><img src="../../godot/art/staff/chorip-sleep.png" width="112" alt="초립 일꾼 수면 포즈 초안"></td>
  </tr>
  <tr>
    <td><code>band-work.png</code> · <code>band-sleep.png</code><br><strong>Draft</strong> · 차렷 자세와 몽글 수면</td>
    <td><code>chorip-work.png</code> · <code>chorip-sleep.png</code><br><strong>Draft</strong> · 누런 풀 갓</td>
  </tr>
  <tr>
    <th>패랭이 · 작업/수면</th>
    <th>백립 · 작업/수면</th>
  </tr>
  <tr>
    <td align="center"><img src="../../godot/art/staff/paeraengi-work.png" width="112" alt="패랭이 선임 작업 포즈 초안"><img src="../../godot/art/staff/paeraengi-sleep.png" width="112" alt="패랭이 선임 수면 포즈 초안"></td>
    <td align="center"><img src="../../godot/art/staff/baengnip-work.png" width="112" alt="백립 매니저 작업 포즈 초안"><img src="../../godot/art/staff/baengnip-sleep.png" width="112" alt="백립 매니저 수면 포즈 초안"></td>
  </tr>
  <tr>
    <td><code>paeraengi-work.png</code> · <code>paeraengi-sleep.png</code><br><strong>Draft</strong> · 넓은 대나무 갓</td>
    <td><code>baengnip-work.png</code> · <code>baengnip-sleep.png</code><br><strong>Draft</strong> · 흰 갓</td>
  </tr>
</table>

### 초안 → 확정 게이트

1. 점장은 `144×144`, 토끼는 `128×128` 투명 PNG로 다시 출력한다.
2. 발끝이 이미지 아래 변에 닿고 불필요한 투명 여백이 없는지 확인한다.
3. 실제 표시 크기 `72×72`·`64×64`와 줌 `0.45`, `1.0`, `1.8`에서 번짐·접점·가림 순서를 본다.
4. 점장과 직원은 크기가 같고, 점장은 손의 연장·직원은 모자로 구분되는지 본다.
5. 사용자 승인 기록이 남은 뒤에만 `확정`으로 바꾼다.

---

## 이미지 주문 변경 — Godot 전환 후

최신 `ASSETS.md`, `MOTION.md`, `tools/art.mjs` 기준 필수 총수는 `170장`이다.
가게가 10채로 늘면서 물건이 80장, 좌판이 10장이 됐다.
성장 카드 90장과 가게별 점장 20장은 폴백이 있어 선택 작업으로 분리됐다.

| 분류 | 전체 | 확정 | 초안 | 없음 | 제작 규격 → 화면 표시 |
|---|---:|---:|---:|---:|---|
| 공용 점장·촌장 | 6 | 0 | 6 | 0 | 144×144 → 72×72 |
| 직원 | 8 | 0 | 8 | 0 | 144×144 → 72×72 |
| 물건 | 80 | 0 | 0 | 80 | 128×224 → 64×112 |
| 손님 필드 | 30 | 0 | 30 | 0 | 128×128 → 64×64 |
| 손님 카드 1단 | 30 | 0 | 20 | 10 | 512×768 → 카드 화면 |
| 쥐·까마귀·삽살개 | 3 | 0 | 0 | 3 | 128×128 → 64×64 |
| 가게별 좌판 | 10 | 0 | 0 | 10 | 192×176 → 96×88 |
| 카드 뒷면·룰렛 | 3 | 0 | 2 | 1 | 512×768 / 512×512 / 64×96 |
| **필수 합계** | **170** | **0** | **66** | **104** | |
| 손님 성장 카드 (선택) | 90 | 0 | 0 | 90 | 512×768 |
| 가게별 점장 (선택) | 20 | 0 | 0 | 20 | 144×144 → 72×72 |
| **전체 관리 대상** | **280** | **0** | **66** | **214** | |

제작 우선순위는 최신 주문서대로 `손님 필드 30 → 카드 1단 30 → 점장 → 직원 → 물건 80 → 좌판·나쁜 놈`이다.
손님 필드 30종, 점장, 직원은 모두 초안이므로 다음 큰 묶음은 손님 카드 1단으로 넘어간다. 성장 카드와 전용 점장은 필수 작업 뒤로 둔다.

---

## 과거 게임 화면 기록

<table>
  <tr>
    <td align="center"><img src="./qa/village-map-v1.png" width="280" alt="Godot 이전 HTML 마을 화면"></td>
  </tr>
  <tr>
    <td><strong>Legacy HTML/CSS QA</strong><br>Godot 전환 전의 세로 마을 화면 구조 시험. 현재 런타임 화면이나 카메라 기준으로 사용하지 않는다.</td>
  </tr>
</table>

최신 게임 브랜치에는 `godot/shot 2.png`가 한 장 보존돼 있다. 대표 화면이 안정되면
`docs/art/qa/godot-*.png`로 옮겨 날짜와 확인 커밋을 함께 남긴다.

---

## 아카이브 갱신 규칙

1. 마스터 원화와 게임용 축소 PNG를 둘 다 보존한다.
2. 반려된 버전도 삭제하지 않고 `Revision` 또는 `Rejected` 이유와 함께 둔다.
3. 게임 연결 여부는 별도 표식으로 남기고, 연결됐다는 이유만으로 `확정`하지 않는다.
4. `확정`은 최신 규격·Godot 화면 검수·사용자 승인을 모두 통과했을 때만 사용한다.
5. 생성물이 추가될 때마다 이 문서에 썸네일을 먼저 놓고 생성 로그 ID를 연결한다.
6. 파일명 목록만 있는 문서는 주문서이고, 이 문서는 실제 이미지를 보는 기록이다.
