import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final _supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _orderStream;

  @override
  void initState() {
    super.initState();
    _orderStream = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.order['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text("Track Order", style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _orderStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final order = snapshot.data!.first;
          final status = (order['status'] ?? 'pending').toString().toLowerCase();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderInfo(order),
                const SizedBox(height: 32),
                _buildStatusTimeline(status),
                const SizedBox(height: 32),
                _buildDeliveryAddress(order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderInfo(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Row(
        children: [
           ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.order['products']?['image_url'] != null
              ? Image.network(widget.order['products']['image_url'], width: 70, height: 70, fit: BoxFit.cover)
              : Container(color: const Color(0xFFE8F5E9), width: 70, height: 70, child: const Icon(Icons.eco_rounded, color: Color(0xFF4CAF50))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.order['products']?['name'] ?? "Product", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B5E20))),
                const SizedBox(height: 4),
                Text("Order #${order['id'].toString().substring(0, 8).toUpperCase()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text("Rs. ${order['total_price']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2E7D32))),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    currentStatus = currentStatus.toLowerCase();
    
    // Standard statuses in order
    final List<String> statusSequence = [
      'pending',
      'accepted',
      'processing',
      'delivering',
      'delivered'
    ];

    final Map<String, List<String>> statusData = {
      'pending': ['Order Placed', 'We have received your order'],
      'accepted': ['Order Accepted', 'Farmer has accepted your order'],
      'processing': ['Processing', 'Farmer is picking fresh produce'],
      'delivering': ['Out for Delivery', 'Your basket is on its way'],
      'delivered': ['Delivered', 'Item has been delivered successfully'],
      'cancelled': ['Cancelled', 'This order has been cancelled'],
    };
    
    // If status is cancelled, we show a special view or just the cancelled state
    if (currentStatus == 'cancelled') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Order Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
            child: Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.red),
                const SizedBox(width: 12),
                const Text("This order has been cancelled", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      );
    }

    int currentStepIndex = statusSequence.indexOf(currentStatus);
    if (currentStepIndex == -1) currentStepIndex = 0; // Default to first step

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Order Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        const SizedBox(height: 24),
        ...List.generate(statusSequence.length * 2 - 1, (index) {
          if (index.isOdd) {
             final stepIdx = index ~/ 2;
             bool isCompleted = stepIdx < currentStepIndex;
             return Container(margin: const EdgeInsets.only(left: 12), height: 30, width: 2, color: isCompleted ? const Color(0xFF4CAF50) : Colors.grey[200]);
          }
          final stepIdx = index ~/ 2;
          final step = statusSequence[stepIdx];
          bool isCompleted = stepIdx <= currentStepIndex;
          bool isCurrent = stepIdx == currentStepIndex;

          return Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF4CAF50) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: isCompleted ? const Color(0xFF4CAF50) : Colors.grey[300]!, width: 2),
                ),
                child: isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusData[step]![0], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isCompleted ? const Color(0xFF1B5E20) : Colors.grey)),
                  Text(statusData[step]![1], style: TextStyle(fontSize: 12, color: isCompleted ? Colors.grey[600] : Colors.grey[400])),
                ],
              ),
              if (isCurrent) ... [
                const Spacer(),
                const Icon(Icons.timer_outlined, color: Colors.orange, size: 20),
              ]
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDeliveryAddress(Map<String, dynamic> order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on_rounded, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text("Delivery Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
            ],
          ),
          const SizedBox(height: 12),
          Text(order['delivery_address'] ?? "No address provided", style: const TextStyle(color: Color(0xFF757575), fontSize: 14)),
        ],
      ),
    );
  }
}
