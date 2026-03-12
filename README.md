# Debug Toolkit

In-app debug panel for Flutter apps. Network inspector, log viewer, and system info — visible only in debug mode.

## Features

- **Network Inspector** — Capture all Dio HTTP calls with method, URL, headers, body, response, status, and latency
- **Log Viewer** — In-app log viewer with levels (DEBUG, INFO, WARNING, ERROR), search, filter, delete, and copy
- **System Info** — Device model, OS version, app version, build number, environment
- **Floating Button** — Draggable debug button overlay
- **Plugin System** — Register custom debug tool tabs
- **Debug Only** — All methods are no-ops in release builds

## Quick Start

### 1. Add dependency

```yaml
dependencies:
  debug_toolkit:
    git:
      url: https://github.com/your-org/debug_toolkit.git
```

### 2. Initialize

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  DebugToolkit.initialize(
    navigatorKey: navigatorKey,
    maxLogs: 500,
    maxRequests: 200,
    showFloatingButton: true,
    environment: 'development',
  );

  runApp(MyApp());
}
```

### 3. Add Dio interceptor

```dart
final dio = Dio();
dio.interceptors.add(DebugToolkit.dioInterceptor());
```

### 4. Show floating button

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    DebugToolkit.showOverlay(context);
  });
}
```

### 5. Log messages

```dart
DebugToolkit.log('User logged in', tag: 'Auth');
DebugToolkit.log('Payment failed', level: LogLevel.error, tag: 'Payment');
DebugToolkit.log('Cache hit', level: LogLevel.debug, tag: 'Cache');
```

### 6. Open panel programmatically

```dart
DebugToolkit.showPanel(context);
```

## Extending with Custom Tools

Register custom tabs that appear in the debug panel:

```dart
DebugToolkit.registerTool(DebugTool(
  name: 'Database',
  icon: Icons.storage,
  builder: (context) => MyDatabaseInspector(),
));
```

## Architecture

```
lib/src/
  core/           # Singleton API, in-memory storage
  domain/         # Models (LogEntry, NetworkEntry, DebugTool) and services
  data/           # Dio interceptor, system info collector
  presentation/   # UI: overlay, panel screen, tabs, widgets
```

## API Reference

| Method | Description |
| --- | --- |
| `DebugToolkit.initialize(...)` | Initialize the toolkit (no-op in release) |
| `DebugToolkit.log(message, {level, tag})` | Add a log entry |
| `DebugToolkit.dioInterceptor()` | Get Dio interceptor for network capture |
| `DebugToolkit.showOverlay(context)` | Show floating debug button |
| `DebugToolkit.hideOverlay()` | Hide floating debug button |
| `DebugToolkit.showPanel(context)` | Open debug panel screen |
| `DebugToolkit.registerTool(tool)` | Add custom tab to panel |
| `DebugToolkit.dispose()` | Clean up resources |

## Configuration

| Parameter | Default | Description |
| --- | --- | --- |
| `navigatorKey` | null | App's navigator key for overlay |
| `maxLogs` | 500 | Maximum log entries in memory |
| `maxRequests` | 200 | Maximum network entries in memory |
| `showFloatingButton` | true | Show draggable debug button |
| `environment` | null | Environment label (dev/staging/prod) |
