import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

void main() {
  runApp(const MyApp());
}

// نقطة دخول منفصلة تشتغل جوه الـ overlay نفسه
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BlurOverlayWidget(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _permissionGranted = false;
  bool _overlayActive = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await FlutterOverlayWindow.isPermissionGranted();
    setState(() => _permissionGranted = status);
  }

  Future<void> _requestPermission() async {
    final granted = await FlutterOverlayWindow.requestPermission();
    setState(() => _permissionGranted = granted ?? false);
  }

  Future<void> _toggleOverlay() async {
    if (_overlayActive) {
      await FlutterOverlayWindow.closeOverlay();
      setState(() => _overlayActive = false);
    } else {
      await FlutterOverlayWindow.showOverlay(
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
      );
      setState(() => _overlayActive = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Blur Filter')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _permissionGranted
                    ? 'صلاحية الـ Overlay ممنوحة ✅'
                    : 'محتاج صلاحية الـ Overlay',
              ),
              const SizedBox(height: 20),
              if (!_permissionGranted)
                ElevatedButton(
                  onPressed: _requestPermission,
                  child: const Text('طلب الصلاحية'),
                ),
              if (_permissionGranted)
                ElevatedButton(
                  onPressed: _toggleOverlay,
                  child: Text(_overlayActive ? 'إيقاف الفلتر' : 'تشغيل الفلتر'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// محتوى الـ overlay نفسه - حاليًا مربع بلور تجريبي ثابت
class BlurOverlayWidget extends StatelessWidget {
  const BlurOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            left: 100,
            top: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 300,
                  height: 400,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
