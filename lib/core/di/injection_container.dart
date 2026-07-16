import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../feactures/auth/login/presentation/providers/login_provider.dart';
import '../../feactures/auth/register/presentation/providers/register_provider.dart';
import '../../feactures/propietario/presentation/providers/tool_provider.dart';
import '../../feactures/solicitante/presentation/providers/catalog_provider.dart';
import '../../feactures/checkout/presentation/providers/rental_provider.dart';
import '../../feactures/checkout/presentation/providers/chat_provider.dart';
import '../../feactures/admin/presentation/providers/admin_provider.dart';
import '../../feactures/review/presentation/providers/review_provider.dart';

import '../../feactures/auth/login/data/di/login_di.dart';
import '../../feactures/auth/register/data/di/register_di.dart';
import '../../feactures/propietario/data/di/propietario_di.dart';
import '../../feactures/solicitante/data/di/solicitante_di.dart';
import '../../feactures/checkout/data/di/checkout_di.dart';
import '../../feactures/review/data/di/review_di.dart';

/// Contenedor de inyección de dependencias global.
///
/// Agrega los `ChangeNotifierProvider` de cada feature (construidos con las
/// factories `*DI` que ya existían en cada feature) en una sola lista lista
/// para pasarle a `MultiProvider`. No reemplaza el DI por-feature: solo
/// centraliza el punto donde se ensamblan para la raíz de la app.
class InjectionContainer {
  static List<SingleChildWidget> get providers => [
        ChangeNotifierProvider<LoginProvider>(
          create: (_) => LoginProvider(
            loginUseCase: LoginDI.provideLoginUseCase(),
          ),
        ),
        ChangeNotifierProvider<RegisterProvider>(
          create: (_) => RegisterProvider(
            registerUseCase: RegisterDI.provideRegisterUseCase(),
            verifyKycUseCase: RegisterDI.provideVerifyKycUseCase(),
          ),
        ),
        ChangeNotifierProvider<ToolProvider>(
          create: (_) => ToolProvider(
            getTools: PropietarioDI.provideGetTools(),
            createTool: PropietarioDI.provideCreateTool(),
            updateTool: PropietarioDI.provideUpdateTool(),
            deleteTool: PropietarioDI.provideDeleteTool(),
            getPricingSuggestion: PropietarioDI.provideGetPricingSuggestion(),
            predictCondition: PropietarioDI.providePredictCondition(),
            autoValuate: PropietarioDI.provideAutoValuate(),
            uploadToolPhoto: PropietarioDI.provideUploadToolPhoto(),
            getSubscriptionPreference:
                PropietarioDI.provideGetSubscriptionPreference(),
            confirmSubscriptionPayment:
                PropietarioDI.provideConfirmSubscriptionPayment(),
            refreshIsPro: PropietarioDI.provideRefreshIsPro(),
          ),
        ),
        ChangeNotifierProvider<CatalogProvider>(
          create: (_) => CatalogProvider(
            getCatalog: SolicitanteDI.provideGetCatalog(),
          ),
        ),
        ChangeNotifierProvider<RentalProvider>(
          create: (_) => RentalProvider(
            createRental: CheckoutDI.provideCreateRental(),
            getRentals: CheckoutDI.provideGetRentals(),
            getRental: CheckoutDI.provideGetRental(),
            confirmDelivery: CheckoutDI.provideConfirmDelivery(),
            confirmReturn: CheckoutDI.provideConfirmReturn(),
            disputeRental: CheckoutDI.provideDisputeRental(),
            cancelRental: CheckoutDI.provideCancelRental(),
            verifyContract: CheckoutDI.provideVerifyContract(),
            getPreference: CheckoutDI.provideGetPreference(),
            streamRental: CheckoutDI.provideStreamRental(),
          ),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(CheckoutDI.repository),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (_) => AdminProvider(),
        ),
        ChangeNotifierProvider<ReviewProvider>(
          create: (_) => ReviewProvider(
            submitReview: ReviewDI.provideSubmitReview(),
            getToolReviews: ReviewDI.provideGetToolReviews(),
            getUserReviews: ReviewDI.provideGetUserReviews(),
          ),
        ),
      ];
}
