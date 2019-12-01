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

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AtomFeed feed;

  @override
  void initState() {
    super.initState();
    loadAtomFeed();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('sellsbrothers.com')),
        body: feed == null
            ? Center(child: CircularProgressIndicator())
            : ListView(
                children: feed.items
                    .map(
                      (item) => ListTile(
                        title: Text(item.title),
                        subtitle: Text(item.summary),
                        trailing: Image.network(item.links.firstWhere((l) => l.rel == 'enclosure', orElse: () => AtomLink('http://localhost:8080/public/favicon.ico', null, null, null, null, null))?.href),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsPage(item))),
                      ),
                    )
                    .toList(),
              ),
      );

  void loadAtomFeed() async {
    var resp = await http.Client().get('http://localhost:8080/feed.atom');
    var xmlString = resp.body;
    setState(() => feed = AtomFeed.parse(xmlString));
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
