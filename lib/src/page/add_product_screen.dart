import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/ProcessingAct.dart';
import 'package:searchfield/searchfield.dart';
import 'package:flutter_iem_new/src/dto/prepackDto.dart';
import 'package:flutter_iem_new/src/service/api_service.dart';
import '../dto/PrepackRecipeItem.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  List<PrepackDto> _allSemiFinishedProducts = [];
  SearchFieldListItem<PrepackDto>? _selectedSearchItem;
  PrepackDto? _selectedProduct;
  List<PrepackRecipeItem> _recipeItems = [];

  final TextEditingController _typeAheadController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _searchScrollController = ScrollController();

  bool _hasSelectedProduct = false;

  final Map<int, bool> _useManualLoss = {};
  final Map<int, double> _manualLossValues = {};
  final Map<int, TextEditingController> _rawControllers = {};
  final Map<int, TextEditingController> _manualLossControllers = {};

  @override
  void initState() {
    super.initState();
    _loadPrepacksFromApi();

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _hasSelectedProduct) {
        setState(() {
          _typeAheadController.clear();
          _selectedSearchItem = null;
          _hasSelectedProduct = false;
        });
      }
    });
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
        _recipeItems = recipe.cast<PrepackRecipeItem>();
      });
    } catch (e) {
      debugPrint('Ошибка при загрузке рецепта: $e');
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Ввод продуктов в БД", style: TextStyle(fontSize: 22)),
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

            // ---------- Кнопка "Сохранить" ----------
            if (_selectedProduct != null)
              if (_selectedProduct != null)
                ElevatedButton(
                  onPressed: _recipeItems.isNotEmpty ? _onSavePressed : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
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
        SearchField<PrepackDto>(
          controller: _typeAheadController,
          focusNode: _searchFocusNode,
          scrollController: ScrollController(),
          searchInputDecoration: SearchInputDecoration(
            hintText: 'Начните вводить...',
            maintainHintHeight: true,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          suggestions: _allSemiFinishedProducts
              .map((prod) => SearchFieldListItem<PrepackDto>(
                    prod.name,
                    item: prod,
                  ))
              .toList(),
          selectedValue: _selectedSearchItem,
          emptyWidget: const Center(
            child: Text(
              'Ничего не найдено',
              style: TextStyle(fontSize: 18),
            ),
          ),
          onSuggestionTap: (SearchFieldListItem<PrepackDto> item) async {
            final chosenPrepack = item.item!;
            setState(() {
              _selectedSearchItem = item;
              _selectedProduct = chosenPrepack;
              _typeAheadController.text = chosenPrepack.name;
              _useManualLoss.clear();
              _manualLossValues.clear();
              _rawControllers.clear();
              _manualLossControllers.clear();
              _hasSelectedProduct = true;
              _recipeItems = [];
            });
            await _loadPrepackRecipe(chosenPrepack.id);
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
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(3),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: [
              _buildHeaderCell("Ингредиент / Сырьё"),
              _buildHeaderCell("Потери"),
              _buildHeaderCell("Выход"),
            ],
          ),
          for (var item in _recipeItems)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildRawInputColumn(item),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildLossColumn(item),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildYieldColumn(item),
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

  Widget _buildRawInputColumn(PrepackRecipeItem item) {
    final keyId = item.sourceId;
    final controller = _rawControllers.putIfAbsent(
      keyId,
      () {
        final c = TextEditingController(text: item.initAmount.toString());
        c.addListener(() {
          setState(() {});
        });
        return c;
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'Кол-во (сырьё), г',
            labelStyle: TextStyle(fontSize: 16),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLossColumn(PrepackRecipeItem item) {
    final keyId = item.sourceId;
    final isManual = _useManualLoss[keyId] ?? false;
    final manualLossController = _manualLossControllers.putIfAbsent(
      keyId,
      () {
        final c = TextEditingController();
        c.addListener(() {
          setState(() {});
        });
        return c;
      },
    );

    Widget lossesWidget;
    if (!isManual) {
      lossesWidget = _buildAutoLossInfo(item);
    } else {
      lossesWidget = _buildManualLossInfo(item, manualLossController);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: lossesWidget),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: 1.3,
              child: Checkbox(
                value: isManual,
                onChanged: (bool? value) {
                  setState(() {
                    _useManualLoss[keyId] = value ?? false;
                  });
                },
              ),
            ),
            const Text(
              'Ручной\nввод',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAutoLossInfo(PrepackRecipeItem item) {
    final lossesAmount = item.lossesAmount;
    final lossesPercentage = item.lossesPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Авто-потери:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          "${lossesPercentage.toStringAsFixed(2)} %",
          style: const TextStyle(fontSize: 18),
        ),
        Text(
          "(${lossesAmount.toStringAsFixed(2)} г)",
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildManualLossInfo(
      PrepackRecipeItem item, TextEditingController controller) {
    final keyId = item.sourceId;
    final initText = _rawControllers[keyId]?.text;
    final rawValue = _parseDouble(initText) ?? 0.0;
    final lossVal = _parseDouble(controller.text) ?? 0.0;

    double manualLossPercent = 0;
    if (rawValue > 0) {
      manualLossPercent = (lossVal / rawValue) * 100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ручные потери:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'Потери, г',
            labelStyle: TextStyle(fontSize: 16),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "~ ${manualLossPercent.toStringAsFixed(2)} %",
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildYieldColumn(PrepackRecipeItem item) {
    final keyId = item.sourceId;
    final rawText = _rawControllers[keyId]?.text;
    final rawValue = _parseDouble(rawText) ?? 0.0;
    final isManual = _useManualLoss[keyId] ?? false;

    double lossKg;
    if (isManual) {
      final manualLoss =
          _parseDouble(_manualLossControllers[keyId]?.text) ?? 0.0;
      lossKg = manualLoss;
    } else {
      lossKg = item.lossesAmount;
    }

    final result = rawValue - lossKg;
    return Center(
      child: Text(
        "${result.toStringAsFixed(2)} г",
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  double? _parseDouble(String? text) {
    if (text == null || text.isEmpty) return null;
    return double.tryParse(text);
  }

  // ------------------- Ниже логика сохранения -------------------

  /// Собираем обновлённые данные из полей и формируем List<PrepackRecipeItem>
  List<PrepackRecipeItem> _getUpdatedRecipeItems() {
    return _recipeItems.map((item) {
      final keyId = item.sourceId;

      // initAmount из поля
      final rawString = _rawControllers[keyId]?.text ?? '${item.initAmount}';
      final parsedRaw = double.tryParse(rawString) ?? item.initAmount;

      // потери
      final isManual = _useManualLoss[keyId] ?? false;
      double newLossesAmount;
      double newLossesPercent;

      if (isManual) {
        final lossText = _manualLossControllers[keyId]?.text ?? '0';
        final manualLoss = double.tryParse(lossText) ?? 0.0;
        newLossesAmount = manualLoss;
        newLossesPercent =
            (parsedRaw > 0) ? (manualLoss / parsedRaw) * 100 : 0.0;
      } else {
        newLossesAmount = item.lossesAmount;
        newLossesPercent = item.lossesPercentage;
      }

      final newFinalAmount = parsedRaw - newLossesAmount;

      return PrepackRecipeItem(
        sourceId: item.sourceId,
        name: item.name,
        initAmount: parsedRaw,
        finalAmount: newFinalAmount,
        lossesAmount: newLossesAmount,
        lossesPercentage: newLossesPercent,
      );
    }).toList();
  }

  /// Например, считаем сумму выходов (finalAmount) или что-то другое
  double _calculateTotalYield() {
    double total = 0.0;
    final updatedItems = _getUpdatedRecipeItems();
    for (final item in updatedItems) {
      total += item.finalAmount;
    }
    return total;
  }

  Future<void> _onSavePressed() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Выберите полуфабрикат перед сохранением')),
      );
      return;
    }

    if (_recipeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Список ингредиентов не может быть пустым')),
      );
      return;
    }

    final updatedItems = _getUpdatedRecipeItems();
    final totalAmount = _calculateTotalYield();

    final actDto = ProcessingActDto(
      employeeId: 1, // например, фиксированное
      prepackId: _selectedProduct!.id,
      amount: totalAmount, // сколько всего получилось
      barcode: null,
      name: null,
      itemDataList: updatedItems,
    );

    try {
      final api = ApiService();
      await api.saveProcessing(actDto);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сохранено успешно!')),
      );
      // Или вернуться назад:
      // Navigator.pop(context);
    } catch (e) {
      debugPrint('Ошибка при сохранении: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    }
  }
}
