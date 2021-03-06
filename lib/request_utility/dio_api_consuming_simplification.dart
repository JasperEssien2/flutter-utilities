import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_utilities/request_utility/request_utility_export.dart';

abstract class DioApiConsumption
    extends SimplifyApiConsumingBase<Response, SuccessResponse, ErrorResponse> {
  @override
  Future<SuccessResponse> simplifyApiRequest(
      Future<Response> Function() requestFunction,
      {bool useStatusCodeForSuccessCheck = true,
      required SuccessResponse Function(dynamic data) successResponse,
      ErrorResponse Function(Response errorData)? errorResponse,
      bool Function(dynamic data)? dataSuccessValidator,
      int statusCodeSuccess = 200}) async {
    try {
      return await _makeRequest(
        requestFunction,
        useStatusCodeForSuccessCheck,
        statusCodeSuccess,
        successResponse,
        errorResponse,
        dataSuccessValidator: dataSuccessValidator,
      );
    } on SocketException catch (_) {
      throw RequestFailedException<ErrorResponse>(
        ErrorResponse(
            errorMessage:
                'Something went wrong, please check your internet and try again',
            statusCode: 400),
      );
    } on DioError catch (e) {
      throw RequestFailedException<ErrorResponse>(
        e.response == null
            ? ErrorResponse(errorMessage: '${e.message}', statusCode: 400)
            : parseErrorFromResponse(e.response!),
      );
    }
  }

  Future<SuccessResponse> _makeRequest(
      Future<Response> Function() requestFunction,
      bool isStatusCode,
      int statusCodeSuccess,
      SuccessResponse Function(dynamic data) successResponse,
      ErrorResponse Function(Response data)? errorResponse,
      {bool Function(dynamic data)? dataSuccessValidator}) async {
    var response = await requestFunction();

    if (isStatusCode) {
      return _handleResponseBasedOnStatusCode(
          response, statusCodeSuccess, successResponse, errorResponse);
    } else {
      return _handleResponseBasedOnDataReturned(
          response, successResponse, errorResponse, dataSuccessValidator);
    }
  }

  SuccessResponse _handleResponseBasedOnStatusCode(
      Response response,
      int statusCodeSuccess,
      SuccessResponse Function(dynamic data) successResponse,
      ErrorResponse Function(Response data)? errorResponse) {
    if (response.statusCode == statusCodeSuccess) {
      return successResponse(response.data);
    } else {
      throw RequestFailedException<ErrorResponse>(
        parseErrorFromResponse(response),
      );
    }
  }

  SuccessResponse _handleResponseBasedOnDataReturned(
      Response response,
      SuccessResponse Function(dynamic data) successResponse,
      ErrorResponse Function(Response data)? errorResponse,
      bool Function(dynamic data)? dataSuccessValidator) {
    assert(dataSuccessValidator != null);
    if (dataSuccessValidator!(response.data)) {
      return successResponse(response.data);
    }
    throw RequestFailedException<ErrorResponse>(
      parseErrorFromResponse(response),
    );
  }

  @override
  ErrorResponse parseErrorFromResponse(Response requestResponse);
}
