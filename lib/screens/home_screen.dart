/// Main home screen of the app (the shell after login).
///
/// This screen hosts a bottom navigation bar with four tabs: Home
/// (dashboard), History, Reports and Profile, plus a red emergency SOS
/// button in the centre. The dashboard tab itself lives in
/// `dashboard_tab.dart`; the small card widgets it uses live in
/// `lib/widgets/`.

library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nav_item.dart';
import 'dashboard_tab.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

/// Shell screen with bottom navigation tabs and the SOS button.
///
/// Shown after a successful login. [HomeScreen] itself only manages
/// tab switching; each tab is a separate widget.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Index of the currently selected tab (0 = dashboard).
  int _currentIndex = 0;

  /// The four main tabs, kept alive as a stable list.
  final List<Widget> _pages = [
    const DashboardTab(),
    const HistoryScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The tab content for the selected index.
      body: _pages[_currentIndex],
      // Bottom navigation bar for switching between major pages.
      bottomNavigationBar: BottomAppBar(
        height: 64,
        color: AppColors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home tab (dashboard).
            NavItem(
              icon: _currentIndex == 0 ? Icons.home : Icons.home_outlined,
              label: 'Home',
              isSelected: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            // History tab.
            NavItem(
              icon: _currentIndex == 1 ? Icons.history : Icons.history_outlined,
              label: 'History',
              isSelected: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            // Space reserved for the centre SOS button.
            const SizedBox(width: 48),
            // Reports tab.
            NavItem(
              icon: _currentIndex == 2
                  ? Icons.bar_chart
                  : Icons.bar_chart_outlined,
              label: 'Reports',
              isSelected: _currentIndex == 2,
              onTap: () => setState(() => _currentIndex = 2),
            ),
            // Profile tab.
            NavItem(
              icon: _currentIndex == 3 ? Icons.person : Icons.person_outlined,
              label: 'Profile',
              isSelected: _currentIndex == 3,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
      // Emergency SOS button displayed prominently in the centre.
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: _showEmergencySheet,
          backgroundColor: const Color(0xFFE53935),
          elevation: 10,
          shape: const CircleBorder(),
          child: const Icon(Icons.emergency, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Opens the emergency assistance bottom sheet.
  ///
  /// Loads the user's emergency contact from Firestore (name and phone
  /// number) and shows it in a modal sheet. When no contact is saved,
  /// an empty state with instructions is shown instead.
  Future<void> _showEmergencySheet() async {
    final user = AuthService().currentUser;
    String? contactName;
    String? contactNumber;
    var loaded = false;
    if (user != null) {
      try {
        final profile = await FirestoreService().getUserProfile(user.uid);
        contactName = profile?.emergencyContactName;
        contactNumber = profile?.emergencyContactNumber;
        loaded = true;
      } catch (_) {
        // Show the sheet even when Firestore is unavailable.
        loaded = true;
      }
    } else {
      loaded = true;
    }
    if (!mounted) return;

    // Bottom sheet with the emergency contact information.
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small drag handle at the top of the sheet.
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.emergency, color: Color(0xFFE53935), size: 40),
              const SizedBox(height: 8),
              // Sheet title.
              Text(
                'Emergency Assistance',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              // Loading spinner, empty state or contact details.
              if (!loaded)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              else if (contactName == null || contactNumber == null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.contact_emergency_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No emergency contact saved',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add one from Edit Profile so help is always available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.subtitleGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                // Contact tile with name and phone number.
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(
                      Icons.contact_emergency,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  title: Text(
                    contactName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Call $contactNumber using your phone dialer'),
                ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Button that closes the sheet.
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}