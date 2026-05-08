Unit testing scaffold for EdVenture

What I added:
- `EVQuizSessionStateTests.swift` — unit tests for `EVQuizSessionState` logic.
- `EVQuizQuestionTests.swift` — round-trip tests for `EVQuizQuestion`.

How to wire these into Xcode:
1. In Xcode open the `EdVenture` project.
2. Add a new target: `File` → `New` → `Target...` → select `iOS Unit Testing Bundle`.
3. Name it `EdVentureTests` and make sure `Language` is Swift and `Target to be tested` is `EdVenture`.
4. In the new test target's Build Settings ensure `Enable Testability` (`ENABLE_TESTABILITY`) is `YES` for the Debug configuration.
5. Add the files from `EdVentureTests/` into the test target (select the files and check the `EdVentureTests` box in the File Inspector).

Run tests:
- From Xcode: Product → Test (⌘U).
- From command line (requires xcodebuild):
```bash
xcodebuild -workspace EdVenture.xcworkspace -scheme EdVenture -destination 'platform=iOS Simulator,name=iPhone 14' test
```

Notes:
- I intentionally avoided editing `project.pbxproj` automatically. That prevents accidental project corruption — wiring the test target through Xcode is quick and safe.
- These tests focus on pure logic (no network or Firebase) so they should run quickly.

If you want, I can:
- Add the test target changes directly into `project.pbxproj` so tests appear immediately.
- Add more tests for other pure logic classes (e.g., `EVCredentialStore`, with keychain mocks).
