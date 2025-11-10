import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/processing_screens/prepackDto.dart';
import 'package:flutter_iem_new/src/service/api_service.dart';
import '../../dto/processing_screens/PrepackRecipeItem.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  List<PrepackDto> _allSemiFinishedProducts = [];
  PrepackDto? _selectedProduct;
  List<PrepackRecipeItem> _recipeItems = [];

  final TextEditingController _typeAheadController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();


  @override
  void initState() {
    super.initState();
    _loadPrepacksFromApi();
  }

  Future<void> _loadPrepacksFromApi() async {
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
      });
    } catch (e) {
      debugPrint('Ошибка при загрузке заготовок: $e');
    }
  }

  Future<void> _loadPrepackRecipe(int prepackId) async {
    try {
      final api = ApiService();
      final recipe = await api.fetchPrepackRecipe(prepackId);
      setState(() {
        _recipeItems = recipe;
      });
    } catch (e) {
      debugPrint('Ошибка при загрузке рецепта: $e');
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ввод продуктов в БД",
          style: TextStyle(fontSize: 22),
        ),
        centerTitle: true,
        toolbarHeight: 60,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSearchableProductSelector(),
            const SizedBox(height: 24),
            if (_selectedProduct != null)
              Expanded(child: _buildIngredientsTable()),

          ],
        ),
      ),
    );
  }

  Widget _buildSearchableProductSelector() {
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
              _typeAheadController.text = selectedProduct.name;
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

  Widget _buildIngredientsTable() {
    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(color: Colors.grey, width: 2.0),
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: [
              _buildHeaderCell("Ингредиент"),
              _buildHeaderCell("Потери"),
              _buildHeaderCell("Выход"),
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
