import 'package:debug_toolkit/debug_toolkit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize the toolkit
  DebugToolkit.initialize(
    maxLogs: 500,
    maxRequests: 200,
    showFloatingButton: true,
    environment: 'development',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Debug Toolkit Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Dio _dio;

  @override
  void initState() {
    super.initState();

    // 2. Add the Dio interceptor
    _dio = Dio()..interceptors.add(DebugToolkit.dioInterceptor());

    // 3. Show the floating debug button after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugToolkit.showOverlay(context);
    });
  }

  Future<void> _makeRequest() async {
    DebugToolkit.log('Making API request', tag: 'Network');

    try {
      await _dio.get('https://jsonplaceholder.typicode.com/posts/1');
      DebugToolkit.log('Request succeeded',
          level: LogLevel.info, tag: 'Network');
    } catch (e) {
      DebugToolkit.log('Request failed: $e',
          level: LogLevel.error, tag: 'Network');
    }
  }

  Future<void> _makeFailedRequest() async {
    DebugToolkit.log('Making failing request',
        level: LogLevel.warning, tag: 'Network');

    try {
      await _dio.get('https://jsonplaceholder.typicode.com/posts/9999999');
    } catch (e) {
      DebugToolkit.log('Expected failure: $e',
          level: LogLevel.error, tag: 'Network');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Toolkit Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _makeRequest,
              child: const Text('Make GET Request'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _makeFailedRequest,
              child: const Text('Make Failing Request'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                DebugToolkit.log('Button pressed', tag: 'UI');
                DebugToolkit.log(
                  'User action logged',
                  level: LogLevel.debug,
                  tag: 'UI',
                );
              },
              child: const Text('Add Log Entries'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => DebugToolkit.showPanel(context),
              child: const Text('Open Debug Panel'),
            ),
          ],
        ),
      ),
    );
  }
}
