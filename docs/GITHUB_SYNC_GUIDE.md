# GitHub → 로컬 동기화 절차

> 저장소: [modam2026/app_wallet_app](https://github.com/modam2026/app_wallet_app)  
> 로컬 경로: `C:\DEV_flutter\app_wallet_app`  
> 작성일: 2026-03-12

---

## 1. 최초 1회 설정 (처음 연결할 때만)

로컬 폴더에 remote(원격 저장소)가 연결되어 있지 않은 경우 아래 절차를 진행합니다.

### 1-1. PowerShell 터미널에서 프로젝트 폴더로 이동

```powershell
cd C:\DEV_flutter\app_wallet_app
```

### 1-2. remote 연결 확인

```powershell
git remote -v
```

> 아무것도 출력되지 않으면 remote가 없는 상태 → 1-3으로 이동

### 1-3. remote 추가

```powershell
git remote add origin https://github.com/modam2026/app_wallet_app.git
```

### 1-4. GitHub 내용 가져오기

```powershell
git fetch origin
```

### 1-5. 로컬을 GitHub master 브랜치로 강제 초기화

```powershell
git reset --hard origin/master
```

> ⚠ 로컬에서 수정한 내용은 **모두 사라집니다.**

### 1-6. upstream 브랜치 설정 (이후 git pull 편의를 위해)

```powershell
git branch --set-upstream-to=origin/master master
```

---

## 2. 이후 동기화 (평상시 사용)

remote가 이미 연결된 상태에서 GitHub 최신 내용을 받을 때 사용합니다.

### 2-1. 일반 동기화 (로컬 변경사항 유지)

```powershell
git pull
```

### 2-2. GitHub 내용으로 강제 덮어쓰기 (로컬 변경사항 무시)

```powershell
git fetch origin
git reset --hard origin/master
```

> ⚠ 로컬에서 수정한 내용은 **모두 사라집니다.**

---

## 3. 로컬에만 있는 파일(untracked) 삭제

`git reset --hard`는 git이 추적하지 않는 파일은 삭제하지 않습니다.  
untracked 파일까지 완전히 삭제하려면 아래 명령을 사용합니다.

### 3-1. 삭제될 파일 미리 확인 (dry-run)

```powershell
git clean -nfd
```

### 3-2. 실제 삭제

```powershell
git clean -fd
```

---

## 4. 앱 재빌드 및 설치

GitHub에서 받은 최신 코드로 앱을 빌드하고 폰에 설치합니다.

### 4-1. DB를 초기화하고 싶을 때 (앱 완전 삭제 후 재설치)

```powershell
# 앱 완전 삭제 (DB 포함)
& "C:\Users\modam\AppData\Local\Android\Sdk\platform-tools\adb.exe" -s R3CW8013A7B uninstall com.modamtech.app_wallet_app

# APK 빌드
flutter build apk

# 폰에 설치
flutter install -d R3CW8013A7B --release
```

### 4-2. DB 유지하고 앱만 업데이트할 때

```powershell
flutter build apk
flutter install -d R3CW8013A7B --release
```

---

## 5. 참고 사항

| 명령어 | 설명 |
|---|---|
| `git remote -v` | 현재 연결된 remote 확인 |
| `git status` | 로컬 변경사항 확인 |
| `git log --oneline -5` | 최근 커밋 5개 확인 |
| `git pull` | GitHub 최신 내용 받기 (로컬 변경사항 유지) |
| `git fetch origin` + `git reset --hard origin/master` | GitHub 내용으로 강제 덮어쓰기 |
| `git clean -fd` | untracked 파일 삭제 |

---

## 6. 주의사항

- `git reset --hard`는 **되돌릴 수 없습니다.** 중요한 로컬 변경사항은 미리 백업하세요.
- `flutter install`은 앱을 **업데이트(데이터 유지)** 합니다. DB 초기화가 필요하면 `adb uninstall` 후 재설치하세요.
- `adb` 명령어가 인식되지 않으면 전체 경로를 사용하세요:  
  `C:\Users\modam\AppData\Local\Android\Sdk\platform-tools\adb.exe`
