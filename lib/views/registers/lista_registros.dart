import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';

class ListaRegistros extends StatelessWidget {
  final String tituloOrden;

  const ListaRegistros({super.key, this.tituloOrden = 'No definido'});

  @override
  Widget build(BuildContext context) {
    // lista vacía aqui irian los registros obtenidos de la base de datos
    final List registros = [];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con flecha atrás y título dinámico
              Container(
                color: AppColors.backgroundCard,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.textWhite,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tituloOrden,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar registro...',
                    hintStyle: const TextStyle(color: AppColors.textPaleGreen),
                    filled: true,
                    fillColor: AppColors.backgroundCard,
                    prefixIcon: const Icon(Icons.search, color: AppColors.textWhite),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: AppColors.textWhite),
                ),
              ),
              // Chips de filtrado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Alfabético'),
                      selected: false,
                      onSelected: (_) {},
                      backgroundColor: AppColors.buttonGreen2,
                      labelStyle: const TextStyle(color: AppColors.textWhite),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Fecha'),
                      selected: false,
                      onSelected: (_) {},
                      backgroundColor: AppColors.buttonGreen2,
                      labelStyle: const TextStyle(color: AppColors.textWhite),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Lista de registros o mensaje vacío
              Expanded(
                child: registros.isEmpty
                    ? Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.photo_library_outlined, color: AppColors.textPaleGreen, size: 64),
                          SizedBox(height: 24),
                          Text(
                            'No hay registros disponibles.',
                            style: TextStyle(
                              color: AppColors.textPaleGreen,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: registros.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    // Aquí iría el widget de registro cuando haya datos reales
                    return Container();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}