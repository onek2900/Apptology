import 'package:nearpay_flutter_sdk/nearpay.dart';

class NearpayService {
  late Nearpay nearpay;

  // Constructor to initialize NearpayService with authentication details
    NearpayService() {
      nearpay = Nearpay(
        authType: AuthenticationType.login,
        authValue: " ",
        env: Environments.sandbox,
        locale: Locale.localeDefault,
      );
    }

  // Method to initialize Nearpay
  Future<void> initializeNearpay() async {
    try {
      await nearpay.initialize();
      await nearpay.setup();
    } catch (e) {
      throw "Initialization failed: $e";
    }
  }

  // Method to logout from Nearpay
  Future<void> logoutNearpay() async {
    try {
      await nearpay.logout();
    } catch (e) {
      throw "Logout failed: $e";
    }
  }

  // Method to perform a purchase
  Future<void> makePurchase({
    required int amount,
    required String customerReferenceNumber,
    bool enableReceiptUi = true,
    bool enableReversalUi = true,
    bool enableUiDismiss = true,
    int finishTimeout = 60,
  }) async {
    try {
      await nearpay.initialize();
      await nearpay.purchase(
        amount: amount,
        customerReferenceNumber: customerReferenceNumber,
        enableReceiptUi: enableReceiptUi,
        enableReversalUi: enableReversalUi,
        enableUiDismiss: enableUiDismiss,
        finishTimeout: finishTimeout,
      );
    } catch(response) {
      print('error $response');
    }
  }
}
