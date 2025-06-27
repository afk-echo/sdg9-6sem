import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../globals.dart';

class PriceForecastPage extends StatefulWidget {
  const PriceForecastPage({super.key});

  @override
  State<PriceForecastPage> createState() => _PriceForecastPageState();
}

class _PriceForecastPageState extends State<PriceForecastPage> {
  final _formKey = GlobalKey<FormState>();

  List<String> _districts = [];
  List<String> _commodities = [];
  Map<String, List<String>> _varietiesByCommodity = {};
  List<String> _varieties = [];

  String? _selectedDistrict;
  String? _selectedCommodity;
  String? _selectedVariety;
  DateTime? _selectedDate;

  bool _loading = false;
  bool _optionsLoading = true;
  String? _error;
  double? _forecastPrice;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    setState(() {
      _optionsLoading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('http://localhost:8000/price-forecast-options'); // Adjust as needed
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _districts = List<String>.from(data['districts']);
          _commodities = List<String>.from(data['commodities']);
          _varietiesByCommodity = Map<String, List<String>>.from(
            (data['varieties_by_commodity'] as Map).map(
              (k, v) => MapEntry(k, List<String>.from(v)),
            ),
          );
          _selectedDistrict = null;
          _selectedCommodity = null;
          _selectedVariety = null;
          _varieties = [];
        });
      } else {
        setState(() {
          _error = "Failed to load options: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Failed to connect to backend: $e";
      });
    } finally {
      setState(() {
        _optionsLoading = false;
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _fetchForecast(String lang) async {
    setState(() {
      _loading = true;
      _error = null;
      _forecastPrice = null;
    });

    try {
      final uri = Uri.parse('http://localhost:8000/price-forecast'); // Adjust as needed
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'district': _selectedDistrict,
          'commodity': _selectedCommodity,
          'variety': _selectedVariety,
          'forecast_date': _selectedDate!.toIso8601String().substring(0, 10),
        }),
      );
      if (response.statusCode == 200) {
        final price = double.tryParse(response.body);
        if (price != null && price >= 0) {
          setState(() => _forecastPrice = price);
        } else {
          setState(() => _error = "No forecast available for the selected options.");
        }
      } else {
        setState(() => _error = "Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _error = "Failed to connect to backend: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Price Forecast')),
          body: _optionsLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select District',
                            border: OutlineInputBorder(),
                          ),
                          items: _districts
                              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          value: _selectedDistrict,
                          onChanged: (val) => setState(() {
                            _selectedDistrict = val;
                          }),
                          validator: (val) => val == null ? 'Please select a district' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Commodity',
                            border: OutlineInputBorder(),
                          ),
                          items: _commodities
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          value: _selectedCommodity,
                          onChanged: (val) {
                            setState(() {
                              _selectedCommodity = val;
                              _selectedVariety = null;
                              _varieties = val != null
                                  ? (_varietiesByCommodity[val] ?? [])
                                  : [];
                            });
                          },
                          validator: (val) => val == null ? 'Please select a commodity' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Variety',
                            border: OutlineInputBorder(),
                          ),
                          items: _varieties
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          value: _selectedVariety,
                          onChanged: (val) => setState(() => _selectedVariety = val),
                          validator: (val) => val == null ? 'Please select a variety' : null,
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _pickDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Select Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _selectedDate == null
                                  ? 'Tap to select date'
                                  : _selectedDate!.toIso8601String().substring(0, 10),
                              style: TextStyle(
                                color: _selectedDate == null ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate() && _selectedDate != null) {
                                    _fetchForecast(lang);
                                  }
                                },
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Get Forecast'),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                        if (_forecastPrice != null)
                          Card(
                            margin: const EdgeInsets.only(top: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Forecasted Price: ₹${_forecastPrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'for $_selectedCommodity ($_selectedVariety) in $_selectedDistrict on ${_selectedDate!.toIso8601String().substring(0, 10)}',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
