import 'package:amap_core_fluttify/amap_core_fluttify.dart';
import 'package:amap_location_fluttify/amap_location_fluttify.dart';
import 'package:amap_location_fluttify/src/android/android.export.g.dart';
import 'package:amap_location_fluttify/src/ios/ios.export.g.dart';

/// 定位结果 model
class Location {
  Location({
    this.address,
    this.latLng,
    this.altitude,
    this.bearing,
    this.country,
    this.province,
    this.city,
    this.cityCode,
    this.adCode,
    this.district,
    this.poiName,
    this.street,
    this.streetNumber,
    this.aoiName,
    this.accuracy,
    this.speed,
  });

  /// 地址全称
  String? address;

  /// 经纬度
  LatLng? latLng;

  /// 海拔
  double? altitude;

  /// 设备朝向/移动方向
  double? bearing;

  /// 国家
  String? country;

  /// 省份
  String? province;

  /// 城市
  String? city;

  /// 城市编号
  String? cityCode;

  /// 邮编
  String? adCode;

  /// 区域
  String? district;

  /// poi名称
  String? poiName;

  /// 街道
  String? street;

  /// 街道号
  String? streetNumber;

  /// aoi名称
  String? aoiName;

  /// 精度
  double? accuracy;

  /// 速度
  double? speed;

  @override
  String toString() {
    return 'Location{\naddress: $address, \nlatLng: ${latLng?.latitude}, ${latLng?.longitude}, \naltitude: $altitude, \nbearing: $bearing, \ncountry: $country, \nprovince: $province, \ncity: $city, \ncityCode: $cityCode, \nadCode: $adCode, \ndistrict: $district, \npoiName: $poiName, \nstreet: $street, \nstreetNumber: $streetNumber, \naoiName: $aoiName, \naccuracy: $accuracy\n}';
  }
}

/// 后台定位notification
class BackgroundNotification {
  BackgroundNotification({
    required this.contentTitle,
    required this.contentText,
    this.when,
    required this.channelId,
    required this.channelName,
    this.enableLights = true,
    this.showBadge = true,
  });

  String contentTitle;
  String contentText;
  int? when;
  String channelId;
  String channelName;
  bool enableLights;
  bool showBadge;
}

class GeoFenceEvent {
  final String? customId;
  final String? fenceId;
  final GeoFenceStatus? status;
  final GeoFence? genFence;

  GeoFenceEvent({
    this.customId,
    this.fenceId,
    this.status,
    this.genFence,
  });

  @override
  String toString() {
    return 'GeoFenceEvent{customId: $customId, fenceId: $fenceId, status: $status, genFence: $genFence}';
  }
}

class GeoFence {
  final com_amap_api_fence_GeoFence? androidModel;
  final AMapGeoFenceRegion? iosModel;

  GeoFence.android(this.androidModel) : this.iosModel = null;

  GeoFence.ios(this.iosModel) : this.androidModel = null;

  Future<String?> get customId async {
    return platform(
      android: (pool) => androidModel!.getCustomId(),
      ios: (pool) => iosModel!.get_customID(),
    );
  }
}
