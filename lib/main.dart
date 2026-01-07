import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'CheapSharkAPI.dart';
import 'settings.dart';



// TODO
// Add firebase/firestone notifications


void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => Settingsprovider(),
    child: const MainApp()
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}


const double _padding = 20;
const double _margin = 5;
const double _spacing = 10;
const Duration _snackbarDuration = Duration(seconds: 2);


class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Settingsprovider>(
      builder: (context, settings, _) {
        if(!settings.loaded){
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        return MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: settings.seedColourC,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: settings.seedColourC,
            brightness: Brightness.dark,
          ),
          themeMode: settings.themeMode,
          home: HomePage(),
          debugShowCheckedModeBanner: false,
        );
      }
    );
  }
}





class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{
  int _selectedIndex = 0;
  bool _initialised = false;
  late final List<Widget> _pages;

  @override
  void initState(){
    super.initState();
    _pages = [
      DealsPage(),
      SearchPage(),
      SavedPage(),
      Settings()
    ];
  }

  @override 
  void didChangeDependencies(){
    super.didChangeDependencies();
    final settings = Provider.of<Settingsprovider>(context, listen: false);
    if(!_initialised && settings.loaded){
      _selectedIndex = settings.startPageIndex;
      _initialised = true;
    }
  }

  final List<List<dynamic>> _items = [
    [Icon(Icons.attach_money_rounded), "Deals"],
    [Icon(Icons.search_rounded), "Search"],
    [Icon(Icons.favorite_rounded), "Saved"],
    [Icon(Icons.settings_rounded), "Settings"]
  ];

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: SafeArea(
        child: _pages[_selectedIndex]
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _items.map((x){
          return BottomNavigationBarItem(
            icon: x[0],
            label: x[1],
            backgroundColor: Theme.of(context).colorScheme.primary
          );
        }).toList()
      ),
    );
  }
}





class DealsPage extends StatefulWidget{
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  List<Map<String, dynamic>>? _results;
  String displayMethod = "simple";
  bool _loading = true;

  @override
  void initState(){
    super.initState();
    _getDeals();
  }

  Future<void> _getDeals() async {
    setState(() {
      _loading = true;
      _results = null;
    });

    final settings = Provider.of<Settingsprovider>(context, listen: false);
    final results = await CheapSharkAPI().getDeals(settings.stores);
    final filtered = CheapSharkAPI.searchGameFilter(results);
    if(!mounted) return;

    setState(() {
      _results = filtered;
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(_padding),
      child: Column(
        children: [
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          _results == null
          ? _loading ? Text("") : Expanded(child: Center(child: Text("No Deals", style: Theme.of(context).textTheme.titleLarge)))
          : Expanded(child:SingleChildScrollView(
              child: SearchGameTable(key: ValueKey(displayMethod), games: _results!, displayMethod: displayMethod)
            )
          ),
        ],
      ),
    );
  }
}






class SearchPage extends StatefulWidget{
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _search = TextEditingController();
  List<Map<String, dynamic>>? _results;
  String displayMethod = "simple";
  bool _loading = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _searchGames(String query) async {
    setState(() {
      _loading = true;
      _results = null;
    });

    if(query == ""){
      setState(() => _loading = false);
      return;
    }

    final settings = Provider.of<Settingsprovider>(context, listen: false);
    final results = await CheapSharkAPI().searchGames(query, settings.stores);
    final sorted = CheapSharkAPI.searchGameSort(results);
    final filtered = CheapSharkAPI.searchGameFilter(sorted);
    if(!mounted) return;

    setState(() {
      _results = filtered;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(_padding),
      child: Column(
        children: [
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: _searchGames,
            decoration: InputDecoration(
              labelText: "Search",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_spacing),
              ),
              contentPadding: const EdgeInsets.all(_spacing),
            ),
          ),
          const SizedBox(height: _padding),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          _results == null
          ? _loading ? Text("") : Expanded(child: Center(child: Text("Search For a Game", style: Theme.of(context).textTheme.titleLarge)))
          : Expanded(
            child:
            SingleChildScrollView(
              child: SearchGameTable(key: ValueKey(displayMethod), games: _results!, displayMethod: displayMethod)
            )
          ),
        ],
      ),
    );
  }
}


class SearchGameTable extends StatefulWidget{
  final List<Map<String, dynamic>> games;
  final String displayMethod;

  const SearchGameTable({
    super.key,
    required this.games,
    required this.displayMethod
  });

  @override
  State<SearchGameTable> createState() => _SearchGameTableState();
}

class _SearchGameTableState extends State<SearchGameTable>{
  late List<List<String>> gameData;

  @override
  void initState(){
    super.initState();
    gameData = widget.games.map((x) => CheapSharkAPI.searchGameToList(x)).toList();
    _getinlist();
  }


  Future<void> _getinlist() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsgames = prefs.getStringList("games") ?? [];
    setState((){
      for(int i=0; i < gameData.length; i++){
        gameData[i].add(prefsgames.contains(gameData[i][0]).toString());
      }
    });
  }

  Future<void> _addGame(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final games = prefs.getStringList("games") ?? [];
    if(games.contains(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Game Already Added"),
          duration: _snackbarDuration,
        )
      );
      return;
    }
    games.add(id);
    await prefs.setStringList("games", games);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Game Added"),
        duration: _snackbarDuration,
      )
    );
    setState(() => gameData[gameData.indexWhere((x) => x[0] == id)][gameData[0].length-1] = "true");
  }

  Future<void> _removeGame(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final games = prefs.getStringList("games") ?? [];
    if(!games.contains(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Game Already Removed"),
          duration: _snackbarDuration,
        )
      );
      return;
    }
    games.remove(id);
    await prefs.setStringList("games", games);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Game Removed"),
        duration: _snackbarDuration,
      )
    );
    setState(() => gameData[gameData.indexWhere((x) => x[0] == id)][gameData[0].length-1] = "false");
  }



  @override
  Widget build(BuildContext context){
    final settings = Provider.of<Settingsprovider>(context);
    return settings.displayMode == "simple"
    ? Table(
      border: TableBorder(horizontalInside: BorderSide(color: Theme.of(context).colorScheme.outline, width: 2)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FixedColumnWidth(40),
      },
      children: gameData.map((x){
        return TableRow(
          decoration: BoxDecoration(
            gradient: 
              x[6] == "0%" ? LinearGradient(colors: [Colors.red.withAlpha(100), Colors.transparent])
              : LinearGradient(colors: [Colors.green.withAlpha(100), Colors.transparent])
          ),
          children: [
            x[7] == "None" ? Text("")
            : Padding(padding: EdgeInsets.all(_spacing), child: ClipRRect(borderRadius: BorderRadius.circular(_spacing), child: Image.network(x[7], fit: BoxFit.cover))),
            Padding(padding: EdgeInsets.all(_margin), child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GamePage(id: x[0]))),
              child: Text(x[1], textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: EdgeInsetsGeometry.zero),
              onPressed: x[x.length-1] == "true" ? () async => await _removeGame(x[0]) : () async => await _addGame(x[0]),
              label: Icon(x[x.length-1] == "true" ? Icons.remove_rounded : Icons.add_rounded)
            )
          ]
        );
      }).toList()
    )
    : Table(
      border: TableBorder(horizontalInside: BorderSide(color: Theme.of(context).colorScheme.outline, width: 2)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FixedColumnWidth(40),
      },
      children: gameData.map((x){
        return TableRow(
          decoration: BoxDecoration(
            gradient: 
              x[6] == "0%" ? LinearGradient(colors: [Colors.red.withAlpha(25), Colors.transparent])
              : LinearGradient(colors: [Colors.green.withAlpha(25), Colors.transparent])
          ),
          children: [
            x[7] == "None" ? Text("")
            : Padding(padding: EdgeInsets.all(_spacing), child: ClipRRect(borderRadius: BorderRadius.circular(_spacing), child: Image.network(x[7], fit: BoxFit.cover))),
            Padding(padding: EdgeInsets.all(_margin), child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GamePage(id: x[0]))),
              child: Text(x[1], textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium))),
            Padding(padding: EdgeInsets.all(_spacing), child: Text(x[2], textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)),
            Padding(padding: EdgeInsets.all(_spacing), child: Column(children: [
              Text(x[4], textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              if(x[3] == "1")
              Text(x[5], textAlign: TextAlign.center, style: TextStyle(decoration: TextDecoration.lineThrough))
            ])),
            Padding(padding: EdgeInsets.all(_spacing), child: Text(x[6], textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: EdgeInsetsGeometry.zero),
              onPressed: () async{
                final prefs = await SharedPreferences.getInstance();
                final games = prefs.getStringList("games") ?? [];
                if(games.contains(x[0])) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Game Already Added"),
                      duration: _snackbarDuration,
                    )
                  );
                  return;
                }
                games.add(x[0]);
                await prefs.setStringList("games", games);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Game Added"),
                    duration: _snackbarDuration,
                  )
                );
              },
              label: Icon(Icons.add_rounded)
            )
          ]
        );
      }).toList()
    );
  }
}









class SavedPage extends StatefulWidget{
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage>{
  List<dynamic> _games = [];
  String sortMethod = "id";
  String displayMethod = "simple";
  bool _loading = true;
  int _rate = CheapSharkAPI.rateLimit;
  
  @override
  void initState(){
    super.initState();
    _getGames();
  } 

  void _getGames() async {
    final settings = Provider.of<Settingsprovider>(context, listen: false);
    _rate = settings.apiDelay;
    final prefs = await SharedPreferences.getInstance();
    final gamesprefs = prefs.getStringList("games") ?? [];
    final List<Map<String, dynamic>> gamesData = [];
    for(final game in gamesprefs){
      final data = await CheapSharkAPI().getGame(game);
      gamesData.add(data);
      await Future.delayed(Duration(milliseconds: _rate));
      if(!mounted) return;
    }
    final gamesMod = gamesData.map((x) => CheapSharkAPI.gameListToList(x, settings.stores)).toList();
    final gamesSorted = CheapSharkAPI.gamesListSort(gamesMod, sortMethod);
    if(!mounted) return;

    setState((){
      _games = gamesSorted;
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context){
    return Padding(
      padding: EdgeInsets.all(_padding),
      child: Column(
        children: [
          Row(
            spacing: _spacing,
            children: [
              // if(_games.isNotEmpty)
              // Expanded(
              //   child: DropdownButtonFormField<String>(
              //     initialValue: displayMethod,
              //     decoration: InputDecoration(
              //       labelText: "Display",
              //       border: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(_spacing),
              //       ),
              //       contentPadding: const EdgeInsets.all(_spacing),
              //     ),
              //     items: const [
              //       DropdownMenuItem(value: "simple", child: Text("Simple")),
              //       DropdownMenuItem(value: "expanded", child: Text("Expanded"))
              //     ],
              //     onChanged: (c) => setState(() {
              //       displayMethod = c!;
              //     }),
              //   )
              // ),
              if(_games.isNotEmpty)
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: sortMethod,
                  decoration: InputDecoration(
                    labelText: "Sort by",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_spacing),
                    ),
                    contentPadding: const EdgeInsets.all(_spacing),
                  ),
                  items: const [
                    DropdownMenuItem(value: "id", child: Text("ID")),
                    DropdownMenuItem(value: "title", child: Text("Title")),
                    DropdownMenuItem(value: "price", child: Text("Price")),
                    DropdownMenuItem(value: "discount", child: Text("Discount")),
                    DropdownMenuItem(value: "cheapest", child: Text("Cheapest")),
                  ],
                  onChanged: (c) => setState(() {
                    sortMethod = c!;
                    _games = CheapSharkAPI.gamesListSort(_games, sortMethod);
                  }),
                )
              )
            ]
          ),
          SizedBox(height: _padding),
          Expanded(child: _loading
            ? Center(child: CircularProgressIndicator())
            : GameListTable(key: ValueKey(displayMethod), games: _games, displayMethod: displayMethod)
          )
        ]
      )
    );
  }
}



class GameListTable extends StatefulWidget{
  final List<dynamic> games;
  final String displayMethod;

  const GameListTable({
    super.key,
    required this.games,
    required this.displayMethod
  });

  @override
  State<GameListTable> createState() => _GameListTableState();
}

class _GameListTableState extends State<GameListTable>{
  late final List<dynamic> games;
  late final String displayMethod;

  @override
  void initState(){
    super.initState();
    games = widget.games;
    displayMethod = widget.displayMethod;
  }


  void removeGame(String id) async{
    setState(() => games.removeWhere((g) => g[0] == id));
    final prefs = await SharedPreferences.getInstance();
    final prefsgames = prefs.getStringList("games") ?? [];
    prefsgames.remove(id);
    await prefs.setStringList("games", prefsgames);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Game removed"),
        duration: _snackbarDuration,
      )
    );
  }


  @override
  Widget build(BuildContext context){
    final settings = Provider.of<Settingsprovider>(context);
    return games.isEmpty
      ? Center(child: Text("Search to Add Games", style: Theme.of(context).textTheme.titleLarge))
      : settings.displayMode == "simple"
        ? SingleChildScrollView(child: Table(
        border: TableBorder(horizontalInside: BorderSide(color: Theme.of(context).colorScheme.outline, width: 2)),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1),
          2: FixedColumnWidth(40),
        },
        children: [
          TableRow(
            children: [
              Padding(padding: EdgeInsets.all(_spacing), child: Text("Title", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
              Padding(padding: EdgeInsets.all(_spacing), child: Text("Best Price", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
              Padding(padding: EdgeInsets.all(_spacing), child: Text("", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
            ]
          ),
          ...games.map((x){
            return TableRow(
              decoration: BoxDecoration(
                gradient: 
                  x[2][0][1] == x[2][0][2] ? LinearGradient(colors: [Colors.red.withAlpha(100), Colors.transparent])
                  : x[3] == x[4] ? LinearGradient(colors: [Colors.green.withAlpha(100), Colors.transparent])
                  : null
              ),
              children: [
                Padding(padding: EdgeInsets.all(_margin), child: GestureDetector(
                  onTap: () async {
                    final bool? r = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => GamePage(id: x[0])));
                    if(r == null || r == true) removeGame(x[0]);
                  },
                  child: Text(x[1], textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge))),
                Padding(padding: EdgeInsets.all(_margin), child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(x[2][0][0][2]), mode: LaunchMode.externalApplication),
                  child: Text("${x[2][0][0][0]}\n\$${x[3].toStringAsFixed(2)}", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium))),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(padding: EdgeInsetsGeometry.zero),
                  onPressed: () => removeGame(x[0]), 
                  label: Icon(Icons.remove_rounded)
                )
              ]
            );
          })
        ]
      ))
      : SingleChildScrollView(child: Table(
        border: TableBorder(horizontalInside: BorderSide(color: Theme.of(context).colorScheme.outline, width: 2)),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(4),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
          5: FixedColumnWidth(40),
        },
        children: [
          TableRow(
            children: [
              Padding(padding: EdgeInsets.all(_spacing), child: Text("Thumb", textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge)),
              Padding(padding: EdgeInsets.all(_spacing), child: Text("Title", textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge)),
              Padding(padding: EdgeInsets.all(_spacing), child: Text("Deals\nStore | Price | Retail | Discount", textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge)),
              Padding(padding: EdgeInsets.all(_spacing), child: Text("Best Price", textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge)),
              Padding(padding: EdgeInsets.all(_spacing), child: Text("Best Ever", textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge)),
              Padding(padding: EdgeInsets.all(_spacing), child: Text("", textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge)),
            ]
          ),
          ...games.map((x){
            return TableRow(
              decoration: BoxDecoration(
                gradient: 
                  x[2][0][1] == x[2][0][2] ? LinearGradient(colors: [Colors.red.withAlpha(100), Colors.transparent])
                  : x[3] == x[4] ? LinearGradient(colors: [Colors.green.withAlpha(100), Colors.transparent])
                  : null
              ),
              children: [
                Padding(padding: EdgeInsets.all(_spacing), child: ClipRRect(borderRadius: BorderRadius.circular(_spacing), child: Image.network(x[5], fit: BoxFit.cover))),
                Padding(padding: EdgeInsets.all(_margin), child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GamePage(id: x[0]))),
                  child: Text(x[1], textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge))),
                Padding(padding: EdgeInsets.all(_spacing), child: GameListDealTable(deals: x[2], size: 1)),
                Padding(padding: EdgeInsets.all(_spacing), child: Text("\$${x[3].toStringAsFixed(2)}", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)),
                Padding(padding: EdgeInsets.all(_spacing), child: Text("\$${x[4].toStringAsFixed(2)}", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(padding: EdgeInsetsGeometry.zero),
                  onPressed: () => removeGame(x[0]), 
                  label: Icon(Icons.remove_rounded)
                )
              ]
            );
          })
        ]
      ));
  }
}

class GameListDealTable extends StatelessWidget{
  final List<List<dynamic>> deals;
  late final List<dynamic> dealsList = List.from(deals).map((x){
    x[1] is String ? null : x[1] = "\$${x[1].toStringAsFixed(2)}";
    x[2] is String ? null : x[2] = "\$${x[2].toStringAsFixed(2)}";
    x[3] is String ? null : x[3] = "${x[3].toStringAsFixed(0)}%";
    return x;
  }).toList();
  final int size;
  
  GameListDealTable({
    super.key,
    required this.deals,
    required this.size
  });

  @override
  Widget build(BuildContext context){
    print(dealsList);
    return SingleChildScrollView(child: Table(
      border: TableBorder(horizontalInside: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: FlexColumnWidth(5),
        1: FlexColumnWidth(5),
        2: FlexColumnWidth(5),
        3: FlexColumnWidth(3),
      },
      children: dealsList.map((x){
        return TableRow(
          children: [
            Padding(padding: size == 1 ? EdgeInsets.all(_margin) : EdgeInsets.symmetric(horizontal: _margin, vertical: _spacing), child: GestureDetector(
              onTap: () => launchUrl(Uri.parse(x[0][2]), mode: LaunchMode.externalApplication),
              child: Text(x[0][0], textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall))),
            Padding(padding: size == 1 ? EdgeInsets.all(_margin) : EdgeInsets.symmetric(horizontal: _margin, vertical: _spacing), child: Text(x[1], textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)),
            Padding(padding: size == 1 ? EdgeInsets.all(_margin) : EdgeInsets.symmetric(horizontal: _margin, vertical: _spacing), child: Text(x[2], textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)),
            Padding(padding: size == 1 ? EdgeInsets.all(_margin) : EdgeInsets.symmetric(horizontal: _margin, vertical: _spacing), child: Text(x[3], textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)),
          ]
        );
      }).toList()
    ));
  }
}






class GamePage extends StatefulWidget{
  final String id;

  const GamePage({
    super.key,
    required this.id
  });

  @override
  State<GamePage> createState() => _GamePageState(); 
}

class _GamePageState extends State<GamePage>{
  late final String id;
  List<dynamic>? game;
  bool? inlist = false;
  
  @override
  void initState(){
    super.initState();
    id = widget.id;
    _getGame();
    _getinlist();
  }

  void _getGame() async {
    final settings = Provider.of<Settingsprovider>(context, listen: false);
    final data = await CheapSharkAPI().getGame(id);
    final gamesMod = CheapSharkAPI.gameListToList(data, settings.stores);    
    setState((){
      game = gamesMod;
    });
  }

  void _getinlist() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsgames = prefs.getStringList("games") ?? [];
    final il = prefsgames.contains(id);
    setState(() => inlist = il);
  }


  void _addGame(String id) async{
    final prefs = await SharedPreferences.getInstance();
    final prefsgames = prefs.getStringList("games") ?? [];
    if(!prefsgames.contains(id)){
      prefsgames.add(id);
      await prefs.setStringList("games", prefsgames);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Game Added"),
          duration: _snackbarDuration,
        )
      );
    }
  }

  void _removeGame(String id) async{
    final prefs = await SharedPreferences.getInstance();
    final prefsgames = prefs.getStringList("games") ?? [];
    prefsgames.remove(id);
    await prefs.setStringList("games", prefsgames);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Game Removed"),
        duration: _snackbarDuration,
      )
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool pop, T){
        if(pop) return;
        Navigator.pop(context, !inlist!);
      },
      child: game == null
        ? Scaffold(
          appBar: AppBar(title: Text(id)),
          body: SafeArea(child: Center(child: CircularProgressIndicator()))
        )
        : Scaffold(
          appBar: AppBar(title: Text(id)),
          body: SafeArea(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(_padding),
            child: Column(
              children: [
                Padding(padding: EdgeInsets.all(_spacing), child: ClipRRect(borderRadius: BorderRadius.circular(_spacing), child: Image.network(game![5], fit: BoxFit.cover))),
                Padding(padding: EdgeInsets.all(_spacing), child: Text(game![1], textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium)),
                Divider(height: _padding*3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Card(child: Column(children: [
                      Padding(padding: EdgeInsets.only(top: _spacing, bottom: _margin/2), child: Text("Best Price", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)),
                      Padding(padding: EdgeInsets.only(top: _margin/2, bottom: _spacing), child: Text("\$${game![3].toStringAsFixed(2)}", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge))
                    ]))),
                    Expanded(child: Card(child: Column(children: [
                      Padding(padding: EdgeInsets.only(top: _spacing, bottom: _margin/2), child: Text("Best Ever", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)),
                      Padding(padding: EdgeInsets.only(top: _margin/2, bottom: _spacing), child: Text("\$${game![4].toStringAsFixed(2)}", textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge))
                    ]))),
                  ]
                ),
                Divider(height: _padding*3),
                GameListDealTable(deals: game![2], size: 2)
              ]
            )
          ))),
          bottomNavigationBar: SafeArea(child: Padding(padding: EdgeInsets.all(_padding),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(_padding), 
                foregroundColor: inlist! ? Colors.red : Colors.green,
                textStyle: Theme.of(context).textTheme.titleMedium
              ),
              onPressed: (){
                setState((){
                  inlist! ? _removeGame(id) : _addGame(id);
                  inlist = !inlist!;
                });
              }, 
              child: inlist == null ? CircularProgressIndicator()
                : Text(inlist! ? "Remove Game": "Add Game")
            )  
          ),
        )
    ));
  }
}
















class Settings extends StatelessWidget{
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settingsprovider>(context);
    return SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(_padding),
      child: Column(
        spacing: _spacing,
        children: [
          Text("Appearance", style: Theme.of(context).textTheme.titleLarge),
          Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
            DropdownButtonFormField(
              initialValue: settings.startPageIndex,
              decoration: InputDecoration(
                labelText: "Start Page",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_spacing),
                ),
                contentPadding: const EdgeInsets.all(_spacing),
              ),
              items: [
                DropdownMenuItem(value: 0, child: Text("Deals")),
                DropdownMenuItem(value: 1, child: Text("Search")),
                DropdownMenuItem(value: 2, child: Text("Saved"))
              ], 
              onChanged: (index) => settings.setStartPageIndex(index!)
            ),
            DropdownButtonFormField(
              initialValue: settings.displayMode,
              decoration: InputDecoration(
                labelText: "Display",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_spacing),
                ),
                contentPadding: const EdgeInsets.all(_spacing),
              ),
              items: [
                DropdownMenuItem(value: "simple", child: Text("Simple")),
                DropdownMenuItem(value: "expanded", child: Text("Expanded"))
              ], 
              onChanged: (mode) => settings.setDisplayMode(mode!.toString())
            ),
            DropdownButtonFormField(
              initialValue: settings.themeMode,
              decoration: InputDecoration(
                labelText: "Theme",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_spacing),
                ),
                contentPadding: const EdgeInsets.all(_spacing),
              ),
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text("System")),
                DropdownMenuItem(value: ThemeMode.light, child: Text("Light")),
                DropdownMenuItem(value: ThemeMode.dark, child: Text("Dark"))
              ], 
              onChanged: (mode) => settings.setTheme(mode!)
            ),
            DropdownButtonFormField(
              initialValue: settings.seedColour,
              decoration: InputDecoration(
                labelText: "Colour",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_spacing),
                ),
                contentPadding: const EdgeInsets.all(_spacing),
              ),
              items: Settingsprovider.colours.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), 
              onChanged: (colour) => settings.setColour(colour!)
            ),
          ]))),
          Divider(height: _padding),
          Text("API & Stores", style: Theme.of(context).textTheme.titleLarge),
          Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
            TextFormField(
              initialValue: settings.apiDelay.toString(),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              onChanged: (v){
                final ms = int.tryParse(v);
                if(ms != null && ms >= 0) settings.setAPIDelay(ms);
              },
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: "API Call Rate",
                suffix: Text("ms"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_spacing),
                ),
                contentPadding: const EdgeInsets.all(_spacing),
              ),
            ),
            Row(children: [Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(_padding),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => SelectedStoresPage()));
              }, 
              child: Text("Select Stores", textAlign: TextAlign.center),
            ))]),
          ]))),
          Divider(height: _padding),
          Text("Data", style: Theme.of(context).textTheme.titleLarge),
          Row(children: [Expanded(child: Card(child: Padding(padding: EdgeInsets.all(_padding), child:
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(_padding),
                textStyle: Theme.of(context).textTheme.titleMedium,
                foregroundColor: Colors.red
              ),
              onPressed: () async {
                await settings.clearGames();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Game Removed"),
                    duration: _snackbarDuration,
                  )
                );
              }, 
              child: Text("Clear Saved Games"),
            )
          )))]),
          Divider(height: _padding),
          Text("Information", style: Theme.of(context).textTheme.titleLarge),
          Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [ 
            Row(children: [Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(_padding),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => AboutPage()));
              }, 
              child: Text("About App", textAlign: TextAlign.center),
            ))]),
            Row(children: [Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(_padding),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => TipsTricksPage()));
              }, 
              child: Text("Tips & Tricks", textAlign: TextAlign.center),
            ))]),
            Row(children: [Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(_padding),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => SCDataPage()));
              }, 
              child: Text("Stored & Collected Data", textAlign: TextAlign.center),
            ))]),
            Row(children: [Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(_padding),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => LegalPage()));
              }, 
              child: Text("Legal", textAlign: TextAlign.center),
            ))])
          ])))
        ]
      )
    ));
  }
}




class SelectedStoresPage extends StatelessWidget{
  const SelectedStoresPage({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settingsprovider>(context);
    return Scaffold(
      appBar: AppBar(title: Text("Stores")),
      body: SafeArea(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(_padding), child: Center(child: Column(spacing: _spacing, children: [
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("The selected stores will be used in:\nDeals, Searches and Game page info", textAlign: TextAlign.center),
        ]))),
        Divider(),
        ...CheapSharkAPI.stores.keys.map((x){
          return CheckboxListTile(
            title: Text(CheapSharkAPI.stores[x]![0], style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(CheapSharkAPI.stores[x]![1]),
            contentPadding: EdgeInsets.symmetric(horizontal: _spacing, vertical: 0),
            value: settings.stores.contains(x), 
            onChanged: (t){
              final s = settings.stores;
              t! ? s.add(x) : s.remove(x);
              settings.setStores(s);
            }
          );
        })
      ])))))
    );
  }
}


class AboutPage extends StatelessWidget{
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("About")),
      body: SafeArea(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(_padding), child: Center(child: Column(spacing: _spacing, children: [
        Text("Purpose", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("This app is designed to search and save games, and provide deals and prices over a variety of reputable online stores.", textAlign: TextAlign.center),
          Text("This serves to remove the need for managing multiple apps and/or store notifaction services to keep track of your favourite games, and have a central location to reliably get aggrigate and live information on these games.", textAlign: TextAlign.center),
        ]))),
        Divider(),
        Text("What Can You Do?", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("There are two main functions of this app; Searching and Saving, with some other smaller features available like; getting the latest deals.", textAlign: TextAlign.center),
          Text("Getting Deals allows you to find all of the latest deals from a variety of reputable online stores.", textAlign: TextAlign.center),
          Text("Searching allows you to search for any game, edition, DLC, or bundle that is available on said stores.", textAlign: TextAlign.center),
          Text("Saving allows you to save any game you search for in a tracked deals list, allowing you to quickly see the current sale and price status of these games.", textAlign: TextAlign.center),
        ]))),
        Divider(),
        Text("Requirements", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("The only requirement in using the app is an active internet connection, as the app uses an API service to get game information.", textAlign: TextAlign.center),
        ]))),
        Divider(),
        Text("Behind the Scenes", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("Full credit for the information used in this app goes to the CheapShark team and their API service.", textAlign: TextAlign.center),
        ])))
      ])))))
    );
  }
}

class TipsTricksPage extends StatelessWidget{
  const TipsTricksPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tips & Tricks")),
      body: SafeArea(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(_padding), child: Center(child: Column(spacing: _spacing, children: [
        Text("Game Screen", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("Clicking on the name of a game will open a games page, which contains all the relevant information about the game", textAlign: TextAlign.center),
        ]))),
        Divider(),
        Text("Store Shortcut", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("Clicking on the name of a store will open the game in the respective store.", textAlign: TextAlign.center),
          Text("This opens the link in your default browser and navigates straight to the official store, not through a proxy service.", textAlign: TextAlign.center),
        ]))),
        Divider(),
        Text("Colours", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("You may have noticed that games in all screens will be highlighted green or red. This is actually an indicator of the deal status of the game.", textAlign: TextAlign.center),
          Text("In the Deals and Search screen, games highlighted green are on sale in at least one available store. Whereas those highlighted red, are at retail price on all stores.", textAlign: TextAlign.center),
          Text("In the Saved screen it is slightly different. Games the are NOT highlighted are on sale in at least one available store, red remains the same (no sales), and green now represents games that are at their cheapest ever price.", textAlign: TextAlign.center),
        ])))
      ])))))
    );
  }
}

class SCDataPage extends StatelessWidget{
  const SCDataPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Data")),
      body: SafeArea(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(_padding), child: Center(child: Column(spacing: _spacing, children: [
        Text("Stored Data", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("The only information that the app stores is the ID's of your saved games", textAlign: TextAlign.center),
          Text("As this app is based around live information, no caching of information is done as, most likely, this data will be incorrect.", textAlign: TextAlign.center),
        ]))),
        Divider(),
        Text("Collected Data", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("This app does NOT collect any information on the user or installed devices.", textAlign: TextAlign.center),
        ]))),
        Divider(),
        Text("API Data", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("The API service does NOT get or collect any information on the user or installed devices.", textAlign: TextAlign.center),
          Text("The only data the API gets is a game ID.", textAlign: TextAlign.center),
        ])))
      ])))))
    );
  }
}

class LegalPage extends StatelessWidget{
  const LegalPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Legal")),
      body: SafeArea(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(_padding), child: Center(child: Column(spacing: _spacing, children: [
        Text("Legal Stuffs", style: Theme.of(context).textTheme.titleMedium),
        Card(child: Padding(padding: EdgeInsets.all(_padding), child: Column(spacing: _padding, children: [
          Text("Don't really know what to put here...", textAlign: TextAlign.center),
          Text("No legal stuff I guess, just go get them games for cheap.", textAlign: TextAlign.center),
        ])))
      ])))))
    );
  }
}