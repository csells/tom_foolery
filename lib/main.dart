import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tom Foolery',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

// TODO: hook Dart networking such that an HTTP GET for a relative url, e.g. /foo/bar.jpg,
// can be patched to be absolute, e.g. https://csells.github.io/sb6/foo/bar.jpg

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AtomFeed feed;

  @override
  void initState() {
    super.initState();
    loadAtomFeed('https://csells.github.io/sb6/feed.atom');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('sellsbrothers.com')),
        body: feed == null
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: feed.items
                          .map(
                            (item) => ListTile(
                              title: Text(item.title),
                              subtitle: Text(item.summary),
                              trailing: Image.network(item.links.firstWhere((l) => l.rel == 'enclosure', orElse: () => AtomLink('https://csells.github.io/sb6/public/favicon.ico', null, null, null, null, null))?.href),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsPage(item))),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.spaceEvenly,
                    layoutBehavior: ButtonBarLayoutBehavior.padded,
                    children: [
                      RaisedButton(child: Text('<<'), onPressed: getPressedHandler('first')),
                      RaisedButton(child: Text('<'), onPressed: getPressedHandler('previous')),
                      RaisedButton(child: Text('>'), onPressed: getPressedHandler('next')),
                      RaisedButton(child: Text('>>'), onPressed: getPressedHandler('last')),
                    ],
                  ),
                ],
              ),
      );

  void loadAtomFeed(String feedlink) async {
    var resp = await http.Client().get(feedlink);
    setState(() => feed = AtomFeed.parse(resp.body));
  }

  // This function doesn't handle the button presses; it created the appropriate handler that will be called when the button is pressed.
  // We want the button to be disenabled if there's nothing to do, e.g. no previous page or we're on the first/last page
  // In those cases, we return null. This causes the button to be disabled.
  // In the other case, when pressing the button can do something, we return the function that will be called when the button is pressed.
  // This is a little tricky even for me...
  Function getPressedHandler(String rel) {
    if (feed == null) return null;

    var relatedFeed = feed.links.firstWhere((l) => l.rel == rel, orElse: () => null);
    if (relatedFeed == null) return null;

    var selfFeed = feed.links.firstWhere((l) => l.rel == 'self', orElse: () => null);
    if (relatedFeed.href == selfFeed.href) return null;

    return () => loadAtomFeed(relatedFeed.href);
  }
}

class DetailsPage extends StatelessWidget {
  final AtomItem item;
  DetailsPage(this.item);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(item.updated)),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Html(data: item.content),
              ),
            ],
          ),
        ),
      );
}
