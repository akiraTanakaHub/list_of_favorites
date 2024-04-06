import 'package:english_words/english_words.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'first Flutter App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  WordPair current = WordPair.random();
  List<WordPair> history = [];

  GlobalKey? historyListKey;

  void getNext() {
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorites([WordPair? pair]) {
    pair = pair ?? current;
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

// ...

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = const FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if(constraints.maxWidth <= 450) {
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                    child: BottomNavigationBar(
                      items: [
                        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
                      ],
                      currentIndex: selectedIndex,
                      onTap: (value) => setState(() => selectedIndex = value),
                    )
                )
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                    child: NavigationRail(
                      extended: constraints.maxWidth >= 680,
                      destinations: [
                        NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
                        NavigationRailDestination(icon: Icon(Icons.favorite), label: Text('Favorites')),
                      ],
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (value) => setState(() => selectedIndex = value),
                    )
                ),
                Expanded(child: mainArea),
              ],
            );
          }
        }
      ),
    );
  }
}

// main page
class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: HistoryListView(), flex: 3),
          SizedBox(height: 10.0),
          BigCard(pair: pair),
          SizedBox(height: 10.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: appState.toggleFavorites,
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10.0),
              ElevatedButton.icon(
                  onPressed: appState.getNext,
                  icon: Icon(Icons.navigate_next),
                  label: Text('Next'),
              ),
            ],
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }
}

//

class BigCard extends StatelessWidget {
  const BigCard({
    Key? key,
    required this.pair,
  }) : super(key: key);

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 21.0,
    );

    return Card(
      color: theme.colorScheme.primary,
      // elevation: 8.0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: AnimatedSize(
          duration: Duration(milliseconds: 250),
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(
                  pair.first,
                  style: style.copyWith(fontWeight: FontWeight.w200),
                ),
                Text(
                  pair.second,
                  style: style.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    if(appState.favorites.isEmpty) {
      return SizedBox(
        height: double.infinity,
        child: Center(
          child: Text('No favorites yet!'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 100, left: 30),
          child: Text('You have ${appState.favorites.length} favorites'),
        ),
        Expanded(
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 400 / 80,
            ),
            children: [
              for(var pair in appState.favorites)
                ListTile(
                  leading: IconButton(
                    icon: Icon(Icons.delete_outline, semanticLabel: 'Delete'),
                    color: theme.colorScheme.primary,
                    onPressed: () => appState.removeFavorite(pair),
                  ),
                  title: Text(pair.asLowerCase, semanticsLabel: pair.asPascalCase),
                )
            ],
          ),
        ),
      ],
    );
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({super.key});

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {

  final _key = GlobalKey();
  static const Gradient _maskingGradient = LinearGradient(
    colors: [Colors.transparent, Colors.black],
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;
    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: appState.favorites.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                onPressed: () => appState.toggleFavorites(pair),
                icon: appState.favorites.contains(pair) ? Icon(Icons.favorite, size: 12) : SizedBox(),
                label: Text(pair.asLowerCase, semanticsLabel: pair.asPascalCase),
              ),
            ),
          );
        },
      ),
    );
  }
}




