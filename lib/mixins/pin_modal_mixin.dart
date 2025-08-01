import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/child/bank/modal/pin_setup_modal.dart';
import '../screens/child/bank/modal/pin_input_modal.dart';

/// PIN 모달 처리를 위한 공통 mixin
///
/// 사용법:
/// ```dart
/// class MyScreen extends StatefulWidget {
///   // ...
/// }
///
/// class _MyScreenState extends State<MyScreen> with PinModalMixin {
///   void _someFunction() {
///     showPinModalWithCheck(
///       onPinVerified: (pin) {
///         print('PIN 검증 완료: $pin');
///         // 실제 로직 수행
///       },
///       onCancel: () {
///         print('PIN 입력 취소됨');
///       },
///     );
///   }
/// }
/// ```
mixin PinModalMixin<T extends StatefulWidget> on State<T> {
  /// PIN 설정 여부를 확인하고 적절한 모달을 표시하는 공통 함수
  ///
  /// [onPinVerified]: PIN 검증 완료 시 호출되는 콜백 (PIN 문자열을 매개변수로 받음)
  /// [onCancel]: 사용자가 취소 시 호출되는 콜백
  /// [title]: PIN 입력 모달의 제목 (기본값: '결제 비밀번호를 입력해 주세요')
  Future<void> showPinModalWithCheck({
    required Function(String pin) onPinVerified,
    VoidCallback? onCancel,
    String title = '결제 비밀번호를 입력해 주세요',
  }) async {
    try {
      // 먼저 사용자 정보 확인해서 계좌번호가 있는지 체크
      final userInfo = await AuthService.getUserInfo();
      final hasAccount =
          userInfo['bankAccount'] != null &&
          userInfo['bankAccount'].toString().isNotEmpty;

      if (hasAccount) {
        // 계좌가 등록되어 있으면 PIN이 무조건 설정되어 있으므로 바로 PIN 입력 모달 표시
        print('[PinModalMixin] 계좌 정보 확인됨, 바로 PIN 입력 모달 표시');
        await _showPinInputModal(
          title: title,
          onPinVerified: onPinVerified,
          onCancel: onCancel,
        );
      } else {
        // 계좌가 없으면 PIN 관련 기능을 사용할 수 없으므로 취소 처리
        print('[PinModalMixin] 계좌 정보 없음, PIN 인증 불가');
        if (onCancel != null) {
          onCancel();
        }
      }
    } catch (e) {
      print('[PinModalMixin] PIN 모달 표시 오류: $e');
      // 에러 발생 시 취소 콜백 호출
      if (onCancel != null) {
        onCancel();
      }
    }
  }

  /// PIN 입력 모달만 바로 표시하는 함수 (PIN이 이미 설정되어 있다고 가정)
  ///
  /// [onPinVerified]: PIN 검증 완료 시 호출되는 콜백 (PIN 문자열을 매개변수로 받음)
  /// [onCancel]: 사용자가 취소 시 호출되는 콜백
  /// [title]: PIN 입력 모달의 제목 (기본값: '결제 비밀번호를 입력해 주세요')
  Future<void> showPinInputModalOnly({
    required Function(String pin) onPinVerified,
    VoidCallback? onCancel,
    String title = '결제 비밀번호를 입력해 주세요',
  }) async {
    await _showPinInputModal(
      title: title,
      onPinVerified: onPinVerified,
      onCancel: onCancel,
    );
  }

  /// PIN 입력 모달 표시 (내부 함수)
  Future<void> _showPinInputModal({
    required String title,
    required Function(String pin) onPinVerified,
    VoidCallback? onCancel,
  }) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => PinInputModal(
            title: title,
            onPinEntered: (pin) async {
              Navigator.pop(context); // PIN 입력 모달 닫기

              // PIN 검증
              final verifyResult = await AuthService.verifyPin(pin: pin);

              if (verifyResult['success'] == true) {
                // PIN 검증 성공
                onPinVerified(pin);
              } else {
                // PIN 검증 실패 - 에러 표시 후 다시 입력 모달 표시
                _showPinErrorAndRetry(
                  errorMessage: verifyResult['message'] ?? 'PIN 번호가 일치하지 않습니다.',
                  title: title,
                  onPinVerified: onPinVerified,
                  onCancel: onCancel,
                );
              }
            },
            onCancel: () {
              Navigator.pop(context);
              if (onCancel != null) onCancel();
            },
          ),
    );
  }

  /// PIN 설정 모달 표시 (내부 함수)
  Future<void> _showPinSetupModal({
    required Function(String pin) onPinSet,
    VoidCallback? onCancel,
  }) async {
    // 먼저 확인 다이얼로그 표시
    final shouldSetup = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('결제 비밀번호 설정'),
            content: const Text('안전한 거래를 위해 결제 비밀번호를 설정해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                  if (onCancel != null) onCancel();
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('설정하기'),
              ),
            ],
          ),
    );

    if (shouldSetup == true) {
      // PIN 설정 바텀 시트 표시
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => PinSetupModal(
              onPinSet: (pin) {
                print('[PinModalMixin] PIN 설정 완료: ${pin.length}자리');
                onPinSet(pin);
              },
              onCancel: () {
                Navigator.pop(context);
                if (onCancel != null) onCancel();
              },
            ),
      );
    }
  }

  /// PIN 에러 표시 후 재시도 (내부 함수)
  void _showPinErrorAndRetry({
    required String errorMessage,
    required String title,
    required Function(String pin) onPinVerified,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('인증 실패'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (onCancel != null) onCancel();
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // 다시 PIN 입력 모달 표시
                  _showPinInputModal(
                    title: title,
                    onPinVerified: onPinVerified,
                    onCancel: onCancel,
                  );
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
    );
  }
}
