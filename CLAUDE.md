# CLAUDE.md

## README 수정 규칙

README를 수정할 때는 반드시 영어/한국어 두 파일을 모두 업데이트해야 합니다.

- `README.md` — 영어
- `README.ko.md` — 한국어

## 배포 방법

릴리즈는 **git tag 푸시**로 GitHub Actions가 자동 처리합니다.
브랜치 push만으로는 워크플로우가 실행되지 않습니다.

```zsh
# 1. 변경사항 커밋 & push (버전은 워크플로우가 자동으로 덮어씀)
git add -p
git commit -m "feat: ..."
git push origin main

# 2. 다음 버전 태그 생성 & push → GitHub Actions 자동 실행
git tag v0.X.Y
git push origin v0.X.Y
```

워크플로우가 하는 일:
1. zsh 파일의 `_CLAUDE_TMUX_VERSION` 을 태그 버전으로 자동 업데이트
2. GitHub Release 생성
3. Homebrew 탭 formula 자동 업데이트 (SHA256 포함)

업데이트 후 사용자는 `claude-tmux update` 로 최신 버전 설치 가능.
