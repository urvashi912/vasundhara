import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:pict_frontend/pages/Biowaste/blogs.dart';
import 'package:pict_frontend/pages/Biowaste/videos.dart';
import 'package:pict_frontend/pages/ChatBot/chatbot.dart';
import 'package:pict_frontend/pages/Events/event_details.dart';
import 'package:pict_frontend/pages/Recycler/recycleChatbot.dart';
import 'package:pict_frontend/providers/event_notifier.dart';
import 'package:pict_frontend/utils/constants/app_colors.dart';
import 'package:pict_frontend/utils/constants/app_constants.dart';
import 'package:pict_frontend/utils/logging/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pict_frontend/utils/geolocation/geolocation_service.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

import '../../models/Event.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  String? _name;
  String? _id;
  String? _userImage;
  String? _location;
  String? _aqi;
  bool _isLoadingAqi = false;
  Position? _currentPosition;

  final String _googleAirQualityApiKey = "AIzaSyDlaOgAIfENMBp18EY8vn07MdtTd0QwmUU"; // Google Air Quality API key

  Future<void> getSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Load user data first
    setState(() {
      _name = prefs.getString("name");
      _id = prefs.getString("userId");
      _userImage = prefs.getString("image");
      _location = prefs.getString("cityName");
    });
    
    // Get current position and fetch AQI
    try {
      // Use GeolocationService methods properly
      await GeolocationService.determinePosition();
      GeolocationService.storeLocation();
      
      // Get the actual position for AQI request
      _currentPosition = await _getCurrentPosition();
      
      // Update location from prefs after it's stored
      SharedPreferences updatedPrefs = await SharedPreferences.getInstance();
      setState(() {
        _location = updatedPrefs.getString("cityName") ?? _location;
      });
      
      // Fetch AQI after location is confirmed
      if (_currentPosition != null) {
        await _fetchAqi();
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _aqi = "Location unavailable";
      });
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  Future<void> _fetchAqi() async {
    if (_currentPosition == null) {
      // Try to get current position if not available
      try {
        _currentPosition = await _getCurrentPosition();
      } catch (e) {
        print('Failed to get current position: $e');
        setState(() {
          _aqi = "Location unavailable";
        });
        return;
      }
    }

    if (_currentPosition == null) {
      setState(() {
        _aqi = "Location unavailable";
      });
      return;
    }

    setState(() {
      _isLoadingAqi = true;
    });

    try {
      final lat = _currentPosition!.latitude;
      final lon = _currentPosition!.longitude;

      print('Using coordinates: Lat: $lat, Lon: $lon');

      // Google Air Quality API endpoint
      final url = 'https://airquality.googleapis.com/v1/currentConditions:lookup?key=$_googleAirQualityApiKey';
      
      // Request body for Google Air Quality API
      final requestBody = {
        "location": {
          "latitude": lat,
          "longitude": lon
        },
        "extraComputations": [
          "HEALTH_RECOMMENDATIONS",
          "DOMINANT_POLLUTANT_CONCENTRATION",
          "POLLUTANT_CONCENTRATION",
          "LOCAL_AQI",
          "POLLUTANT_ADDITIONAL_INFO"
        ],
        "languageCode": "en"
      };

      print('Google Air Quality API URL: $url');
      print('Request Body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      print('Response Status Code: ${response.statusCode}');
      print('Google Air Quality API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('indexes') && data['indexes'] != null && data['indexes'].isNotEmpty) {
          // Look for Indian AQI first (ind_cpcb), then other local standards, finally universal AQI
          Map<String, dynamic>? selectedIndex;
          
          // Priority order: Indian CPCB > USA EPA > Universal AQI > Others
          final priorityOrder = ['ind_cpcb', 'usa_epa', 'uaqi'];
          
          for (String priorityCode in priorityOrder) {
            for (var index in data['indexes']) {
              if (index['code'] == priorityCode) {
                selectedIndex = index;
                break;
              }
            }
            if (selectedIndex != null) break;
          }
          
          // If no priority match, use the first available index
          selectedIndex ??= data['indexes'][0];
          
          if (selectedIndex != null && selectedIndex.containsKey('aqi')) {
            final int aqi = selectedIndex['aqi']?.toInt() ?? 0;
            final String category = selectedIndex['category'] ?? 'Unknown';
            final String displayName = selectedIndex['displayName'] ?? 'AQI';
            final String code = selectedIndex['code'] ?? '';
            final String? dominantPollutant = selectedIndex['dominantPollutant'];
            
            // Create display string with AQI standard info
            String aqiDisplay = "$aqi";
            
            // Add category with color indication
            String categoryDisplay = _getAQICategoryWithColor(aqi, category);
            aqiDisplay += " ($categoryDisplay)";
            
            // Add AQI standard info for clarity
            if (code == 'ind_cpcb') {
              aqiDisplay += " - Indian Standard";
            } else if (code == 'usa_epa') {
              aqiDisplay += " - US EPA";
            } else if (code == 'uaqi') {
              aqiDisplay += " - Universal";
            } else if (displayName.isNotEmpty && displayName != 'AQI') {
              aqiDisplay += " - $displayName";
            }
            
            setState(() {
              _aqi = aqiDisplay;
            });
            
            print('Selected AQI Standard: ${selectedIndex['code']} - ${selectedIndex['displayName']}');
            print('AQI Value: $aqi, Category: $category');
            print('Coordinates used: $lat, $lon');
            if (dominantPollutant != null) {
              print('Dominant Pollutant: $dominantPollutant');
            }
          } else {
            setState(() {
              _aqi = "No AQI data available";
            });
          }
        } else {
          setState(() {
            _aqi = "No AQI data for this location";
          });
        }
      } else if (response.statusCode == 400) {
        print('Bad Request: ${response.body}');
        final errorData = json.decode(response.body);
        setState(() {
          _aqi = "Invalid location data";
        });
      } else if (response.statusCode == 403) {
        print('API Key Error: ${response.body}');
        setState(() {
          _aqi = "API access denied";
        });
      } else if (response.statusCode == 429) {
        print('Rate limit exceeded: ${response.body}');
        setState(() {
          _aqi = "Rate limit exceeded";
        });
      } else {
        print('Failed to load AQI: ${response.statusCode}');
        print('Error Response: ${response.body}');
        setState(() {
          _aqi = "Service unavailable";
        });
      }
    } catch (e) {
      print('Error fetching AQI: $e');
      setState(() {
        _aqi = "Connection error";
      });
    } finally {
      setState(() {
        _isLoadingAqi = false;
      });
    }
  }

  String _getAQICategoryWithColor(int aqi, String category) {
    // Return category with appropriate indication
    if (aqi <= 50) {
      return "Good";
    } else if (aqi <= 100) {
      return "Moderate";
    } else if (aqi <= 150) {
      return "Unhealthy for Sensitive";
    } else if (aqi <= 200) {
      return "Unhealthy";
    } else if (aqi <= 300) {
      return "Very Unhealthy";
    } else {
      return "Hazardous";
    }
  }

  Color _getAQIColor(String? aqiString) {
    if (aqiString == null) return Colors.grey;
    
    // Extract AQI number from string
    final RegExp aqiRegex = RegExp(r'(\d+)');
    final match = aqiRegex.firstMatch(aqiString);
    
    if (match != null) {
      final int aqi = int.tryParse(match.group(1)!) ?? 0;
      
      if (aqi <= 50) {
        return Colors.green;
      } else if (aqi <= 100) {
        return Colors.yellow[700]!;
      } else if (aqi <= 150) {
        return Colors.orange;
      } else if (aqi <= 200) {
        return Colors.red;
      } else if (aqi <= 300) {
        return Colors.purple;
      } else {
        return Colors.red[900]!;
      }
    }
    
    return Colors.grey;
  }

  // Add refresh functionality
  Future<void> _refreshData() async {
    await getSession();
  }

  @override
  void initState() {
    _name = "";
    _id = "";
    _userImage = "";
    _location = "";
    getSession();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(getAllEvents);

    LoggerHelper.info(events.toString());
    print(_id);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Column(
                    children: [
                      AppBar(
                        automaticallyImplyLeading: false,
                        title: Text(
                          maxLines: 1,
                          "india",
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                              ),
                        ),
                        centerTitle: true,
                        backgroundColor: TColors.primaryGreen,
                        actions: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: _userImage != null && _userImage!.isNotEmpty
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
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    "assets/images/villager.png",
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                  )
                                : const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                          )
                        ],
                      ),
                      ClipPath(
                        child: SizedBox(
                          height: 80,
                          width: double.infinity,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: TColors.primaryGreen,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(100),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Vasundhara",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge!
                                      .copyWith(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                ),
                                if (_isLoadingAqi)
                                  const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                else if (_aqi != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getAQIColor(_aqi).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getAQIColor(_aqi).withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      "AQI: $_aqi",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.black
                                                : Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                if (!_isLoadingAqi &&
                                    _location != null &&
                                    _location!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.black54
                                              : Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _location!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.black54
                                                    : Colors.white70,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Text(
                  "Services Categories",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 22),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const VideosPage(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? TColors.white
                                      : TColors.black),
                            ),
                            child: Image.asset(
                              "assets/images/videos.png",
                              scale: 2,
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            "Videos",
                            style:
                                Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: TColors.darkGrey,
                                    ),
                          )
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const BlogPage(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? TColors.white
                                      : TColors.black),
                            ),
                            child: Image.asset(
                              "assets/images/blogs.png",
                              scale: 2,
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            "Blogs",
                            style:
                                Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: TColors.darkGrey,
                                    ),
                          )
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const ChatBot(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? TColors.white
                                      : TColors.black),
                            ),
                            child: Image.asset(
                              "assets/images/footprints.png",
                              scale: 2,
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            "CO₂ Footprints",
                            style:
                                Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: TColors.darkGrey,
                                    ),
                          )
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const RecyclerChatbot(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? TColors.white
                                      : TColors.black),
                            ),
                            child: Image.asset(
                              "assets/images/recycle.png",
                              scale: 2,
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            "Reuse",
                            style:
                                Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: TColors.darkGrey,
                                    ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 20, bottom: 0),
                child: Text(
                  "Recommended For You",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 22),
                ),
              ),
              Expanded(
                child: events.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return const Center(
                        child: Text("There are no events!"),
                      );
                    }

                    return ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        Event event = events[index];
                        Color color = index % 3 == 0
                            ? TColors.primaryYellow
                            : index % 3 == 1
                                ? TColors.accentGreen
                                : TColors.accentYellow;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 5),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => EventDetailsPage(
                                    event: event,
                                    userId: _id!,
                                    userImage: _userImage!,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event.eventName.toString(),
                                            softWrap: true,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall!
                                                .copyWith(
                                                    fontWeight: FontWeight.w400,
                                                    color: TColors.black),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          event.volunteers!.isNotEmpty
                                              ? Text(
                                                  event.volunteers!.length == 1
                                                      ? "${event.volunteers!.length} Volunteer"
                                                      : "${event.volunteers!.length} Volunteers",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge!
                                                      .copyWith(
                                                          color: TColors.black),
                                                )
                                              : const SizedBox.shrink(),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            "${AppConstants.months[event.eventStartDate!.month - 1]} ${event.eventStartDate!.day}"
                                                .toUpperCase(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge!
                                                .copyWith(color: TColors.black),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Hero(
                                      tag: event.id!,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        radius: 60,
                                        child: SizedBox(
                                          width: 180,
                                          height: 180,
                                          child: ClipOval(
                                            clipBehavior:
                                                Clip.antiAliasWithSaveLayer,
                                            child: event.eventPoster == null
                                                ? Image.network(
                                                    "${AppConstants.IP}/poster/fallback-poster.png",
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Image.asset(
                                                        "assets/images/cleandrive.jpg",
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                : Image.asset(
                                                    "assets/images/cleandrive.jpg",
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}