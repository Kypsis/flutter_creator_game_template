import 'dart:async';

import 'package:creator/creator.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

import '../style/snack_bar.dart';
import 'ad_removal_state.gen.dart';

/// Allows buying in-app. Facade of `package:in_app_purchase`.
class InAppPurchaseController {
  static final Logger _log = Logger('InAppPurchases');

  static StreamSubscription<List<PurchaseDetails>>? subscription;

  static final adRemoval = Creator.value(AdRemovalPurchaseState.notStarted());

  /// Launches the platform UI for buying an in-app purchase.
  ///
  /// Currently, the only supported in-app purchase is ad removal.
  /// To support more, ad additional classes similar to [AdRemovalPurchase]
  /// and modify this method.
  static Future<void> buy(Ref ref) async {
    if (!await InAppPurchase.instance.isAvailable()) {
      _reportError(ref, message: 'InAppPurchase.instance not available');
      return;
    }

    ref.set(adRemoval, AdRemovalPurchaseState.pending());

    _log.info('Querying the store with queryProductDetails()');
    final response = await InAppPurchase.instance.queryProductDetails({AdRemovalPurchaseState.productId});

    if (response.error != null) {
      _reportError(ref,
          message: 'There was an error when making the purchase: '
              '${response.error}');
      return;
    }

    if (response.productDetails.length != 1) {
      _log.info(
        'Products in response: '
        '${response.productDetails.map((e) => '${e.id}: ${e.title}, ').join()}',
      );
      _reportError(ref,
          message: 'There was an error when making the purchase: '
              'product ${AdRemovalPurchaseState.productId} does not exist?');
      return;
    }
    final productDetails = response.productDetails.single;

    _log.info('Making the purchase');
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    try {
      final success = await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      _log.info('buyNonConsumable() request was sent with success: $success');
      // The result of the purchase will be reported in the purchaseStream,
      // which is handled in [_listenToPurchaseUpdated].
    } catch (e) {
      _log.severe('Problem with calling inAppPurchaseInstance.buyNonConsumable(): '
          '$e');
    }
  }

  static void dispose() {
    subscription?.cancel();
  }

  /// Asks the underlying platform to list purchases that have been already
  /// made (for example, in a previous session of the game).
  static Future<void> restorePurchases(Ref ref) async {
    if (!await InAppPurchase.instance.isAvailable()) {
      _reportError(ref, message: 'InAppPurchase.instance not available');
      return;
    }

    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      _log.severe('Could not restore in-app purchases: $e');
    }
    _log.info('In-app purchases restored');
  }

  /// Subscribes to the [inAppPurchaseInstance.purchaseStream].
  static void subscribe(Ref ref) {
    subscription?.cancel();
    subscription = InAppPurchase.instance.purchaseStream.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(ref, purchaseDetailsList: purchaseDetailsList);
    }, onDone: () {
      subscription?.cancel();
    }, onError: (dynamic error) {
      _log.severe('Error occurred on the purchaseStream: $error');
    });
  }

  static Future<void> _listenToPurchaseUpdated(Ref ref, {required List<PurchaseDetails> purchaseDetailsList}) async {
    for (final purchaseDetails in purchaseDetailsList) {
      _log.info(() => 'New PurchaseDetails instance received: '
          'productID=${purchaseDetails.productID}, '
          'status=${purchaseDetails.status}, '
          'purchaseID=${purchaseDetails.purchaseID}, '
          'error=${purchaseDetails.error}, '
          'pendingCompletePurchase=${purchaseDetails.pendingCompletePurchase}');

      if (purchaseDetails.productID != AdRemovalPurchaseState.productId) {
        _log.severe("The handling of the product with id "
            "'${purchaseDetails.productID}' is not implemented.");
        ref.set(adRemoval, AdRemovalPurchaseState.notStarted());

        continue;
      }

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          ref.set(adRemoval, AdRemovalPurchaseState.pending());

          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            ref.set(adRemoval, AdRemovalPurchaseState.active());
            if (purchaseDetails.status == PurchaseStatus.purchased) {
              showSnackBar('Thank you for your support!');
            }
          } else {
            _log.severe('Purchase verification failed: $purchaseDetails');
            ref.set(adRemoval, AdRemovalPurchaseState.error(StateError('Purchase could not be verified')));
          }
          break;
        case PurchaseStatus.error:
          _log.severe('Error with purchase: ${purchaseDetails.error}');
          ref.set(adRemoval, AdRemovalPurchaseState.error(purchaseDetails.error!));

          break;
        case PurchaseStatus.canceled:
          ref.set(adRemoval, AdRemovalPurchaseState.notStarted());

          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        // Confirm purchase back to the store.
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }

  static void _reportError(Ref ref, {required String message}) {
    _log.severe(message);
    showSnackBar(message);
    ref.set(adRemoval, AdRemovalPurchaseState.error(message));
  }

  static Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    _log.info('Verifying purchase: ${purchaseDetails.verificationData}');
    // TODO: verify the purchase.
    // See the info in [purchaseDetails.verificationData] to learn more.
    // There's also a codelab that explains purchase verification
    // on the backend:
    // https://codelabs.developers.google.com/codelabs/flutter-in-app-purchases#9
    return true;
  }
}
