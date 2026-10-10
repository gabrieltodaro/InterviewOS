# InterviewOS

InterviewOS is an iOS app for tracking job opportunities and interview processes. Each opportunity has its own Kanban board, job description, process cards, debriefs, and linked interview questions. Data is stored with SwiftData; optional iCloud sync uses CloudKit.

## Requirements

- Xcode with an iOS 26 SDK and an iOS 26 simulator
- macOS capable of running that Xcode version

The app target currently has an **iOS 26.0** deployment target. The Swift packages declare iOS 17.0 as their minimum, but the app target setting determines which devices can run the app.

## Open and run

1. Open `InterviewOSApp/InterviewOSApp.xcodeproj` in Xcode.
2. Select the shared **InterviewOSApp** scheme and an iOS simulator.
3. Press **Run** (`Command-R`).

Xcode resolves the four local Swift packages from `Packages/`. No package installation or server is required. The app starts in local-only mode, so an Apple Developer team is not needed for simulator use.

To build from Terminal:

```sh
xcodebuild -project InterviewOSApp/InterviewOSApp.xcodeproj \
  -scheme InterviewOSApp \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' build
```

## Use the app

1. In **Opportunities**, tap **+** and enter a company, role title, and job description. Saving creates the default stages: Applied, Scheduling, Interviewing, Waiting, Offer, and Closed.
2. Open the opportunity board. Add a process card from a column, then drag it to another column to change its stage.
3. Open a card to edit its type, status, people, links, schedule, and debrief. Link an existing question or create one inline. Use **Save** to persist card edits.
4. Use **Question Bank** to create and edit questions, search their text, and filter by tags.
5. For a scheduled card, use **Add to Calendar** or **Schedule Notification**. The app requests the corresponding permission when you first use that action. Notifications are set for 60 minutes before the scheduled time when possible.

## Project layout

| Path | Responsibility |
| --- | --- |
| `InterviewOSApp/InterviewOSApp.xcodeproj` | Xcode project and shared app scheme |
| `InterviewOSApp/InterviewOSApp` | App entry, tabs, settings, EventKit and notification scheduling |
| `Packages/InterviewOSDomain` | Framework-independent models and default stages |
| `Packages/InterviewOSPersistence` | Repository protocols and `AppServices` dependency contract |
| `Packages/InterviewOSApplePersistence` | SwiftData models, mapping, repositories, and container configuration |
| `Packages/InterviewOSUI` | SwiftUI screens, Kanban components, and preview mocks |

The UI package works through repository protocols and does not import SwiftData. Its key screen previews use `MockAppServices`, with `MockInterviewScheduler` for the card detail preview.

## iCloud sync

The Settings tab offers an **iCloud Sync** toggle. The app starts with a local SwiftData container. If sync is enabled, it attempts a CloudKit-backed container and falls back to local-only mode if container creation fails. The current mode is shown in Settings.

To configure CloudKit for a signed build:

1. Select the **InterviewOSApp** target in Xcode and set your Team and unique bundle identifier under **Signing & Capabilities**.
2. Enable **iCloud**, select **CloudKit**, and configure a CloudKit container for that bundle identifier.
3. Update `InterviewOSApp/InterviewOSApp/InterviewOSApp.entitlements` to match the selected container. The project already references this file.
4. Enable code signing for the target when building for a physical device. The project currently has `CODE_SIGNING_ALLOWED = NO` for simulator builds.

CloudKit is optional. Data can be created and used without a network connection in local mode.

## Calendar and notifications

`AppleInterviewScheduler` uses EventKit to create or update a calendar event for a scheduled card. The card stores the event identifier for later updates. It uses UserNotifications to request permission and schedule a local reminder; the request identifier is stored on the card. The app's `Info.plist` contains the calendar permission message.

## Quick verification

- Create an opportunity with a job description and reopen it.
- Add a card, drag it to a different column, relaunch, and confirm its stage.
- Set a future date on a card, save, add it to Calendar, and grant access when prompted.
- Schedule a notification for the same card and grant notification access when prompted.
