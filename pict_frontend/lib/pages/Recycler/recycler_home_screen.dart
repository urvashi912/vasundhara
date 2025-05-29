import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pict_frontend/models/Report.dart';
import 'package:pict_frontend/services/report_service.dart';
import 'report_detail_page.dart';
import 'package:pict_frontend/utils/session/SharedPreference.dart';
import 'package:pict_frontend/pages/Auth/signin_screen.dart';

// Create provider for reports state
final reportsProvider = StateNotifierProvider<ReportsNotifier, AsyncValue<List<Report>>>((ref) {
  return ReportsNotifier();
});

class ReportsNotifier extends StateNotifier<AsyncValue<List<Report>>> {
  ReportsNotifier() : super(const AsyncValue.loading()) {
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      state = const AsyncValue.loading();
      final reports = await ReportService.getAllReports();
      state = AsyncValue.data(reports);
    } catch (e, stack) {
      print("Error loading reports: $e");
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> searchReports(String query) async {
    if (query.isEmpty) {
      loadReports();
      return;
    }

    try {
      state = const AsyncValue.loading();
      final reports = await ReportService.getSearchReport(query);
      state = AsyncValue.data(reports);
    } catch (e, stack) {
      print("Error searching reports: $e");
      state = AsyncValue.error(e, stack);
    }
  }

}
class RecyclerHomePage extends ConsumerStatefulWidget {
  const RecyclerHomePage({super.key});

  @override
  _RecyclerHomePageState createState() => _RecyclerHomePageState();
}

class _RecyclerHomePageState extends ConsumerState<RecyclerHomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ensure reports are loaded when the page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).loadReports();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Recycler Dashboard"),
        actions: [
          TextButton(
            onPressed: () => _showLogoutDialog(context),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search reports...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(reportsProvider.notifier).loadReports();
                  },
                ),
              ),
              onSubmitted: (value) {
                ref.read(reportsProvider.notifier).searchReports(value);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(reportsProvider.notifier).loadReports(),
              child: reportsState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading reports: ${error.toString()}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(reportsProvider.notifier).loadReports();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (reports) {
                  if (reports.isEmpty) {
                    return const Center(
                      child: Text(
                        'No reports available',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.report, color: Colors.white),
                          ),
                          title: Text(
                            report.description ?? 'No Description',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (report.uploaderName != null)
                                Text(
                                  'Reporter: ${report.uploaderName}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              const SizedBox(height: 4),
                              if (report.location?.formattedAddress != null)
                                Text(
                                  report.location!.formattedAddress!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              _buildStatusChip(report.reportStatus),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportDetailPage(
                                  report: report.toJson(),
                                ),
                              ),
                            ).then((_) {
                              ref.read(reportsProvider.notifier).loadReports();
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    switch (status?.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'resolved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status?.toUpperCase() ?? 'UNKNOWN',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text("Once logged out, you need to login again"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String res = await Utils.logout();
                if (res == "ok" && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                  );
                }
              },
              child: const Text("Okay"),
            ),
          ],
        );
      },
    );
  }
}
