import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewModels/propietario_view_model.dart';
// Import corregido apuntando a la carpeta login dentro de auth
import '../../../auth/login/presentation/viewModels/auth_view_model.dart';

class PropietarioScreen extends StatefulWidget {
  const PropietarioScreen({super.key});

  @override
  State<PropietarioScreen> createState() => _PropietarioScreenState();
}

class _PropietarioScreenState extends State<PropietarioScreen> {
  @override
  void initState() {
    super.initState();
    // Cargamos las herramientas apenas se construye la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      context.read<PropietarioViewModel>().loadTools(token);
    });
  }

  // Método para mostrar el formulario de Crear Herramienta (Create del CRUD)
  void _mostrarFormularioCrear(BuildContext context, String token, PropietarioViewModel viewModel) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final catCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Herramienta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre (ej. Martillo)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: 'Categoría (ej. Manual)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                viewModel.createTool(token, nameCtrl.text, descCtrl.text, catCtrl.text);
                Navigator.pop(context); // Cierra el modal tras guardar
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PropietarioViewModel>();
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';

    return Scaffold(
      body: SafeArea(
        child: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    title: Text('Mi Inventario (Propietario)'),
                    floating: true,
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tool = viewModel.tools[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: Icon(
                              Icons.build,
                              color: tool.isAvailable ? Colors.green : Colors.red,
                            ),
                            title: Text(tool.name),
                            subtitle: Text('${tool.category} - ${tool.isAvailable ? "Disponible" : "Prestada"}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              // (Delete del CRUD)
                              onPressed: () => viewModel.deleteTool(token, tool.id),
                            ),
                            // (Update del CRUD: Cambia el estado al tocar la tarjeta)
                            onTap: () {
                              viewModel.toggleAvailability(token, tool.id, tool.isAvailable);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Estado de ${tool.name} actualizado')),
                              );
                            },
                          ),
                        );
                      },
                      childCount: viewModel.tools.length,
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioCrear(context, token, viewModel),
        tooltip: 'Agregar herramienta',
        child: const Icon(Icons.add),
      ),
    );
  }
}