# Dart Future / async / await 완전 정리

> 작성일: 2026-03-12

---

## 1. Future 란?

`Future`는 **비동기 작업의 결과를 나중에 받겠다는 약속(Promise)** 입니다.

```
음식점에서 주문 → 번호표 받음 → 나중에 음식 나오면 수령
Future        → 번호표      → 나중에 결과값 반환
```

```dart
// Future<List<String>> 의 의미
Future<List<String>>
   │         │
   │         └── 최종적으로 받을 값의 타입: 문자열 리스트
   └── 지금 당장이 아니라 나중에 완료될 작업
```

---

## 2. 동기 vs 비동기

```dart
// 동기 - 결과가 즉시 반환됨
String getName() {
  return "홍길동";
}
String name = getName();  // 즉시 결과 받음

// 비동기 - 결과가 나중에 반환됨 (DB 조회, 네트워크 등)
Future<String> getNameFromDB() async {
  final db = await openDatabase(...);
  return "홍길동";
}
String name = await getNameFromDB();  // 완료될 때까지 대기
```

---

## 3. Future / async / await 관계

| 키워드 | 위치 | 역할 |
|---|---|---|
| `Future<T>` | 함수 반환 타입 | "나중에 T 타입을 반환할게" |
| `async` | 함수 선언부 | "이 함수는 비동기 함수야" |
| `await` | 함수 호출부 | "Future가 완료될 때까지 기다려" |

```dart
// 세 개가 항상 세트로 사용됨
Future<String> getNameFromDB() async {   // Future + async
  final db = await openDatabase(...);    // await
  return "홍길동";
}

// 호출할 때
String name = await getNameFromDB();     // await
```

---

## 4. await 없으면 어떻게 되나?

`await` 없이 `Future` 함수를 호출하면 **결과를 기다리지 않고 즉시 다음 줄로 넘어갑니다.**

```dart
// ❌ await 없음 → Future 객체(번호표)만 받고 즉시 다음 줄 실행
void loadData() {
  print("1. 시작");
  String name = getNameFromDB();  // Future 객체만 반환
  print("2. name = $name");       // "Instance of 'Future<String>'" 출력!
  print("3. 끝");
}
// 출력:
// 1. 시작
// 2. name = Instance of 'Future<String>'  ← 실제 값 아님!
// 3. 끝

// ✅ await 있음 → 완료될 때까지 기다렸다가 다음 줄 실행
void loadData() async {
  print("1. 시작");
  String name = await getNameFromDB();  // 완료될 때까지 대기
  print("2. name = $name");             // "홍길동" 출력
  print("3. 끝");
}
// 출력:
// 1. 시작
// (DB 대기...)
// 2. name = 홍길동  ✅
// 3. 끝
```

---

## 5. 기본값은 sync (동기)

Dart에서 함수는 **기본이 동기(sync)** 입니다.  
`sync` 키워드는 존재하지 않으며, `async`를 붙여야 비동기 함수가 됩니다.

```dart
// 아무것도 안 붙이면 → 이미 동기 함수 (기본값)
void loadData() {
  print("동기 함수");
}

// async 붙이면 → 비동기 함수로 변환
void loadData() async {
  await getNameFromDB();
}
```

> 단, `sync*`는 동기 제너레이터(Iterable 반환)에 사용하는 특수 키워드입니다.

---

## 6. 기본이 sync인데 왜 Future 함수는 기다리지 않나?

`loadData()`가 sync냐 async냐의 문제가 아니라,  
**호출하는 함수가 `Future`를 반환하느냐**가 핵심입니다.

```dart
// 호출하는 함수의 반환 타입에 따라 결정됨
String        getName()       → 즉시 결과 반환 (기다림)
Future<String> getNameFromDB() → Future 객체 반환 (기다리지 않음, await 필요)
```

```dart
// getNameFromDB()가 Future<String>을 반환하면
// loadData()가 sync라도 실제 값을 받을 수 없음
void loadData() {
  String name = getNameFromDB();  // 컴파일 에러 or Future 객체 반환
}

// await를 사용하려면 함수에 async 필요
void loadData() async {
  String name = await getNameFromDB();  // ✅ 실제 값 받음
}
```

---

## 7. 각각의 스레드로 처리되나? Dart vs Java

### Dart: 단일 스레드 + 이벤트 루프

```
Dart는 싱글 스레드입니다.
스레드를 새로 만들지 않고 이벤트 루프(Event Loop)로 비동기 처리합니다.

메인 스레드
    ↓
await getNameFromDB()  → DB 작업을 OS/플랫폼에 위임하고 이벤트 루프로 복귀
    ↓                     (다른 UI 작업, 이벤트 처리 계속)
DB 완료 이벤트 도착  → 이벤트 루프가 await 이후 코드 재개
```

### Java: 멀티 스레드

```java
// Java는 새 스레드를 직접 만들어서 처리
new Thread(() -> {
    String name = getNameFromDB();  // 별도 스레드에서 실행
    runOnUiThread(() -> textView.setText(name));
}).start();
```

### 비교

| | Dart | Java |
|---|---|---|
| 스레드 방식 | 단일 스레드 + 이벤트 루프 | 멀티 스레드 |
| 비동기 처리 | `Future` + `async/await` | `Thread`, `Callable`, `CompletableFuture` |
| 문법 | `await` 키워드 | `.get()`, `.thenApply()` 등 |
| 복잡도 | 상대적으로 단순 | 스레드 동기화 필요 |

---

## 8. Future를 반환하는 함수가 정해져 있나?

**아닙니다.** 두 가지 경우 모두 가능합니다.

### 8-1. 라이브러리/플랫폼에서 제공하는 Future 함수

```dart
// sqflite (DB)
Future<Database> openDatabase(...)
Future<List<Map>> rawQuery(...)

// http (네트워크)
Future<Response> http.get(...)

// File I/O
Future<String> file.readAsString()
```

### 8-2. 사용자 정의 함수에도 Future/async 적용 가능

```dart
// 직접 만드는 함수에도 자유롭게 적용 가능
Future<List<String>> getGroupNames() async {
  final db = await SQLHelper.appMngmntDB();
  final result = await db.rawQuery('SELECT name FROM groups');
  return result.map((row) => row['name'] as String).toList();
}

// 호출할 때
List<String> names = await getGroupNames();
```

---

## 9. async 선언 후 내부에 await가 없으면?

```dart
Future<void> loadData() async {
  print("시작");
  doSomething();   // await 없음
  print("끝");
}
```

**동작은 정상이지만 경고가 발생합니다.**

- 함수는 정상 실행됨
- `Future<void>`를 반환하지만 즉시 완료됨 (사실상 동기와 동일하게 동작)
- Dart 분석기가 `"async" keyword is used but no "await" found` 경고 표시

```dart
// 내부에 await가 없다면 async 제거하는 것이 올바름
void loadData() {   // async 불필요
  print("시작");
  doSomething();
  print("끝");
}
```

---

## 10. 전체 요약

```
Future  → 비동기 작업의 결과 타입 (나중에 줄게)
async   → 이 함수는 비동기 함수임을 선언 (await 사용 가능)
await   → Future가 완료될 때까지 기다림 (실제 값 받기)

규칙:
  1. await는 반드시 async 함수 안에서만 사용 가능
  2. Future 반환 함수 호출 시 await 없으면 실제 값 못 받음
  3. 함수 기본값은 sync, async 키워드로 비동기 전환
  4. 사용자 정의 함수에도 Future/async 자유롭게 적용 가능
  5. async 선언 후 내부에 await 없으면 불필요한 async (경고)
```

---

## 11. await가 필요한 작업 종류

| 작업 종류 | 예시 | async/await 필요 |
|---|---|---|
| 메모리 연산 | 변수 읽기, 계산 | ❌ |
| DB 조회 | sqflite | ✅ |
| 네트워크 통신 | API 호출 | ✅ |
| 파일 읽기/쓰기 | File I/O | ✅ |
| 타이머 대기 | `Future.delayed` | ✅ |
