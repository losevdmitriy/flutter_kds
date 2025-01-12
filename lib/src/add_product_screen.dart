import 'package:flutter/material.dart';
import 'package:searchfield/searchfield.dart';

import 'package:flutter_iem_new/src/dto/ingredientDto.dart';
import 'package:flutter_iem_new/src/dto/prepackDto.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  /// Список доступных полуфабрикатов
  final List<PrepackDto> _allSemiFinishedProducts = [
    PrepackDto(
      id: 1,
      name: 'Полуфабрикат #1',
      ingredients: [
        IngredientDto(id: 1, name: 'Картофель', lossPercent: 10.0),
        IngredientDto(id: 2, name: 'Морковь', lossPercent: 5.0),
      ],
    ),
    PrepackDto(
      id: 2,
      name: 'Полуфабрикат #2',
      ingredients: [
        IngredientDto(id: 3, name: 'Курица', lossPercent: 12.0),
        IngredientDto(id: 4, name: 'Лук репчатый', lossPercent: 3.0),
      ],
    ),
    PrepackDto(
      id: 3,
      name: 'Полуфабрикат #3 (Пицца)',
      ingredients: [
        IngredientDto(id: 5, name: 'Тесто', lossPercent: 8.0),
        IngredientDto(id: 6, name: 'Сыр', lossPercent: 2.0),
      ],
    ),
    // ... и т.д.
  ];

  /// Текущее выбранное значение для SearchField
  SearchFieldListItem<PrepackDto>? _selectedSearchItem;

  /// Текущий выбранный полуфабрикат (из _selectedSearchItem.item)
  PrepackDto? _selectedProduct;

  /// Контроллер поискового поля
  final TextEditingController _typeAheadController = TextEditingController();

  /// Фокус для поля поиска
  final FocusNode _searchFocusNode = FocusNode();

  /// Скролл-контроллер для списка подсказок (новое в 1.2.2)
  final ScrollController _searchScrollController = ScrollController();

  /// Флаг, указывающий, что уже выбрали полуфабрикат
  bool _hasSelectedProduct = false;

  /// Остальные переменные (карты, контроллеры) для ингредиентов
  final Map<int, bool> _useManualLoss = {};
  final Map<int, double> _manualLossValues = {};
  final Map<int, TextEditingController> _rawControllers = {};
  final Map<int, TextEditingController> _manualLossControllers = {};

  @override
  void initState() {
    super.initState();

    // Если пользователь снова фокусируется на поле поиска — сбрасываем выбор
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
          ],
        ),
      ),
    );
  }

  /// Поле поиска + SearchField
  Widget _buildSearchableProductSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Выберите полуфабрикат:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        /// Виджет SearchField 1.2.2
        SearchField<PrepackDto>(
          controller: _typeAheadController,
          focusNode: _searchFocusNode,
          scrollController: _searchScrollController,
          // Вместо обычного hint используем SearchInputDecoration для наглядности
          searchInputDecoration: SearchInputDecoration(
            hintText: 'Начните вводить...',
            maintainHintHeight: true, // c 1.2.1 можно использовать это свойство
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          /// Полный список для автоподсказок
          suggestions: _allSemiFinishedProducts
              .map(
                (prod) => SearchFieldListItem<PrepackDto>(
                  prod.name,
                  item: prod,
                ),
              )
              .toList(),

          /// Явно указываем текущее выбранное значение
          selectedValue: _selectedSearchItem,

          /// Что отобразить, если ничего не найдено
          emptyWidget: const Center(
            child: Text(
              'Ничего не найдено',
              style: TextStyle(fontSize: 18),
            ),
          ),

          /// Callback при тапе по варианту
          onSuggestionTap: (SearchFieldListItem<PrepackDto> item) {
            setState(() {
              _selectedSearchItem = item;
              _selectedProduct = item.item; // item.item — это PrepackDto
              _typeAheadController.text = item.item!.name;

              // Сбрасываем все данные ингредиентов
              _useManualLoss.clear();
              _manualLossValues.clear();
              _rawControllers.clear();
              _manualLossControllers.clear();

              // Флаг, что продукт выбран
              _hasSelectedProduct = true;
            });
          },
        ),
      ],
    );
  }

  /// Таблица ингредиентов
  Widget _buildIngredientsTable() {
    final ingredients = _selectedProduct!.ingredients;

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
          for (var ingredient in ingredients)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildRawInputColumn(ingredient),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildLossColumn(ingredient),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildYieldColumn(ingredient),
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

  /// Колонка ввода сырья
  Widget _buildRawInputColumn(IngredientDto ingredient) {
    final controller = _rawControllers.putIfAbsent(
      ingredient.id,
      () {
        final c = TextEditingController();
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
          ingredient.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'Кол-во (сырьё), кг',
            labelStyle: TextStyle(fontSize: 16),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  /// Колонка для потерь
  Widget _buildLossColumn(IngredientDto ingredient) {
    final isManual = _useManualLoss[ingredient.id] ?? false;
    final manualLossController = _manualLossControllers.putIfAbsent(
      ingredient.id,
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
      lossesWidget = _buildAutoLossInfo(ingredient);
    } else {
      lossesWidget = _buildManualLossInfo(ingredient, manualLossController);
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
                    _useManualLoss[ingredient.id] = value ?? false;
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

  Widget _buildAutoLossInfo(IngredientDto ingredient) {
    final rawValue = _parseDouble(_rawControllers[ingredient.id]?.text) ?? 0.0;
    final autoLossPercent = ingredient.lossPercent;
    final autoLossKg = rawValue * (autoLossPercent / 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Авто-потери:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          "${autoLossPercent.toStringAsFixed(2)} %",
          style: const TextStyle(fontSize: 18),
        ),
        Text(
          "(${autoLossKg.toStringAsFixed(2)} кг)",
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildManualLossInfo(
    IngredientDto ingredient,
    TextEditingController controller,
  ) {
    final rawValue = _parseDouble(_rawControllers[ingredient.id]?.text) ?? 0.0;
    final lossKg = _parseDouble(controller.text) ?? 0.0;

    double manualLossPercent = 0;
    if (rawValue > 0) {
      manualLossPercent = (lossKg / rawValue) * 100;
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
            labelText: 'Потери, кг',
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

  /// Колонка "Выход": крупные цифры по центру
  Widget _buildYieldColumn(IngredientDto ingredient) {
    final rawValue = _parseDouble(_rawControllers[ingredient.id]?.text) ?? 0.0;
    final isManual = _useManualLoss[ingredient.id] ?? false;

    double lossKg;
    if (isManual) {
      final manualLoss =
          _parseDouble(_manualLossControllers[ingredient.id]?.text) ?? 0.0;
      lossKg = manualLoss;
    } else {
      final autoLossPercent = ingredient.lossPercent;
      lossKg = rawValue * (autoLossPercent / 100);
    }
    final result = rawValue - lossKg;

    return Center(
      child: Text(
        "${result.toStringAsFixed(2)} кг",
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  double? _parseDouble(String? text) {
    if (text == null || text.isEmpty) return null;
    return double.tryParse(text);
  }
}
