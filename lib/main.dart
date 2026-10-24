import 'package:flutter/material.dart';

import 'device_apps.dart';
import 'screens/account.dart';
import 'screens/currency_picker.dart';
import 'screens/details.dart';
import 'screens/home.dart';
import 'screens/recurring.dart';
import 'screens/welcome.dart';
import 'store.dart';
import 'sfx.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SpentStore();
  await store.load();
  runApp(SpentScope(store: store, child: const SpentApp()));
}

class SpentApp extends StatelessWidget {
  const SpentApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Spent',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) => PhoneFrame(child: child!),
        home: const AuthGate(),
      );
}

/// On wide screens (the web preview), show the app inside a phone outline like the mockups.
/// On an actual phone the frame disappears and the app fills the screen.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;

  static const _size = Size(390, 844);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width < 600 || mq.size.height < 700) return child;

    final scale = ((mq.size.height - 48) / _size.height).clamp(0.6, 1.0);
    return ColoredBox(
      color: C.page,
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: _size.width,
            height: _size.height,
            decoration: BoxDecoration(
              color: C.screen,
              borderRadius: BorderRadius.circular(54),
              border: Border.all(color: Colors.white, width: 6),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 60, offset: Offset(0, 24))],
            ),
            clipBehavior: Clip.antiAlias,
            child: MediaQuery(
              data: mq.copyWith(size: _size, padding: const EdgeInsets.only(top: 50, bottom: 20), viewPadding: const EdgeInsets.only(top: 50, bottom: 20)),
              child: Material(
                type: MaterialType.transparency,
                child: Stack(children: [child, const _StatusBar()]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 12, 30, 0),
            child: Row(
              children: [
                Text('9:41', style: t(16, FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.signal_cellular_alt_rounded, size: 17, color: C.ink),
                const SizedBox(width: 4),
                const Icon(Icons.wifi_rounded, size: 17, color: C.ink),
                const SizedBox(width: 4),
                const Icon(Icons.battery_full_rounded, size: 19, color: C.ink),
              ],
            ),
          ),
        ),
      );
}

/// Signed out → Welcome; signed in without a currency → currency step; otherwise the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SpentScope.of(context);
    final user = s.user;
    final Widget screen;
    if (user == null) {
      screen = const WelcomeScreen();
    } else if (s.currency == null) {
      screen = const CurrencyPickerScreen(onboarding: true);
    } else {
      screen = Shell(key: ValueKey(user.email));
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: screen);
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  var _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPaymentApps());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncPaymentApps();
  }

  /// Pull in payment notifications the Android listener queued while Spent was closed.
  Future<void> _syncPaymentApps() async {
    if (!DeviceApps.supported) return;
    final store = SpentScope.of(context);
    await DeviceApps.refreshInstalled();
    await DeviceApps.setWatched(store.connectedApps);
    final added = store.receiveDetected(await DeviceApps.drain());
    if (added > 0 && mounted) {
      Sfx.notify();
      toast(context, '$added new payment${added == 1 ? '' : 's'} detected. Review them on Home.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _tab,
              children: [
                HomeScreen(onOpenRecurring: () => setState(() => _tab = 1)),
                const RecurringScreen(),
                const AccountScreen(),
              ],
            ),
          ),
          // The dock owns the bottom of the screen: content fades out above it instead of
          // sliding under the tab bar and + button.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 104 + bottom,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.38],
                    colors: [Color(0x00FFFFFF), Colors.white],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottom + 12,
            child: Row(
              children: [
                Expanded(
                  child: _TabBar(
                    index: _tab,
                    onSelect: (i) {
                      if (i != _tab) Sfx.select();
                      setState(() => _tab = i);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Pressable(
                  onTap: () => openNew(context),
                  semanticLabel: 'Add transaction',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [C.brand, Color(0xFFFF8A3D)],
                      ),
                      boxShadow: [BoxShadow(color: Color(0x40FA5A0A), blurRadius: 18, offset: Offset(0, 6))],
                    ),
                    child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        height: 60,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFFEDEDED)),
          boxShadow: softShadow,
        ),
        child: Row(
          children: [
            _item(0, 'Home', (on) => SMark(size: 18, color: on ? C.brand : C.ink)),
            _item(1, 'Recurring', (on) => Icon(Icons.history_rounded, size: 21, color: on ? C.brand : C.ink)),
            _item(2, 'Account', (on) => Icon(Icons.person_outline_rounded, size: 21, color: on ? C.brand : C.ink)),
          ],
        ),
      );

  Widget _item(int i, String label, Widget Function(bool on) icon) {
    final on = index == i;
    return Expanded(
      child: Pressable(
        onTap: () => onSelect(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(color: on ? C.pill : Colors.transparent, borderRadius: BorderRadius.circular(99)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon(on),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, textScaler: TextScaler.noScaling, style: t(11, FontWeight.w600, color: on ? C.brand : C.ink, height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}
