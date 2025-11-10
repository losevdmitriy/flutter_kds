import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/processing_screens/prepackDto.dart';
import 'package:flutter_iem_new/src/service/api_service.dart';
import '../../dto/processing_screens/PrepackRecipeItem.dart';

class TTKDisplayScreen extends StatefulWidget {
  const TTKDisplayScreen({Key? key}) : super(key: key);

  @override
  _TTKDisplayScreenState createState() => _TTKDisplayScreenState();
}

class _TTKDisplayScreenState extends State<TTKDisplayScreen> {
  List<PrepackDto> _allSemiFinishedProducts = [];
  PrepackDto? _selectedProduct;
  List<PrepackRecipeItem> _recipeItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrepacksFromApi();
  }

  Future<void> _loadPrepacksFromApi() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final api = ApiService();
      final sources = await api.fetchPrepacks();
      final prepackList = sources.map((src) {
        return PrepackDto(
          id: src.id ?? 0,
          name: src.name,
        );
      }).toList();

      setState(() {
        _allSemiFinishedProducts = prepackList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Ошибка при загрузке заготовок: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<void> _loadPrepackRecipe(int prepackId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final api = ApiService();
      final recipe = await api.fetchPrepackRecipe(prepackId);
      setState(() {
        _recipeItems = recipe;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Ошибка при загрузке рецепта: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки рецепта: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Технико-технологические карты",
          style: TextStyle(fontSize: 22),
        ),
        centerTitle: true,
        toolbarHeight: 60,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrepacksFromApi,
            tooltip: 'Обновить список',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildProductSelector(),
                  const SizedBox(height: 24),
                  if (_selectedProduct != null)
                    Expanded(child: _buildRecipeDisplay()),
                  if (_selectedProduct == null)
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Выберите полуфабрикат для просмотра ТТК",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProductSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Выберите полуфабрикат:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Autocomplete<PrepackDto>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<PrepackDto>.empty();
            }
            return _allSemiFinishedProducts.where((PrepackDto product) =>
                product.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          displayStringForOption: (PrepackDto option) => option.name,
          onSelected: (PrepackDto selectedProduct) async {
            setState(() {
              _selectedProduct = selectedProduct;
              _recipeItems = [];
            });
            await _loadPrepackRecipe(selectedProduct.id);
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Начните вводить...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecipeDisplay() {
    if (_recipeItems.isEmpty) {
      return const Center(
        child: Text(
          "Рецепт не найден",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(color: Colors.grey, width: 2.0),
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: [
              _buildHeaderCell("Ингредиент"),
              _buildHeaderCell("Сырьё (г)"),
              _buildHeaderCell("Потери (г)"),
              _buildHeaderCell("Выход (г)"),
            ],
          ),
          for (var item in _recipeItems)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "${item.initAmount.toStringAsFixed(2)} г",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "${item.lossesAmount.toStringAsFixed(2)} г",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "${item.finalAmount.toStringAsFixed(2)} г",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }
}
