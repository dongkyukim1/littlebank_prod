# 리틀뱅크 - 아이들 목표 달성 앱

아이들이 목표를 계획하고 성공적으로 달성하면 용돈을 관리할 수 있는 Flutter 앱입니다. 재미있고 직관적인 인터페이스를 통해 아이들의 금융 교육을 돕습니다.

## 주요 기능

- 회원가입 및 로그인 기능
- 목표 설정 및 관리
- 용돈 적립 및 목표 달성 진행도 확인
- 용돈 내역 관리
- 목표 달성 시 축하 메시지

## 스크린샷

(앱 출시 후 스크린샷이 추가될 예정입니다)

## 사용된 기술

- Flutter
- Material Design 3
- Google Fonts
- Percent Indicator 패키지 (진행률 표시)
- Provider (상태 관리)
- SharedPreferences (로컬 데이터 저장)

## 시작하기

1. 프로젝트 복제:
```
git clone https://github.com/yourusername/kids_goal_tracker.git
```

2. 의존성 설치:
```
flutter pub get
```

3. 앱 실행:
```
flutter run
```

## 프로젝트 구조

- `lib/models` - 데이터 모델 클래스 (사용자, 목표 등)
- `lib/screens` - 앱 화면 위젯 (로그인, 회원가입, 홈, 목표 상세 등)
- `lib/widgets` - 재사용 가능한 UI 컴포넌트
- `lib/theme` - 앱 테마 정의
- `lib/services` - API 통신 및 데이터 관리 서비스 (향후 구현)

## 향후 개발 계획

- 부모 연결 기능 (자녀 목표 관리 및 용돈 지급)
- 목표 달성 시 리워드 시스템
- 용돈 자동 적립 기능
- 목표 달성 통계 및 그래프
- 푸시 알림 기능 (목표 마감일 리마인더)

## 라이센스

MIT

# 개발 모드로 실행
flutter run -d <device-id>

# AAB 빌드
flutter build appbundle --release