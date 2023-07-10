import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) {
        var appState = MyAppState();
        appState.readFile(); // Call readFile to populate Ilist
        return appState;
      },
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
            scaffoldBackgroundColor: const Color.fromRGBO(255, 255, 255, 0)),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];
  var Ilist = <String>[];
  var inventoryList = <Ingredient>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  Future<void> writeToFile(String name, DateTime date) async {
    final file = File("lib/Ingredients.txt");
    await file.writeAsString('$name,${date.toString()}\n',
        mode: FileMode.append);
    notifyListeners();
  }

  void readFile() async {
    try {
      var file = File("lib/ingredients.txt");
      if (await file.exists()) {
        var contents = await file.readAsLines();
        if (contents.isNotEmpty) {
          inventoryList = contents.map((ingredientName) {
            var ingredient = Ingredient();
            var ingredientData = ingredientName.split(",");
            ingredient.name = ingredientData[0];
            ingredient.date = DateTime.parse(ingredientData[1]);
            return ingredient;
          }).toList();
        }
      }
    } catch (e) {
      print("Error reading file: $e");
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = Placeholder();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Ingredients List'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatefulWidget {
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: IngredientInputBox(),
          ),
          SizedBox(height: 10),
          SizedBox(
            child: IngredientShowcase(appState),
            height: 600,
          ),

          // ElevatedButton.icon(
          //   onPressed: () {
          //     // appState.toggleFavorite();
          //   },
          //   icon: Icon(icon),
          //   label: Text('Like'),
          // ),
          // SizedBox(width: 10),
          // ElevatedButton(
          //   onPressed: () {
          //     appState.getNext();
          //   },
          //   child: Text('Next'),
          // ),
        ],
      ),
    );
  }

  Widget IngredientShowcase(MyAppState appState) {
    appState.readFile();
    if (appState.inventoryList.isEmpty) {
      return Center(
        child: Text(
          "You have no ingredients",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else {
      setState(() {});
      DateTime today = DateTime.now();
      List<Widget> ingredientListTiles = [];

      for (var ingredient in appState.inventoryList) {
        DateTime expirationDate = ingredient.date;
        Duration difference = expirationDate.difference(today);
        int expireDays = difference.inDays;
        bool isExpired = expirationDate.isBefore(DateTime.now());
        String expirationText =
            isExpired ? 'Expired' : 'Expires on ${expirationDate.toString()}';

        Widget ingredientTile = Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            visualDensity: VisualDensity(horizontal: .5),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: getColor(expireDays),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            textColor: Color.fromRGBO(255, 255, 255, 1),
            leading: Icon(Icons.favorite),
            title: Text(ingredient.name),
            subtitle: Text(expirationText),
          ),
        );

        ingredientListTiles.add(ingredientTile);
      }

      return Container(
        height: 600,
        child: SingleChildScrollView(
          child: Column(
            children: ingredientListTiles,
          ),
        ),
      );
    }
  }

  Color getColor(int number) {
    if (number < 2) {
      return Colors.red;
    } else if (number < 7) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }
}

class IngredientInputBox extends StatefulWidget {
  const IngredientInputBox({
    super.key,
  });

  @override
  State<IngredientInputBox> createState() => _IngredientInputBoxState();
}

class _IngredientInputBoxState extends State<IngredientInputBox> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    DateTime? selectedDate;
    return Container(
      color: Colors.black,
      width: 260,
      child: TextField(
        style: TextStyle(
          color: Color.fromRGBO(255, 255, 255, 1),
        ),
        autocorrect: true,
        decoration: InputDecoration(
            border: OutlineInputBorder(), labelText: "Enter Ingredients"),
        onSubmitted: (String ingredientName) async {
          await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('When does the ${ingredientName} expire?'),
                  content: ElevatedButton(
                    child: Text('Select expiration date'),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                        DateTime expirationDate = pickedDate;
                        appState.writeToFile(ingredientName, expirationDate);
                      }

                      Navigator.of(context).pop();
                    },
                    // onEditingComplete: Navigator.of(context).pop,
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        appState.writeToFile(ingredientName, DateTime(2200));
                      },
                      child: const Text('No expiration'),
                    ),
                  ],
                );
              });
        },
      ),
    );
  }
} //Ingredientinput box

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    appState.readFile();
    if (appState.Ilist.isEmpty) {
      return Center(
        child: Text(
          "You have no ingredients",
          style: TextStyle(
            color: Color.fromRGBO(255, 255, 255, 1),
          ),
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'You have '
            '${appState.Ilist.length} ingredients:',
            style: TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
          ),
        ),
        for (var ingredient in appState.Ilist)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              visualDensity: VisualDensity(horizontal: .5),
              shape: RoundedRectangleBorder(
                side:
                    BorderSide(color: Color.fromRGBO(0, 255, 0, .5), width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              textColor: Color.fromRGBO(255, 255, 255, 1),
              leading: Icon(Icons.favorite),
              title: Text(ingredient),
            ),
          ),
      ],
    );
  }
}

class Ingredient {
  String _name = "";

  String get name => _name;

  set name(String value) {
    _name = value;
  }

  DateTime _date = DateTime.now();

  DateTime get date => _date;

  set date(DateTime value) {
    _date = value;
  }

  int _quantity = 0;

  int get quantity => _quantity;

  set quantity(int value) {
    _quantity = value;
  }
}
