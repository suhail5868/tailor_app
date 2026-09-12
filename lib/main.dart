import 'package:flutter/material.dart';

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
              const Text(
                'کد مشتری: 1',
                textAlign: TextAlign.right,
                style: TextStyle(
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
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('اطلاعات مشتری ثبت شد'),
                      ),
                    );
                  },
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

  const MeasurementRow({
    super.key,
    required this.title,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
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
