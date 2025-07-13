import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import  'dart:math';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//import 'package:sqflite/sqflite.dart';
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:flutter/widgets.dart';
import 'package:my_map/database.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Change the default factory. On iOS/Android, if not using `sqlite_flutter_lib` you can forget
  // this step, it will use the sqlite version available on the system.

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

  late String originLanguage;
  late String foreignLanguage;


  final translator = GoogleTranslator();
  Future<void> getNext(inputString, foreignString) async {
      final prefs = await SharedPreferences.getInstance();
      originLanguage= prefs.getString('originLanguage') ?? 'en';
      foreignLanguage= prefs.getString('foreignLanguage') ?? 'de';
      print(originLanguage);
    if (inputString != "") {
      currentString = inputString;
      translation = await translator.translate(
        currentString.toString(),
        from: originLanguage,
        to: foreignLanguage,
      );
    } else if (foreignString != "") {
      currentString = await translator.translate(
        foreignString.toString(),
        from: foreignLanguage,
        to: originLanguage,
      );
      translation = foreignString;
    } else {
      currentString = WordPair.random().first;
      translation = await translator.translate(
        currentString.toString(),
        from: originLanguage,
        to: foreignLanguage,
      );
    }
    notifyListeners();
  }

}
Future<String> loadOrigin() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('originLanguage') ?? 'en';
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
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
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
              child:getPage(selectedIndex)

            ),
          ),
        ],
      ),
    );
  }
  Widget getPage(int index){
    switch (selectedIndex){
      case 0:
        return TranslatorPage();
      case 1:
        return CardListPage();
      case 2:
        return SettingsWidget();
      default:
        return CardListPage();

    }
    
    
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
    TextEditingController(
        text: appState.translation?.toString() ?? '');


    String inputString =
        appState.currentString != null ? appState.currentString.toString() : "";
    String inputStringTranslation =
        appState.translation != null ? appState.translation.toString() : "";
    var inputField =SizedBox(
      width: 250,
        child:TextField(
      //word: inputString,
      maxLength:100,

      controller: _inputStringController,
      decoration: InputDecoration(
        labelText: 'original word',


      ),
    ));
    var outputField = SizedBox(
      width: 250,
        child:TextField(
      //word: inputString,
      maxLength:100,
      controller: _inputStringTranslationController,
          decoration: InputDecoration(
            labelText: 'translated word',


          ),
        ));
    return Center(

      child: Column(
        mainAxisAlignment:MainAxisAlignment.center ,
        children: [
          Row(
                children: [
            Column(children: [
                  inputField,
               outputField,
            ]),
            TextButton(onPressed: (){
              _inputStringTranslationController.text='';
              _inputStringController.text='';
              }, child: Text('X'))
          ]),
          FloatingActionButton.large(
            backgroundColor: Colors.purple,
            child: Text("Translate", style: TextStyle(color: Colors.green)),
            onPressed: () {
              inputString = _inputStringController.text;
              inputStringTranslation = _inputStringTranslationController.text;
              appState.getNext(inputString, inputStringTranslation);
            },
          ),
          Container(
            child: FloatingActionButton.large(
              backgroundColor: Colors.purple,
              child: Text("<3", style: TextStyle(color: Colors.green)),
              onPressed: () {
                inputString = _inputStringController.text;
                inputStringTranslation = _inputStringTranslationController.text;
                _inputStringTranslationController.text='';
                _inputStringController.text='';
                if (inputString == "" || inputStringTranslation == "") {
                  //print('noInputString');
                  inputString = _inputStringController.text;
                  inputStringTranslation = _inputStringTranslationController.text;
                } else {
                  appState._dictionaryDatabase.insertWord({
                    'originalWord': inputString,
                    'translatedWord': inputStringTranslation,
                    'isKnown':0,
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
    return Scaffold(
      body:Padding(
      padding: const EdgeInsets.all(12.0),
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: receivedDictionary,
        builder: (context, snapshot) {
          List<Widget> children;
          if (snapshot.hasData) {
            //print(snapshot.data);
            Iterable<Map<String,Object?>> selectedWords=snapshot.data!;
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
                        textColor: entry['isKnown']==0?Colors.pink:Colors.lightGreen,
                        subtitle: Text(translatedWord),
                        tileColor: Colors.white60,
                        trailing:IconButton(
                            onPressed: (){
                              //print('deleting:'+entry['id']!.toString());
                              appState._dictionaryDatabase.removeWord(entry['id'] as int);
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
                    final result =Navigator.push(context,
                        MaterialPageRoute(builder: (context)=>CardPage(
                          selectedWords:getUnknownWords(selectedWords.toList()).take(10).toList(),
                          dictionaryDatabase: appState._dictionaryDatabase,
                        )));
                    if (result==true){
                      setState(() {
                        receivedDictionary = appState._dictionaryDatabase.getDictionary();
                      });

                    }

                  },
                  child: Text('<Start!>')),
            ];
          } else {
            return Column(children: [Text('loading')]);
          }
          //for (var i =0;i<snapshot.data!.length;i++) {
          //  print(snapshot.data?[i]);
          //}
          return Column(children: children);
        },
      ),
    ));
  }

  List<Map<String,Object?>> getUnknownWords(List<Map<String,Object?>> wordMap) {
    //print(wordMap);
    return [
      for (final map in wordMap)
        if (map['isKnown'] ==0 || map['isKnown'] ==false)
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
    currElement = Text(widget.selectedWords[currentIndex]['originalWord'].toString());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedWords.length < 2) {
      return Scaffold(
        body: Column(children:[
          TextButton(onPressed: (){
            Navigator.pop(context,true);
          }, child: Text('back')),
          Center(child: Text('Add more words ;3'))],
        ));
    }
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context,true);
                  },
                  child: Text('Back'),
                )
              ],
            ),
                 Expanded(
                     child: Column(

                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:[
                    TextButton(
                        onPressed: (){
                          //widget.selectedWords.remove(value);
                          //DictionaryDatabase
                          widget.dictionaryDatabase.markAsKnown(widget.selectedWords[currentIndex]);
                          widget.selectedWords.remove(widget.selectedWords[currentIndex]);
                          setState(() {
                            currentIndex=(currentIndex)%widget.selectedWords.length;
                            hiddenElement=true;
                            currElement = Text(widget.selectedWords[currentIndex]['originalWord'].toString());
                          });

                        },
                        child: Text('<I KnowIt!>')),
                    /*Card(
                    child: SizedBox(
                      width: 200,
                      height: 100,
                      child: Center(
                        child: Text(widget.selectedWords[currentIndex]['originalWord'].toString()),
                      ),
                    ),
                  ),
                     */
                  ElevatedButton(
                    style:ElevatedButton.styleFrom(
                      shape:  RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(20)
                      ),
                    ),
                    onPressed: () {

                      setState(() {
                        if (hiddenElement){
                         currElement=Text(widget.selectedWords[currentIndex]['translatedWord'].toString());
                        }else{
                          currElement = Text(widget.selectedWords[currentIndex]['originalWord'].toString());
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
                ]),
                  TextButton(
                      onPressed: (){
                        //widget.selectedWords.remove(value);
                        setState(() {
                          if(currentIndex+1==widget.selectedWords.length){
                            for (var i = 0; i < widget.selectedWords.length; i++) {
                              var temp= widget.selectedWords[i]['originalWord'].toString();
                              widget.selectedWords[i]['originalWord']=widget.selectedWords[i]['translatedWord'].toString();
                              widget.selectedWords[i]['translatedWord']=temp;
                            }
                          }
                          currentIndex=(currentIndex+1)%widget.selectedWords.length;
                          hiddenElement=true;
                          currElement = Text(widget.selectedWords[currentIndex]['originalWord'].toString());
                        });
                      },
                      child: Text('>')),
                ],
              )])),
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


class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  LanguageLabel? originLanguage;
  LanguageLabel? foreignLanguage;

  @override
  Widget build(BuildContext context) {
    return Column(children: [Padding(
      padding: const EdgeInsets.all(40),
      child: FutureBuilder(

          future: getPreferences(),
          builder: (BuildContext context,AsyncSnapshot snapshot)
          {
            if (snapshot.hasData){
              print(snapshot.data!.getString('originLanguage'));
              originLanguage = LanguageLabel.fromString(snapshot.data!.getString('originLanguage'));
              foreignLanguage = LanguageLabel.fromString(snapshot.data!.getString('foreignLanguage'));
            return Column(children:[ DropdownMenu<LanguageLabel>(
        width: 300, // Fixed width for consistent behavior
        initialSelection: originLanguage ?? LanguageLabel.en,
        dropdownMenuEntries: LanguageLabel.entries,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(20),
        ),
        menuStyle: MenuStyle(
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        onSelected: (LanguageLabel? language) {
          setState(() {
            originLanguage= language;
            savePref('originLanguage', originLanguage!.language.toString());
          });
        },
        controller: TextEditingController(
          text: originLanguage?.label ?? 'Select language',
        ),
        label: const Text('Origin Language'),
      ),Padding(padding: EdgeInsets.all(20),
        child:DropdownMenu<LanguageLabel>(
        width: 300, // Fixed width for consistent behavior
        initialSelection: foreignLanguage?? LanguageLabel.de,
        dropdownMenuEntries: LanguageLabel.entries,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(20),
        ),
        menuStyle: MenuStyle(
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        onSelected: (LanguageLabel? language) {
          setState(() {
            foreignLanguage= language;
            savePref('foreignLanguage', foreignLanguage!.language.toString());

          });
        },
        controller: TextEditingController(
          text: foreignLanguage?.label ?? 'Select language',
        ),
        label: const Text('Foreign Language'),
      )),
      ]);}else{
            return Text('loading');
            }

            }
    )
    )]);
  }
  Future<void> savePref(String prefKey, String newLanguage) async{
    print(prefKey);
    print(newLanguage);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, newLanguage);
    return ;
  }
}

Future<SharedPreferences> getPreferences(){
  return SharedPreferences.getInstance();
}

enum LanguageLabel {
  en('English', 'en'),
  de('Deutsch', 'de'),
  sk('Slovak', 'sk'),
  ua('Ukrainian', 'ua'),
  ru('Russian', 'ru');

  const LanguageLabel(this.label, this.language);
  final String label;
  final String language;
  // this is the only part in this project from llm. I tried to do it the recommended way from doc but it had issues
  static List<DropdownMenuEntry<LanguageLabel>> get entries =>
      values.map<DropdownMenuEntry<LanguageLabel>>(
            (LanguageLabel language) => DropdownMenuEntry(
          value: language,
          label: language.label,
        ),
      ).toList();

  static LanguageLabel? fromString(String? languageCode) {
    if (languageCode == null) return null;
    return LanguageLabel.values.firstWhere(
          (e) => e.language == languageCode,
      orElse: () => LanguageLabel.en,
    );
  }
}