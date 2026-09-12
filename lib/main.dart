import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TailorApp());
}

final List<String> measurementNames = [
  'قد',
  'شانه',
  'آستین',
  'کمر',
  'شلوار',
  'پاچه',
  'یقه',
];

class TailorApp extends StatelessWidget {
  const TailorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپلیکیشن خیاطی',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int customerCount = 0;

  @override
  void initState() {
    super.initState();
    loadCount();
  }

  Future<void> loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('customers');

    int count = 0;

    if (saved != null) {
      final data = jsonDecode(saved);
      count = data.length;
    }

    if (!mounted) return;

    setState(() {
      customerCount = count;
    });
  }

  Future<void> openNewCustomer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerPage(),
      ),
    );

    loadCount();
  }

  Future<void> openCustomerList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerListPage(),
      ),
    );

    loadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت خیاطی'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'تعداد مشتریان',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$customerCount',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openNewCustomer,
                icon: const Icon(Icons.person_add),
                label: const Text('ثبت مشتری جدید'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: openCustomerList,
                icon: const Icon(Icons.people),
                label: const Text('لیست مشتریان'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
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

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final noteController = TextEditingController();

  final Map<String, TextEditingController> amountControllers = {};
  final Map<String, TextEditingController> modelControllers = {};

  @override
  void initState() {
    super.initState();

    for (final name in measurementNames) {
      amountControllers[name] = TextEditingController();
      modelControllers[name] = TextEditingController();
    }

    loadNextCode();
  }

  Future<void> loadNextCode() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      customerCode = prefs.getInt('next_customer_code') ?? 1;
    });
  }

  Map<String, dynamic> collectMeasurements() {
    final Map<String, dynamic> result = {};

    for (final name in measurementNames) {
      result[name] = {
        'amount': amountControllers[name]!.text.trim(),
        'model': modelControllers[name]!.text.trim(),
      };
    }

    return result;
  }

  Future<void> saveCustomer() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      showMessage('لطفاً نام مشتری را وارد کنید.');
      return;
    }

    final measurements = collectMeasurements();

    final customer = {
      'code': customerCode,
      'name': name,
      'phone': phoneController.text.trim(),
      'note': noteController.text.trim(),
      'date': formatDate(DateTime.now()),
      'unit': unit,
      'measurements': measurements,
      'clothingRecords': [
        {
          'title': 'لباس اول',
          'date': formatDate(DateTime.now()),
          'unit': unit,
          'measurements': measurements,
        }
      ],
    };

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('customers');

    List<dynamic> customers = [];

    if (saved != null) {
      customers = jsonDecode(saved);
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
    noteController.clear();

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
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    noteController.dispose();

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
                padding: const EdgeInsets.all(14),
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

            const SizedBox(height: 10),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'شماره تماس',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'یادداشت مشتری',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

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

            ...measurementNames.map(
              (name) => MeasurementRow(
                title: name,
                unit: unit,
                amountController: amountControllers[name]!,
                modelController: modelControllers[name]!,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: saveCustomer,
              icon: const Icon(Icons.save),
              label: const Text('ذخیره مشتری'),
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
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 7),

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

          const SizedBox(width: 7),

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

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    loadCustomers();
    searchController.addListener(searchCustomers);
  }

  Future<void> loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString('customers');

    if (saved == null) {
      setState(() {
        customers = [];
        filteredCustomers = [];
      });
      return;
    }

    final data = jsonDecode(saved);

    setState(() {
      customers = List<dynamic>.from(data).reversed.toList();
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
          final phone = customer['phone'].toString().toLowerCase();

          return name.contains(query) ||
              code.contains(query) ||
              phone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> openDetails(dynamic customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailsPage(
          customer: customer,
        ),
      ),
    );

    loadCustomers();
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
                labelText: 'جستجوی نام، کد یا شماره تماس',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: filteredCustomers.isEmpty
                ? const Center(
                    child: Text('مشتری پیدا نشد.'),
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
                            '${customer['phone'].toString().isEmpty ? 'شماره ثبت نشده' : customer['phone']}'
                            '\nتاریخ: ${customer['date'] ?? 'ثبت نشده'}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(
                            Icons.arrow_back_ios,
                            size: 18,
                          ),
                          onTap: () => openDetails(customer),
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

class CustomerDetailsPage extends StatefulWidget {
  final dynamic customer;

  const CustomerDetailsPage({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailsPage> createState() =>
      _CustomerDetailsPageState();
}

class _CustomerDetailsPageState
    extends State<CustomerDetailsPage> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController noteController;

  late String unit;

  final Map<String, TextEditingController> amountControllers = {};
  final Map<String, TextEditingController> modelControllers = {};

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.customer['name'].toString(),
    );

    phoneController = TextEditingController(
      text: widget.customer['phone'].toString(),
    );

    noteController = TextEditingController(
      text: widget.customer['note']?.toString() ?? '',
    );

    unit = widget.customer['unit']?.toString() ?? 'انچ';

    Map<String, dynamic> measurements = {};

    if (widget.customer['measurements'] != null) {
      measurements = Map<String, dynamic>.from(
        widget.customer['measurements'],
      );
    }

    for (final name in measurementNames) {
      final data = measurements[name];

      amountControllers[name] = TextEditingController(
        text: data == null ? '' : data['amount'].toString(),
      );

      modelControllers[name] = TextEditingController(
        text: data == null ? '' : data['model'].toString(),
      );
    }
  }

  Map<String, dynamic> collectMeasurements() {
    final Map<String, dynamic> result = {};

    for (final name in measurementNames) {
      result[name] = {
        'amount': amountControllers[name]!.text.trim(),
        'model': modelControllers[name]!.text.trim(),
      };
    }

    return result;
  }

  Future<void> saveChanges() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString('customers');

    if (saved == null) return;

    final List<dynamic> customers = jsonDecode(saved);

    final code = widget.customer['code'];

    final index = customers.indexWhere(
      (customer) => customer['code'] == code,
    );

    if (index == -1) return;

    final measurements = collectMeasurements();

    customers[index]['name'] =
        nameController.text.trim();

    customers[index]['phone'] =
        phoneController.text.trim();

    customers[index]['note'] =
        noteController.text.trim();

    customers[index]['unit'] = unit;

    customers[index]['measurements'] =
        measurements;

    await prefs.setString(
      'customers',
      jsonEncode(customers),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('اطلاعات ذخیره شد.'),
      ),
    );
  }

  Future<void> deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف مشتری'),
          content: Text(
            'آیا مشتری «${widget.customer['name']}» حذف شود؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('خیر'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('بله، حذف شود'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString('customers');

    if (saved == null) return;

    final List<dynamic> customers = jsonDecode(saved);

    final code = widget.customer['code'];

    customers.removeWhere(
      (customer) => customer['code'] == code,
    );

    await prefs.setString(
      'customers',
      jsonEncode(customers),
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> addClothing() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddClothingPage(
          customer: widget.customer,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  void showClothing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClothingListPage(
          customer: widget.customer,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    noteController.dispose();

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
        title: const Text('ویرایش مشتری'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: deleteCustomer,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'کد مشتری: ${widget.customer['code']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'تاریخ ثبت: ${widget.customer['date'] ?? 'ثبت نشده'}',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'نام مشتری',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'شماره تماس',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'یادداشت',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'واحد اندازه‌گیری',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
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

            const Text(
              'اندازه‌ها',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            ...measurementNames.map(
              (name) => MeasurementRow(
                title: name,
                unit: unit,
                amountController: amountControllers[name]!,
                modelController: modelControllers[name]!,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('ذخیره تغییرات'),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: addClothing,
              icon: const Icon(Icons.add),
              label: const Text(
                'ثبت لباس جدید برای این مشتری',
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: showClothing,
              icon: const Icon(Icons.checkroom),
              label: const Text(
                'مشاهده لباس‌های مشتری',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddClothingPage extends StatefulWidget {
  final dynamic customer;

  const AddClothingPage({
    super.key,
    required this.customer,
  });

  @override
  State<AddClothingPage> createState() =>
      _AddClothingPageState();
}

class _AddClothingPageState
    extends State<AddClothingPage> {
  final titleController = TextEditingController();

  String unit = 'انچ';

  final Map<String, TextEditingController> amountControllers = {};
  final Map<String, TextEditingController> modelControllers = {};

  @override
  void initState() {
    super.initState();

    for (final name in measurementNames) {
      amountControllers[name] =
          TextEditingController();

      modelControllers[name] =
          TextEditingController();
    }
  }

  Future<void> saveClothing() async {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('نام یا مدل لباس را وارد کنید.'),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString('customers');

    if (saved == null) return;

    final List<dynamic> customers = jsonDecode(saved);

    final code = widget.customer['code'];

    final index = customers.indexWhere(
      (customer) => customer['code'] == code,
    );

    if (index == -1) return;

    final measurements = <String, dynamic>{};

    for (final name in measurementNames) {
      measurements[name] = {
        'amount': amountControllers[name]!.text.trim(),
        'model': modelControllers[name]!.text.trim(),
      };
    }

    if (customers[index]['clothingRecords'] == null) {
      customers[index]['clothingRecords'] = [];
    }

    final records = List<dynamic>.from(
      customers[index]['clothingRecords'],
    );

    records.add({
      'title': title,
      'date': formatDate(DateTime.now()),
      'unit': unit,
      'measurements': measurements,
    });

    customers[index]['clothingRecords'] = records;

    await prefs.setString(
      'customers',
      jsonEncode(customers),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لباس جدید ثبت شد.'),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    titleController.dispose();

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
        title: const Text('ثبت لباس جدید'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'مشتری: ${widget.customer['name']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'نام / مدل لباس',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

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

            ...measurementNames.map(
              (name) => MeasurementRow(
                title: name,
                unit: unit,
                amountController: amountControllers[name]!,
                modelController: modelControllers[name]!,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: saveClothing,
              icon: const Icon(Icons.save),
              label: const Text('ذخیره لباس'),
            ),
          ],
        ),
      ),
    );
  }
}

class ClothingListPage extends StatelessWidget {
  final dynamic customer;

  const ClothingListPage({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> records = [];

    if (customer['clothingRecords'] != null) {
      records = List<dynamic>.from(
        customer['clothingRecords'],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('لباس‌های مشتری'),
        centerTitle: true,
      ),
      body: records.isEmpty
          ? const Center(
              child: Text('هنوز لباسی ثبت نشده است.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];

                final measurements =
                    Map<String, dynamic>.from(
                  record['measurements'],
                );

                return Card(
                  child: ExpansionTile(
                    title: Text(
                      record['title'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'تاریخ: ${record['date'] ?? 'ثبت نشده'}'
                      '\nواحد: ${record['unit']}',
                    ),
                    children: [
                      ...measurementNames.map((name) {
                        final data = measurements[name];

                        if (data == null) {
                          return const SizedBox();
                        }

                        return ListTile(
                          title: Text(name),
                          subtitle: Text(
                            'مقدار: '
                            '${data['amount'].toString().isEmpty ? 'ثبت نشده' : data['amount']} '
                            '${record['unit']}\n'
                            'مدل لباس: '
                            '${data['model'].toString().isEmpty ? 'ثبت نشده' : data['model']}',
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

String formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year/$month/$day';
}
