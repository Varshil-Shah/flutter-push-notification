import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart';

import 'package:push_notification/models/push_notification.dart';
import 'package:push_notification/notification_badge.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FirebaseMessaging _messaging;
  late int _totalNotificationCounter;

  PushNotification? _notificationInfo;

  void registerNotification() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      sound: true,
      badge: true,
      provisional: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("USER GRANTED THE PERMISSON");

      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          PushNotification notification = PushNotification(
            title: message.notification!.title,
            body: message.notification!.body,
            dataTitle: message.data['title'],
            dataBody: message.data['body'],
          );
          setState(() {
            _totalNotificationCounter++;
            _notificationInfo = notification;
          });

          showSimpleNotification(
            Text(_notificationInfo!.title.toString()),
            leading:
                NotificationBadge(totalNotification: _totalNotificationCounter),
            subtitle: Text(_notificationInfo!.body.toString()),
            background: Colors.deepOrangeAccent.shade700,
            duration: const Duration(seconds: 3),
          );
        },
      );
    } else {
      debugPrint("PERMISSION DECLINED BY USER");
    }
  }

  void checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      PushNotification notification = PushNotification(
        title: initialMessage.notification!.title,
        body: initialMessage.notification!.body,
        dataTitle: initialMessage.data['title'],
        dataBody: initialMessage.data['body'],
      );
      setState(() {
        _totalNotificationCounter++;
        _notificationInfo = notification;
      });
    }
  }

  Future<void> backgroundNotificationHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    PushNotification notification = PushNotification(
      title: message.notification!.title,
      body: message.notification!.body,
      dataTitle: message.data['title'],
      dataBody: message.data['body'],
    );
    setState(() {
      _totalNotificationCounter++;
      _notificationInfo = notification;
    });

    showSimpleNotification(
      Text(message.notification!.title.toString()),
      leading: NotificationBadge(totalNotification: _totalNotificationCounter),
      subtitle: Text(message.notification!.body.toString()),
      background: Colors.deepOrangeAccent.shade700,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void initState() {
    // When app is running in background -
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        PushNotification notification = PushNotification(
          title: message.notification!.title,
          body: message.notification!.body,
          dataTitle: message.data['title'],
          dataBody: message.data['body'],
        );
        setState(() {
          _totalNotificationCounter++;
          _notificationInfo = notification;
        });
        showSimpleNotification(
          Text(message.notification!.title.toString()),
          leading:
              NotificationBadge(totalNotification: _totalNotificationCounter),
          subtitle: Text(message.notification!.body.toString()),
          background: Colors.deepOrangeAccent.shade700,
          duration: const Duration(seconds: 3),
        );
      },
    );

    // Normal notification -
    registerNotification();

    // When app is in terminated state -
    checkForInitialMessage();

    FirebaseMessaging.onBackgroundMessage(backgroundNotificationHandler);

    _totalNotificationCounter = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Push Notification"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Flutter Push Notification",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            NotificationBadge(totalNotification: _totalNotificationCounter),
            _notificationInfo != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 9),
                      Text(
                        "TITLE: ${_notificationInfo!.dataTitle ?? _notificationInfo!.title}",
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "BODY: ${_notificationInfo!.dataBody ?? _notificationInfo!.body}",
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
