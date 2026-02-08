import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_info.dart';
import '../widgets/app_card.dart';
import '../repositories/app_repository.dart';
import 'app_details_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appRepo = Provider.of<AppRepository>(context, listen: false);

    return Scaffold(
      body: StreamBuilder<List<AppInfo>>(
        stream: appRepo.getAppsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allApps = snapshot.data ?? [];

          // Client-side filtering for search
          final query = _searchController.text.toLowerCase();
          final filteredApps = allApps.where((app) {
            return app.name.toLowerCase().contains(query) ||
                app.description.toLowerCase().contains(query);
          }).toList();

          return CustomScrollView(
            slivers: [
              // 1. App Bar with Search
              SliverAppBar(
                floating: true,
                pinned: true,
                expandedHeight: 140.0,
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings, color: Colors.white),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: const Text(
                    'Somali Apps',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade800,
                          Colors.indigo.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {});
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search apps...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Featured Section
              if (allApps.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child:
                      Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Featured',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          )
                          .animate()
                          .fade(duration: 500.ms)
                          .slideX(begin: -0.1, end: 0),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.9),
                      itemCount: allApps.take(3).length,
                      itemBuilder: (context, index) {
                        final app = allApps[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AppDetailsScreen(appInfo: app),
                              ),
                            );
                          },
                          child:
                              Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Theme.of(context).cardColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  app.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                  maxLines: 1,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  app.description,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AppDetailsScreen(
                                                              appInfo: app,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.indigo,
                                                        foregroundColor:
                                                            Colors.white,
                                                        minimumSize: const Size(
                                                          100,
                                                          36,
                                                        ),
                                                      ),
                                                  child: const Text('View'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                imageUrl: app.iconUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                      color: Theme.of(
                                                        context,
                                                      ).hoverColor,
                                                    ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fade(
                                    delay: (index * 100).ms,
                                    duration: 500.ms,
                                  )
                                  .scale(
                                    begin: const Offset(0.95, 0.95),
                                    end: const Offset(1, 1),
                                  ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // 3. Grid Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'All Apps',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),
              ),

              // 4. Apps Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return AppCard(appInfo: filteredApps[index]);
                  }, childCount: filteredApps.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
