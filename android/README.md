# LearnHarness Android v1

A native Flutter Android client for the LearnHarness server in this fork.
This is a fork of [amosblomqvist/learnharness](https://github.com/amosblomqvist/learnharness),
kept under the same AGPL-3.0 license. Upstream code is untouched in this
scaffold; Android code lives only in `android/`.

## What v1 does

- Home: "What do you want to learn?" composer, Teach and Practice session
  creation, and recent sessions from `GET /api/chats`.
- Teaching: session list, session record from `GET /api/chats/:id`, and
  sending a turn with `POST /api/chat`.
- Practice: practice session creation (`kind: "practice"`) and the same
  session detail view.
- Graph: node and chain counts and proposition list from `GET /api/graph`.
- Settings: server URL and optional access token, stored on the phone.
  Provider keys are never entered here; they stay on the server.

## What v1 does not do

- It does not bundle the LearnHarness server, Electron, or the Claude Code
  CLI. The server must run elsewhere.
- No live SSE streaming yet: after sending, v1 reloads the record.
- No native question dock, confidence rail, plan tree, or pinch-zoom
  graph canvas yet. Those are follow-ups, not claimed here.
- No offline teaching, no local file access, and no desktop demo builder.

## Run the server

From the fork root, on a machine you control:

```sh
npm install
npm run dev
```

Then, in the Android app Settings, enter that server's address, for
example `http://192.168.1.10:3000` on the same network. For a phone
emulator, the host machine is usually `http://10.0.2.2:3000`.

Do not expose the server publicly without access control: the desktop
app has no remote login, and a public server would expose your provider
keys and spending.

## Build the APK

Do not rely on a local Gradle build in a sandbox. Use GitHub Actions:

- Workflow: `.github/workflows/android-apk.yml` in this fork
- Trigger: manual `workflow_dispatch` only
- Steps: Flutter 3.47.7, Java 17, `flutter pub get`, `flutter analyze`,
  `flutter test`, `flutter build apk --release`, upload the APK artifact

No APK is claimed until CI builds it and it is checked on a real phone.
