import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () => state.loadAll(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  _buildNotificationBanner(),
                  const SizedBox(height: 20),
                  _buildBrowseHeader(),
                  const SizedBox(height: 14),
                  _buildFriendsGrid(),
                  const SizedBox(height: 24),
                  _buildMoreRooms(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Friends' Rooms",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications, color: AppColors.gold, size: 18),
        ),
      ],
    );
  }

  Widget _buildNotificationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🐑', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DreamCo. visited your room',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '2 minutes ago',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'View all ›',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Browse Friends',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            const Text(
              "Everyone's rooms are public",
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.check_circle, color: AppColors.green, size: 14),
          ],
        ),
      ],
    );
  }

  Widget _buildFriendsGrid() {
    final friends = [
      _FriendData(
        name: 'Sleepy01',
        isOnline: true,
        nights: 12,
        avgSleep: '8.1h',
        rank: 'Top 5%',
        isFriend: false,
        roomColors: [const Color(0xFF2a2040), const Color(0xFF1c1830)],
      ),
      _FriendData(
        name: 'MoonWlk',
        isOnline: true,
        nights: 9,
        avgSleep: '7.6h',
        rank: 'Top 10%',
        isFriend: false,
        roomColors: [const Color(0xFF302818), const Color(0xFF251e14)],
      ),
      _FriendData(
        name: 'DreamCo.',
        isOnline: true,
        nights: 7,
        avgSleep: '7.2h',
        rank: 'Top 20%',
        isFriend: true,
        roomColors: [const Color(0xFF2a2040), const Color(0xFF1c1830)],
      ),
      _FriendData(
        name: 'NapQueen',
        isOnline: true,
        nights: 6,
        avgSleep: '6.9h',
        rank: 'Top 20%',
        isFriend: true,
        roomColors: [const Color(0xFF0d1b3e), const Color(0xFF1c2340)],
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.58,
      ),
      itemCount: friends.length,
      itemBuilder: (context, index) => _buildFriendCard(friends[index]),
    );
  }

  Widget _buildFriendCard(_FriendData friend) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room preview
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: friend.roomColors,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: const Center(
              child: Text('🐑', style: TextStyle(fontSize: 40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        friend.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (friend.isOnline) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('🔥 ', style: TextStyle(fontSize: 10)),
                    Text(
                      '${friend.nights} nights',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    const Text('🌙 ', style: TextStyle(fontSize: 10)),
                    Text(
                      '${friend.avgSleep} avg',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('🏆 ', style: TextStyle(fontSize: 10)),
                    Text(
                      friend.rank,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Visit Room button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Visit Room',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Add Friend / Friends button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: friend.isFriend
                        ? AppColors.green.withValues(alpha: 0.15)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: friend.isFriend
                          ? AppColors.green.withValues(alpha: 0.3)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      friend.isFriend ? '✓ Friends' : '👤+ Add Friend',
                      style: TextStyle(
                        color: friend.isFriend ? AppColors.green : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreRooms() {
    final rooms = ['CozyCloud', 'StarryNap', 'PillowPals', 'DreamySheep'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'More rooms',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'View more ›',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rooms.length,
            separatorBuilder: (context2, idx) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2a2040).withValues(alpha: 0.8),
                          const Color(0xFF1c1830),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Center(
                      child: Text('🐑', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rooms[index],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FriendData {
  final String name;
  final bool isOnline;
  final int nights;
  final String avgSleep;
  final String rank;
  final bool isFriend;
  final List<Color> roomColors;

  _FriendData({
    required this.name,
    required this.isOnline,
    required this.nights,
    required this.avgSleep,
    required this.rank,
    required this.isFriend,
    required this.roomColors,
  });
}
