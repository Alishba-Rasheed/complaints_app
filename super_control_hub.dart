import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/system_provider.dart';
import 'super_user_management_screen.dart';
import 'super_categories_screen.dart';
import 'super_settings_screen.dart';

class SuperControlHub extends StatefulWidget {
  const SuperControlHub({super.key});

  @override
  State<SuperControlHub> createState() => _SuperControlHubState();
}

class _SuperControlHubState extends State<SuperControlHub> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('SYSTEM AUTHORITY HUB',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          indicatorWeight: 4,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'PARTICIPANTS'),
            Tab(icon: Icon(Icons.category_rounded), text: 'CATEGORIES'),
            Tab(icon: Icon(Icons.settings_suggest_rounded), text: 'SETTINGS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Reuse existing screens but inside the hub
          SuperUserManagementScreenContent(),
          SuperCategoriesScreenContent(),
          SuperSettingsScreenContent(),
        ],
      ),
    );
  }
}

// Wrapper versions of existing screens to fit into the hub
class SuperUserManagementScreenContent extends StatelessWidget {
  const SuperUserManagementScreenContent({super.key});
  @override
  Widget build(BuildContext context) {
    // This will require modifying original SuperUserManagementScreen to be a content widget
    return const SuperUserManagementScreen(); 
  }
}

class SuperCategoriesScreenContent extends StatelessWidget {
  const SuperCategoriesScreenContent({super.key});
  @override
  Widget build(BuildContext context) {
    return const SuperCategoriesScreen();
  }
}

class SuperSettingsScreenContent extends StatelessWidget {
  const SuperSettingsScreenContent({super.key});
  @override
  Widget build(BuildContext context) {
    return const SuperSettingsScreen();
  }
}