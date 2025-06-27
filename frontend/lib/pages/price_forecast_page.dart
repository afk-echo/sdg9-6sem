import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../globals.dart';
import '../generated/l10n.dart';

class PriceForecastPage extends StatefulWidget {
  const PriceForecastPage({super.key});

  @override
  State<PriceForecastPage> createState() => _PriceForecastPageState();
}

class _PriceForecastPageState extends State<PriceForecastPage> {
  final _formKey = GlobalKey<FormState>();
  List<String> _districts = [], _commodities = [], _varieties = [];
  Map<String, List<String>> _varietiesByCommodity = {};

  String? _selectedDistrict, _selectedCommodity, _selectedVariety;
  DateTime? _selectedDate;
  bool _loading = false, _optionsLoading = true;
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
      final response = await http.get(Uri.parse('http://localhost:8000/price-forecast-options'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _districts = List<String>.from(data['districts']);
          _commodities = List<String>.from(data['commodities']);
          _varietiesByCommodity = Map.from(data['varieties_by_commodity'])
              .map((k, v) => MapEntry(k, List<String>.from(v)));
        });
      } else {
        _error = "${S.of(context)!.loadOptionsFail} ${response.statusCode}";
      }
    } catch (e) {
      _error = "${S.of(context)!.backendError} $e";
    } finally {
      setState(() => _optionsLoading = false);
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _fetchForecast(String lang) async {
    setState(() {
      _loading = true;
      _error = null;
      _forecastPrice = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/price-forecast'),
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
          _forecastPrice = price;
        } else {
          _error = S.of(context)!.noForecast;
        }
      } else {
        _error = "${S.of(context)!.serverError} ${response.statusCode}";
      }
    } catch (e) {
      _error = "${S.of(context)!.backendError} $e";
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
          appBar: AppBar(title: Text(S.of(context)!.priceForecastTitle)),
          body: _optionsLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: S.of(context)!.selectDistrict,
                            border: const OutlineInputBorder(),
                          ),
                          items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          value: _selectedDistrict,
                          onChanged: (val) => setState(() => _selectedDistrict = val),
                          validator: (val) => val == null ? S.of(context)!.districtRequired : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: S.of(context)!.selectCommodity,
                            border: const OutlineInputBorder(),
                          ),
                          items: _commodities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          value: _selectedCommodity,
                          onChanged: (val) {
                            setState(() {
                              _selectedCommodity = val;
                              _selectedVariety = null;
                              _varieties = val != null ? (_varietiesByCommodity[val] ?? []) : [];
                            });
                          },
                          validator: (val) => val == null ? S.of(context)!.commodityRequired : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: S.of(context)!.selectVariety,
                            border: const OutlineInputBorder(),
                          ),
                          items: _varieties.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          value: _selectedVariety,
                          onChanged: (val) => setState(() => _selectedVariety = val),
                          validator: (val) => val == null ? S.of(context)!.varietyRequired : null,
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _pickDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: S.of(context)!.selectDate,
                              border: const OutlineInputBorder(),
                            ),
                            child: Text(
                              _selectedDate == null
                                  ? S.of(context)!.tapToSelectDate
                                  : _selectedDate!.toIso8601String().substring(0, 10),
                              style: TextStyle(
                                color: _selectedDate == null ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loading || _selectedDate == null
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    _fetchForecast(lang);
                                  }
                                },
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(S.of(context)!.getForecast),
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
                                    "${S.of(context)!.forecastedPrice}: ₹${_forecastPrice!.toStringAsFixed(2)}",
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${S.of(context)!.forecastDetails(_selectedCommodity!, _selectedVariety!, _selectedDistrict!, _selectedDate!.toIso8601String().substring(0, 10))}",
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
