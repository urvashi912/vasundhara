import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:pict_frontend/bloc/chat_bloc.dart';
import 'package:pict_frontend/models/ChatBot.dart';
import 'package:pict_frontend/utils/constants/app_colors.dart';
import 'package:pict_frontend/utils/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final _formKey = GlobalKey<FormState>();
  final electricityController = TextEditingController();
  final transportationController = TextEditingController();
  final shortFlightsController = TextEditingController();
  final mediumFlightsController = TextEditingController();
  final longFlightsController = TextEditingController();
  String dietaryChoice = 'Vegan';

  double yearlyElectricityEmissions = 0;
  double yearlyTransportationEmissions = 0;
  double totalAirTravelEmissions = 0;
  double dietaryChoiceEmissions = 0;
  double totalYearlyEmissions = 0;

  String? _id;
  String? _userImage;

  Future<Null> getSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _id = prefs.getString("userId");
      _userImage = prefs.getString("image");
    });
  }

  @override
  void initState() {
    _id = "";
    _userImage = "";
    getSession();
    super.initState();
  }

  void calculateEmissions() {
    const electricityFactor = 0.3978;
    const transportationFactor = 9.087;
    const kgCO2ePerYearFactor = 12;
    const airTravelFactorShortHaul = 100.0;
    const airTravelFactorMediumHaul = 200.0;
    const airTravelFactorLongHaul = 300.0;
    const dietaryFactors = {
      'Vegan': 200.0,
      'Vegetarian': 400.0,
      'Pescatarian': 600.0,
      'MeatEater': 800.0,
    };

    final electricity = double.tryParse(electricityController.text) ?? 0;
    final transportation = double.tryParse(transportationController.text) ?? 0;
    final shortFlights = double.tryParse(shortFlightsController.text) ?? 0;
    final mediumFlights = double.tryParse(mediumFlightsController.text) ?? 0;
    final longFlights = double.tryParse(longFlightsController.text) ?? 0;

    setState(() {
      yearlyElectricityEmissions = electricity * electricityFactor * kgCO2ePerYearFactor;
      yearlyTransportationEmissions = transportation * transportationFactor * kgCO2ePerYearFactor;
      totalAirTravelEmissions = (shortFlights * airTravelFactorShortHaul) +
          (mediumFlights * airTravelFactorMediumHaul) +
          (longFlights * airTravelFactorLongHaul);
      dietaryChoiceEmissions = dietaryFactors[dietaryChoice] ?? 0;
      totalYearlyEmissions = yearlyElectricityEmissions +
          yearlyTransportationEmissions +
          totalAirTravelEmissions +
          dietaryChoiceEmissions;
    });
  }

  Widget _buildForm() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(electricityController, 'Electricity Usage (kWh/Month)'),
              _buildTextField(transportationController, 'Transportation (Miles/Week)'),
              _buildTextField(shortFlightsController, 'Short Flights (per Year)'),
              _buildTextField(mediumFlightsController, 'Medium Flights (per Year)'),
              _buildTextField(longFlightsController, 'Long Flights (per Year)'),
              DropdownButtonFormField<String>(
                value: dietaryChoice,
                decoration: InputDecoration(
                  labelText: 'Dietary Choice',
                  border: OutlineInputBorder(),
                ),
                items: ['Vegan', 'Vegetarian', 'Pescatarian', 'MeatEater']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    dietaryChoice = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    calculateEmissions();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Calculate Emissions',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        keyboardType: TextInputType.number,
        validator: (value) => value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  Widget _buildCustomBarChart() {
    final List<double> emissionsData = [
      yearlyElectricityEmissions,
      yearlyTransportationEmissions,
      totalAirTravelEmissions,
      dietaryChoiceEmissions,
    ];

    final List<String> labels = [
      'Electricity',
      'Transport',
      'Flights',
      'Diet',
    ];

    final List<Color> colors = [
      TColors.primaryGreen,
      TColors.accentGreen,
      TColors.primaryYellow,
      TColors.error,
    ];

    // Find the maximum emission value for scaling
    final maxEmission = emissionsData.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 350, // Increased height to accommodate labels
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(emissionsData.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 80, // Fixed width for each bar
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (emissionsData[index] / maxEmission) * 150, // Scale bars dynamically
                          decoration: BoxDecoration(
                            color: colors[index],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[index],
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emissionsData[index].toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Total Yearly Emissions: ${totalYearlyEmissions.toStringAsFixed(2)} kg CO2e',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: TColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Carbon Footprint Calculator",
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _userImage!.isNotEmpty
                ? CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: SizedBox(
                width: 180,
                height: 180,
                child: ClipOval(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: _userImage == "null"
                      ? Image.asset(
                    "assets/images/villager.png",
                    fit: BoxFit.cover,
                  )
                      : Image.network(
                    "${AppConstants.IP}/userImages/$_userImage",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
                : const CircularProgressIndicator(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildForm(),
            if (totalYearlyEmissions > 0) ...[
              const SizedBox(height: 20),
              _buildCustomBarChart(),
            ],
          ],
        ),
      ),
    );
  }
}