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
      title: 'اپلیکیشن خیاطی',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const CustomerPage(),
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

    final String? oldData = prefs.getString('customers');

    List<dynamic> customers = [];

    if (oldData != null) {
      customers = jsonDecode(oldData);
    }

    customers.add(customer);

    await prefs.setString(
      'customers',
      jsonEncode(customers),
    );

    await prefs.setInt(
      'next_customer_code',
      customerCode + 1,
    );

    showMessage('مشتری با موفقیت ذخیره شد.');

    clearForm();

    setState(() {
      customerCode++;
    });
  }

  void clearForm() {
    nameController.clear();
    phoneController.clear();

    for (final controller in amountControllers.values) {
      controller.clear();
    }

    for (final controller in modelControllers.values) {
      controller.clear();
    }

    setState(() {
      unit = 'انچ';
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ثبت مشتری جدید'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'کد مشتری: $customerCode',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'نام مشتری',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: phoneController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'شماره تماس',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'واحد اندازه‌گیری',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('انچ'),
                      value: 'انچ',
                      groupValue: unit,
                      onChanged: (value) {
                        setState(() {
                          unit = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('سانتی‌متر'),
                      value: 'سانتی‌متر',
                      groupValue: unit,
                      onChanged: (value) {
                        setState(() {
                          unit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                'اندازه‌ها',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ...measurements.map(
                (measurement) => MeasurementRow(
                  title: measurement,
                  unit: unit,
                  amountController:
                      amountControllers[measurement]!,
                  modelController:
                      modelControllers[measurement]!,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: saveCustomer,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'ذخیره مشتری',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
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
            width: 70,
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: TextField(
              controller: amountController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'مقدار',
                suffixText: unit,
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: TextField(
              controller: modelController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'مدل لباس',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
