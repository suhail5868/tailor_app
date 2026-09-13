import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
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
        child: LockPage(),
      ),
    );
  }
}

// ======================================================
// قفل برنامه
// ======================================================

class LockPage extends StatefulWidget {
  const LockPage({super.key});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  final TextEditingController pinController = TextEditingController();

  bool loading = true;
  bool hasPin = false;
  String savedPin = '';

  @override
  void initState() {
    super.initState();
    loadPin();
  }

  Future<void> loadPin() async {
    final prefs = await SharedPreferences.getInstance();

    savedPin = prefs.getString('app_pin') ?? '';
    hasPin = savedPin.isNotEmpty;

    setState(() {
      loading = false;
    });
  }

  void enterApp() {
    if (hasPin) {
      if (pinController.text == savedPin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز نادرست است')),
        );
        pinController.clear();
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!hasPin) {
      return const HomePage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('قفل برنامه'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 70,
            ),
            const SizedBox(height: 20),
            const Text(
              'رمز ورود را وارد کنید',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'رمز ۴ رقمی',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => enterApp(),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enterApp,
                child: const Text('ورود'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// صفحه اصلی
// ======================================================

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
    final data = prefs.getString('customers');

    if (data == null) {
      setState(() {
        customerCount = 0;
      });
      return;
    }

    final List list = jsonDecode(data);

    setState(() {
      customerCount = list.length;
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

  Future<void> openCustomers() async {
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
        title: const Text('اپلیکیشن خیاطی'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );

              loadCount();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadCount,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 60,
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
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: openNewCustomer,
                icon: const Icon(Icons.person_add),
                label: const Text(
                  'ثبت مشتری جدید',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 55,
              child: OutlinedButton.icon(
                onPressed: openCustomers,
                icon: const Icon(Icons.people),
                label: const Text(
                  'لیست مشتریان',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// ثبت مشتری
// ======================================================

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  final List<TextEditingController> amountControllers = [];
  final List<TextEditingController> modelControllers = [];

  String unit = 'سانتی‌متر';
  String selectedDate = formatDate(DateTime.now());

  String? imagePath;
  int customerCode = 1;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < measurementNames.length; i++) {
      amountControllers.add(TextEditingController());
      modelControllers.add(TextEditingController());
    }

    loadNextCode();
  }

  Future<void> loadNextCode() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('customers');

    if (data == null) {
      setState(() {
        customerCode = 1;
      });
      return;
    }

    final List customers = jsonDecode(data);

    int maxCode = 0;

    for (final customer in customers) {
      final code = int.tryParse('${customer['code']}') ?? 0;

      if (code > maxCode) {
        maxCode = code;
      }
    }

    setState(() {
      customerCode = maxCode + 1;
    });
  }

  Future<void> chooseImage() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        imagePath = image.path;
      });
    }
  }

  Future<void> saveCustomer() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام مشتری را وارد کنید')),
      );
      return;
    }

    final measurements = <Map<String, dynamic>>[];

    for (int i = 0; i < measurementNames.length; i++) {
      measurements.add({
        'name': measurementNames[i],
        'amount': amountControllers[i].text.trim(),
        'model': modelControllers[i].text.trim(),
      });
    }

    final customer = {
      'code': customerCode,
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'note': noteController.text.trim(),
      'date': selectedDate,
      'unit': unit,
      'imagePath': imagePath,
      'measurements': measurements,
      'clothingRecords': [
        {
          'title': 'لباس اول',
          'date': selectedDate,
          'unit': unit,
          'measurements': measurements,
        }
      ],
    };

    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString('customers');

    List customers = [];

    if (data != null) {
      customers = jsonDecode(data);
    }

    customers.add(customer);

    await prefs.setString(
      'customers',
      jsonEncode(customers),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('مشتری با موفقیت ثبت شد')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    noteController.dispose();

    for (final controller in amountControllers) {
      controller.dispose();
    }

    for (final controller in modelControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت مشتری'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: chooseImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    imagePath != null ? FileImage(File(imagePath!)) : null,
                child: imagePath == null
                    ? const Icon(
                        Icons.camera_alt,
                        size: 35,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'کد مشتری: $customerCode',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'یادداشت',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            initialValue: unit,
            decoration: const InputDecoration(
              labelText: 'واحد اندازه',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'سانتی‌متر',
                child: Text('سانتی‌متر'),
              ),
              DropdownMenuItem(
                value: 'انچ',
                child: Text('انچ'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  unit = value;
                });
              }
            },
          ),
          const SizedBox(height: 15),
          Text(
            'تاریخ: $selectedDate',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 15),
          const Text(
            'اندازه‌ها',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            measurementNames.length,
            (index) => MeasurementRow(
              name: measurementNames[index],
              amountController: amountControllers[index],
              modelController: modelControllers[index],
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
    );
  }
}

// ======================================================
// ردیف اندازه
// ======================================================

class MeasurementRow extends StatelessWidget {
  final String name;
  final TextEditingController amountController;
  final TextEditingController modelController;

  const MeasurementRow({
    super.key,
    required this.name,
    required this.amountController,
    required this.modelController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'مقدار',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: 'مدل / توضیحات لباس',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// لیست مشتریان
// ======================================================

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController searchController = TextEditingController();

  List customers = [];

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('customers');

    if (data == null) {
      setState(() {
        customers = [];
      });
      return;
    }

    setState(() {
      customers = jsonDecode(data);
    });
  }

  List get filteredCustomers {
    final text = searchController.text.trim().toLowerCase();

    if (text.isEmpty) {
      return customers;
    }

    return customers.where((customer) {
      final name = '${customer['name']}'.toLowerCase();
      final phone = '${customer['phone']}'.toLowerCase();
      final code = '${customer['code']}'.toLowerCase();

      return name.contains(text) ||
          phone.contains(text) ||
          code.contains(text);
    }).toList();
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
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'جستجوی نام، شماره یا کد',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: filteredCustomers.isEmpty
                ? const Center(
                    child: Text('مشتری یافت نشد'),
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
                            backgroundImage:
                                customer['imagePath'] != null &&
                                        customer['imagePath']
                                            .toString()
                                            .isNotEmpty
                                    ? FileImage(
                                        File(
                                          customer['imagePath'],
                                        ),
                                      )
                                    : null,
                            child: customer['imagePath'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            '${customer['name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'کد: ${customer['code']}  |  ${customer['phone']}',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerDetailsPage(
                                  customer: customer,
                                ),
                              ),
                            );

                            loadCustomers();
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

// ======================================================
// جزئیات مشتری
// ======================================================

class CustomerDetailsPage extends StatefulWidget {
  final Map customer;

  const CustomerDetailsPage({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailsPage> createState() =>
      _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController noteController;

  late String unit;
  late String? imagePath;

  final List<TextEditingController> amountControllers = [];
  final List<TextEditingController> modelControllers = [];

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: '${widget.customer['name'] ?? ''}',
    );

    phoneController = TextEditingController(
      text: '${widget.customer['phone'] ?? ''}',
    );

    noteController = TextEditingController(
      text: '${widget.customer['note'] ?? ''}',
    );

    unit = '${widget.customer['unit'] ?? 'سانتی‌متر'}';

    imagePath = widget.customer['imagePath'];

    final measurements =
        widget.customer['measurements'] as List? ?? [];

    for (int i = 0; i < measurementNames.length; i++) {
      String amount = '';
      String model = '';

      if (i < measurements.length) {
        amount = '${measurements[i]['amount'] ?? ''}';
        model = '${measurements[i]['model'] ?? ''}';
      }

      amountControllers.add(
        TextEditingController(text: amount),
      );

      modelControllers.add(
        TextEditingController(text: model),
      );
    }
  }

  Future<void> chooseImage() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        imagePath = image.path;
      });
    }
  }

  Future<List> getCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('customers');

    if (data == null) {
      return [];
    }

    return jsonDecode(data);
  }

  Future<void> saveChanges() async {
    final customers = await getCustomers();

    final code = widget.customer['code'];

    final measurements = <Map<String, dynamic>>[];

    for (int i = 0; i < measurementNames.length; i++) {
      measurements.add({
        'name': measurementNames[i],
        'amount': amountControllers[i].text.trim(),
        'model': modelControllers[i].text.trim(),
      });
    }

    for (int i = 0; i < customers.length; i++) {
      if ('${customers[i]['code']}' == '$code') {
        customers[i]['name'] = nameController.text.trim();
        customers[i]['phone'] = phoneController.text.trim();
        customers[i]['note'] = noteController.text.trim();
        customers[i]['unit'] = unit;
        customers[i]['imagePath'] = imagePath;
        customers[i]['measurements'] = measurements;

        final records =
            customers[i]['clothingRecords'] as List? ?? [];

        if (records.isNotEmpty) {
          records[0]['measurements'] = measurements;
          records[0]['unit'] = unit;
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'customers',
      jsonEncode(customers),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تغییرات ذخیره شد')),
    );
  }

  Future<void> deleteCustomer() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف مشتری'),
          content: const Text(
            'آیا از حذف این مشتری مطمئن هستید؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('خیر'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('بله، حذف شود'),
            ),
          ],
        );
      },
    );

    if (answer != true) return;

    final customers = await getCustomers();

    customers.removeWhere(
      (customer) =>
          '${customer['code']}' ==
          '${widget.customer['code']}',
    );

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'customers',
      jsonEncode(customers),
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> addClothing() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddClothingPage(
          customerCode: widget.customer['code'],
        ),
      ),
    );

    setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    noteController.dispose();

    for (final controller in amountControllers) {
      controller.dispose();
    }

    for (final controller in modelControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records =
        widget.customer['clothingRecords'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات مشتری'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: chooseImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    imagePath != null && imagePath!.isNotEmpty
                        ? FileImage(File(imagePath!))
                        : null,
                child: imagePath == null
                    ? const Icon(
                        Icons.camera_alt,
                        size: 35,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'کد مشتری: ${widget.customer['code']}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
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
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'یادداشت',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: unit,
            decoration: const InputDecoration(
              labelText: 'واحد اندازه',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'سانتی‌متر',
                child: Text('سانتی‌متر'),
              ),
              DropdownMenuItem(
                value: 'انچ',
                child: Text('انچ'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  unit = value;
                });
              }
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'اندازه‌ها',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            measurementNames.length,
            (index) => MeasurementRow(
              name: measurementNames[index],
              amountController: amountControllers[index],
              modelController: modelControllers[index],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('ذخیره تغییرات'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: addClothing,
              icon: const Icon(Icons.add),
              label: const Text('افزودن لباس جدید'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClothingListPage(
                      customer: widget.customer,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.checkroom),
              label: Text(
                'لباس‌ها (${records.length})',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: TextButton.icon(
              onPressed: deleteCustomer,
              icon: const Icon(Icons.delete),
              label: const Text('حذف مشتری'),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// افزودن لباس
// ======================================================

class AddClothingPage extends StatefulWidget {
  final dynamic customerCode;

  const AddClothingPage({
    super.key,
    required this.customerCode,
  });

  @override
  State<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends State<AddClothingPage> {
  final TextEditingController titleController =
      TextEditingController();

  final List<TextEditingController> amountControllers = [];
  final List<TextEditingController> modelControllers = [];

  String unit = 'سانتی‌متر';

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < measurementNames.length; i++) {
      amountControllers.add(TextEditingController());
      modelControllers.add(TextEditingController());
    }
  }

  Future<void> saveClothing() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString('customers');

    if (data == null) return;

    final customers = jsonDecode(data);

    final measurements = <Map<String, dynamic>>[];

    for (int i = 0; i < measurementNames.length; i++) {
      measurements.add({
        'name': measurementNames[i],
        'amount': amountControllers[i].text.trim(),
        'model': modelControllers[i].text.trim(),
      });
    }

    for (final customer in customers) {
      if ('${customer['code']}' ==
          '${widget.customerCode}') {
        final records =
            customer['clothingRecords'] as List? ?? [];

        records.add({
          'title': titleController.text.trim().isEmpty
              ? 'لباس جدید'
              : titleController.text.trim(),
          'date': formatDate(DateTime.now()),
          'unit': unit,
          'measurements': measurements,
        });

        customer['clothingRecords'] = records;
      }
    }

    await prefs.setString(
      'customers',
      jsonEncode(customers),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لباس جدید ذخیره شد')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    titleController.dispose();

    for (final controller in amountControllers) {
      controller.dispose();
    }

    for (final controller in modelControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('افزودن لباس'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'نام / مدل لباس',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: unit,
            decoration: const InputDecoration(
              labelText: 'واحد اندازه',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'سانتی‌متر',
                child: Text('سانتی‌متر'),
              ),
              DropdownMenuItem(
                value: 'انچ',
                child: Text('انچ'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  unit = value;
                });
              }
            },
          ),
          const SizedBox(height: 15),
          ...List.generate(
            measurementNames.length,
            (index) => MeasurementRow(
              name: measurementNames[index],
              amountController: amountControllers[index],
              modelController: modelControllers[index],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: saveClothing,
              icon: const Icon(Icons.save),
              label: const Text('ذخیره لباس'),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// لیست لباس‌ها
// ======================================================

class ClothingListPage extends StatefulWidget {
  final Map customer;

  const ClothingListPage({
    super.key,
    required this.customer,
  });

  @override
  State<ClothingListPage> createState() =>
      _ClothingListPageState();
}

class _ClothingListPageState extends State<ClothingListPage> {
  List records = [];

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString('customers');

    if (data == null) return;

    final customers = jsonDecode(data);

    for (final customer in customers) {
      if ('${customer['code']}' ==
          '${widget.customer['code']}') {
        setState(() {
          records =
              customer['clothingRecords'] as List? ?? [];
        });

        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لباس‌های مشتری'),
        centerTitle: true,
      ),
      body: records.isEmpty
          ? const Center(
              child: Text('هنوز لباسی ثبت نشده است'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];

                final measurements =
                    record['measurements'] as List? ?? [];

                return Card(
                  child: ExpansionTile(
                    title: Text(
                      '${record['title'] ?? 'لباس'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'تاریخ: ${record['date'] ?? ''} | '
                      'واحد: ${record['unit'] ?? ''}',
                    ),
                    children: [
                      ...measurements.map(
                        (measurement) => ListTile(
                          title: Text(
                            '${measurement['name']}',
                          ),
                          subtitle: Text(
                            'مقدار: ${measurement['amount'] ?? ''}'
                            '   |   مدل: ${measurement['model'] ?? ''}',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ======================================================
// تنظیمات
// ======================================================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pinEnabled = false;
  String customerCount = '0';

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final pin = prefs.getString('app_pin') ?? '';
    final data = prefs.getString('customers');

    int count = 0;

    if (data != null) {
      count = jsonDecode(data).length;
    }

    setState(() {
      pinEnabled = pin.isNotEmpty;
      customerCount = '$count';
    });
  }

  Future<void> setPin() async {
    final controller = TextEditingController();

    final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تنظیم رمز'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'رمز ۴ رقمی',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.length == 4) {
                  Navigator.pop(
                    context,
                    controller.text,
                  );
                }
              },
              child: const Text('ذخیره'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (pin == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('app_pin', pin);

    setState(() {
      pinEnabled = true;
    });
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('app_pin');

    setState(() {
      pinEnabled = false;
    });
  }

  Future<void> backupData() async {
    final prefs = await SharedPreferences.getInstance();

    final backup = {
      'app': 'tailor_app',
      'version': 1,
      'data': prefs.getKeys().fold<Map<String, dynamic>>({}, (map, key) {
        map[key] = prefs.get(key);
        return map;
      }),
    };

    final directory =
        Directory('/storage/emulated/0/Download');

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File(
      '${directory.path}/tailor_backup.json',
    );

    await file.writeAsString(
      jsonEncode(backup),
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'پشتیبان اطلاعات اپلیکیشن خیاطی',
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'فایل پشتیبان ساخته شد:\n${file.path}',
        ),
      ),
    );
  }

  Future<void> restoreData() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (files.isEmpty || files.first.path == null) {
      return;
    }

    try {
      final file = File(files.first.path!);
      final content = await file.readAsString();

      final backup = jsonDecode(content);

      if (backup['app'] != 'tailor_app') {
        throw Exception('فایل پشتیبان معتبر نیست');
      }

      final data = backup['data'];

      if (data is Map) {
        final prefs = await SharedPreferences.getInstance();

        for (final entry in data.entries) {
          final key = entry.key.toString();
          final value = entry.value;

          if (value is String) {
            await prefs.setString(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is List) {
            await prefs.setStringList(
              key,
              value.map((e) => e.toString()).toList(),
            );
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اطلاعات با موفقیت بازیابی شد.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در بازیابی اطلاعات: $e'),
        ),
      );
    }
  }
}

// ======================================================
// تاریخ
// ======================================================

String formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');

  return '$y/$m/$d';
}
