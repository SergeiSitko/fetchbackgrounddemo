import 'dart:developer';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    log("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  log('[BackgroundFetch] Headless event received.');
  // Do your work here...

  BackGroundWork.instance.incrementCounterValue();

  BackgroundFetch.finish(taskId);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final worker = BackGroundWork.instance;

  final taskId = 'com.listta';

  @override
  void initState() {
    super.initState();
    _configFetch();
  }

  Future<void> _configFetch() async {
    final status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      // <-- Event handler
      // This is the fetch-event callback.
      log("[BackgroundFetch] Event received $taskId");
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      // <-- Task timeout handler.
      // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
      log("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    log('[BackgroundFetch] configure success: $status');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('background job'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            ElevatedButton(
                onPressed: () {
                  BackgroundFetch.scheduleTask(
                    TaskConfig(
                        taskId: taskId,
                        delay: 30 * 1000,
                        periodic: true,
                        forceAlarmManager: true,
                        stopOnTerminate: false,
                        enableHeadless: true),
                  );
                },
                child: const Text('Schedule job')),
            ElevatedButton(
                onPressed: () {
                  BackgroundFetch.stop(taskId);
                },
                child: const Text('Cancel job')),
            ElevatedButton(
                onPressed: () async {
                  await worker.getCounterValue();
                  setState(() {});
                },
                child: const Text('Show current value')),
            const Spacer(),
            Text('Current value is ${worker.memoryValue}'),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class BackGroundWork {
  int memoryValue = 0;

  BackGroundWork._privateConstructor();

  static final BackGroundWork _instance = BackGroundWork._privateConstructor();

  static BackGroundWork get instance => _instance;

  incrementCounterValue() async {
    final oldValue = await getCounterValue();
    memoryValue = oldValue + 1;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setInt('BackGroundCounterValue', memoryValue);
  }

  Future<int> getCounterValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    memoryValue = prefs.getInt('BackGroundCounterValue') ?? 0;
    return memoryValue;
  }
}
