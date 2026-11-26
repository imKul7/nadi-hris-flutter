import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, this.status);
  @override String toString() => message;
}

class LiveSession {
  final NadiApi api;
  final String token;
  final Map<String, dynamic> user;
  LiveSession({required this.api, required this.token, required this.user});
  String get role => (user['role'] ?? 'karyawan').toString();
  String get name => (user['name'] ?? 'Pengguna').toString();
  String get department => (user['department_name'] ?? '-').toString();
}

class NadiApi {
  static const configuredUrl = String.fromEnvironment('NADI_API_URL');
  static String get defaultUrl {
    if (configuredUrl.isNotEmpty) return configuredUrl;
    return kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  }
  final String baseUrl;
  NadiApi({String? baseUrl}) : baseUrl=(baseUrl ?? defaultUrl).replaceAll(RegExp(r'/$'), '');

  Future<Map<String,dynamic>> call(String method, String path, {String? token, Map<String,dynamic>? body}) async {
    final url=Uri.parse('$baseUrl$path');
    try {
      final response=await http.Request(method,url).letSend(token:token, body:body);
      Map<String,dynamic> value;
      try {value=(jsonDecode(response.body) as Map).cast<String,dynamic>();}
      catch(_){throw ApiException('Respons server tidak valid',response.statusCode);}
      if(response.statusCode<200 || response.statusCode>=300){
        throw ApiException((value['error']??'Permintaan gagal').toString(),response.statusCode);
      }
      return value;
    } on ApiException {rethrow;}
    catch(e){throw ApiException('Tidak bisa terhubung ke $baseUrl. Pastikan server menyala dan alamat IP sesuai perangkat. ($e)',0);}
  }
  Future<LiveSession> login(String email,String password) async {
    final value=await call('POST','/api/login',body:{'email':email,'password':password});
    return LiveSession(api:this,token:value['token'] as String,user:(value['user'] as Map).cast<String,dynamic>());
  }
}

extension NadiSend on http.Request {
  Future<http.Response> letSend({String? token,Map<String,dynamic>? body}) async {
    headers['Accept']='application/json';
    if(token!=null)headers['Authorization']='Bearer $token';
    if(body!=null){headers['Content-Type']='application/json';this.body=jsonEncode(body);}
    final stream=await send().timeout(const Duration(seconds:15));
    return http.Response.fromStream(stream).timeout(const Duration(seconds:15));
  }
}
