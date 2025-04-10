import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class NotificationItem {
  final String body;
  final String type;
  NotificationItem({required this.body, required this.type});
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Notifications',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NotificationHome(),
      routes: {
        '/details': (context) => NotificationDetailsPage(),
      },
    );
  }
}

class NotificationHome extends StatefulWidget {
  @override
  _NotificationHomeState createState() => _NotificationHomeState();
}

class _NotificationHomeState extends State<NotificationHome> {
  final List<NotificationItem> _history = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    messaging.getToken().then((value) {
      setState(() {
        _token = value;
      });
      print('FCM Token: $value');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String type = message.data['notificationType'] ?? 'regular';
      String body = message.notification?.body ?? 'No body';

      _history.add(NotificationItem(body: body, type: type));
      _showNotificationDialog(body, type);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Navigator.pushNamed(context, '/details');
    });
  }

  void _showNotificationDialog(String body, String type) {
    Color bgColor = type == 'important' ? Colors.red : Colors.blue;
    String title = type == 'important' ? '🚨 Important Message' : '🔔 Regular Message';

    // You can add sound/vibration here using packages like `flutter_local_notifications`

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor.withOpacity(0.1),
        title: Text(title, style: TextStyle(color: bgColor)),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Ok", style: TextStyle(color: bgColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FCM Notifications"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Your FCM Token:", style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(_token ?? "Loading..."),
            const SizedBox(height: 20),
            Text("Notification History", style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return ListTile(
                    title: Text(item.body),
                    leading: Icon(
                      item.type == 'important' ? Icons.warning : Icons.notifications,
                      color: item.type == 'important' ? Colors.red : Colors.blue,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationDetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notification Details")),
      body: Center(
        child: Text(
          "You tapped a notification!",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
