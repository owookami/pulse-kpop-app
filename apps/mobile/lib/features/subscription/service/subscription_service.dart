import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mobile/features/subscription/model/subscription_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// 구독 서비스 프로바이더
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  // 실제 환경에서는 InAppSubscriptionService 사용
  if (kReleaseMode) {
    return InAppSubscriptionService();
  }
  // 개발 환경에서는 Mock 서비스 사용
  return MockSubscriptionService();
});

/// 구독 서비스 인터페이스
abstract class SubscriptionService {
  /// 구독 상태 확인
  Future<SubscriptionState> checkSubscriptionStatus();

  /// 구독 상품 목록 가져오기
  Future<List<SubscriptionProduct>> getSubscriptionProducts();

  /// 구독 구매
  Future<bool> purchaseSubscription(SubscriptionProduct product);

  /// 구매 복원
  Future<bool> restorePurchases();

  /// 구독 관리 페이지 열기
  Future<bool> openManageSubscriptions();

  /// 구독 취소
  Future<bool> cancelSubscription();
}

/// Mock 구독 서비스 구현
class MockSubscriptionService implements SubscriptionService {
  bool _isPremium = false;
  DateTime? _expiryDate;

  @override
  Future<SubscriptionState> checkSubscriptionStatus() async {
    // 실제 구현에서는 인앱 결제 API 통신을 수행
    await Future.delayed(const Duration(milliseconds: 500));

    // Supabase 클라이언트에서 현재 사용자 확인
    final currentUser = Supabase.instance.client.auth.currentUser;

    // 관리자 이메일인 경우 무조건 프리미엄 상태로 반환
    if (currentUser != null && currentUser.email == 'loupslim@gmail.com') {
      return SubscriptionState(
        type: SubscriptionType.yearly,
        isActive: true,
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
      );
    }

    return SubscriptionState(
      type: _isPremium ? SubscriptionType.monthly : SubscriptionType.free,
      isActive: _isPremium,
      expiryDate: _expiryDate,
      purchaseDate: _isPremium ? DateTime.now().subtract(const Duration(days: 5)) : null,
    );
  }

  @override
  Future<List<SubscriptionProduct>> getSubscriptionProducts() async {
    // 실제 구현에서는 인앱 결제 API로 상품 정보를 가져옴
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      const SubscriptionProduct(
        id: 'premium_monthly',
        title: '월간 프리미엄',
        description: '모든 프리미엄 기능 이용 가능',
        price: 9900,
        type: SubscriptionType.monthly,
      ),
      const SubscriptionProduct(
        id: 'premium_yearly',
        title: '연간 프리미엄',
        description: '월간 구독 대비 20% 할인된 가격',
        price: 99000,
        type: SubscriptionType.yearly,
      ),
    ];
  }

  @override
  Future<bool> purchaseSubscription(SubscriptionProduct product) async {
    // 실제 구현에서는 인앱 결제 API 통신을 수행
    await Future.delayed(const Duration(seconds: 1));

    // 구매 성공 시뮬레이션
    _isPremium = true;

    if (product.type == SubscriptionType.monthly) {
      _expiryDate = DateTime.now().add(const Duration(days: 30));
    } else if (product.type == SubscriptionType.yearly) {
      _expiryDate = DateTime.now().add(const Duration(days: 365));
    }

    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    // 실제 구현에서는 인앱 결제 API 통신을 수행
    await Future.delayed(const Duration(seconds: 1));

    // 복원 성공 시뮬레이션 (랜덤)
    final success = DateTime.now().millisecond % 2 == 0;

    if (success) {
      _isPremium = true;
      _expiryDate = DateTime.now().add(const Duration(days: 30));
    }

    return success;
  }

  @override
  Future<bool> cancelSubscription() async {
    // 실제 구현에서는 구독 취소 API 호출
    await Future.delayed(const Duration(seconds: 1));

    // 취소 성공 시뮬레이션
    // 구독이 즉시 취소되지 않고 만료일까지 유지되는 것이 일반적이므로
    // _isPremium은 변경하지 않고 취소 처리 여부만 반환
    return true;
  }

  @override
  Future<bool> openManageSubscriptions() async {
    // 실제 구현에서는 앱스토어나 구글플레이 구독 관리 페이지로 이동
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // 플랫폼별 스토어 URL
      final Uri storeUrl;

      if (Platform.isIOS) {
        // iOS: 앱스토어 구독 관리 페이지
        storeUrl = Uri.parse('https://apps.apple.com/account/subscriptions');
      } else if (Platform.isAndroid) {
        // Android: 구글 플레이 구독 관리 페이지
        storeUrl = Uri.parse('https://play.google.com/store/account/subscriptions');
      } else {
        // 웹이나 다른 플랫폼은 지원하지 않음
        return false;
      }

      // URL 열기
      final result = await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
      return result;
    } catch (e) {
      // 실패한 경우 false 반환
      return false;
    }
  }
}

/// 구독 서비스 인터페이스
abstract class ISubscriptionService {
  /// 구독 상품 목록 조회
  Future<List<SubscriptionProduct>> getProducts();

  /// 구독 상태 확인
  Future<SubscriptionState> getSubscriptionStatus();

  /// 구독 구매
  Future<bool> purchase(SubscriptionProduct product);

  /// 구독 복원
  Future<bool> restorePurchases();

  /// 구독 취소
  Future<bool> cancelSubscription();
}

/// 인앱 결제 기반 구독 서비스 구현
class InAppSubscriptionService implements SubscriptionService {
  /// 싱글톤 인스턴스
  static final InAppSubscriptionService _instance = InAppSubscriptionService._internal();

  /// 팩토리 생성자
  factory InAppSubscriptionService() => _instance;

  /// 내부 생성자
  InAppSubscriptionService._internal();

  /// 인앱 결제 인스턴스
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  /// 구독 스트림 구독
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// 구독 이벤트 스트림 컨트롤러
  final StreamController<SubscriptionState> _stateController =
      StreamController<SubscriptionState>.broadcast();

  /// 구독 상태 스트림
  Stream<SubscriptionState> get stateStream => _stateController.stream;

  /// 현재 구독 상태
  SubscriptionState _currentState = const SubscriptionState();

  /// 구독 상품 ID 목록
  ///
  /// 실제 구현 시 각 플랫폼의 스토어에 등록된 ID로 변경해야 함
  /// iOS: App Store Connect > 앱 > 인앱 구매 항목에 등록된 ID
  /// Android: Google Play Console > 수익 창출 > 제품 > 인앱 상품에 등록된 ID
  final List<String> _productIds = [
    'com.pulse.subscription.monthly', // 월간 프리미엄 (iOS, Android 동일 ID 권장)
    'com.pulse.subscription.yearly', // 연간 프리미엄 (iOS, Android 동일 ID 권장)
  ];

  /// 구독 상품 매핑 데이터 (기본값)
  final Map<String, SubscriptionProduct> _products = {
    'com.pulse.subscription.monthly': const SubscriptionProduct(
      id: 'com.pulse.subscription.monthly',
      title: '월간 프리미엄',
      description: '월 단위 프리미엄 구독으로 모든 기능을 이용하세요.',
      price: 9900,
      type: SubscriptionType.monthly,
    ),
    'com.pulse.subscription.yearly': const SubscriptionProduct(
      id: 'com.pulse.subscription.yearly',
      title: '연간 프리미엄',
      description: '연간 프리미엄 구독으로 저렴하게 모든 기능을 이용하세요.',
      price: 99000,
      type: SubscriptionType.yearly,
    ),
  };

  /// 초기화 여부
  bool _isInitialized = false;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 웹 환경에서는 인앱 결제 불가
    if (kIsWeb) {
      _currentState = _currentState.toError('웹에서는 인앱 결제를 지원하지 않습니다.');
      _stateController.add(_currentState);
      return;
    }

    try {
      // 인앱 결제 가능 여부 확인
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        _currentState = _currentState.toError('인앱 결제를 사용할 수 없습니다.');
        _stateController.add(_currentState);
        return;
      }

      // 구독 이벤트 리스너 설정
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdated,
        onDone: () {
          _subscription?.cancel();
        },
        onError: (error) {
          _currentState = _currentState.toError('구독 처리 중 오류가 발생했습니다: $error');
          _stateController.add(_currentState);
        },
      );

      // 구독 상태 초기화
      await checkSubscriptionStatus();

      _isInitialized = true;
    } catch (e) {
      _currentState = _currentState.toError('구독 서비스 초기화 중 오류가 발생했습니다: $e');
      _stateController.add(_currentState);
    }
  }

  /// 구독 이벤트 처리
  Future<void> _handlePurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 결제 진행 중
        _currentState = _currentState.toLoading();
        _stateController.add(_currentState);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // 결제 오류
        _currentState = _currentState.toError('구매 중 오류가 발생했습니다: ${purchaseDetails.error?.message}');
        _stateController.add(_currentState);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // 구매 또는 복원 완료 시 서버 검증 후 상태 업데이트
        await _verifyAndUpdatePurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        // 사용자가 취소한 경우
        _currentState = _currentState.copyWith(
          isLoading: false,
          error: '구매가 취소되었습니다.',
        );
        _stateController.add(_currentState);
      }

      // 구매 처리 완료 후 정리
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// 구매 영수증 검증 및 상태 업데이트
  Future<void> _verifyAndUpdatePurchase(PurchaseDetails purchase) async {
    try {
      // 영수증 검증 로직
      final isValid = await _verifyReceipt(purchase);

      if (!isValid) {
        _currentState = _currentState.toError('구매 영수증 검증에 실패했습니다.');
        _stateController.add(_currentState);
        return;
      }

      // 검증 성공 시 상태 업데이트
      final productId = purchase.productID;
      final product = _products[productId];

      if (product != null) {
        final now = DateTime.now();
        // 구독 유형에 따른 만료일 계산
        final expiryDate = product.type == SubscriptionType.monthly
            ? DateTime(now.year, now.month + 1, now.day)
            : DateTime(now.year + 1, now.month, now.day);

        _currentState = _currentState.copyWith(
          type: product.type,
          isActive: true,
          purchaseDate: now,
          expiryDate: expiryDate,
          isLoading: false,
          error: null,
        );
        _stateController.add(_currentState);

        // 서버에 구독 정보 저장
        await _saveSubscriptionToServer(purchase, expiryDate);
      }
    } catch (e) {
      _currentState = _currentState.toError('구매 처리 중 오류가 발생했습니다: $e');
      _stateController.add(_currentState);
    }
  }

  /// 구매 영수증 검증
  Future<bool> _verifyReceipt(PurchaseDetails purchase) async {
    try {
      // 플랫폼별 영수증 검증 로직 구현
      if (Platform.isIOS) {
        // iOS 영수증 검증 - App Store 서버 검증 필요
        final receipt = purchase.verificationData.serverVerificationData;

        // TODO: 서버 측에서 App Store 영수증 검증 API 호출
        // App Store 서버 검증 URL: https://buy.itunes.apple.com/verifyReceipt (프로덕션)
        // 샌드박스 검증 URL: https://sandbox.itunes.apple.com/verifyReceipt (개발)

        // 영수증 데이터와 앱 공유 비밀키를 서버에 전송해 검증
        // final response = await _verifyIosReceipt(receipt);
        // return response.isValid;

        // 임시 구현: 항상 성공으로 처리 (실제 구현에서는 서버 검증 필요)
        return true;
      } else if (Platform.isAndroid) {
        // Android 영수증 검증 - Google Play 개발자 API 검증 필요
        final purchaseToken = purchase.verificationData.serverVerificationData;
        final packageName = purchase.verificationData.source;

        // TODO: 서버 측에서 Google Play Developer API 호출하여 검증
        // Google Play API: https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions/get

        // 구매 토큰과 패키지명을 서버에 전송해 검증
        // final response = await _verifyAndroidPurchase(packageName, purchaseToken);
        // return response.isValid;

        // 임시 구현: 항상 성공으로 처리 (실제 구현에서는 서버 검증 필요)
        return true;
      }

      return false;
    } catch (e) {
      // 오류 발생 시 로그 기록 및 false 반환
      print('영수증 검증 오류: $e');
      return false;
    }
  }

  /// 서버에 구독 정보 저장
  Future<void> _saveSubscriptionToServer(PurchaseDetails purchase, DateTime expiryDate) async {
    try {
      // 현재 사용자 ID 가져오기
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('사용자 인증 정보가 없습니다.');
      }

      // Supabase 함수 호출하여 구독 정보 저장
      await Supabase.instance.client.rpc(
        'save_subscription',
        params: {
          'p_user_id': userId,
          'p_product_id': purchase.productID,
          'p_purchase_token': purchase.verificationData.serverVerificationData,
          'p_platform': Platform.isIOS ? 'ios' : 'android',
          'p_expiry_date': expiryDate.toIso8601String(),
        },
      );

      print('구독 정보가 서버에 저장되었습니다.');
    } catch (e) {
      print('서버에 구독 정보 저장 중 오류: $e');
      // 서버 저장 실패해도 로컬 구독은 유효하므로 예외 전파하지 않음
    }
  }

  @override
  Future<List<SubscriptionProduct>> getSubscriptionProducts() async {
    await initialize();

    if (kIsWeb) {
      return _products.values.toList();
    }

    try {
      // 스토어에서 상품 정보 요청
      final productDetailsResponse = await _inAppPurchase.queryProductDetails(_productIds.toSet());

      if (productDetailsResponse.error != null) {
        throw Exception('상품 정보 조회 중 오류가 발생했습니다: ${productDetailsResponse.error}');
      }

      // 스토어에서 정보 가져오기 성공 시 상품 정보 업데이트
      if (productDetailsResponse.productDetails.isNotEmpty) {
        final products = <SubscriptionProduct>[];

        for (final product in productDetailsResponse.productDetails) {
          final id = product.id;
          final defaultProduct = _products[id];

          if (defaultProduct != null) {
            // 스토어 데이터로 상품 정보 업데이트
            products.add(SubscriptionProduct(
              id: id,
              title: product.title,
              description: product.description,
              // 가격은 string에서 double로 변환 (rawPrice에는 로컬 통화 기준 가격)
              price: double.parse(product.rawPrice.toString()),
              type: defaultProduct.type,
              currencySymbol: product.currencySymbol,
              currencyCode: product.currencyCode,
            ));
          }
        }

        return products;
      }

      // 스토어에서 정보를 가져오지 못한 경우 기본값 반환
      return _products.values.toList();
    } catch (e) {
      print('상품 정보 조회 오류: $e');
      // 오류 발생 시 기본값 반환
      return _products.values.toList();
    }
  }

  @override
  Future<SubscriptionState> checkSubscriptionStatus() async {
    await initialize();

    try {
      // 현재 사용자 확인
      final currentUser = Supabase.instance.client.auth.currentUser;

      // 관리자 이메일인 경우 무조건 프리미엄 상태로 반환
      if (currentUser != null && currentUser.email == 'loupslim@gmail.com') {
        final state = SubscriptionState(
          type: SubscriptionType.yearly,
          isActive: true,
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
        );
        _currentState = state;
        _stateController.add(state);
        return state;
      }

      // 플랫폼별 구독 상태 확인 로직
      if (Platform.isIOS) {
        // iOS: StoreKit에서 구독 상태 확인
        final activeSubscriptions = await _getActiveIOSSubscriptions();
        if (activeSubscriptions.isNotEmpty) {
          // 가장 유효기간이 긴 구독 찾기
          activeSubscriptions.sort((a, b) {
            final aExpiry = a.expiryDate ?? DateTime.now();
            final bExpiry = b.expiryDate ?? DateTime.now();
            return bExpiry.compareTo(aExpiry);
          });
          final longestSubscription = activeSubscriptions.first;

          _currentState = longestSubscription;
          _stateController.add(longestSubscription);
          return longestSubscription;
        }
      } else if (Platform.isAndroid) {
        // Android: Google Play 빌링에서 구독 상태 확인
        final activeSubscriptions = await _getActiveAndroidSubscriptions();
        if (activeSubscriptions.isNotEmpty) {
          // 가장 유효기간이 긴 구독 찾기
          activeSubscriptions.sort((a, b) {
            final aExpiry = a.expiryDate ?? DateTime.now();
            final bExpiry = b.expiryDate ?? DateTime.now();
            return bExpiry.compareTo(aExpiry);
          });
          final longestSubscription = activeSubscriptions.first;

          _currentState = longestSubscription;
          _stateController.add(longestSubscription);
          return longestSubscription;
        }
      }

      // 서버에서 구독 상태 확인
      final serverSubscription = await _getServerSubscriptionStatus();
      if (serverSubscription != null) {
        _currentState = serverSubscription;
        _stateController.add(serverSubscription);
        return serverSubscription;
      }

      // 구독 없음
      _currentState = const SubscriptionState(
        type: SubscriptionType.free,
        isActive: false,
      );
      _stateController.add(_currentState);
      return _currentState;
    } catch (e) {
      _currentState = _currentState.toError('구독 상태 확인 중 오류가 발생했습니다: $e');
      _stateController.add(_currentState);
      return _currentState;
    }
  }

  /// iOS 활성 구독 조회
  Future<List<SubscriptionState>> _getActiveIOSSubscriptions() async {
    try {
      // iOS에서는 SKPaymentQueue를 통해 활성 구독 확인
      // 실제 구현에서는 앱 내 구매 플러그인의 API 사용

      // 임시 구현 (실제로는 StoreKit API 호출 필요)
      return [];
    } catch (e) {
      print('iOS 구독 확인 오류: $e');
      return [];
    }
  }

  /// Android 활성 구독 조회
  Future<List<SubscriptionState>> _getActiveAndroidSubscriptions() async {
    try {
      // Android에서는 Google Play Billing 라이브러리를 통해 활성 구독 확인
      // 실제 구현에서는 앱 내 구매 플러그인의 API 사용

      // 임시 구현 (실제로는 Google Play Billing API 호출 필요)
      return [];
    } catch (e) {
      print('Android 구독 확인 오류: $e');
      return [];
    }
  }

  /// 서버에서 구독 상태 조회
  Future<SubscriptionState?> _getServerSubscriptionStatus() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      // 서버에서 구독 상태 확인 함수 호출
      final response = await Supabase.instance.client.rpc(
        'check_subscription_status',
        params: {
          'user_uuid': userId,
        },
      );

      if (response != null && response is List && response.isNotEmpty) {
        final subscriptionData = response[0];
        final hasActiveSubscription = subscriptionData['has_active_subscription'] as bool;

        if (hasActiveSubscription) {
          final subscriptionType = subscriptionData['subscription_type'] as String;
          final daysRemaining = subscriptionData['days_remaining'] as int;

          // 만료일 계산
          final expiryDate = DateTime.now().add(Duration(days: daysRemaining));

          // 구독 유형 결정
          final type = subscriptionType.contains('yearly')
              ? SubscriptionType.yearly
              : SubscriptionType.monthly;

          return SubscriptionState(
            type: type,
            isActive: true,
            expiryDate: expiryDate,
            // 구매일은 정확히 알 수 없으므로 대략적으로 설정
            purchaseDate: type == SubscriptionType.yearly
                ? DateTime.now().subtract(const Duration(days: 30))
                : DateTime.now().subtract(const Duration(days: 7)),
          );
        }
      }

      return null;
    } catch (e) {
      print('서버 구독 확인 오류: $e');
      return null;
    }
  }

  @override
  Future<bool> purchaseSubscription(SubscriptionProduct product) async {
    await initialize();

    _currentState = _currentState.toLoading();
    _stateController.add(_currentState);

    if (kIsWeb) {
      _currentState = _currentState.toError('웹에서는 인앱 결제를 지원하지 않습니다.');
      _stateController.add(_currentState);
      return false;
    }

    try {
      // 스토어에서 상품 정보 조회
      final productDetailsResponse = await _inAppPurchase.queryProductDetails({product.id});

      if (productDetailsResponse.error != null || productDetailsResponse.productDetails.isEmpty) {
        throw Exception('상품 정보를 찾을 수 없습니다: ${productDetailsResponse.error}');
      }

      final productDetails = productDetailsResponse.productDetails.first;

      // 플랫폼별 구매 파라미터 설정
      final purchaseParam = Platform.isIOS
          ? PurchaseParam(
              productDetails: productDetails,
              applicationUserName: Supabase.instance.client.auth.currentUser?.id,
            )
          : PurchaseParam(
              productDetails: productDetails,
              applicationUserName: Supabase.instance.client.auth.currentUser?.id,
            );

      // 구독 상품 구매 시작
      bool purchaseStarted;

      // 상품 유형에 따라 적절한 메서드 호출
      if (Platform.isIOS) {
        // iOS에서는 자동 갱신 구독으로 구매 처리
        purchaseStarted = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Android에서는 구독 상품으로 구매 처리
        purchaseStarted = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }

      // 구매 시작 여부 반환
      return purchaseStarted;
    } catch (e) {
      _currentState = _currentState.toError('구매 요청 중 오류가 발생했습니다: $e');
      _stateController.add(_currentState);
      return false;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    await initialize();

    _currentState = _currentState.toLoading();
    _stateController.add(_currentState);

    if (kIsWeb) {
      _currentState = _currentState.toError('웹에서는 인앱 결제를 지원하지 않습니다.');
      _stateController.add(_currentState);
      return false;
    }

    try {
      // 이전 구매 복원
      await _inAppPurchase.restorePurchases();

      // 구매 복원은 비동기적으로 처리되며 purchaseStream을 통해 결과가 전달됨
      // 성공 여부는 purchaseStream의 이벤트로 확인할 수 있음
      return true;
    } catch (e) {
      _currentState = _currentState.toError('구매 복원 중 오류가 발생했습니다: $e');
      _stateController.add(_currentState);
      return false;
    }
  }

  @override
  Future<bool> openManageSubscriptions() async {
    // 구독 취소는 앱 스토어나 Google Play에서 직접 처리해야 함
    // 앱 내에서는 구독 취소 링크 제공만 가능
    try {
      final url = Platform.isIOS || Platform.isMacOS
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions';

      // URL 실행
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('구독 관리 페이지를 열 수 없습니다.');
      }
    } catch (e) {
      _currentState = _currentState.toError('구독 취소 링크 열기에 실패했습니다: $e');
      _stateController.add(_currentState);
      return false;
    }
  }

  @override
  Future<bool> cancelSubscription() async {
    // 실제로는 구독 취소도 앱 스토어 또는 Google Play를 통해 처리되므로
    // 구독 관리 페이지를 여는 것과 동일한 동작을 수행
    return openManageSubscriptions();
  }

  /// 서비스 정리
  void dispose() {
    _subscription?.cancel();
    _stateController.close();
  }
}
