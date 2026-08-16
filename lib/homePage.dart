import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/firebase_service.dart';
import 'widgets/app_colors.dart';
import 'widgets/ui_components.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// HomePage uses Statefulness to handle animations.
// SingleTickerProviderStateMixin gives this class access to a Ticker, which triggers
// animation frames (essential for smooth animations).
class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Controller to drive the speed, duration, and behavior of the water wave animation
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Initialize the AnimationController to repeat every 2 seconds
    _waveController = AnimationController(
      vsync: this, // TickerProvider to sync animation with screen refresh rates
      duration: const Duration(seconds: 2),
    )..repeat(); // Keep the wave animation repeating indefinitely
  }

  // Dispose the controller when the screen is destroyed to prevent memory leaks
  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtain the instance of FirebaseService to get the status streams
    final firebase = Provider.of<FirebaseService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: firebase.tankStatusStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: AppColors.primaryBlue),
                    SizedBox(height: 20),
                    Text(
                      'Connecting to Tank...',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              debugPrint('STREAM ERROR: ${snapshot.error}');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.offline, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Connection Error\n${snapshot.error}',
                        style: const TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data ?? {};
            final num levelNum = data['current_level_liters'] ?? 0;
            final int level = levelNum.toInt();
            // Tank capacity = 10 Liters (10000 ml)
            final double percent = (level / 10).clamp(0.0, 1.0);
            final int percentInt = (percent * 100).toInt();
            final int emptyLiters = 10 - level;
            final bool isOnline = data['is_filling'] == true || data['is_wasting'] == true || level > 0;

            // UI-only conversion: display in milliliters (capacity = 10000 ml)
            final int levelMl = (level * 1000) ~/ 10;
            final int capacityMl = 10000;
            final int emptyMl = emptyLiters * 1000;
            final double intakeFlowMl = ((data['intakeFlow'] ?? 0.0) as num).toDouble() * 1000;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Smart Tank',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Live Monitoring',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => firebase.signOut(),
                        icon: const Icon(
                          Icons.logout,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Water Level Card ──
                  _DarkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with badge
                        Row(
                          children: [
                            const Icon(Icons.water_drop, color: AppColors.primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Water Level',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.goodBadge),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                percentInt >= 50 ? 'GOOD' : percentInt >= 20 ? 'LOW' : 'CRITICAL',
                                style: TextStyle(
                                  color: percentInt >= 50
                                      ? AppColors.goodBadge
                                      : percentInt >= 20
                                          ? Colors.orangeAccent
                                          : AppColors.offline,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Water level visualization + stats
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Animated water fill box
                            SizedBox(
                              width: 130,
                              height: 140,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  color: const Color(0xFF0A1628),
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      // Water fill
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 800),
                                        curve: Curves.easeInOut,
                                        height: 140 * percent,
                                        decoration: const BoxDecoration(
                                          gradient: AppColors.waterFillGradient,
                                        ),
                                      ),
                                      // Wave overlay
                                      Positioned(
                                        bottom: (140 * percent) - 12,
                                        left: 0,
                                        right: 0,
                                        child: AnimatedBuilder(
                                          animation: _waveController,
                                          builder: (context, child) {
                                            return CustomPaint(
                                              size: const Size(130, 24),
                                              painter: WaterWavePainter(
                                                animationValue: _waveController.value,
                                                color: AppColors.cyan.withOpacity(0.3),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      // Percentage text
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$percentInt',
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 42,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              '%',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 20),

                            // Stats column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _StatRow(label: 'Capacity', value: '$capacityMl ml'),
                                  const SizedBox(height: 10),
                                  _StatRow(label: 'Current', value: '$levelMl ml'),
                                  const SizedBox(height: 16),
                                  // Fill progress bar
                                  const Text(
                                    'Fill Progress',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 6,
                                      backgroundColor: const Color(0xFF1A2744),
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Footer: last updated + online/offline
                        Row(
                          children: [
                            Icon(Icons.access_time, color: AppColors.textMuted, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Last updated: ${isOnline ? "Just now" : "Waiting for hardware..."}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOnline ? AppColors.online : AppColors.offline,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: isOnline ? AppColors.online : AppColors.offline,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Sensor Readings Card ──
                  _InfoCard(
                    title: 'Intake Flow',
                    value: '${intakeFlowMl.toStringAsFixed(0)} ml/min',
                    icon: Icons.speed,
                  ),

                  const SizedBox(height: 20),

                  // ── Pump Control Card ──
                  _DarkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pump Control',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Divider(color: AppColors.cardBorder, height: 24),

                        // Solenoid Valves header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.water_drop,
                                color: AppColors.primaryBlue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Solenoid Valves',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Inlet Valve (Input Valve)
                        _ControlCard(
                          title: 'Inlet Valve',
                          subtitle: 'Pumping water to tank',
                          icon: Icons.water_drop,
                          value: data['filling_valve'] ?? false,
                          onChanged: (val) async {
                            try {
                              await firebase.toggleValve('filling_valve', val);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // Outlet Valve (Output Valve)
                        _ControlCard(
                          title: 'Outlet Valve',
                          subtitle: 'Water usage control',
                          icon: Icons.outbox,
                          value: data['outgoing_valve'] ?? false,
                          onChanged: (val) async {
                            try {
                              await firebase.toggleValve('outgoing_valve', val);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatusIndicator(
                        label: 'Filling',
                        isActive: data['is_filling'] ?? false,
                        activeColor: Colors.greenAccent,
                      ),
                      const SizedBox(width: 40),
                      _StatusIndicator(
                        label: 'Usage',
                        isActive: data['is_wasting'] ?? false,
                        activeColor: Colors.orangeAccent,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A row showing a label and bold value (e.g., "Capacity  1000 L")
class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Dark themed card container
class _DarkCard extends StatelessWidget {
  final Widget child;

  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

/// Helper widget to display a small circular status light (e.g. indicating active filling/wasting)
class _StatusIndicator extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;

  const _StatusIndicator({
    required this.label,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Glowing color if active, gray if inactive
            color: isActive ? activeColor : AppColors.textMuted,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Custom card widget with a title, icon, and switch toggling values in the database
class _ControlCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ControlCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ControlCard> createState() => _ControlCardState();
}

class _ControlCardState extends State<_ControlCard> {
  late bool _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  @override
  void didUpdateWidget(_ControlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync local state with external data when stream updates
    if (oldWidget.value != widget.value) {
      _localValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _localValue ? 'Open' : 'Closed',
                style: TextStyle(
                  color: _localValue ? AppColors.online : AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _localValue,
          onChanged: (val) {
            setState(() => _localValue = val);
            widget.onChanged(val);
          },
          activeColor: AppColors.primaryBlue,
          activeTrackColor: AppColors.primaryBlue.withOpacity(0.4),
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: const Color(0xFF1A2744),
        ),
      ],
    );
  }
}

/// A simple card to display a piece of information (e.g., sensor reading)
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
