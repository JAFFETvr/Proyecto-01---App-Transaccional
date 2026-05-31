import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../propietario/presentation/viewModels/propietario_view_model.dart';
import '../../../auth/presentation/viewModels/auth_view_model.dart';

class SolicitanteScreen extends StatefulWidget {
  const SolicitanteScreen({super.key});

  @override
  State<SolicitanteScreen> createState() => _SolicitanteScreenState();
}

class _SolicitanteScreenState extends State<SolicitanteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      // Reutilizamos el ViewModel del propietario para la lectura pública
      context.read<PropietarioViewModel>().loadTools(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PropietarioViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de Herramientas')),
      body: SafeArea(
        child: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: viewModel.tools.length,
                  itemBuilder: (context, index) {
                    final tool = viewModel.tools[index];
                    return Card(
                      elevation: 3,
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Container(color: Theme.of(context).colorScheme.surfaceVariant), // Placeholder imagen
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Theme.of(context).colorScheme.surface,
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tool.name, style: Theme.of(context).textTheme.titleMedium),
                                  Text(
                                    tool.isAvailable ? 'Disponible' : 'Prestada',
                                    style: TextStyle(color: tool.isAvailable ? Colors.green : Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}