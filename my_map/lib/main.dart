import 'dart:ffi';
import 'dart:io';
import  'dart:math';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:translator/translator.dart';
import 'package:flutter/widgets.dart';
import 'package:my_map/database.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
  }
  // Change the default factory. On iOS/Android, if not using `sqlite_flutter_lib` you can forget
  // this step, it will use the sqlite version available on the system.
  databaseFactory = databaseFactoryFfi;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var currentString;
  var translation;
  final DictionaryDatabase _dictionaryDatabase = DictionaryDatabase.instance;

  final translator = GoogleTranslator();
  Future<void> getNext(inputString, foreignString) async {
    if (inputString != "") {
      currentString = inputString;
      translation = await translator.translate(
        currentString.toString(),
        from: 'en',
        to: 'de',
      );
    } else if (foreignString != "") {
      currentString = await translator.translate(
        foreignString.toString(),
        from: 'de',
        to: 'en',
      );
      translation = foreignString;
    } else {
      currentString = WordPair.random().first;
      translation = await translator.translate(
        currentString.toString(),
        from: 'en',
        to: 'de',
      );
    }
    notifyListeners();
  }

}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePage();
}

class _MyHomePage extends State<MyHomePage> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: false,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_card),
                  label: Text('MyCars'),
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
              color: Theme.of(context).colorScheme.primaryContainer,
              //NO OTEHR PAGES WILL OR SHOULD BE ADDED BECAUSE THIS PROJECT WILL BE A FINISHED PRODUCT WITH ONLY THESE 2 FEATURES
              child: selectedIndex == 0 ? TranslatorPage() : CardListPage(),
            ),
          ),
        ],
      ),
    );
  }

}

class TranslatorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    var appState = context.watch<MyAppState>();
    final TextEditingController _inputStringController =
    TextEditingController(text: appState.currentString?.toString() ?? '');

    final TextEditingController _inputStringTranslationController =
    TextEditingController(text: appState.translation?.toString() ?? '');

    String inputString =
        appState.currentString != null ? appState.currentString.toString() : "";
    String inputStringTranslation =
        appState.translation != null ? appState.translation.toString() : "";
    var inputField = WrapperWidget(
      word: inputString,
      sentence: "original word",
      controller: _inputStringController,
    );
    var outputField = WrapperWidget(
      word: inputStringTranslation,
      sentence: "translation",
      controller: _inputStringTranslationController,
    );
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          inputField,
          outputField,
          FloatingActionButton.large(
            backgroundColor: Colors.purple,
            child: Text("Translate", style: TextStyle(color: Colors.green)),
            onPressed: () {
              inputString = _inputStringController.text;
              inputStringTranslation = _inputStringTranslationController.text;
              appState.getNext(inputString, inputStringTranslation);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton.large(
              backgroundColor: Colors.purple,
              child: Text("<3", style: TextStyle(color: Colors.green)),
              onPressed: () {
                inputString = _inputStringController.text;
                inputStringTranslation = _inputStringTranslationController.text;
                if (inputString == "" || inputStringTranslation == "") {
                  //print('noInputString');
                  inputString = _inputStringController.text;
                  inputStringTranslation = _inputStringTranslationController.text;
                } else {
                  appState._dictionaryDatabase.insertWord({
                    'originalWord': inputString,
                    'translatedWord': inputStringTranslation,
                    'isKnown':'false',
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CardListPage extends StatefulWidget {
  const CardListPage({Key? key}) : super(key: key);

  @override
  _CardListPage createState() => _CardListPage();
}

class _CardListPage extends State<CardListPage> {

  @override

  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // TODO: implement build
    var receivedDictionary = appState._dictionaryDatabase.getDictionary();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: receivedDictionary,
        builder: (context, snapshot) {
          List<Widget> children;
          if (snapshot.hasData) {
            Iterable<Map<String,Object?>> selectedWords=snapshot.data!.take(10);
            children =[
              Expanded(
                  child: ListView(
                children: selectedWords.map((entry){
                  final originalWord = entry['originalWord'].toString();
                  final translatedWord= entry['translatedWord'].toString();
                  return Container(
                    decoration: BoxDecoration(
                      border:Border.all(color:Colors.blueGrey)

                    ),
                      child:ListTile(
                        title:Text(originalWord),
                        textColor: entry['isKnown']=='true'?Colors.lightGreen:Colors.pink,
                        subtitle: Text(translatedWord),
                        tileColor: Colors.white60,
                        trailing:IconButton(
                            onPressed: (){
                              //print('deleting:'+entry['id']!.toString());
                              appState._dictionaryDatabase.removeWord(entry['id'] as int);//??? I'm not sure why either but stackoverflow said
                              setState(() {
                                receivedDictionary =
                                    appState._dictionaryDatabase
                                        .getDictionary();
                              });
                            },
                            icon: Icon(Icons.ac_unit_sharp)) ,
                    )
                  );
                }).toList(),
              )
              ),
              TextButton(
                  onPressed: (){
                    //print(getUnknownWords(selectedWords.toList()));
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context)=>CardPage(
                          selectedWords:getUnknownWords(selectedWords.toList()),
                          dictionaryDatabase: appState._dictionaryDatabase,
                        )));
                  },
                  child: Text('<Start!>')),
            ];
          } else {
            return Column(children: [Text('Error')]);
          }
          //for (var i =0;i<snapshot.data!.length;i++) {
          //  print(snapshot.data?[i]);
          //}
          return Column(children: children);
        },
      ),
    );
  }

  List<Map<String,Object?>> getUnknownWords(List<Map<String,Object?>> wordMap) {
    //print(wordMap);
    return [
      for (final map in wordMap)
        if (map['isKnown'] =='false')
          {
            'id': map['id'],
            'originalWord': map['originalWord'],
            'translatedWord': map['translatedWord'],
            'isKnown': 0,
          }
    ];
  }

}
class CardPage extends StatefulWidget {
  final List<Map<String, Object?>> selectedWords;
  final DictionaryDatabase dictionaryDatabase ;

  const CardPage({Key? key,
    required this.selectedWords,
    required this.dictionaryDatabase,
  }) : super(key: key);

  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  static bool hiddenElement=true;
  late Widget currElement;
  static int currentIndex=0;


  @override
  void initState() {
    super.initState();
    currElement = Text('');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedWords.length < 2) {
      return Scaffold(
        body: Column(children:[
          TextButton(onPressed: (){
            Navigator.pop(context);
          }, child: Text('back')),
          Center(child: Text('Add more words ;3'))],
        ));
    }
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Back'),
                )
              ],
            ),
            Column(children:[Center(
              child: Row(
                children: [

                  Column( children:[
                    TextButton(
                        onPressed: (){
                          //widget.selectedWords.remove(value);
                          //DictionaryDatabase
                          widget.dictionaryDatabase.markAsKnown(widget.selectedWords[currentIndex]);
                          widget.selectedWords.remove(widget.selectedWords[currentIndex]);
                          setState(() {
                            currentIndex=(currentIndex)%widget.selectedWords.length;
                            hiddenElement=true;
                            currElement = Text('');
                          });

                        },
                        child: Text('<IKnowIt!>')),
                    Card(
                    child: SizedBox(
                      width: 200,
                      height: 100,
                      child: Center(
                        child: Text(widget.selectedWords[currentIndex]['originalWord'].toString()),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (hiddenElement){
                         currElement=Text(widget.selectedWords[currentIndex]['translatedWord'].toString());
                        }else{
                          currElement = Text('');
                        }
                      });
                      hiddenElement=!hiddenElement;
                    },
                    child: SizedBox(
                      width: 200,
                      height: 100,
                      child: Center(child: currElement),
                    ),
                  ),
                ])
                ],
              ),
            )]),
            Column(children:[Center(child:
            TextButton(
                onPressed: (){
                  //widget.selectedWords.remove(value);
                  setState(() {
                    currentIndex=(currentIndex+1)%widget.selectedWords.length;
                    hiddenElement=true;
                    currElement = Text('');
                  });
                },
                child: Text('>')),

            ),
            ]),
          ],
        ),
      ),
    );
  }
}

class WrapperWidget extends StatelessWidget {
  final String word;
  final String sentence;

  final TextEditingController controller;

  const WrapperWidget({
    Key? key,
    required this.word,
    required this.sentence,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SizedBox(
      width: 400,
      child: Card(
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("$sentence:"),
            ),
            SizedBox(
              width: 250,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: word,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
