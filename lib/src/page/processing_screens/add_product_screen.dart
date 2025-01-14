import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/processing_screens/ProcessingAct.dart';
import 'package:searchfield/searchfield.dart';
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
  SearchFieldListItem<PrepackDto>? _selectedSearchItem;
  PrepackDto? _selectedProduct;
  List<PrepackRecipeItem> _recipeItems = [];

  final TextEditingController _typeAheadController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _searchScrollController = ScrollController();

  bool _hasSelectedProduct = false;

  // Раньше было _useManualLoss / _manualLossControllers, переименуем:
  final Map<int, bool> _useManualYield = {};
  final Map<int, TextEditingController> _manualYieldControllers = {};

  // Исходное количество, как и прежде
  final Map<int, TextEditingController> _rawControllers = {};

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
        _recipeItems = recipe;
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
              // Сбрасываем вручную
              _useManualYield.clear();
              _manualYieldControllers.clear();
              _rawControllers.clear();
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

  /// Колонка "Ингредиент / Сырьё" + ввод сырья
  Widget _buildRawInputColumn(PrepackRecipeItem item) {
    final keyId = item.sourceId;

    // Контроллер для "исходного кол-ва" (raw)
    final controller = _rawControllers.putIfAbsent(
      keyId,
      () {
        // Ставим текущее значение из item.initAmount
        final c = TextEditingController(text: item.initAmount.toString());
        c.addListener(() {
          setState(() {}); // Перерисовываем, чтобы пересчитать потери
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

  /// Колонка "Потери"
  ///
  /// Теперь она всегда выводит разницу = initAmount - finalAmount.
  /// Если "ручной ввод" не включён, считаем finalAmount = (init - потери из item).
  /// Если включён, finalAmount = то, что пользователь вписал в текстовое поле "Выход".
  Widget _buildLossColumn(PrepackRecipeItem item) {
    final keyId = item.sourceId;
    final bool isManual = _useManualYield[keyId] ?? false;

    final rawValue = _parseDouble(_rawControllers[keyId]?.text) ?? 0.0;

    double finalValue;
    if (isManual) {
      // Ручной ввод выхода
      final manualController = _manualYieldControllers[keyId];
      final manualYield = _parseDouble(manualController?.text) ?? 0.0;
      finalValue = manualYield;
    } else {
      // Авто-выход = raw - item.lossesAmount
      // (как было в исходной логике)
      finalValue = rawValue - item.lossesAmount;
      if (finalValue < 0) finalValue = 0; // на всякий случай
    }

    // Потери = rawValue - finalValue
    final losses = rawValue - finalValue;
    final lossesPercent = (rawValue > 0) ? (losses / rawValue) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Потери: ${losses.toStringAsFixed(2)} г",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          "(${lossesPercent.toStringAsFixed(2)}%)",
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  /// Колонка "Выход"
  ///
  /// - Если чекбокс "Ручной ввод" не установлен, показываем авто-выход = (init - item.lossesAmount)
  /// - Если чекбокс установлен, показываем текстовое поле для ручного ввода выхода.
  /// - Рядом с TextField размещаем сам чекбокс.
  Widget _buildYieldColumn(PrepackRecipeItem item) {
    final keyId = item.sourceId;
    final bool isManual = _useManualYield[keyId] ?? false;

    // Инициализируем контроллер для ручного выхода
    final controller = _manualYieldControllers.putIfAbsent(
      keyId,
      () {
        // Пусть по умолчанию будет (init - lossesAmount)
        final autoYield = item.initAmount - item.lossesAmount;
        final c = TextEditingController(text: autoYield.toStringAsFixed(2));
        c.addListener(() {
          setState(() {}); // чтобы пересчитать потери
        });
        return c;
      },
    );

    final rawValue = _parseDouble(_rawControllers[keyId]?.text) ?? 0.0;
    // Если ручной ввод НЕ установлен, авто-выход:
    double finalValue = rawValue - item.lossesAmount;
    if (finalValue < 0) finalValue = 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: isManual
              ? TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Выход (г)',
                    labelStyle: TextStyle(fontSize: 16),
                    border: OutlineInputBorder(),
                  ),
                )
              : Center(
                  child: Text(
                    "${finalValue.toStringAsFixed(2)} г",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            Transform.scale(
              scale: 1.3,
              child: Checkbox(
                value: isManual,
                onChanged: (val) {
                  setState(() {
                    _useManualYield[keyId] = val ?? false;
                  });
                },
              ),
            ),
            const Text('Ручной\nввод',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
          ],
        ),
      ],
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

      // Считываем initAmount (сырьё)
      final rawString = _rawControllers[keyId]?.text ?? '${item.initAmount}';
      final parsedRaw = double.tryParse(rawString) ?? item.initAmount;

      final bool isManual = _useManualYield[keyId] ?? false;

      double finalAmount; // Выход
      double newLossesAmount; // Поту
      double newLossesPercent;

      if (isManual) {
        // Ручной ввод выхода
        final yieldString = _manualYieldControllers[keyId]?.text ?? '';
        final parsedYield = double.tryParse(yieldString) ?? 0.0;
        finalAmount = parsedYield;
        // Потери = raw - выход
        newLossesAmount = parsedRaw - finalAmount;
        if (newLossesAmount < 0) newLossesAmount = 0;
        newLossesPercent =
            (parsedRaw > 0) ? (newLossesAmount / parsedRaw) * 100 : 0.0;
      } else {
        // Авто-выход (raw - item.lossesAmount)
        // Берём lossesAmount из item
        newLossesAmount = item.lossesAmount;
        finalAmount = parsedRaw - newLossesAmount;
        if (finalAmount < 0) finalAmount = 0;
        // old logic
        newLossesPercent =
            (parsedRaw > 0) ? (newLossesAmount / parsedRaw) * 100 : 0.0;
      }

      item.initAmount = parsedRaw;
      item.finalAmount = finalAmount;
      item.lossesAmount = newLossesAmount;
      item.lossesPercentage = newLossesPercent;

      return item;
    }).toList();
  }

  /// Например, считаем сумму выходов (finalAmount)
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
      // Например, вернуться назад:
      // Navigator.pop(context);
    } catch (e) {
      debugPrint('Ошибка при сохранении: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    }
  }
}
