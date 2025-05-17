import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(AdavvuApp());
}

class AdavvuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adavvu - EMI Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF8A2BE2), // Violet
        scaffoldBackgroundColor: Color(0xFF121212), // Dark background
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF8A2BE2),
          secondary: Color(0xFF9370DB),
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
        ),
        fontFamily: 'Roboto', // Fallback to Roboto if Poppins is unavailable
        textTheme: TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        cardTheme: CardTheme(
          color: Color(0xFF1E1E1E),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF8A2BE2),
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF8A2BE2),
          foregroundColor: Colors.white,
        ),
      ),
      home: HomePage(),
    );
  }
}

class EMI {
  String id;
  String name;
  double totalAmount;
  double monthlyPayment;
  int tenureMonths;
  int paidMonths;
  DateTime startDate;
  DateTime nextDueDate;
  List<Payment> payments;

  EMI({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.monthlyPayment,
    required this.tenureMonths,
    required this.paidMonths,
    required this.startDate,
    required this.nextDueDate,
    required this.payments,
  });

  double get remainingAmount => totalAmount - (monthlyPayment * paidMonths);
  int get remainingMonths => tenureMonths - paidMonths;
  double get percentageCompleted =>
      tenureMonths > 0 ? (paidMonths / tenureMonths) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'monthlyPayment': monthlyPayment,
      'tenureMonths': tenureMonths,
      'paidMonths': paidMonths,
      'startDate': startDate.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'payments': payments.map((payment) => payment.toJson()).toList(),
    };
  }

  factory EMI.fromJson(Map<String, dynamic> json) {
    return EMI(
      id: json['id'],
      name: json['name'],
      totalAmount: json['totalAmount'],
      monthlyPayment: json['monthlyPayment'],
      tenureMonths: json['tenureMonths'],
      paidMonths: json['paidMonths'],
      startDate: DateTime.parse(json['startDate']),
      nextDueDate: DateTime.parse(json['nextDueDate']),
      payments:
          (json['payments'] as List)
              .map((payment) => Payment.fromJson(payment))
              .toList(),
    );
  }
}

class Payment {
  String id;
  DateTime date;
  double amount;
  String note;

  Payment({
    required this.id,
    required this.date,
    required this.amount,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'note': note,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      date: DateTime.parse(json['date']),
      amount: json['amount'],
      note: json['note'] ?? '',
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<EMI> _emiList = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadEMIs();
  }

  Future<void> _loadEMIs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final emiListJson = prefs.getString('emiList') ?? '[]';
      final List<dynamic> decodedList = jsonDecode(emiListJson);

      setState(() {
        _emiList = decodedList.map((item) => EMI.fromJson(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading EMIs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEMIs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emiListJson = jsonEncode(
        _emiList.map((emi) => emi.toJson()).toList(),
      );
      await prefs.setString('emiList', emiListJson);
    } catch (e) {
      print('Error saving EMIs: $e');
    }
  }

  void _addEMI(EMI emi) {
    setState(() {
      _emiList.add(emi);
      _saveEMIs();
    });
  }

  void _updateEMI(EMI updatedEMI) {
    setState(() {
      final index = _emiList.indexWhere((emi) => emi.id == updatedEMI.id);
      if (index != -1) {
        _emiList[index] = updatedEMI;
        _saveEMIs();
      }
    });
  }

  void _deleteEMI(String id) {
    setState(() {
      _emiList.removeWhere((emi) => emi.id == id);
      _saveEMIs();
    });
  }

  void _recordPayment(EMI emi, Payment payment) {
    setState(() {
      final index = _emiList.indexWhere((e) => e.id == emi.id);
      if (index != -1) {
        _emiList[index].payments.add(payment);
        _emiList[index].paidMonths += 1;

        // Calculate next due date
        _emiList[index].nextDueDate = DateTime(
          _emiList[index].nextDueDate.year,
          _emiList[index].nextDueDate.month + 1,
          _emiList[index].nextDueDate.day,
        );

        _saveEMIs();
      }
    });
  }

  double getTotalMonthlyEMI() {
    return _emiList.fold(0, (sum, emi) => sum + emi.monthlyPayment);
  }

  int getUpcomingPaymentsCount() {
    final now = DateTime.now();
    final nextWeek = now.add(Duration(days: 7));

    return _emiList
        .where(
          (emi) =>
              emi.nextDueDate.isAfter(now) &&
              emi.nextDueDate.isBefore(nextWeek),
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
              : Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (int index) {
                      setState(() {
                        _selectedIndex = index;
                        _pageController.animateToPage(
                          index,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      });
                    },
                    backgroundColor: Color(0xFF1A1A1A),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard),
                        label: Text('Dashboard'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.list),
                        label: Text('EMI List'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.history),
                        label: Text('Payment History'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings),
                        label: Text('Settings'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      children: [
                        DashboardPage(
                          emiList: _emiList,
                          totalMonthlyEMI: getTotalMonthlyEMI(),
                          upcomingPayments: getUpcomingPaymentsCount(),
                          onAddEMI: _addEMI,
                        ),
                        EMIListPage(
                          emiList: _emiList,
                          onAddEMI: _addEMI,
                          onUpdateEMI: _updateEMI,
                          onDeleteEMI: _deleteEMI,
                          onRecordPayment: _recordPayment,
                        ),
                        PaymentHistoryPage(emiList: _emiList),
                        SettingsPage(),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final List<EMI> emiList;
  final double totalMonthlyEMI;
  final int upcomingPayments;
  final Function(EMI) onAddEMI;

  const DashboardPage({
    required this.emiList,
    required this.totalMonthlyEMI,
    required this.upcomingPayments,
    required this.onAddEMI,
  });

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    final formatter = NumberFormat("#,##0.00", "en_US");

    // Get EMIs due soon
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
              // Refresh handled by state management
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
                        // Use EMIListPage's dialog for consistency
                        EMIListPage(
                          emiList: emiList,
                          onAddEMI: onAddEMI,
                          onUpdateEMI: (emi) {},
                          onDeleteEMI: (id) {},
                          onRecordPayment: (emi, payment) {},
                        )._showAddEMIDialog(context);
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

                    // Summary Cards
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

                    SizedBox(height: 24),

                    // EMI Distribution Chart
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EMI Distribution',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              height: 300,
                              child:
                                  totalMonthlyEMI == 0
                                      ? Center(
                                        child: Text(
                                          'No EMI data to display',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      )
                                      : PieChart(
                                        PieChartData(
                                          sections:
                                              emiList.map((emi) {
                                                return PieChartSectionData(
                                                  color: Color(
                                                    (emiList.indexOf(emi) *
                                                                700 +
                                                            0xFF9370DB) %
                                                        0xFFFFFFFF,
                                                  ),
                                                  value: emi.monthlyPayment,
                                                  title:
                                                      '${(emi.monthlyPayment / totalMonthlyEMI * 100).toStringAsFixed(0)}%',
                                                  radius: 100,
                                                  titleStyle: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              }).toList(),
                                          centerSpaceRadius: 40,
                                          sectionsSpace: 2,
                                        ),
                                      ),
                            ),
                            SizedBox(height: 20),

                            // Legend
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children:
                                  emiList.map((emi) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Color(
                                              (emiList.indexOf(emi) * 700 +
                                                      0xFF9370DB) %
                                                  0xFFFFFFFF,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          emi.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Due This Week Section
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Due This Week',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (dueThisWeek.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      // Navigate to EMI List Page
                                      (context
                                                  .findAncestorWidgetOfExactType<
                                                    PageView
                                                  >()!
                                                  .controller
                                              as PageController)
                                          .animateToPage(
                                            1,
                                            duration: Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                    },
                                    child: Text('View All'),
                                  ),
                              ],
                            ),
                            SizedBox(height: 10),
                            if (dueThisWeek.isEmpty)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 48,
                                        color: Colors.green,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No payments due this week!',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...dueThisWeek.map((emi) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: Color(0xFF8A2BE2),
                                      child: Text(
                                        emi.name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(emi.name),
                                    subtitle: Text(
                                      'Due on ${DateFormat('dd MMM').format(emi.nextDueDate)}',
                                    ),
                                    trailing: Text(
                                      '₹${formatter.format(emi.monthlyPayment)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Progress Overview
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EMI Progress Overview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            ...emiList.map((emi) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            emi.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${emi.percentageCompleted.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value:
                                          emi.paidMonths /
                                          (emi.tenureMonths > 0
                                              ? emi.tenureMonths
                                              : 1),
                                      backgroundColor: Colors.grey.shade800,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${emi.paidMonths}/${emi.tenureMonths} months paid',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          '${emi.remainingMonths} months left',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class EMIListPage extends StatelessWidget {
  final List<EMI> emiList;
  final Function(EMI) onAddEMI;
  final Function(EMI) onUpdateEMI;
  final Function(String) onDeleteEMI;
  final Function(EMI, Payment) onRecordPayment;

  const EMIListPage({
    required this.emiList,
    required this.onAddEMI,
    required this.onUpdateEMI,
    required this.onDeleteEMI,
    required this.onRecordPayment,
  });

  void _showAddEMIDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    double totalAmount = 0;
    double monthlyPayment = 0;
    int tenureMonths = 0;
    DateTime startDate = DateTime.now();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add New EMI'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'EMI Name'),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter a name' : null,
                      onSaved: (value) => name = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Total Amount (₹)',
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value!.isEmpty || double.tryParse(value) == null
                                  ? 'Please enter a valid amount'
                                  : null,
                      onSaved: (value) => totalAmount = double.parse(value!),
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Monthly Payment (₹)',
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value!.isEmpty || double.tryParse(value) == null
                                  ? 'Please enter a valid amount'
                                  : null,
                      onSaved: (value) => monthlyPayment = double.parse(value!),
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Tenure (Months)'),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value!.isEmpty || int.tryParse(value) == null
                                  ? 'Please enter a valid number'
                                  : null,
                      onSaved: (value) => tenureMonths = int.parse(value!),
                    ),
                    ListTile(
                      title: Text(
                        'Start Date: ${DateFormat('dd MMM yyyy').format(startDate)}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          startDate = selectedDate;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Validate that monthlyPayment * tenureMonths is reasonable
                    if (monthlyPayment * tenureMonths < totalAmount * 0.9 ||
                        monthlyPayment * tenureMonths > totalAmount * 1.1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Monthly payment and tenure do not match total amount',
                          ),
                        ),
                      );
                      return;
                    }
                    final emi = EMI(
                      id: Uuid().v4(),
                      name: name,
                      totalAmount: totalAmount,
                      monthlyPayment: monthlyPayment,
                      tenureMonths: tenureMonths,
                      paidMonths: 0,
                      startDate: startDate,
                      nextDueDate: startDate,
                      payments: [],
                    );
                    onAddEMI(emi);
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEditEMIDialog(BuildContext context, EMI emi) {
    final _formKey = GlobalKey<FormState>();
    String name = emi.name;
    double totalAmount = emi.totalAmount;
    double monthlyPayment = emi.monthlyPayment;
    int tenureMonths = emi.tenureMonths;
    DateTime startDate = emi.startDate;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit EMI'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'EMI Name'),
                      initialValue: name,
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter a name' : null,
                      onSaved: (value) => name = value!,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Total Amount (₹)',
                      ),
                      initialValue: totalAmount.toString(),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value!.isEmpty || double.tryParse(value) == null
                                  ? 'Please enter a valid amount'
                                  : null,
                      onSaved: (value) => totalAmount = double.parse(value!),
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Monthly Payment (₹)',
                      ),
                      initialValue: monthlyPayment.toString(),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value!.isEmpty || double.tryParse(value) == null
                                  ? 'Please enter a valid amount'
                                  : null,
                      onSaved: (value) => monthlyPayment = double.parse(value!),
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Tenure (Months)'),
                      initialValue: tenureMonths.toString(),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value!.isEmpty || int.tryParse(value) == null
                                  ? 'Please enter a valid number'
                                  : null,
                      onSaved: (value) => tenureMonths = int.parse(value!),
                    ),
                    ListTile(
                      title: Text(
                        'Start Date: ${DateFormat('dd MMM yyyy').format(startDate)}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          startDate = selectedDate;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Validate that monthlyPayment * tenureMonths is reasonable
                    if (monthlyPayment * tenureMonths < totalAmount * 0.9 ||
                        monthlyPayment * tenureMonths > totalAmount * 1.1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Monthly payment and tenure do not match total amount',
                          ),
                        ),
                      );
                      return;
                    }
                    final updatedEMI = EMI(
                      id: emi.id,
                      name: name,
                      totalAmount: totalAmount,
                      monthlyPayment: monthlyPayment,
                      tenureMonths: tenureMonths,
                      paidMonths: emi.paidMonths,
                      startDate: startDate,
                      nextDueDate: emi.nextDueDate,
                      payments: emi.payments,
                    );
                    onUpdateEMI(updatedEMI);
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context, EMI emi) {
    final _formKey = GlobalKey<FormState>();
    double amount = emi.monthlyPayment;
    String note = '';
    DateTime paymentDate = DateTime.now();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Record Payment'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Amount (₹)'),
                      initialValue: amount.toString(),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value!.isEmpty || double.tryParse(value) == null
                                  ? 'Please enter a valid amount'
                                  : null,
                      onSaved: (value) => amount = double.parse(value!),
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Note (Optional)'),
                      onSaved: (value) => note = value ?? '',
                    ),
                    ListTile(
                      title: Text(
                        'Payment Date: ${DateFormat('dd MMM yyyy').format(paymentDate)}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: paymentDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          paymentDate = selectedDate;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final payment = Payment(
                      id: Uuid().v4(),
                      date: paymentDate,
                      amount: amount,
                      note: note,
                    );
                    onRecordPayment(emi, payment);
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Record'),
              ),
            ],
          ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    String query = '';
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Search EMIs'),
            content: TextField(
              decoration: InputDecoration(
                labelText: 'Enter EMI name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => query = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Filter EMIs based on query
                  final filtered =
                      emiList
                          .where(
                            (emi) => emi.name.toLowerCase().contains(
                              query.toLowerCase(),
                            ),
                          )
                          .toList();
                  Navigator.of(context).pop();
                  // Show filtered results in a new page or update state
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('Search Results'),
                          content:
                              filtered.isEmpty
                                  ? Text('No EMIs found')
                                  : SizedBox(
                                    width: double.maxFinite,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final emi = filtered[index];
                                        return ListTile(
                                          title: Text(emi.name),
                                          subtitle: Text(
                                            '₹${NumberFormat("#,##0.00", "en_US").format(emi.monthlyPayment)}/month',
                                          ),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            _showEditEMIDialog(context, emi);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Close'),
                            ),
                          ],
                        ),
                  );
                },
                child: Text('Search'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00", "en_US");

    return Scaffold(
      appBar: AppBar(
        title: Text('EMI List', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
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
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: emiList.length,
                itemBuilder: (context, index) {
                  final emi = emiList[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Color(0xFF8A2BE2),
                                    child: Text(
                                      emi.name.substring(0, 1).toUpperCase(),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emi.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Started on ${DateFormat('dd MMM yyyy').format(emi.startDate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              PopupMenuButton(
                                itemBuilder:
                                    (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                      PopupMenuItem(
                                        value: 'record',
                                        child: Text('Record Payment'),
                                      ),
                                    ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditEMIDialog(context, emi);
                                  } else if (value == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text('Delete EMI'),
                                            content: Text(
                                              'Are you sure you want to delete ${emi.name}? This action cannot be undone.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  onDeleteEMI(emi.id);
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                  } else if (value == 'record') {
                                    _showRecordPaymentDialog(context, emi);
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Monthly Payment',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '₹${formatter.format(emi.monthlyPayment)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Amount',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '₹${formatter.format(emi.totalAmount)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Remaining Amount',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '₹${formatter.format(emi.remainingAmount)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Progress',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value:
                                          emi.paidMonths /
                                          (emi.tenureMonths > 0
                                              ? emi.tenureMonths
                                              : 1),
                                      backgroundColor: Colors.grey.shade800,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${emi.paidMonths}/${emi.tenureMonths} months',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEMIDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }
}

class PaymentHistoryPage extends StatelessWidget {
  final List<EMI> emiList;

  const PaymentHistoryPage({required this.emiList});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    final allPayments =
        emiList
            .asMap()
            .entries
            .expand(
              (entry) => entry.value.payments.map(
                (payment) => {'emi': entry.value, 'payment': payment},
              ),
            )
            .toList()
          ..sort(
            (a, b) => (b['payment'] as Payment).date.compareTo(
              (a['payment'] as Payment).date,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          allPayments.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'No Payment History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Record payments to view history',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: allPayments.length,
                itemBuilder: (context, index) {
                  final paymentData = allPayments[index];
                  final emi = paymentData['emi'] as EMI;
                  final payment = paymentData['payment'] as Payment;

                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF8A2BE2),
                        child: Text(
                          emi.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        '${emi.name} - ₹${formatter.format(payment.amount)}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paid on ${DateFormat('dd MMM yyyy').format(payment.date)}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          if (payment.note.isNotEmpty)
                            Text(
                              'Note: ${payment.note}',
                              style: TextStyle(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  void _clearData(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Clear All Data'),
            content: Text(
              'Are you sure you want to clear all EMI and payment data? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('emiList');
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('All data cleared')));
                  // Refresh the app state
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 24),
            Text(
              'Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text(
                'Clear All Data',
                style: TextStyle(color: Colors.red),
              ),
              leading: Icon(Icons.delete_forever, color: Colors.red),
              onTap: () => _clearData(context),
            ),
          ],
        ),
      ),
    );
  }
}
