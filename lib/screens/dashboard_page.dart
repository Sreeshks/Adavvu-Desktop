import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/emi.dart';
import '../widgets/dashboard_card.dart';

class DashboardPage extends StatelessWidget {
  final List<EMI> emiList;
  final double totalMonthlyEMI;
  final int upcomingPayments;
  final PageController pageController;

  const DashboardPage({
    required this.emiList,
    required this.totalMonthlyEMI,
    required this.upcomingPayments,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    final formatter = NumberFormat("#,##0.00", "en_US");

    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7));
    final dueThisWeek =
        emiList
            .where(
              (emi) =>
                  emi.nextDueDate.isAfter(now) &&
                  emi.nextDueDate.isBefore(endOfWeek),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Refresh data
            },
          ),
        ],
      ),
      body:
          emiList.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'No EMIs Found',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Add your first EMI to start tracking',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Add EMI'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        pageController.animateToPage(
                          1,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Adavvu',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      currentMonth,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Monthly EMI',
                            value: '₹${formatter.format(totalMonthlyEMI)}',
                            icon: Icons.currency_rupee,
                            color: Color(0xFF8A2BE2),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: DashboardCard(
                            title: 'Total EMIs',
                            value: emiList.length.toString(),
                            icon: Icons.credit_card,
                            color: Color(0xFF9370DB),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: DashboardCard(
                            title: 'Due This Week',
                            value: upcomingPayments.toString(),
                            icon: Icons.alarm,
                            color: Color(0xFFBA68C8),
                          ),
                        ),
                      ],
                    ),
                    // ... rest of the dashboard UI ...
                  ],
                ),
              ),
    );
  }
}
