import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Earnings"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Title + Payout Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Earnings & Rewards",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text("Request"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            /// Summary Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                EarningsCard(title: "Today", amount: "₹0"),
                EarningsCard(title: "This Week", amount: "₹0"),
                EarningsCard(title: "This Month", amount: "₹0"),
                EarningsCard(title: "Total Earned", amount: "₹0"),
              ],
            ),

            const SizedBox(height: 25),

            /// Earnings Trend
            const Text(
              "Earnings Trend",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),

            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 0),
                        FlSpot(1, 0),
                        FlSpot(2, 0),
                        FlSpot(3, 0),
                        FlSpot(4, 0),
                        FlSpot(5, 0),
                        FlSpot(6, 0),
                      ],
                      isCurved: true,
                      dotData: FlDotData(show: false),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Transactions"),
                Tab(text: "Rewards"),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 200,
              child: TabBarView(
                controller: _tabController,
                children: const [
                  Center(child: Text("No transactions found.")),
                  Center(child: Text("No rewards found.")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class EarningsCard extends StatelessWidget {
  final String title;
  final String amount;

  const EarningsCard({
    super.key,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.currency_rupee, color: Colors.green),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          )
        ],
      ),
    );
  }
}