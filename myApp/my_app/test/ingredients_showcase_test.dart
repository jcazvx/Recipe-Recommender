import 'package:test/test.dart';
import 'package:my_app/main.dart';

void main(){
    test('Test ingredients', () {
        final ingredient = Ingredient();
        ingredient.name = 'test';
        expect(ingredient.name, 'test');
    });
}