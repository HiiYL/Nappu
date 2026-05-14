import 'package:flutter/material.dart';

class SleepLog {
  final DateTime date;
  final String quality; // Poor, Okay, Good, Great
  final int bedtimeHour;
  final int wakeupHour;
  final double duration;

  SleepLog({
    required this.date,
    required this.quality,
    required this.bedtimeHour,
    required this.wakeupHour,
    required this.duration,
  });
}

class LockedApp {
  final String name;
  final IconData icon;
  final Color iconColor;
  final String status; // Locked, Reminder

  LockedApp({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.status,
  });
}

class ShopItem {
  final String name;
  final String emoji;
  final int price;
  final bool owned;
  final bool equipped;

  ShopItem({
    required this.name,
    required this.emoji,
    required this.price,
    this.owned = false,
    this.equipped = false,
  });

  ShopItem copyWith({bool? owned, bool? equipped}) {
    return ShopItem(
      name: name,
      emoji: emoji,
      price: price,
      owned: owned ?? this.owned,
      equipped: equipped ?? this.equipped,
    );
  }
}

class AppState extends ChangeNotifier {
  String userName = 'Aisyah';
  int tokens = 240;
  int streak = 7;
  int nappuLevel = 8;
  int nappuXp = 720;
  int nappuMaxXp = 1000;
  String nappuMood = 'happy';
  double lastNightSleep = 7.5;
  int sleepQualityPercent = 84;

  // Sleep tasks
  List<Map<String, dynamic>> sleepTasks = [
    {'task': 'No screen 30 mins before bed', 'coins': 20, 'done': true},
    {'task': 'Dim lights at 10:30 PM', 'coins': 15, 'done': true},
    {'task': '5-min mindfulness breathing', 'coins': 25, 'done': false},
    {'task': 'Sleep by 11:00 PM', 'coins': 30, 'done': false},
  ];

  // Weekly sleep data [hours, isIdeal]
  List<Map<String, dynamic>> weeklyData = [
    {'day': 'M', 'hours': 6.5, 'ideal': false},
    {'day': 'T', 'hours': 8.0, 'ideal': true},
    {'day': 'W', 'hours': 7.5, 'ideal': true},
    {'day': 'T', 'hours': 5.5, 'ideal': false},
    {'day': 'F', 'hours': 6.0, 'ideal': false},
    {'day': 'S', 'hours': 8.5, 'ideal': true},
    {'day': 'S', 'hours': 7.0, 'ideal': true},
  ];

  // App lock
  bool lockEnabled = true;
  int lockStartHour = 22;
  int lockStartMinute = 30;
  int lockEndHour = 7;
  int lockEndMinute = 0;

  List<LockedApp> lockedApps = [
    LockedApp(name: 'Instagram', icon: Icons.camera_alt, iconColor: const Color(0xFFe1306c), status: 'Locked'),
    LockedApp(name: 'TikTok', icon: Icons.music_note, iconColor: const Color(0xFF69c9d0), status: 'Locked'),
    LockedApp(name: 'WhatsApp', icon: Icons.chat_bubble, iconColor: const Color(0xFF25d366), status: 'Reminder'),
    LockedApp(name: 'YouTube', icon: Icons.play_arrow, iconColor: const Color(0xFFff0000), status: 'Locked'),
  ];

  // Shop items
  String selectedCategory = 'Hats';
  List<ShopItem> hats = [
    ShopItem(name: 'Top Hat', emoji: '🎩', price: 0, owned: true, equipped: true),
    ShopItem(name: 'Cap', emoji: '🧢', price: 0, owned: true),
    ShopItem(name: 'Crown', emoji: '👑', price: 120),
    ShopItem(name: 'Flower', emoji: '🌸', price: 80),
    ShopItem(name: 'Helmet', emoji: '🪖', price: 90),
    ShopItem(name: 'Grad Cap', emoji: '🎓', price: 100),
    ShopItem(name: 'Bear Ear', emoji: '🧸', price: 60),
    ShopItem(name: 'Halo', emoji: '✨', price: 200),
  ];

  List<ShopItem> outfits = [
    ShopItem(name: 'Pajamas', emoji: '👕', price: 0, owned: true, equipped: true),
    ShopItem(name: 'Sweater', emoji: '🧥', price: 100),
    ShopItem(name: 'Cape', emoji: '🦸', price: 150),
    ShopItem(name: 'Scarf', emoji: '🧣', price: 70),
  ];

  List<ShopItem> accessories = [
    ShopItem(name: 'Pillow', emoji: '🛏️', price: 50),
    ShopItem(name: 'Blanket', emoji: '🛋️', price: 80),
    ShopItem(name: 'Teddy', emoji: '🧸', price: 60),
    ShopItem(name: 'Moon Lamp', emoji: '🌙', price: 120),
  ];

  // Room themes
  List<Map<String, dynamic>> roomThemes = [
    {'name': 'Night Sky', 'emoji': '🌙', 'price': 0, 'owned': true, 'selected': true},
    {'name': 'Sakura', 'emoji': '🌸', 'price': 0, 'owned': true, 'selected': false},
    {'name': 'Mountain', 'emoji': '⛰️', 'price': 150, 'owned': false, 'selected': false},
  ];

  // Sleep quality for current log
  String currentSleepQuality = 'Good';
  int currentBedtime = 10;
  int currentWakeup = 6;

  void toggleTask(int index) {
    sleepTasks[index]['done'] = !sleepTasks[index]['done'];
    if (sleepTasks[index]['done']) {
      tokens += sleepTasks[index]['coins'] as int;
    } else {
      tokens -= sleepTasks[index]['coins'] as int;
    }
    notifyListeners();
  }

  void setSleepQuality(String quality) {
    currentSleepQuality = quality;
    notifyListeners();
  }

  void setBedtime(int hour) {
    currentBedtime = hour;
    notifyListeners();
  }

  void setWakeup(int hour) {
    currentWakeup = hour;
    notifyListeners();
  }

  void logSleep() {
    int duration = currentWakeup + (24 - currentBedtime);
    if (duration > 12) duration = currentBedtime - currentWakeup;
    tokens += 50;
    nappuXp += 30;
    if (nappuXp >= nappuMaxXp) {
      nappuLevel++;
      nappuXp -= nappuMaxXp;
    }
    notifyListeners();
  }

  void toggleLock() {
    lockEnabled = !lockEnabled;
    notifyListeners();
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void purchaseItem(ShopItem item, String category) {
    if (tokens >= item.price) {
      tokens -= item.price;
      List<ShopItem> list;
      switch (category) {
        case 'Hats':
          list = hats;
          break;
        case 'Outfits':
          list = outfits;
          break;
        default:
          list = accessories;
      }
      final idx = list.indexOf(item);
      if (idx != -1) {
        list[idx] = item.copyWith(owned: true);
      }
      notifyListeners();
    }
  }

  void equipItem(ShopItem item, String category) {
    List<ShopItem> list;
    switch (category) {
      case 'Hats':
        list = hats;
        break;
      case 'Outfits':
        list = outfits;
        break;
      default:
        list = accessories;
    }
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(equipped: list[i] == item);
    }
    notifyListeners();
  }

  int get sleepDuration {
    int d = currentWakeup + (24 - currentBedtime);
    if (d > 16) d = currentBedtime - currentWakeup;
    return d;
  }
}
