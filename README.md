# 台灣外送哥 Taiwan Delivery Bro

騎著機車穿梭台灣街頭的外送員人生模擬器！

A pixel-art delivery simulation game set in Taiwan's bustling streets. Accept orders, dodge police, navigate night markets, and build your delivery empire!

## Play Now

[https://aibotmars-web.github.io/dead-delivery/](https://aibotmars-web.github.io/dead-delivery/)

## Features

- Tap-to-move with A* pathfinding across a 50x50 tile city
- 5 district zones: Night Market, Residential, Commercial, Temple, Apartments
- Order accept/pickup/deliver loop with time pressure
- Police system — ride on sidewalks to save time, but risk fines!
- Parking tickets — red line violations, just like real Taiwan
- 20 chance/fate cards drawn after each delivery
- 10 city events with A/B choices
- Equipment upgrades (scooter, bag, phone, helmet, raincoat, gloves, GPS)
- Daily missions and 10 achievements
- Save/load system with login streak tracking

## Tech Stack

- Flutter 3.x + Flame Engine
- Dart
- Web-first (GitHub Pages), same codebase for iOS/Android

## Development

```bash
flutter pub get
flutter run -d chrome --web-port=8080
```

## Build

```bash
flutter build web --release
```

## License

All rights reserved.
