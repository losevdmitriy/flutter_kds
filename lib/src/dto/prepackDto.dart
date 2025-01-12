import 'ingredientDto.dart';

class PrepackDto {
  final int id;
  final String name;
  final List<IngredientDto> ingredients;

  PrepackDto({
    required this.id,
    required this.name,
    required this.ingredients,
  });
}
