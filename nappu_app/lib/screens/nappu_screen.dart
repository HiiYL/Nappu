import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';

class NappuScreen extends StatefulWidget {
  const NappuScreen({super.key});

  @override
  State<NappuScreen> createState() => _NappuScreenState();
}

class _NappuScreenState extends State<NappuScreen> {
  Future<bool> _confirmPurchase(String itemName, int price) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Purchase', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Buy $itemName for $price tokens?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buy', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('✨ ', style: TextStyle(fontSize: 18)),
                    const Text(
                      "Nappu's Room",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Customise with your tokens',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                _buildPetDisplay(state),
                const SizedBox(height: 14),
                _buildTokenDisplay(state),
                const SizedBox(height: 20),
                _buildShopSection(state),
                const SizedBox(height: 20),
                _buildRoomThemes(state),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  // Theme visual configs
  static const _themeVisuals = {
    'Night Sky': {
      'gradient': [Color(0xFF0d1b3e), Color(0xFF1c2340)],
      'scenery': '✨🌙⭐',
      'border': Color(0xFF2a3560),
    },
    'Sakura': {
      'gradient': [Color(0xFF2d1a2e), Color(0xFF3a1f3d)],
      'scenery': '🌸🌺🌷',
      'border': Color(0xFF5a3060),
    },
    'Mountain': {
      'gradient': [Color(0xFF1a2a1a), Color(0xFF243524)],
      'scenery': '⛰️🌲🌿',
      'border': Color(0xFF3a5040),
    },
  };

  Widget _buildPetDisplay(AppState state) {
    final progress = state.nappuXp / state.nappuMaxXp;
    final theme = _themeVisuals[state.selectedThemeName] ?? _themeVisuals['Night Sky']!;
    final gradientColors = theme['gradient'] as List<Color>;
    final scenery = theme['scenery'] as String;
    final borderColor = theme['border'] as Color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          // Scenery row
          Text(scenery, style: const TextStyle(fontSize: 18, letterSpacing: 8)),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              const Text('🐑', style: TextStyle(fontSize: 70)),
              if (state.equippedHatEmoji.isNotEmpty)
                Positioned(
                  top: 0,
                  right: 40,
                  child: Text(state.equippedHatEmoji, style: const TextStyle(fontSize: 24)),
                ),
              if (state.equippedOutfitEmoji.isNotEmpty)
                Positioned(
                  bottom: 5,
                  right: 35,
                  child: Text(state.equippedOutfitEmoji, style: const TextStyle(fontSize: 20)),
                ),
              if (state.equippedAccessoryEmoji.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 40,
                  child: Text(state.equippedAccessoryEmoji, style: const TextStyle(fontSize: 22)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Nappu · Lv. ${state.nappuLevel}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'XP: ${state.nappuXp} / ${state.nappuMaxXp}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenDisplay(AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.2),
            ),
            child: const Center(
              child: Text('🪙', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.tokens} tokens',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'available to spend',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopSection(AppState state) {
    final categories = ['Hats', 'Outfits', 'Accessories'];
    List<ShopItem> items;
    switch (state.selectedCategory) {
      case 'Outfits':
        items = state.outfits;
        break;
      case 'Accessories':
        items = state.accessories;
        break;
      default:
        items = state.hats;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outfits & Accessories',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: categories.map((cat) {
            final selected = state.selectedCategory == cat;
            return Expanded(
              child: GestureDetector(
                onTap: () => state.setCategory(cat),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.surfaceLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.accent : AppColors.cardBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () async {
                if (item.owned) {
                  state.equipItem(item, state.selectedCategory);
                } else {
                  if (state.tokens < item.price) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Not enough tokens!'), backgroundColor: AppColors.red),
                    );
                    return;
                  }
                  final confirmed = await _confirmPurchase(item.name, item.price);
                  if (confirmed) {
                    state.purchaseItem(item, state.selectedCategory);
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: item.equipped
                      ? AppColors.greenDark.withValues(alpha: 0.3)
                      : item.owned
                          ? AppColors.surfaceLight
                          : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.equipped
                        ? AppColors.green
                        : item.owned
                            ? AppColors.cardBorder
                            : AppColors.cardBorder,
                    width: item.equipped ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    if (item.equipped)
                      const Text(
                        '✓ ON',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (item.owned)
                      const Text(
                        'Owned',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 2),
                          Text(
                            '${item.price}',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoomThemes(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Room Themes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: state.roomThemes.map((theme) {
            return Expanded(
              child: GestureDetector(
                onTap: () async {
                  if (theme.owned) {
                    state.selectRoomTheme(theme.name);
                  } else {
                    if (state.tokens < theme.price) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Not enough tokens!'), backgroundColor: AppColors.red),
                      );
                      return;
                    }
                    final confirmed = await _confirmPurchase(theme.name, theme.price);
                    if (confirmed) {
                      state.purchaseRoomTheme(theme.name);
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.selected ? AppColors.surfaceLight : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.selected ? AppColors.gold : AppColors.cardBorder,
                      width: theme.selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(theme.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(
                        theme.name,
                        style: TextStyle(
                          color: theme.selected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: theme.selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (!theme.owned)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 2),
                              Text(
                                '${theme.price}',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
