import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/energy_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  late TextEditingController _batteryCtrl;
  late TextEditingController _panelCtrl;
  late TextEditingController _lowAlertCtrl;
  late TextEditingController _criticalAlertCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<EnergyProvider>();
    _batteryCtrl = TextEditingController(
      text: p.batteryCapacityWh.toStringAsFixed(0),
    );
    _panelCtrl = TextEditingController(
      text: p.panelCapacityWp.toStringAsFixed(0),
    );
    _lowAlertCtrl = TextEditingController(
      text: p.lowBatteryPercent.toStringAsFixed(0),
    );
    _criticalAlertCtrl = TextEditingController(
      text: p.criticalBatteryPercent.toStringAsFixed(0),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    final p = context.read<EnergyProvider>();
    final battery = double.tryParse(_batteryCtrl.text) ?? 2400;
    final panel = double.tryParse(_panelCtrl.text) ?? 400;
    final low = double.tryParse(_lowAlertCtrl.text) ?? 30;
    final crit = double.tryParse(_criticalAlertCtrl.text) ?? 15;

    await p.setBatteryCapacity(battery);
    await p.setPanelCapacity(panel);
    await p.setAlertThresholds(low, crit);
    await p.completeOnboarding();

    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(context),
                  _buildBatteryPage(context),
                  _buildAlertsPage(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _nextPage,
                  child: Text(_currentPage == 2 ? 'Finish Setup' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.energy_savings_leaf,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to EquiCare',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s configure your system so the app can accurately estimate runtime, charge time, and send you the right alerts.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryPage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hardware Setup',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the specifications of your solar system. You can find these on the labels of your battery and solar panels.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _batteryCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Battery Capacity (Wh)',
              helperText: 'E.g., 200Ah at 12V = 2400 Wh',
              border: OutlineInputBorder(),
              suffixText: 'Wh',
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _panelCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Solar Panel Capacity (Wp)',
              helperText: 'Total wattage of all panels',
              border: OutlineInputBorder(),
              suffixText: 'Wp',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsPage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alert Thresholds',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'When should the app warn you? A clinic with a vaccine fridge might need earlier warnings than a hostel with just lights.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _lowAlertCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Low Battery Warning (%)',
              border: OutlineInputBorder(),
              suffixText: '%',
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _criticalAlertCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Critical Battery Alert (%)',
              border: OutlineInputBorder(),
              suffixText: '%',
            ),
          ),
        ],
      ),
    );
  }
}
