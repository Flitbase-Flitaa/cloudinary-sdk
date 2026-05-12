import 'package:dio/dio.dart';

import '../enums/cloudinary_resource_type.dart';
import '../models/cloudinary_response.dart';
import '../utils/logger.dart';
import 'cloudinary_api.dart';

class CloudinaryApiClient extends CloudinaryApi {
  static const _signedRequestAssertMessage =
      'This endpoint requires an authorized request, check the Cloudinary '
      'constructor you are using and make sure you are using a valid '
      '`apiKey`, `apiSecret` and `cloudName`.';

  final String apiKey;
  final String apiSecret;
  final String cloudName;

  // Convenience accessor so methods below stay terse
  static CloudinaryLogger get _log => CloudinaryLogger.instance;

  CloudinaryApiClient({
    required this.apiKey,
    required this.apiSecret,
    required this.cloudName,
  }) : super(apiKey: apiKey, apiSecret: apiSecret);

  bool get isBasic => apiKey.isEmpty || apiSecret.isEmpty || cloudName.isEmpty;

  Future<CloudinaryResponse> upload({
    String? file,
    List<int>? fileBytes,
    String? publicId,
    String? fileName,
    String? folder,
    CloudinaryResourceType? resourceType,
    Map<String, dynamic>? optParams,
    ProgressCallback? progressCallback,
  }) async {
    assert(!isBasic, _signedRequestAssertMessage);

    if (file == null && fileBytes == null) {
      throw Exception('One of filePath or fileBytes must not be null');
    }

    resourceType ??= CloudinaryResourceType.auto;
    _log.info(
      'upload() → resource: ${resourceType.name}, '
      'folder: $folder, publicId: ${publicId ?? fileName ?? "auto"}',
    );

    var timeStamp = DateTime.now().millisecondsSinceEpoch;
    var params = <String, dynamic>{};

    if (publicId != null || fileName != null) {
      params['public_id'] = publicId ?? fileName;
    }
    if (folder != null) params['folder'] = folder;
    if (optParams != null) params.addAll(optParams);
    params['api_key'] = apiKey;
    params['file'] = fileBytes != null
        ? MultipartFile.fromBytes(
            fileBytes,
            filename: fileName ?? timeStamp.toString(),
          )
        : await MultipartFile.fromFile(file!, filename: fileName);
    params['timestamp'] = timeStamp;
    params['signature'] = getSignature(
      secret: apiSecret,
      timeStamp: timeStamp,
      params: params,
    );

    var formData = FormData.fromMap(params);

    Response<dynamic> response;
    int? statusCode;
    CloudinaryResponse cloudinaryResponse;
    try {
      response = await post(
        '$cloudName/${resourceType.name}/upload',
        data: formData,
        onSendProgress: progressCallback,
      );
      statusCode = response.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromJsonMap(response.data);
      _log.success(
        'upload() → status: $statusCode, '
        'publicId: ${cloudinaryResponse.publicId}',
      );
    } catch (e, st) {
      _log.error('upload() failed', error: e, stackTrace: st);
      if (e is DioException) statusCode = e.response?.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromError('$e');
    }
    cloudinaryResponse.statusCode = statusCode;
    return cloudinaryResponse;
  }

  Future<CloudinaryResponse> unsignedUpload({
    String? file,
    required String uploadPreset,
    List<int>? fileBytes,
    String? publicId,
    String? fileName,
    String? folder,
    CloudinaryResourceType? resourceType,
    Map<String, dynamic>? optParams,
    ProgressCallback? progressCallback,
  }) async {
    assert(uploadPreset.isNotEmpty, 'Upload preset must not be empty.');

    if (file == null && fileBytes == null) {
      throw Exception('One of filePath or fileBytes must not be null');
    }

    resourceType ??= CloudinaryResourceType.auto;
    _log.info(
      'unsignedUpload() → preset: $uploadPreset, '
      'resource: ${resourceType.name}, folder: $folder',
    );

    final params = <String, dynamic>{
      'upload_preset': uploadPreset,
      if (publicId != null || fileName != null)
        'public_id': publicId ?? fileName,
      if (folder != null) 'folder': folder,
      if (optParams?.isNotEmpty ?? false) ...optParams!,
    };

    params['file'] = fileBytes != null
        ? MultipartFile.fromBytes(
            fileBytes,
            filename:
                fileName ?? DateTime.now().millisecondsSinceEpoch.toString(),
          )
        : await MultipartFile.fromFile(file!, filename: fileName);

    var formData = FormData.fromMap(params);

    Response<dynamic> response;
    int? statusCode;
    CloudinaryResponse cloudinaryResponse;
    try {
      response = await post(
        '$cloudName/${resourceType.name}/upload',
        data: formData,
        onSendProgress: progressCallback,
      );
      statusCode = response.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromJsonMap(response.data);
      _log.success(
        'unsignedUpload() → status: $statusCode, '
        'publicId: ${cloudinaryResponse.publicId}',
      );
    } catch (e, st) {
      _log.error('unsignedUpload() failed', error: e, stackTrace: st);
      if (e is DioException) statusCode = e.response?.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromError('$e');
    }
    cloudinaryResponse.statusCode = statusCode;
    return cloudinaryResponse;
  }

  Future<CloudinaryResponse> destroy(
    String publicId, {
    CloudinaryResourceType? resourceType,
    bool? invalidate,
    Map<String, dynamic>? optParams,
  }) async {
    assert(!isBasic, _signedRequestAssertMessage);

    resourceType ??= CloudinaryResourceType.image;
    _log.info(
      'destroy() → publicId: $publicId, '
      'resource: ${resourceType.name}, invalidate: $invalidate',
    );

    var timeStamp = DateTime.now().millisecondsSinceEpoch;
    final params = <String, dynamic>{};

    if (optParams != null) params.addAll(optParams);
    if (invalidate != null) params['invalidate'] = invalidate;
    params['public_id'] = publicId;
    params['api_key'] = apiKey;
    params['timestamp'] = timeStamp;
    params['signature'] = getSignature(
      secret: apiSecret,
      timeStamp: timeStamp,
      params: params,
    );

    var formData = FormData.fromMap(params);

    Response<dynamic> response;
    CloudinaryResponse cloudinaryResponse;
    int? statusCode;
    try {
      response = await post(
        '$cloudName/${resourceType.name}/destroy',
        data: formData,
      );
      statusCode = response.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromJsonMap(response.data);
      _log.success(
        'destroy() → status: $statusCode, '
        'result: ${cloudinaryResponse.result}',
      );
    } catch (e, st) {
      _log.error('destroy() failed', error: e, stackTrace: st);
      if (e is DioException) statusCode = e.response?.statusCode;
      cloudinaryResponse = CloudinaryResponse.fromError('$e');
    }
    cloudinaryResponse.statusCode = statusCode;
    return cloudinaryResponse;
  }
}
