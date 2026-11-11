import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class WifiService {
  final SupabaseClient _supabase;

  WifiService(this._supabase);

  /// Get current WiFi info from GenieACS
  Future<Map<String, dynamic>> getCurrentWifiInfo(String ipAddress) async {
    try {
      // Check if GenieACS is enabled
      final genieacsSettings = await _supabase
          .from('genieacs_settings')
          .select('setting_value')
          .eq('setting_key', 'genieacs_enabled')
          .maybeSingle();

      if (genieacsSettings == null || genieacsSettings['setting_value'] != 'true') {
        return {
          'success': false,
          'message': 'GenieACS belum diaktifkan. Hubungi admin untuk mengaktifkan fitur ini.',
        };
      }

      // The proxy only understands {url, method, body}. It verifies
      // the JWT, checks the IP against the server-side profile, and
      // uses the GenieACS credentials from Edge Function Secrets.
      // No `auth` is sent from the client.
      final genieacsUrl = await _getGenieacsUrl();
      if (genieacsUrl == null) {
        return {
          'success': false,
          'message': 'URL GenieACS tidak dikonfigurasi',
        };
      }

      final query = {
        r'$or': [
          {
            'InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANIPConnection.1.ExternalIPAddress':
                ipAddress
          },
          {'VirtualParameters.pppoeIP': ipAddress},
        ]
      };
      final targetUrl =
          '$genieacsUrl/devices?query=${Uri.encodeComponent(jsonEncode(query))}';

      final response = await _supabase.functions.invoke(
        'genieacs-proxy',
        body: {
          'url': targetUrl,
          'method': 'GET',
        },
      );

      final devices = response.data as List?;
      if (devices != null && devices.isNotEmpty) {
        final device = devices[0] as Map<String, dynamic>;
        String ssid = 'Tidak dapat diambil';
        String wifiPassword = 'Tidak dapat diambil';
        try {
          final wlanConfig = device['InternetGatewayDevice']?['LANDevice']?['1']
              ?['WLANConfiguration']?['1'];
          ssid = wlanConfig?['SSID']?['_value'] ?? 'Tidak dapat diambil';
          wifiPassword = wlanConfig?['PreSharedKey']?['1']?['KeyPassphrase']
                  ?['_value'] ??
              'Tidak dapat diambil';
        } catch (_) {}
        return {
          'success': true,
          'ssid': ssid,
          'password': wifiPassword,
        };
      }

      return {
        'success': false,
        'message': 'Device tidak ditemukan di GenieACS',
      };
    } on FunctionException catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.details ?? e.reasonPhrase ?? "Terjadi kesalahan pada server"}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Change WiFi SSID and/or password via GenieACS
  Future<Map<String, dynamic>> changeWifi({
    required String ipAddress,
    String? newSsid,
    String? newPassword,
  }) async {
    try {
      // Validate input
      if (newSsid == null && newPassword == null) {
        return {
          'success': false,
          'message': 'Minimal isi SSID atau Password baru',
        };
      }

      if (newPassword != null && newPassword.length < 8) {
        return {
          'success': false,
          'message': 'Password minimal 8 karakter',
        };
      }

      final genieacsUrl = await _getGenieacsUrl();
      if (genieacsUrl == null) {
        return {
          'success': false,
          'message': 'URL GenieACS tidak dikonfigurasi',
        };
      }

      // Step 1: find the device for this IP (the proxy verifies
      // server-side that the device belongs to the caller).
      final query = {
        r'$or': [
          {
            'InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANIPConnection.1.ExternalIPAddress':
                ipAddress
          },
          {'VirtualParameters.pppoeIP': ipAddress},
        ]
      };
      final queryUrl =
          '$genieacsUrl/devices?query=${Uri.encodeComponent(jsonEncode(query))}';
      final devicesResponse = await _supabase.functions.invoke(
        'genieacs-proxy',
        body: {
          'url': queryUrl,
          'method': 'GET',
        },
      );
      final devices = devicesResponse.data as List?;
      if (devices == null || devices.isEmpty) {
        return {
          'success': false,
          'message': 'Device tidak ditemukan di GenieACS',
        };
      }
      final deviceId = (devices[0] as Map<String, dynamic>)['_id'];

      // Step 2: set SSID and/or password via tasks.
      if (newSsid != null) {
        await _supabase.functions.invoke(
          'genieacs-proxy',
          body: {
            'url':
                '$genieacsUrl/devices/$deviceId/tasks?timeout=3000&connection_request',
            'method': 'POST',
            'body': {
              'name': 'setParameterValues',
              'parameterValues': [
                [
                  'InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID',
                  newSsid,
                  'xsd:string'
                ]
              ]
            },
          },
        );
      }
      if (newPassword != null) {
        await _supabase.functions.invoke(
          'genieacs-proxy',
          body: {
            'url':
                '$genieacsUrl/devices/$deviceId/tasks?timeout=3000&connection_request',
            'method': 'POST',
            'body': {
              'name': 'setParameterValues',
              'parameterValues': [
                [
                  'InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.PreSharedKey.1.KeyPassphrase',
                  newPassword,
                  'xsd:string'
                ]
              ]
            },
          },
        );
      }

      String message = 'WiFi berhasil diganti';
      if (newSsid != null && newPassword != null) {
        message = 'SSID dan Password berhasil diganti';
      } else if (newSsid != null) {
        message = 'SSID berhasil diganti';
      } else if (newPassword != null) {
        message = 'Password berhasil diganti';
      }
      return {
        'success': true,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Read only the public GenieACS base URL from settings.
  /// Credentials are never read here; genieacs-proxy uses the
  /// GENIEACS_USERNAME / GENIEACS_PASSWORD Edge Function Secrets.
  Future<String?> _getGenieacsUrl() async {
    final row = await _supabase
        .from('genieacs_settings')
        .select('setting_value')
        .eq('setting_key', 'genieacs_url')
        .maybeSingle();
    final url = row?['setting_value'] as String?;
    return (url == null || url.isEmpty) ? null : url;
  }

  /// Save WiFi change log to database
  Future<void> saveWifiChangeLog({
    required String customerId,
    required String ipAddress,
    required String oldSsid,
    required String newSsid,
    required String status,
    String? errorMessage,
  }) async {
    try {
      await _supabase.from('wifi_change_logs').insert({
        'customer_id': customerId,
        'ip_address': ipAddress,
        'old_ssid': oldSsid,
        'new_ssid': newSsid,
        'status': status,
        if (errorMessage != null) 'error_message': errorMessage,
      });
    } catch (e) {
      // Log error but don't throw
      print('Error saving WiFi change log: $e');
    }
  }

  /// Get WiFi change history for a customer
  Future<List<Map<String, dynamic>>> getWifiChangeHistory(String customerId) async {
    try {
      final response = await _supabase
          .from('wifi_change_logs')
          .select()
          .eq('customer_id', customerId)
          .order('changed_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting WiFi change history: $e');
      return [];
    }
  }
}
