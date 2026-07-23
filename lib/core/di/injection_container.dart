// Inyección de Dependencias: DI Manual (no Service Locator, no DI Automatizada).
//
// Cada feature construye su propio grafo de dependencias por constructor en
// una clase `XxxDI` bajo `feactures/<feature>/di/` (ej. `PropietarioDI`):
// Datasource -> Repository -> UseCase -> Provider, sin ningún contenedor de
// resolución automática ni anotaciones/codegen. Eso es DI manual clásica.
//
// `InjectionContainer` es el único lugar donde ese resultado se registra en
// el árbol de widgets, usando `MultiProvider` del paquete `provider`. Que las
// pantallas lean una dependencia con `context.read<ToolProvider>()` NO es
// Service Locator en el sentido de este material (get_it/GetIt.instance):
// aquí la resolución está acotada al árbol de widgets vía InheritedWidget, no
// hay un registro global consultable con `getIt<T>()` fuera de un
// BuildContext. Tampoco hay `injectable` + `build_runner` generando el
// registro (DI Automatizada) — todo el cableado de arriba es código escrito
// a mano.
//
// Si en algún momento se migra a Service Locator real: agregar `get_it`,
// registrar cada dependencia en `GetIt.instance` (reemplazando las `XxxDI`),
// y sustituir `MultiProvider` por consultas directas al locator. Para DI
// Automatizada, el siguiente paso sería anotar esas mismas clases con
// `@injectable`/`@lazySingleton` y generar el registro con `injectable` +
// `build_runner` sobre ese mismo `GetIt.instance`.
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
import '../../feactures/payment_methods/presentation/providers/card_provider.dart';
import '../../feactures/mp_connect/presentation/providers/mp_connect_provider.dart';

import '../../feactures/auth/login/di/login_di.dart';
import '../../feactures/auth/register/di/register_di.dart';
import '../../feactures/propietario/di/propietario_di.dart';
import '../../feactures/solicitante/di/solicitante_di.dart';
import '../../feactures/checkout/di/checkout_di.dart';
import '../../feactures/admin/di/admin_di.dart';
import '../../feactures/review/di/review_di.dart';
import '../../feactures/payment_methods/di/payment_methods_di.dart';
import '../../feactures/mp_connect/di/mp_connect_di.dart';

class InjectionContainer {
  static List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<LoginProvider>(
      create: (_) => LoginProvider(loginUseCase: LoginDI.provideLoginUseCase()),
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
        extractTicketPrice: PropietarioDI.provideExtractTicketPrice(),
        uploadToolPhoto: PropietarioDI.provideUploadToolPhoto(),
        getSubscriptionPreference:
            PropietarioDI.provideGetSubscriptionPreference(),
        confirmSubscriptionPayment:
            PropietarioDI.provideConfirmSubscriptionPayment(),
        refreshIsPro: PropietarioDI.provideRefreshIsPro(),
        getInsurancePreference: PropietarioDI.provideGetInsurancePreference(),
        confirmInsurancePayment: PropietarioDI.provideConfirmInsurancePayment(),
        reconcileInsurance: PropietarioDI.provideReconcileInsurance(),
        cancelInsurance: PropietarioDI.provideCancelInsurance(),
      ),
    ),
    ChangeNotifierProvider<CatalogProvider>(
      create: (_) =>
          CatalogProvider(getCatalog: SolicitanteDI.provideGetCatalog()),
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
        confirmPayment: CheckoutDI.provideConfirmPayment(),
        reconcilePayment: CheckoutDI.provideReconcilePayment(),
        streamRental: CheckoutDI.provideStreamRental(),
      ),
    ),
    ChangeNotifierProvider<ChatProvider>(
      create: (_) => ChatProvider(CheckoutDI.repository),
    ),
    ChangeNotifierProvider<AdminProvider>(
      create: (_) => AdminProvider(
        getStats: AdminDI.provideGetAdminStats(),
        getRentals: AdminDI.provideGetAdminRentals(),
        resolveDispute: AdminDI.provideResolveDispute(),
      ),
    ),
    ChangeNotifierProvider<ReviewProvider>(
      create: (_) => ReviewProvider(
        submitReview: ReviewDI.provideSubmitReview(),
        getToolReviews: ReviewDI.provideGetToolReviews(),
        getUserReviews: ReviewDI.provideGetUserReviews(),
      ),
    ),
    ChangeNotifierProvider<CardProvider>(
      create: (_) => PaymentMethodsDI.provideCardProvider(),
    ),
    ChangeNotifierProvider<MpConnectProvider>(
      create: (_) => MpConnectDI.provideMpConnectProvider(),
    ),
  ];
}
