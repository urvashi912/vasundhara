import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pict_frontend/models/Report.dart';
import 'package:http/http.dart' as http;
import 'package:pict_frontend/utils/constants/app_constants.dart';

final reportServiceProvider = Provider<Report>((ref) {
  return Report();
});

class ReportService {
  static Future<String> addReport(Report report) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${AppConstants.IP}/report/addReport"),
      );

      request.fields.addAll({
        "uploaderId": report.uploaderId!,
        "uploaderName": report.uploaderName!,
        "uploaderEmail": report.uploaderEmail!,
        "description": report.description!,
        "lat": report.location!.lat.toString(),
        "lon": report.location!.lon.toString(),
        "formattedAddress": report.location!.formattedAddress.toString(),
      });

      if (report.reportAttachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'reportAttachment',
            report.reportAttachment!,
          ),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var decodedData = jsonDecode(responseData);
        // Check if "result" is present and not null
        var result = decodedData["result"];
        if (result != null) {
          return result.toString(); // Ensure it's returned as a String
        } else {
          throw Exception("Missing 'result' field in response");
        }
      } else {
        throw Exception("Failed to add report. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Failed to Add report");
    }
  }


  static Future<List<Report>> getAllReports() async {
    try {
      var response = await http.get(
        Uri.parse("${AppConstants.IP}/report/getAllReports"),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<Report> reports = jsonData.map((json) => Report.fromJson(json)).toList();
        return reports;
      } else {
        throw Exception("Failed to fetch reports. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching all reports: $e");
      throw Exception("Failed to fetch reports");
    }
  }
  static Future<List<Report>> getAllUserReports(userId, filter) async {
    try {
      var response = await http.post(
        Uri.parse(
          "${AppConstants.IP}/report/getAllUserReports",
        ),
        body: jsonEncode({"userId": userId, "filter": filter}),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      var result = jsonDecode(response.body)["result"];

      List<Report> reports = [];

      for (var reportJson in result) {
        Report report = Report.fromJson(reportJson);
        reports.add(report);
      }

      // print("Reportttt");
      // print(reports.map((e) => print(e.description)));

      return reports;
    } catch (e) {
      print(e);
      throw Exception("Failed to get User reports");
    }
  }

  static Future<List<Report>> getSearchReport(query) async {
    try {
      var response = await http.post(
        Uri.parse(
          "${AppConstants.IP}/report/searchReport",
        ),
        body: jsonEncode({"searchTerm": query}),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      var result = jsonDecode(response.body)["result"];

      List<Report> reports = [];

      for (var reportJson in result) {
        Report report = Report.fromJson(reportJson);
        reports.add(report);
      }

      print(response.body);
      print(reports);
      // print("Reportttt");
      // print(reports.map((e) => print(e.description)));

      return reports;
    } catch (e) {
      print(e);
      throw Exception("Failed to get User reports");
    }
  }

  static Future<int> getCountOfUserReports(userId) async {
    try {
      var response = await http.post(
        Uri.parse(
          "${AppConstants.IP}/report/getCountOfAllUserReports",
        ),
        body: jsonEncode({
          "userId": userId,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      int result = jsonDecode(response.body)["result"];

      print(result);

      return result;
    } catch (e) {
      print(e);
      throw Exception("Failed to count of user reports");
    }
  }

  // static Future<List<Report>> getAllUserPendingReports(userId) async {
  //   try {
  //     var response = await http.post(
  //       Uri.parse(
  //         "${AppConstants.IP}/report/getAllUserPendingReports",
  //       ),
  //       body: jsonEncode({"userId": userId}),
  //       headers: {
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     var result = jsonDecode(response.body)["result"];

  //     List<Report> reports = [];

  //     for (var reportJson in result) {
  //       Report report = Report.fromJson(reportJson);
  //       reports.add(report);
  //     }

  //     return reports;
  //   } catch (e) {
  //     print(e);
  //     throw Exception("Failed to get User reports");
  //   }
  // }

  // static Future<List<Report>> getAllUserResolvedReports(userId) async {
  //   try {
  //     var response = await http.post(
  //       Uri.parse(
  //         "${AppConstants.IP}/report/getAllUserResolvedReports",
  //       ),
  //       body: jsonEncode({"userId": userId}),
  //       headers: {
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     var result = jsonDecode(response.body)["result"];

  //     List<Report> reports = [];

  //     for (var reportJson in result) {
  //       Report report = Report.fromJson(reportJson);
  //       reports.add(report);
  //     }

  //     return reports;
  //   } catch (e) {
  //     print(e);
  //     throw Exception("Failed to get User reports");
  //   }
  // }

  // static Future<List<Report>> getAllUserRejectedReports(userId) async {
  //   try {
  //     var response = await http.post(
  //       Uri.parse(
  //         "${AppConstants.IP}/report/getAllUserRejectedReports",
  //       ),
  //       body: jsonEncode({"userId": userId}),
  //       headers: {
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     var result = jsonDecode(response.body)["result"];

  //     List<Report> reports = [];

  //     for (var reportJson in result) {
  //       Report report = Report.fromJson(reportJson);
  //       reports.add(report);
  //     }

  //     return reports;
  //   } catch (e) {
  //     print(e);
  //     throw Exception("Failed to get User reports");
  //   }
  // }
}
