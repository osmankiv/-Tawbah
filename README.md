<<<<<<< HEAD
# Tawbah2

A new Flutter project created with FlutLab - https://flutlab.io

## Getting Started

A few resources to get you started if this is your first Flutter project:

- https://flutter.dev/docs/get-started/codelab
- https://flutter.dev/docs/cookbook

For help getting started with Flutter, view our
https://flutter.dev/docs, which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Getting Started: FlutLab - Flutter Online IDE

- How to use FlutLab? Please, view our https://flutlab.io/docs
- Join the discussion and conversation on https://flutlab.io/residents
=======
Tawbah | توبة
Intelligent AI System for Lowering the Gaze — Android App

Tawbah is a professional Android application that helps young people lower their gaze by intelligently filtering on-screen images using Artificial Intelligence. The system selectively blurs images of females only, while keeping the rest of the screen fully visible and usable.

Vision

In a world full of visual distractions, Tawbah was created to support youth in maintaining focus, purity of sight, and ethical browsing — without isolating them from their phone or blocking useful content.

Overview

Unlike traditional content blockers that shut down entire apps or websites, Tawbah works at the image level, directly on the device screen:

Helps users practice غضّ البصر
Preserves normal phone usage across all apps
Blurs only what needs to be blurred
Encourages self-discipline, not isolation

The application runs locally on Android and uses on-device AI (no internet required) to analyze and filter images in real time, through a system-wide overlay.

Key Features
Intelligent selective image filtering, applied system-wide over any app
Female-only image detection
Real-time, on-device processing (no data leaves the phone)
No app or website blocking — only the image itself is filtered
Fully local & privacy-respecting
Adjustable blur strength and detection sensitivity
How It Works

Tawbah operates as an Android system overlay combined with on-device AI models:

The app requests overlay ("display over other apps") and screen-capture permissions
A lightweight, continuous screen capture pipeline reads the current screen content
YOLOv8n detects people/persons present in the captured frame
A lightweight gender classification model evaluates each detected person
If a female is detected, a blur is rendered over that region on the overlay
The rest of the screen is left untouched, so browsing stays smooth and functional

This allows a respectful, uninterrupted phone experience across any app or browser.

Technologies Used
Flutter / Dart — app UI and overlay logic
flutter_overlay_window — system-wide overlay window
TensorFlow Lite — on-device inference (YOLOv8n + gender classifier)
YOLOv8n — person detection
Custom gender classification model (fine-tuned, TFLite-converted)
Android (native platform)
System Requirements
Android 8.0 (API 26) or later
"Display over other apps" permission
Screen capture permission (granted per session, per Android policy)
~50MB free storage for on-device models
Installation (Development)
Clone the repository
bash
git clone https://github.com/osmankiv/tawbah.git
cd tawbah
Install dependencies
bash
flutter pub get
Run the app
bash
flutter run
Grant permissions (first run)

On first launch, the app will prompt for:

Overlay permission ("Display over other apps") — required to render the blur layer
Screen capture permission — required each time the filter is activated (Android system requirement)
Configuration

You can customize:

Detection sensitivity
Blur strength
Gender confidence threshold
Capture frequency (frames analyzed per second, to balance battery vs. responsiveness)
Privacy & Ethics
All processing happens on-device
No images are saved or stored
No external servers or APIs are contacted
No tracking or monitoring of user behavior

Tawbah is designed to support moral discipline, not surveillance.

Use Cases
Personal self-discipline
Youth guidance tools
Religious and conservative environments
Educational institutions
Safe browsing setups on personal devices
Limitations
AI accuracy depends on image clarity and screen content
Some edge cases may bypass detection
Continuous screen capture has a battery/performance cost
Requires manual permission grants due to Android security policy
Future Plans
Improved gender classification accuracy
Adaptive capture frequency for better battery life
iOS feasibility study (iOS has stricter overlay/screen-capture restrictions)
User profiles and scheduling (e.g., auto-enable during certain hours)
Contribution

Contributions are welcome. Feel free to fork the project, open issues, or submit pull requests.

License

MIT License

Purpose

"قُلْ لِلْمُؤْمِنِينَ يَغُضُّوا مِنْ أَبْصَارِهِمْ" — سورة النور

Tawbah exists to help, not to force — a companion on the path of self-control and awareness.

Author

Developed with sincerity, to help youth walk a cleaner digital path.
>>>>>>> 08339b4d3b94423f7ed3b67d813e60c2160bb66f
