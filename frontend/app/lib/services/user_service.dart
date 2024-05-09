import 'package:app/models/user/login_model.dart';
import 'package:app/models/user/my_info_model.dart';
import 'package:app/models/user/password_change_model.dart';
import 'package:app/models/user/password_check_model.dart';
import 'package:app/models/user/pin_change_model.dart';
import 'package:app/models/user/pin_login_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart' as Dio;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

class UserService {
  final _dio = Dio.Dio();
  final _storage = FlutterSecureStorage();
  final baseUrl = dotenv.env['API_URL'] ?? '';

  UserService() {
    _dio.interceptors.add(Dio.InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await _storage.read(key: 'token');
        String? companyCode = await _storage.read(key: 'companyCode');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          options.headers['Company-Code'] = companyCode;
        }
        return handler.next(options);
      },
    ));
    _dio.interceptors.add(LoggingInterceptor());
  }

  ///////////////////////// id 로그인 //////////////////////////////////
  Future<Map<String, dynamic>> login(LoginModel loginModel) async {
    try {
      Dio.Response response =
          await _dio.post('$baseUrl/login', data: loginModel.toJson());
      if (response.statusCode == 200) {
        String? token = response.data['issuedToken']['accessToken'];
        String? companyCode = loginModel.companyCode.toString();
        if (token != null) {
          await _storage.delete(key: 'token');
          await _storage.delete(key: 'companyCode');
          await _storage.write(key: 'token', value: token);
          await _storage.write(key: 'companyCode', value: companyCode);
          return {'success': true};
        } else {
          return {'success': false, 'message': '로그인에 실패하였습니다.'};
        }
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': response.data['message']
        };
      }
    } on Dio.DioException catch (e) {
      // debugPrint(e.message);
      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'message': e.response?.data['message'],
      };
    }
  }

  ///////////////////////// 로그아웃 //////////////////////////////////
  Future<void> logout() async {
    Dio.Response response = await _dio.post(
      '$baseUrl/logout',
    );

    if (response.statusCode == 200) {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'companyCode');
    }
  }

  ///////////////////////// pin 로그인 //////////////////////////////////
  Future<Map<String, dynamic>> pinLogin(PinLoginModel pinLoginModel) async {
    try {
      Dio.Response response = await _dio.post(
        '$baseUrl/users/pin',
        data: pinLoginModel.toJson(),
      );
      if (response.statusCode == 200) {
        if (response.data['authenticated'] == true) {
          return {'success': true};
        } else {
          return {
            'success': false,
            'message': 'pin 번호를 다시 입력해 주세요.',
            'fail_count': response.data['fail_count'],
          };
        }
      } else {
        return {'success': false, 'message': '알 수 없는 오류가 발생하였습니다.'};
      }
    } on Dio.DioException catch (e) {
      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'message': e.response?.data['message'],
        'errorCode': e.response?.data['error_code'],
      };
    }
  }

  ///////////////////////// pin 수정 //////////////////////////////////
  Future<Map<String, dynamic>> pinChange(PinChangeModel pinChangeModel) async {
    try {
      Dio.Response response = await _dio.patch(
        '$baseUrl/users/pin',
        data: pinChangeModel.toJson(),
      );
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': '알 수 없는 오류가 발생하였습니다.'};
      }
    } on Dio.DioException catch (e) {
      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'message': e.response?.data['message'],
      };
    }
  }

  ///////////////////////// 나의 정보 //////////////////////////////////
  Future<Map<String, dynamic>> myInfo() async {
    try {
      Dio.Response response = await _dio.get(
        '$baseUrl/users/profile',
      );
      if (response.statusCode == 200) {
        MyInfoModel myInfoModel =
            MyInfoModel.fromJson(response.data['employee']);

        return {'success': true, 'myInfo': myInfoModel};
      } else {
        return {'success': false, 'message': '알 수 없는 오류가 발생하였습니다.'};
      }
    } on Dio.DioException catch (e) {
      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'message': e.response?.data['message'],
      };
    }
  }

  ///////////////////////// 비밀번호 확인 //////////////////////////////////
  Future<Map<String, dynamic>> passwordCheck(
      PasswordCheckModel passwordCheckModel) async {
    try {
      Dio.Response response = await _dio.get('$baseUrl/users/pwd',
          data: passwordCheckModel.toJson());
      if (response.statusCode == 200) {
        return {
          'success': true,
        };
      } else {
        return {'success': false, 'message': '알 수 없는 오류가 발생하였습니다.'};
      }
    } on Dio.DioException catch (e) {
      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'message': e.response?.data['message'],
      };
    }
  }

  ///////////////////////// 비밀번호 재설정 //////////////////////////////////
  Future<Map<String, dynamic>> passwordChange(
      PasswordChangeModel passwordChangeModel) async {
    try {
      Dio.Response response = await _dio.patch('$baseUrl/users/pwd',
          data: passwordChangeModel.toJson());
      if (response.statusCode == 200) {
        return {
          'success': true,
        };
      } else {
        return {'success': false, 'message': '알 수 없는 오류가 발생하였습니다.'};
      }
    } on Dio.DioException catch (e) {
      return {
        'success': false,
        'statusCode': e.response?.statusCode,
        'message': e.response?.data['message'],
      };
    }
  }
}

class LoggingInterceptor extends Dio.Interceptor {
  @override
  void onRequest(
      Dio.RequestOptions options, Dio.RequestInterceptorHandler handler) {
    debugPrint("REQUEST[${options.method}] => PATH: ${options.path}");
    debugPrint("Request Header: ${options.headers}");
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
      Dio.Response response, Dio.ResponseInterceptorHandler handler) {
    debugPrint(
        "RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}");
    super.onResponse(response, handler);
  }

  @override
  void onError(Dio.DioError err, Dio.ErrorInterceptorHandler handler) {
    debugPrint(
        "ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}");
    super.onError(err, handler);
  }
}