// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'dart:io';

import 'package:amap_core_fluttify/amap_core_fluttify.dart';
import 'package:amap_location_fluttify/src/android/android.export.g.dart';
import 'package:amap_location_fluttify/src/ios/ios.export.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'enums.dart';
import 'extensions.dart';
import 'models.dart';

/// 高德定位 主类
class AmapLocation {
  static AmapLocation instance = AmapLocation._();

  AmapLocation._() {
    initAndroidListener();
  }

  com_amap_api_location_AMapLocationClient? _androidClient;
  com_amap_api_fence_GeoFenceClient? _androidGeoFenceClient;
  AMapLocationManager? _iosClient;
  AMapGeoFenceManager? _iosGeoFenceClient;

  AMapGeoFenceManagerDelegate? _iosGeoFenceDelegate;
  AMapLocationManagerDelegate? _iosLocationDelegate;

  StreamController<Location>? _locationController;
  StreamController<GeoFenceEvent>? _geoFenceEventController;

  /// 初始化
  Future<void> init({required String iosKey}) {
    return platform(
      android: (pool) async {
        // 获取上下文, 这里获取的是Application
        final context = await android_app_Application.get();

        // 创建定位客户端
        _androidClient ??= await com_amap_api_location_AMapLocationClient
            .create__android_content_Context(context);
      },
      ios: (pool) async {
        await AmapCore.init(iosKey);
        _iosClient ??= await AMapLocationManager.create__();
      },
    );
  }

  /// 隐私是否已经展示
  Future<void> updatePrivacyShow(bool value) async {
    return platform(
      android: (pool) async {
        final context = await android_app_Application.get();
        await com_amap_api_location_AMapLocationClient.updatePrivacyShow(
            context, value, true);
      },
      ios: (pool) async {
        AMapLocationManager.updatePrivacyShow_privacyInfo(
          value
              ? AMapPrivacyShowStatus.AMapPrivacyShowStatusDidShow
              : AMapPrivacyShowStatus.AMapPrivacyShowStatusNotShow,
          AMapPrivacyInfoStatus.AMapPrivacyInfoStatusDidContain,
        );
      },
    );
  }

  /// 隐私是否已经同意
  Future<void> updatePrivacyAgree(bool value) async {
    return platform(
      android: (pool) async {
        final context = await android_app_Application.get();
        await com_amap_api_location_AMapLocationClient.updatePrivacyAgree(
          context,
          value,
        );
      },
      ios: (pool) async {
        await AMapLocationManager.updatePrivacyAgree(
          value
              ? AMapPrivacyAgreeStatus.AMapPrivacyAgreeStatusDidAgree
              : AMapPrivacyAgreeStatus.AMapPrivacyAgreeStatusNotAgree,
        );
      },
    );
  }

  /// 单次获取定位信息
  ///
  /// 选择定位模式[mode], 设置定位同时是否需要返回地址描述[needAddress], 设置定位请求超时时间，默认为30秒[timeout].
  Future<Location> fetchLocation({
    LocationAccuracy mode = LocationAccuracy.Low,
    bool? needAddress,
    Duration? timeout,
  }) async {
    var completer = Completer<Location>();
    return platform(
      android: (pool) async {
        assert(_androidClient != null,
            '请先在main方法中调用AmapLocation.instance.init()进行初始化!');

        final listener =
            await com_amap_api_location_AMapLocationListener.anonymous__();
        listener.onLocationChanged = (location) async {
          if (!completer.isCompleted) {
            completer.complete(
              Location(
                address: await location!.getAddress(),
                latLng: LatLng(
                  await location.getLatitude() ?? 0,
                  await location.getLongitude() ?? 0,
                ),
                altitude: await location.getAltitude(),
                bearing: await location.getBearing(),
                country: await location.getCountry(),
                province: await location.getProvince(),
                city: await location.getCity(),
                cityCode: await location.getCityCode(),
                adCode: await location.getAdCode(),
                district: await location.getDistrict(),
                poiName: await location.getPoiName(),
                street: await location.getStreet(),
                streetNumber: await location.getStreetNum(),
                aoiName: await location.getAoiName(),
                accuracy: await location.getAccuracy(),
                speed: await location.speed,
              ),
            );
          }
        };
        await _androidClient?.setLocationListener(listener);

        // 创建选项
        final options =
            await com_amap_api_location_AMapLocationClientOption.create__();
        // 设置单次定位
        await options.setOnceLocation(true);
        // 设置定位模式
        switch (mode) {
          // 高精度定位模式：会同时使用网络定位和GPS定位，优先返回最高精度的定位结果，以及对应的地址描述信息。
          case LocationAccuracy.High:
            await options.setLocationMode(
                com_amap_api_location_AMapLocationClientOption_AMapLocationMode
                    .Hight_Accuracy);
            break;
          // 低功耗定位模式：不会使用GPS和其他传感器，只会使用网络定位（Wi-Fi和基站定位）；
          case LocationAccuracy.Low:
            await options.setLocationMode(
                com_amap_api_location_AMapLocationClientOption_AMapLocationMode
                    .Battery_Saving);
            break;
          case LocationAccuracy.DeviceSensor:
            await options.setLocationMode(
                com_amap_api_location_AMapLocationClientOption_AMapLocationMode
                    .Device_Sensors);
            break;
        }
        // 是否返回地址描述
        if (needAddress != null) await options.setNeedAddress(needAddress);
        // 设置定位请求超时时间，默认为30秒。
        if (timeout != null) {
          await options.setHttpTimeOut(timeout.inMilliseconds);
        }

        await options.setSensorEnable(true);

        // 设置选项
        await _androidClient?.setLocationOption(options);

        // 开始定位
        await _androidClient?.startLocation();

        return completer.future;
      },
      ios: (pool) async {
        assert(_iosClient != null,
            '请先在main方法中调用AmapLocation.instance.init()进行初始化!');
        // 设置定位模式
        switch (mode) {
          // 高精度定位模式：会同时使用网络定位和GPS定位，优先返回最高精度的定位结果，以及对应的地址描述信息。
          case LocationAccuracy.High:
            await _iosClient?.set_desiredAccuracy(10);
            break;
          // 低功耗定位模式：不会使用GPS和其他传感器，只会使用网络定位（Wi-Fi和基站定位）；
          case LocationAccuracy.DeviceSensor:
          case LocationAccuracy.Low:
            await _iosClient?.set_desiredAccuracy(100);
            break;
        }
        // 设置定位请求超时时间，默认为30秒。
        if (timeout != null) {
          await _iosClient?.set_locationTimeout(timeout.inSeconds);
        }

        await _iosClient?.requestLocationWithReGeocode_completionBlock(
          needAddress ?? true,
          (location, regeocode, error) async {
            if (!completer.isCompleted) {
              final latitude =
                  await location!.coordinate.then((it) => it.latitude);
              final longitude =
                  await location.coordinate.then((it) => it.longitude);
              completer.complete(Location(
                address: await regeocode?.get_formattedAddress(),
                latLng: LatLng(await latitude ?? 0, await longitude ?? 0),
                altitude: await location.altitude,
                bearing: await location.course,
                country: await regeocode?.get_country(),
                province: await regeocode?.get_province(),
                city: await regeocode?.get_city(),
                cityCode: await regeocode?.get_citycode(),
                adCode: await regeocode?.get_adcode(),
                district: await regeocode?.get_district(),
                poiName: await regeocode?.get_POIName(),
                street: await regeocode?.get_street(),
                streetNumber: await regeocode?.get_number(),
                aoiName: await regeocode?.get_AOIName(),
                accuracy: await location.horizontalAccuracy,
                speed: await location.speed,
              ));
            }
          },
        );
        return completer.future;
      },
    );
  }

  /// 连续获取定位信息
  ///
  /// 选择定位模式[mode], 设置定位同时是否需要返回地址描述[needAddress], 设置定位请求超时时间，默认为30秒[timeout]
  /// 设置定位间隔[interval], 默认2000 ms， 设置是否开启定位缓存机制[cacheEnable].
  /// [distanceFilter] ios only: 设置更新定位的最小偏移距离, 单位:米.
  Stream<Location> listenLocation({
    LocationAccuracy mode = LocationAccuracy.Low,
    bool? needAddress,
    Duration? timeout,
    int? interval,
    double? distanceFilter,
  }) async* {
    _locationController ??= StreamController<Location>();

    if (Platform.isAndroid) {
      final listener =
          await com_amap_api_location_AMapLocationListener.anonymous__();
      listener.onLocationChanged = (location) async {
        if (!_locationController!.isClosed) {
          _locationController!.add(
            Location(
              address: await location!.getAddress(),
              latLng: LatLng(
                await location.getLatitude() ?? 0,
                await location.getLongitude() ?? 0,
              ),
              altitude: await location.getAltitude(),
              bearing: await location.getBearing(),
              country: await location.getCountry(),
              province: await location.getProvince(),
              city: await location.getCity(),
              cityCode: await location.getCityCode(),
              adCode: await location.getAdCode(),
              district: await location.getDistrict(),
              poiName: await location.getPoiName(),
              street: await location.getStreet(),
              streetNumber: await location.getStreetNum(),
              aoiName: await location.getAoiName(),
              accuracy: await location.getAccuracy(),
              speed: await location.speed,
            ),
          );
        }
      };
      await _androidClient?.setLocationListener(listener);

      // 创建选项
      final options =
          await com_amap_api_location_AMapLocationClientOption.create__();
      // 设置连续定位
      await options.setOnceLocation(false);
      // 设置定位模式
      switch (mode) {
        // 高精度定位模式：会同时使用网络定位和GPS定位，优先返回最高精度的定位结果，以及对应的地址描述信息。
        case LocationAccuracy.High:
          await options.setLocationMode(
              com_amap_api_location_AMapLocationClientOption_AMapLocationMode
                  .Hight_Accuracy);
          break;
        // 低功耗定位模式：不会使用GPS和其他传感器，只会使用网络定位（Wi-Fi和基站定位）；
        case LocationAccuracy.Low:
          await options.setLocationMode(
              com_amap_api_location_AMapLocationClientOption_AMapLocationMode
                  .Battery_Saving);
          break;
        case LocationAccuracy.DeviceSensor:
          await options.setLocationMode(
              com_amap_api_location_AMapLocationClientOption_AMapLocationMode
                  .Device_Sensors);
          break;
      }
      // 是否返回地址描述
      if (needAddress != null) await options.setNeedAddress(needAddress);
      // 设置定位请求超时时间，默认为30秒。
      if (timeout != null) await options.setHttpTimeOut(timeout.inSeconds);
      // 设置定位间隔
      if (interval != null) await options.setInterval(interval);

      await options.setSensorEnable(true);

      // 设置选项
      await _androidClient?.setLocationOption(options);

      // 开始定位
      await _androidClient?.startLocation();

      yield* _locationController!.stream;
    } else if (Platform.isIOS) {
      // 设置定位模式
      switch (mode) {
        // 高精度定位模式：会同时使用网络定位和GPS定位，优先返回最高精度的定位结果，以及对应的地址描述信息。
        case LocationAccuracy.High:
          await _iosClient?.set_desiredAccuracy(10);
          break;
        // 低功耗定位模式：不会使用GPS和其他传感器，只会使用网络定位（Wi-Fi和基站定位）；
        case LocationAccuracy.Low:
        case LocationAccuracy.DeviceSensor:
          await _iosClient?.set_desiredAccuracy(100);
          break;
      }
      // 设置定位请求超时时间，默认为30秒。
      if (timeout != null) {
        await _iosClient?.set_locationTimeout(timeout.inSeconds);
      }
      // 设定定位的最小更新距离
      if (distanceFilter != null) {
        await _iosClient?.set_distanceFilter(distanceFilter);
      }

      // 设置回调
      _iosLocationDelegate ??= await AMapLocationManagerDelegate.anonymous__();
      _iosLocationDelegate!.amapLocationManager_didUpdateLocation_reGeocode =
          (_, location, regeocode) async {
        final latitude = await location!.coordinate.then((it) => it.latitude);
        final longitude = await location.coordinate.then((it) => it.longitude);
        if (!_locationController!.isClosed) {
          _locationController!.add(Location(
            address: await regeocode?.get_formattedAddress(),
            latLng: LatLng(await latitude ?? 0, await longitude ?? 0),
            altitude: await location.altitude,
            bearing: await location.course,
            country: await regeocode?.get_country(),
            province: await regeocode?.get_province(),
            city: await regeocode?.get_city(),
            cityCode: await regeocode?.get_citycode(),
            adCode: await regeocode?.get_adcode(),
            district: await regeocode?.get_district(),
            poiName: await regeocode?.get_POIName(),
            street: await regeocode?.get_street(),
            streetNumber: await regeocode?.get_number(),
            aoiName: await regeocode?.get_AOIName(),
            accuracy: await location.horizontalAccuracy,
            speed: await location.speed,
          ));
        }
      };
      await _iosClient?.set_delegate(_iosLocationDelegate!);
      await _iosClient?.set_locatingWithReGeocode(true);
      await _iosClient?.startUpdatingLocation();

      yield* _locationController!.stream;
    }
  }

  /// 停止定位
  Future<void> stopLocation() {
    return platform(
      android: (pool) async {
        await _locationController?.close();
        _locationController = null;

        await _androidClient?.stopLocation();
      },
      ios: (pool) async {
        await _locationController?.close();
        _locationController = null;

        await _iosClient?.stopUpdatingLocation();
      },
    );
  }

  /// 开启后台定位
  Future<void> enableBackgroundLocation(
    int id,
    BackgroundNotification bgNotification,
  ) {
    return platform(
      android: (pool) async {
        final notification = await android_app_Notification.create(
          contentTitle: bgNotification.contentTitle,
          contentText: bgNotification.contentText,
          when: bgNotification.when,
          channelId: bgNotification.channelId,
          channelName: bgNotification.channelName,
          enableLights: bgNotification.enableLights,
          showBadge: bgNotification.showBadge,
        );
        await checkClient();
        await _androidClient?.enableBackgroundLocation(id, notification);
        pool..add(notification);
      },
      ios: (pool) async {
        await _iosClient?.set_allowsBackgroundLocationUpdates(true);
        await _iosClient?.set_pausesLocationUpdatesAutomatically(false);
      },
    );
  }

  /// 关闭后台定位
  Future<void> disableBackgroundLocation(bool var1) {
    return platform(
      android: (pool) async {
        await checkClient();
        await _androidClient?.disableBackgroundLocation(var1);
      },
      ios: (pool) async {
        await _iosClient?.set_allowsBackgroundLocationUpdates(false);
        await _iosClient?.set_pausesLocationUpdatesAutomatically(true);
      },
    );
  }

  /// 确保client不为空
  Future<void> checkClient() async {
    if (Platform.isAndroid) {
      // 获取上下文, 这里获取的是Application
      final context = await android_app_Application.get();

      // 创建定位客户端
      _androidClient ??= await com_amap_api_location_AMapLocationClient
          .create__android_content_Context(context);
    } else if (Platform.isIOS) {
      _iosClient ??= await AMapLocationManager.create__();
    }
  }

  void initAndroidListener() {
    if (Platform.isAndroid) {
      // 电子围栏回调
      MethodChannel(
        'com.amap.api.fence.GeoFenceClient::addGeoFenceX::Callback',
        kAmapLocationFluttifyMethodCodec,
      ).setMethodCallHandler((call) async {
        if (call.method ==
            'Callback::com.amap.api.fence.GeoFenceClient::addGeoFenceX') {
          final args = await call.arguments as Map;
          final status = args['status'] as int;
          final customId = args['customId'] as String;
          final fenceId = args['fenceId'] as String;
          debugPrint(
              '收到围栏消息: status: $status, customId: $customId, fenceId:$fenceId');
          final fence = com_amap_api_fence_GeoFence()
            ..refId = (args['fence'] as Ref).refId;
          _geoFenceEventController?.add(
            GeoFenceEvent(
              customId: customId,
              fenceId: fenceId,
              status: GeoFenceStatusX.fromAndroid(status),
              genFence: GeoFence.android(fence),
            ),
          );
        }
      });
    }
  }

  /// 创建圆形电子围栏
  Stream<GeoFenceEvent> addCircleGeoFence({
    required LatLng center,
    required double radius,
    String customId = '',
    List<GeoFenceActiveAction> activeActions = const [
      GeoFenceActiveAction.In,
      GeoFenceActiveAction.Out,
      GeoFenceActiveAction.Stayed,
    ],
  }) async* {
    _geoFenceEventController ??= StreamController<GeoFenceEvent>.broadcast();

    if (Platform.isAndroid) {
      final context = await android_app_Application.get();
      _androidGeoFenceClient ??= await com_amap_api_fence_GeoFenceClient
          .create__android_content_Context(context);

      final point = await com_amap_api_location_DPoint.create__double__double(
          center.latitude, center.longitude);

      await _androidGeoFenceClient?.addCircleGeoFence(
        activeActions.getActiveAction(),
        point,
        radius,
        customId,
      );
    } else if (Platform.isIOS) {
      _iosGeoFenceClient ??= await AMapGeoFenceManager.create__();

      _iosGeoFenceDelegate ??= await AMapGeoFenceManagerDelegate.anonymous__();
      _iosGeoFenceDelegate!
              .amapGeoFenceManager_didGeoFencesStatusChangedForRegion_customID_error =
          (_, region, customId, error) async {
        final status = await region!.get_fenceStatus();
        _geoFenceEventController?.add(
          GeoFenceEvent(
            customId: customId,
            fenceId: await region.get_identifier(),
            status: GeoFenceStatusX.fromIOS(status!),
            genFence: GeoFence.ios(region),
          ),
        );
      };
      _iosGeoFenceClient!.set_delegate(_iosGeoFenceDelegate!);

      await _iosGeoFenceClient
          ?.set_activeActionX(activeActions.getActiveAction());

      await _iosGeoFenceClient?.set_allowsBackgroundLocationUpdates(true);

      final point = await CLLocationCoordinate2D.create(
        center.latitude,
        center.longitude,
      );

      await _iosGeoFenceClient
          ?.addCircleRegionForMonitoringWithCenter_radius_customID(
              point, radius, customId);
    } else {
      throw '未实现的平台';
    }

    yield* _geoFenceEventController!.stream;
  }

  /// 创POI电子围栏
  Stream<GeoFenceEvent> addPoiGeoFence({
    required String keyword,
    String poiType = '',
    String city = '',
    int aroundRadius = 10,
    String customId = '',
    List<GeoFenceActiveAction> activeActions = const [
      GeoFenceActiveAction.In,
      GeoFenceActiveAction.Out,
      GeoFenceActiveAction.Stayed,
    ],
  }) async* {
    _geoFenceEventController ??= StreamController<GeoFenceEvent>.broadcast();

    if (Platform.isAndroid) {
      final context = await android_app_Application.get();
      _androidGeoFenceClient ??= await com_amap_api_fence_GeoFenceClient
          .create__android_content_Context(context);

      await _androidGeoFenceClient?.addPoiGeoFence(
        keyword: keyword,
        poiType: poiType,
        city: city,
        aroundRadius: aroundRadius,
        customId: customId,
        activeAction: activeActions.getActiveAction(),
      );
    } else if (Platform.isIOS) {
      _iosGeoFenceClient ??= await AMapGeoFenceManager.create__();
      _iosGeoFenceDelegate ??= await AMapGeoFenceManagerDelegate.anonymous__();

      await _iosGeoFenceClient?.set_delegate(
        _iosGeoFenceDelegate!
          ..amapGeoFenceManager_didGeoFencesStatusChangedForRegion_customID_error =
              (_, region, customId, error) async {
            final status = await region!.get_fenceStatus();
            _geoFenceEventController?.add(
              GeoFenceEvent(
                customId: customId,
                fenceId: await region.get_identifier(),
                status: GeoFenceStatusX.fromIOS(status!),
                genFence: GeoFence.ios(region),
              ),
            );
          },
      );

      await _iosGeoFenceClient
          ?.set_activeActionX(activeActions.getActiveAction());

      await _iosGeoFenceClient?.set_allowsBackgroundLocationUpdates(true);

      await _iosGeoFenceClient
          ?.addKeywordPOIRegionForMonitoringWithKeyword_POIType_city_size_customID(
        keyword,
        poiType,
        city,
        aroundRadius,
        customId,
      );
    } else {
      throw '未实现的平台';
    }

    yield* _geoFenceEventController!.stream;
  }

  /// 创建多边形电子围栏
  Stream<GeoFenceEvent> addPolygonGeoFence({
    required List<LatLng> pointList,
    String customId = '',
    List<GeoFenceActiveAction> activeActions = const [
      GeoFenceActiveAction.In,
      GeoFenceActiveAction.Out,
      GeoFenceActiveAction.Stayed,
    ],
  }) async* {
    _geoFenceEventController ??= StreamController<GeoFenceEvent>.broadcast();

    final latitudeList = pointList.map((e) => e.latitude).toList();
    final longitudeList = pointList.map((e) => e.longitude).toList();

    if (Platform.isAndroid) {
      final context = await android_app_Application.get();
      _androidGeoFenceClient ??= await com_amap_api_fence_GeoFenceClient
          .create__android_content_Context(context);

      final _pointList = await com_amap_api_location_DPoint
          .create_batch__double__double(latitudeList, longitudeList);

      await _androidGeoFenceClient?.addPolygonGeoFence(
        polygon: _pointList,
        customId: customId,
        activeAction: activeActions.getActiveAction(),
      );
    } else if (Platform.isIOS) {
      _iosGeoFenceClient ??= await AMapGeoFenceManager.create__();
      _iosGeoFenceDelegate ??= await AMapGeoFenceManagerDelegate.anonymous__();

      await _iosGeoFenceClient?.set_delegate(
        _iosGeoFenceDelegate!
          ..amapGeoFenceManager_didGeoFencesStatusChangedForRegion_customID_error =
              (_, region, customId, error) async {
            final status = await region!.get_fenceStatus();
            _geoFenceEventController?.add(
              GeoFenceEvent(
                customId: customId,
                fenceId: await region.get_identifier(),
                status: GeoFenceStatusX.fromIOS(status!),
                genFence: GeoFence.ios(region),
              ),
            );
          },
      );

      await _iosGeoFenceClient
          ?.set_activeActionX(activeActions.getActiveAction());
      await _iosGeoFenceClient?.set_allowsBackgroundLocationUpdates(true);

      final _pointList = await CLLocationCoordinate2D.create_batch(
          latitudeList, longitudeList);

      await _iosGeoFenceClient
          ?.addPolygonRegionForMonitoringWithCoordinates_count_customID(
              _pointList, _pointList.length, customId);
    } else {
      throw '未实现的平台';
    }

    yield* _geoFenceEventController!.stream;
  }

  /// 创建行政区划电子围栏
  Stream<GeoFenceEvent> addDistrictGeoFence({
    required String keyword,
    String customId = '',
    List<GeoFenceActiveAction> activeActions = const [
      GeoFenceActiveAction.In,
      GeoFenceActiveAction.Out,
      GeoFenceActiveAction.Stayed,
    ],
  }) async* {
    _geoFenceEventController ??= StreamController<GeoFenceEvent>.broadcast();

    if (Platform.isAndroid) {
      final context = await android_app_Application.get();
      _androidGeoFenceClient ??= await com_amap_api_fence_GeoFenceClient
          .create__android_content_Context(context);

      await _androidGeoFenceClient?.addDistrictGeoFence(
        keyword: keyword,
        customId: customId,
        activeAction: activeActions.getActiveAction(),
      );
    } else if (Platform.isIOS) {
      _iosGeoFenceClient ??= await AMapGeoFenceManager.create__();
      _iosGeoFenceDelegate ??= await AMapGeoFenceManagerDelegate.anonymous__();

      await _iosGeoFenceClient?.set_delegate(
        _iosGeoFenceDelegate!
          ..amapGeoFenceManager_didGeoFencesStatusChangedForRegion_customID_error =
              (_, region, customId, error) async {
            final status = await region!.get_fenceStatus();
            _geoFenceEventController?.add(
              GeoFenceEvent(
                customId: customId,
                fenceId: await region.get_identifier(),
                status: GeoFenceStatusX.fromIOS(status!),
                genFence: GeoFence.ios(region),
              ),
            );
          },
      );

      await _iosGeoFenceClient
          ?.set_activeActionX(activeActions.getActiveAction());
      await _iosGeoFenceClient?.set_allowsBackgroundLocationUpdates(true);
      await _iosGeoFenceClient
          ?.addDistrictRegionForMonitoringWithDistrictName_customID(
              keyword, customId);
    } else {
      throw '未实现的平台';
    }

    yield* _geoFenceEventController!.stream;
  }

  /// 删除单个围栏
  Future<void> removeGeoFence(GeoFence geoFence) async {
    return platform(
      android: (pool) async {
        await _androidGeoFenceClient
            ?.removeGeoFence__com_amap_api_fence_GeoFence(
                geoFence.androidModel!);
      },
      ios: (pool) async {
        await _iosGeoFenceClient?.removeTheGeoFenceRegion(geoFence.iosModel!);
      },
    );
  }

  /// 删除所有围栏
  Future<void> removeAllGeoFence() async {
    return platform(
      android: (pool) async {
        await _androidGeoFenceClient?.removeGeoFence();
      },
      ios: (pool) async {
        await _iosGeoFenceClient?.removeAllGeoFenceRegions();
      },
    );
  }

  /// 释放对象, 如果[AmapLocationDisposeMixin]不能满足需求时再使用这个方法
  Future<void> dispose() async {
    await _locationController?.close();
    _locationController = null;

    await _geoFenceEventController?.close();
    _geoFenceEventController = null;

    // 取消注册广播
    if (Platform.isAndroid) {
      await kAmapLocationFluttifyChannel.invokeMethod(
          'com.amap.api.fence.GeoFenceClient::unregisterBroadcastReceiver');
    }

    await _androidClient?.onDestroy();
    await _androidClient?.release__();
    await _iosClient?.release__();

    final isCurrentPlugin = (Ref it) => it.tag__ == 'amap_location_fluttify';
    await gGlobalReleasePool.where(isCurrentPlugin).release_batch();
    gGlobalReleasePool.removeWhere(isCurrentPlugin);

    _androidClient = null;
    _iosClient = null;
  }
}
