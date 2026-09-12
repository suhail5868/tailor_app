import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TailorApp());
}

class TailorApp extends StatelessWidget {
  const TailorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ثبت اندازه مشتریان',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: CustomerPage(),
      ),
    );
  }
}

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  String unit = 'انچ';
  int customerCode = 1;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final List<String> measurements = [
    'قد',
    'شانه',
    'آستین',
    'کمر',
    'شلوار',
    'پاچه',
    'یقه',
  ];

  final Map<String, TextEditingController> amountControllers = {};
  final Map<String, TextEditingController> modelControllers = {};

  @override
  void initState() {
    super.initState();

    for (final measurement in measurements) {
      amountControllers[measurement] = TextEditingController();
      modelControllers[measurement] = TextEditingController();
    }

    loadNextCustomerCode();
  }

  Future<void> loadNextCustomerCode() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      customerCode = prefs.getInt('next_customer_code') ?? 1;
    });
  }

  Future<void> saveCustomer() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      showMessage('لطفاً نام مشتری را وارد کنید.');
      return;
    }

    final Map<String, dynamic> customer = {
      'code': customerCode,
      'name': name,
      'phone': phone,
      'unit': unit,
      'measurements': {},
    };

    for (final measurement in measurements) {
      customer['measurements'][measurement] = {
        'amount': amountControllers[measurement]!.text.trim(),
        'model': modelControllers[measurement]!.text.trim(),
      };
    }

    final prefs = await SharedPreferences.getInstance();

    final String? savedCustomers = prefs.getString('customers');

    List<dynamic> customers = [];

    if (savedCustomers != null) {
      customers = jsonDecode(savedCustomers);
    }

    customers.add(customer);

    await prefs.setString('customers', jsonEncode(customers));

    await prefs.setInt('next_customer_code', customerCode + 1);

    if (!mounted) return;

    showMessage('مشتری با موفقیت ذخیره شد.');

    clearForm();

    setState(() {
      customerCode++;
    });
  }

  void clearForm() {
    nameController.clear();
    phoneController.clear();

    for (final measurement in measurements) {
      amountControllers[measurement]!.clear();
      modelControllers[measurement]!.clear();
    }

    setState(() {
      unit = 'انچ';
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void openCustomerList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerListPage(),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();

    for (final controller in amountControllers.values) {
      controller.dispose();
    }

    for (final controller in modelControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت مشتری جدید'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'کد مشتری: $customerCode',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'نام مشتری',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'شماره تماس',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'واحد اندازه‌گیری',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            RadioListTile<String>(
              title: const Text('انچ'),
              value: 'انچ',
              groupValue: unit,
              onChanged: (value) {
                setState(() {
                  unit = value!;
                });
              },
            ),

            RadioListTile<String>(
              title: const Text('سانتی‌متر'),
              value: 'سانتی‌متر',
              groupValue: unit,
              onChanged: (value) {
                setState(() {
                  unit = value!;
                });
              },
            ),

            const SizedBox(height: 10),

            const Text(
              'اندازه‌ها',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            ...measurements.map(
              (measurement) => MeasurementRow(
                title: measurement,
                unit: unit,
                amountController: amountControllers[measurement]!,
                modelController: modelControllers[measurement]!,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: saveCustomer,
              icon: const Icon(Icons.save),
              label: const Text('ذخیره مشتری'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: openCustomerList,
              icon: const Icon(Icons.people),
              label: const Text('لیست مشتریان'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeasurementRow extends StatelessWidget {
  final String title;
  final String unit;
  final TextEditingController amountController;
  final TextEditingController modelController;

  const MeasurementRow({
    super.key,
    required this.title,
    required this.unit,
    required this.amountController,
    required this.modelController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            flex: 2,
            child: TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'مقدار',
                suffixText: unit,
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            flex: 3,
            child: TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: 'مدل لباس',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  List<dynamic> customers = [];
  List<dynamic> filteredCustomers = [];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    loadCustomers();

    searchController.addListener(searchCustomers);
  }

  Future<void> loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();

    final String? savedCustomers = prefs.getString('customers');

    if (savedCustomers == null) {
      setState(() {
        customers = [];
        filteredCustomers = [];
      });
      return;
    }

    final List<dynamic> data = jsonDecode(savedCustomers);

    setState(() {
      customers = data.reversed.toList();
      filteredCustomers = customers;
    });
  }

  void searchCustomers() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredCustomers = customers;
      } else {
        filteredCustomers = customers.where((customer) {
          final name = customer['name'].toString().toLowerCase();
          final code = customer['code'].toString();

          return name.contains(query) || code.contains(query);
        }).toList();
      }
    });
  }

  void openCustomerDetails(dynamic customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsPage(
          customer: customer,
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست مشتریان'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'جستجوی نام یا کد مشتری',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: filteredCustomers.isEmpty
                ? const Center(
                    child: Text(
                      'مشتری پیدا نشد.',
                      style: TextStyle(fontSize: 17),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              customer['code'].toString(),
                            ),
                          ),
                          title: Text(
                            customer['name'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            customer['phone'].toString().isEmpty
                                ? 'شماره تماس ثبت نشده'
                                : customer['phone'].toString(),
                          ),
                          trailing: const Icon(
                            Icons.arrow_back_ios,
                            size: 18,
                          ),
                          onTap: () {
                            openCustomerDetails(customer);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CustomerDetailsPage extends StatelessWidget {
  final dynamic customer;

  const CustomerDetailsPage({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> measurements =
        Map<String, dynamic>.from(customer['measurements']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشخصات مشتری'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'کد مشتری: ${customer['code']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'نام: ${customer['name']}',
                      style: const TextStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'شماره تماس: ${customer['phone'].toString().isEmpty ? 'ثبت نشده' : customer['phone']}',
                      style: const TextStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'واحد: ${customer['unit']}',
                      style: const TextStyle(fontSize: 17),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'اندازه‌ها',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            ...measurements.entries.map((entry) {
              final measurement = entry.key;
              final data = Map<String, dynamic>.from(entry.value);

              final amount = data['amount'].toString();
              final model = data['model'].toString();

              return Card(
                child: ListTile(
                  title: Text(
                    measurement,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'مقدار: ${amount.isEmpty ? 'ثبت نشده' : amount} ${customer['unit']}\n'
                    'مدل لباس: ${model.isEmpty ? 'ثبت نشده' : model}',
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
