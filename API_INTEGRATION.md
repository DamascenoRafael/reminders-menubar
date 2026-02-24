# API Integration Guide

This guide explains how REST API support is integrated into the `reminders-menubar` project.

## Added Files

The following API files are included in the project:

```text
reminders-menubar/
└── Services/
    ├── APIResponse.swift    # API response helpers
    └── APIServer.swift      # Swifter-based HTTP server
```

## Integration Steps

### 1. Add the Swifter Dependency

In Xcode:

1. Open `reminders-menubar.xcodeproj`.
2. Select the project in the navigator.
3. Select the `reminders-menubar` target.
4. Open the `Package Dependencies` tab.
5. Click `+` to add a package.
6. Enter `https://github.com/httpswift/swifter.git`.
7. Select a version and add it to the `reminders-menubar` target.

### 2. Integrate with `AppDelegate.swift`

Use the API server singleton and initialize it on launch:

```swift
private var apiServer: APIServer?

func applicationDidFinishLaunching(_ aNotification: Notification) {
    apiServer = APIServer.shared
    apiServer?.initialize()
}

func applicationWillTerminate(_ aNotification: Notification) {
    apiServer?.stop()
}
```

### 3. Add API Files to the Xcode Target

If files are not already part of the target:

1. In Xcode, right-click the `Services` folder.
2. Select `Add Files to reminders-menubar...`.
3. Add API-related `.swift` files.
4. Ensure they are included in target membership for `reminders-menubar`.

## API Endpoints

After launching the app and enabling API Server in settings, the API is available at:

- `http://localhost:7777` (default)
- Or your configured custom port

| Method | Endpoint | Description |
|------|------|------|
| GET | `/` | API information |
| GET | `/health` | Health check |
| GET | `/api/v1/status` | Authorization and server status |
| GET | `/api/v1/projects` | List all projects (Todoist-style) |
| GET | `/api/v1/tasks` | List tasks (Todoist-style), supports `project_id`/`project_ids`, `project_name`/`project_names`, `exclude_project_ids`, `exclude_project_names`, and `filter` |
| POST | `/api/v1/tasks` | Create a task (Todoist-style) |
| POST | `/api/v1/tasks/:id/close` | Complete a task |
| POST | `/api/v1/tasks/:id/reopen` | Reopen a task |
| DELETE | `/api/v1/tasks/:id` | Delete a task |

## Test Commands

```bash
# Basic checks (default port 7777)
curl http://localhost:7777/
curl http://localhost:7777/health
curl http://localhost:7777/api/v1/status
curl http://localhost:7777/api/v1/projects
curl http://localhost:7777/api/v1/tasks
```

## Notes

1. **Permissions**: The app must have Reminders permission to work with EventKit data.
2. **Port**: Default port is `7777`; ensure the selected port is not occupied.
3. **Sandboxing**: If App Sandbox is enabled, make sure network access is configured correctly.

## Troubleshooting

If the API server does not start:

1. Check whether the port is already in use (example for default port): `lsof -i :7777`
2. Check Xcode console logs for startup errors.
3. Verify all API source files are included in the `reminders-menubar` target.
