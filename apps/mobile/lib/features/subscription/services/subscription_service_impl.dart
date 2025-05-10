// 인앱 결제 서비스 구현
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/subscription_models.dart';
import 'subscription_service.dart';

/// InApp Purchase 서비스 구현
class InAppPurchaseService implements SubscriptionService {
  /// 생성자
  InAppPurchaseService({
    InAppPurchase? inAppPurchase,
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance {
    _initialize();
  }

  final InAppPurchase _inAppPurchase;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // 현재 구독 상태 (초기값: 무료)
  SubscriptionStatus _currentStatus = SubscriptionStatus.free();
  @override
  SubscriptionStatus get currentStatus => _currentStatus;

  // 사용 가능한 제품 목록
  final List<SubscriptionProduct> _products = [];
  @override
  List<SubscriptionProduct> get availableProducts => _products;

  // 구매 업데이트 스트림 컨트롤러
  final _purchaseUpdatedController = StreamController<SubscriptionPurchaseResult>.broadcast();

  /// 구매 업데이트 스트림
  @override
  Stream<SubscriptionPurchaseResult> get purchaseUpdated => _purchaseUpdatedController.stream;

  // 초기화 상태
  bool _isInitialized = false;

  // 플랫폼 감지
  bool get _isIOS => !kIsWeb && Platform.isIOS;
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// 초기화 여부
  bool get isInitialized => _isInitialized;

  /// 초기화 메서드
  void _initialize() {
    // 구독 이벤트 리스너 등록
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        debugPrint('인앱 결제 스트림 오류: $error');
        _purchaseUpdatedController.add(
          SubscriptionPurchaseError(
            code: 'purchase_stream_error',
            message: '구독 처리 중 오류가 발생했습니다',
            details: error.toString(),
          ),
        );
      },
    );

    // 구독 상태 로드
    _loadSubscriptionStatus();
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 인앱 결제 초기화
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        debugPrint('인앱 결제를 사용할 수 없습니다');
        _isInitialized = false;
        return;
      }

      // 제품 ID 목록 가져오기
      final productIds = _getProductIds();

      // 제품 정보 조회
      final response = await _inAppPurchase.queryProductDetails(productIds);

      // 제품 정보 변환 및 저장
      _products.clear();

      // 무료 플랜 추가
      _products.add(SubscriptionProduct.free());

      // 구매 가능한 제품 처리
      for (final product in response.productDetails) {
        final subscriptionProduct = _convertToSubscriptionProduct(product);
        if (subscriptionProduct != null) {
          _products.add(subscriptionProduct);
        }
      }

      // 구독 상태 확인
      await checkSubscriptionStatus();

      _isInitialized = true;
      debugPrint('인앱 결제 초기화 완료: ${_products.length}개 제품 로드됨');
    } catch (e) {
      debugPrint('인앱 결제 초기화 실패: $e');
      _isInitialized = false;
    }
  }

  /// 스토어 제품 정보를 SubscriptionProduct로 변환
  SubscriptionProduct? _convertToSubscriptionProduct(ProductDetails product) {
    try {
      // 플랜 타입 결정
      SubscriptionPlanType planType;

      switch (product.id) {
        case 'com.zan.pulse.basic.monthly':
          planType = SubscriptionPlanType.basicMonthly;
          break;
        case 'com.zan.pulse.basic.yearly':
          planType = SubscriptionPlanType.basicYearly;
          break;
        case 'com.zan.pulse.premium.monthly':
          planType = SubscriptionPlanType.premiumMonthly;
          break;
        case 'com.zan.pulse.premium.yearly':
          planType = SubscriptionPlanType.premiumYearly;
          break;
        default:
          return null;
      }

      // 제목 가공
      String title = product.title.replaceAll('(Pulse)', '').replaceAll('Pulse', '').trim();

      // 기본 모델에서 기간 및 등급 가져오기
      final period = planType.period;
      final tier = planType.tier;

      // 인기 플랜 여부 (Premium Monthly를 가장 인기 있는 플랜으로 표시)
      final isMostPopular = planType == SubscriptionPlanType.premiumMonthly;

      // 베스트 밸류 플랜 여부 (Yearly 플랜을 베스트 밸류로 표시)
      final isBestValue = planType == SubscriptionPlanType.basicYearly ||
          planType == SubscriptionPlanType.premiumYearly;

      return SubscriptionProduct(
        planType: planType,
        productId: product.id,
        title: title,
        description: product.description,
        price: product.price,
        rawPrice: _extractPrice(product),
        currencyCode: _extractCurrencyCode(product),
        period: period,
        tier: tier,
        rawDetails: product.price,
        isMostPopular: isMostPopular,
        isBestValue: isBestValue,
      );
    } catch (e) {
      debugPrint('제품 변환 중 오류: $e');
      return null;
    }
  }

  /// 제품 가격에서 숫자만 추출 (예: '₩7,900' -> 7900.0)
  double _extractPrice(ProductDetails product) {
    try {
      // 가격 문자열에서 숫자만 추출
      final priceString = product.price.replaceAll(RegExp(r'[^\d\.]'), '');
      return double.tryParse(priceString) ?? 0.0;
    } catch (e) {
      debugPrint('가격 추출 중 오류: $e');
      return 0.0;
    }
  }

  /// 통화 코드 추출
  String _extractCurrencyCode(ProductDetails product) {
    try {
      // 가격 문자열에서 통화 기호 추출
      final priceString = product.price;
      if (priceString.startsWith('₩')) {
        return 'KRW';
      } else if (priceString.startsWith('\$')) {
        return 'USD';
      } else if (priceString.startsWith('€')) {
        return 'EUR';
      } else if (priceString.startsWith('¥')) {
        return 'JPY';
      }

      // 기본값
      return 'KRW';
    } catch (e) {
      debugPrint('통화 코드 추출 중 오류: $e');
      return 'KRW';
    }
  }

  /// 제품 ID 목록 가져오기
  Set<String> _getProductIds() {
    return {
      'com.zan.pulse.basic.monthly',
      'com.zan.pulse.basic.yearly',
      'com.zan.pulse.premium.monthly',
      'com.zan.pulse.premium.yearly',
    };
  }

  /// 구독 상태 로드
  Future<void> _loadSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString('subscription_status');

      if (statusJson != null) {
        try {
          final Map<String, dynamic> statusMap = Map<String, dynamic>.from(
              // ignore: unnecessary_cast
              jsonDecode(statusJson) as Map<String, dynamic>);
          _currentStatus = SubscriptionStatus.fromJson(statusMap);
        } catch (e) {
          debugPrint('구독 상태 파싱 오류: $e');
          _currentStatus = SubscriptionStatus.free();
        }
      } else {
        _currentStatus = SubscriptionStatus.free();
      }

      // 만료일 체크
      if (_currentStatus.expiryDate != null &&
          _currentStatus.expiryDate!.isBefore(DateTime.now()) &&
          _currentStatus.planType != SubscriptionPlanType.free) {
        // 구독 만료됨
        _currentStatus = SubscriptionStatus.free();
        await _saveSubscriptionStatus();
      }
    } catch (e) {
      debugPrint('구독 상태 로드 중 오류: $e');
      _currentStatus = SubscriptionStatus.free();
    }
  }

  /// 구독 상태 저장
  Future<void> _saveSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = jsonEncode(_currentStatus.toJson());
      await prefs.setString('subscription_status', statusJson);
    } catch (e) {
      debugPrint('구독 상태 저장 중 오류: $e');
    }
  }

  @override
  Future<bool> purchase(SubscriptionProduct product) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 무료 플랜인 경우 바로 처리
    if (product.planType == SubscriptionPlanType.free) {
      _currentStatus = SubscriptionStatus.free();
      await _saveSubscriptionStatus();

      _purchaseUpdatedController.add(
        SubscriptionPurchaseSuccess(
          transaction: SubscriptionTransaction(
            transactionId: 'free_${DateTime.now().millisecondsSinceEpoch}',
            purchaseDate: DateTime.now(),
            planType: SubscriptionPlanType.free,
            productId: 'free',
            price: 0.0,
            currencyCode: 'KRW',
            platform: PaymentPlatform.none,
          ),
          status: _currentStatus,
        ),
      );

      return true;
    }

    // 스토어 제품 찾기
    final productDetail = await _findProductDetail(product.productId);
    if (productDetail == null) {
      debugPrint('제품 정보를 찾을 수 없음: ${product.productId}');

      _purchaseUpdatedController.add(
        const SubscriptionPurchaseError(
          code: 'product_not_found',
          message: '구매하려는 제품을 찾을 수 없습니다',
        ),
      );

      return false;
    }

    try {
      // 구매 요청
      final purchaseParam = PurchaseParam(
        productDetails: productDetail,
        applicationUserName: null, // 사용자 아이디 (옵션)
      );

      // 구독 상품 구매 시작
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      return true; // 구매 프로세스 시작 성공
    } on PlatformException catch (e) {
      debugPrint('구매 시작 중 플랫폼 오류: ${e.message}');

      _purchaseUpdatedController.add(
        SubscriptionPurchaseError(
          code: e.code,
          message: e.message ?? '구매 중 오류가 발생했습니다',
          details: e.details,
        ),
      );

      return false;
    } catch (e) {
      debugPrint('구매 시작 중 오류: $e');

      _purchaseUpdatedController.add(
        SubscriptionPurchaseError(
          code: 'purchase_error',
          message: '구매 중 오류가 발생했습니다',
          details: e.toString(),
        ),
      );

      return false;
    }
  }

  /// 스토어 제품 정보 찾기
  Future<ProductDetails?> _findProductDetail(String productId) async {
    if (!_isInitialized) return null;

    try {
      // 제품 정보 조회
      for (final product in _products) {
        if (product.productId == productId) {
          // 해당 제품 ID로 실제 스토어 제품 찾기
          final response = await _inAppPurchase.queryProductDetails({productId});
          if (response.productDetails.isNotEmpty) {
            return response.productDetails.first;
          }
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('제품 정보 찾기 실패: $e');
      return null;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 구매 내역 복원 요청
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('구매 내역 복원 중 오류: $e');
      return false;
    }
  }

  @override
  Future<SubscriptionStatus> checkSubscriptionStatus() async {
    // 이미 로드된 상태 반환
    return _currentStatus;
  }

  @override
  Future<bool> verifyReceipt(String receiptData) async {
    // 서버 측 영수증 검증 로직 구현
    // 실제 구현에서는 백엔드 서버로 영수증을 전송하여 검증
    return true;
  }

  /// 구매 이벤트 처리
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _handlePendingPurchase(purchaseDetails);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          _handleFailedPurchase(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          _handleCanceledPurchase(purchaseDetails);
          break;
      }
    }
  }

  /// 진행 중인 구매 처리
  void _handlePendingPurchase(PurchaseDetails purchaseDetails) {
    debugPrint('구매 진행 중: ${purchaseDetails.productID}');
    // 진행 중 상태 알림 (옵션)
  }

  /// 성공한 구매 처리
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    debugPrint('구매 성공: ${purchaseDetails.productID}');

    try {
      // 영수증 검증 (실제 구현에서는 서버 측 검증 필요)
      final isValid = await verifyReceipt(purchaseDetails.verificationData.serverVerificationData);

      if (!isValid) {
        debugPrint('영수증 검증 실패: ${purchaseDetails.productID}');
        _purchaseUpdatedController.add(
          const SubscriptionPurchaseError(
            code: 'invalid_receipt',
            message: '구매 영수증 검증에 실패했습니다',
          ),
        );
        return;
      }

      // 구독 상태 업데이트
      final planType = _getPlanTypeFromProductId(purchaseDetails.productID);
      final now = DateTime.now();

      // 만료일 계산
      final expiryDate = _calculateExpiryDate(planType, now);

      // 구독 상태 생성
      _currentStatus = SubscriptionStatus(
        planType: planType,
        isActive: true,
        state: SubscriptionState.active,
        expiryDate: expiryDate,
        willRenew: true,
        receiptData: purchaseDetails.verificationData.serverVerificationData,
        purchaseDate: now,
        subscriptionId: purchaseDetails.purchaseID,
        platform: _getCurrentPlatform(),
      );

      // 상태 저장
      await _saveSubscriptionStatus();

      // 트랜잭션 완료 처리 (중요: 완료하지 않으면 purchaseStream에서 계속 이벤트 발생)
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }

      // 구매 성공 이벤트 발생
      final transaction = _createTransactionFromPurchase(purchaseDetails, planType);
      _purchaseUpdatedController.add(
        SubscriptionPurchaseSuccess(
          transaction: transaction,
          status: _currentStatus,
        ),
      );
    } catch (e) {
      debugPrint('구매 완료 처리 중 오류: $e');
      _purchaseUpdatedController.add(
        SubscriptionPurchaseError(
          code: 'purchase_completion_error',
          message: '구매 완료 처리 중 오류가 발생했습니다',
          details: e.toString(),
        ),
      );
    }
  }

  /// 플랜 타입에 따른 만료일 계산
  DateTime _calculateExpiryDate(SubscriptionPlanType planType, DateTime startDate) {
    switch (planType) {
      case SubscriptionPlanType.basicMonthly:
      case SubscriptionPlanType.premiumMonthly:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case SubscriptionPlanType.basicYearly:
      case SubscriptionPlanType.premiumYearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
      case SubscriptionPlanType.free:
      default:
        return DateTime(9999); // 무기한
    }
  }

  /// 제품 ID로부터 플랜 타입 가져오기
  SubscriptionPlanType _getPlanTypeFromProductId(String productId) {
    switch (productId) {
      case 'com.zan.pulse.basic.monthly':
        return SubscriptionPlanType.basicMonthly;
      case 'com.zan.pulse.basic.yearly':
        return SubscriptionPlanType.basicYearly;
      case 'com.zan.pulse.premium.monthly':
        return SubscriptionPlanType.premiumMonthly;
      case 'com.zan.pulse.premium.yearly':
        return SubscriptionPlanType.premiumYearly;
      default:
        return SubscriptionPlanType.free;
    }
  }

  /// 현재 플랫폼 가져오기
  PaymentPlatform _getCurrentPlatform() {
    if (_isIOS) {
      return PaymentPlatform.appStore;
    } else if (_isAndroid) {
      return PaymentPlatform.googlePlay;
    } else {
      return PaymentPlatform.web;
    }
  }

  /// 구매 정보로부터 트랜잭션 객체 생성
  SubscriptionTransaction _createTransactionFromPurchase(
    PurchaseDetails purchaseDetails,
    SubscriptionPlanType planType,
  ) {
    // 상품 정보 찾기
    double price = 0.0;
    String currencyCode = 'KRW';
    String? orderId;
    String? packageName;

    // 플랫폼별 상세 정보 처리
    if (_isAndroid && purchaseDetails is GooglePlayPurchaseDetails) {
      orderId = purchaseDetails.billingClientPurchase.orderId;
      packageName = purchaseDetails.billingClientPurchase.packageName;
    } else if (_isIOS && purchaseDetails is AppStorePurchaseDetails) {
      // iOS 관련 정보 처리
    }

    return SubscriptionTransaction(
      transactionId: purchaseDetails.purchaseID ?? 'unknown',
      purchaseDate: DateTime.now(),
      planType: planType,
      productId: purchaseDetails.productID,
      price: price,
      currencyCode: currencyCode,
      platform: _getCurrentPlatform(),
      receipt: purchaseDetails.verificationData.serverVerificationData,
      orderId: orderId,
      packageName: packageName,
      status: _currentStatus,
    );
  }

  /// 실패한 구매 처리
  void _handleFailedPurchase(PurchaseDetails purchaseDetails) {
    debugPrint('구매 실패: ${purchaseDetails.error?.message}');

    _purchaseUpdatedController.add(
      SubscriptionPurchaseError(
        code: purchaseDetails.error?.code ?? 'unknown_error',
        message: purchaseDetails.error?.message ?? '구매 중 오류가 발생했습니다',
        details: purchaseDetails.error?.details,
      ),
    );

    // 실패한 트랜잭션 완료 처리
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  /// 취소된 구매 처리
  void _handleCanceledPurchase(PurchaseDetails purchaseDetails) {
    debugPrint('구매 취소: ${purchaseDetails.productID}');

    _purchaseUpdatedController.add(
      const SubscriptionPurchaseCanceled(),
    );

    // 취소된 트랜잭션 완료 처리
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _purchaseUpdatedController.close();
  }
}
