import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return new MyHttpClient(super.createHttpClient(context));
  }
}

void main() {
  HttpOverrides.global = new MyHttpOverrides();
  runApp(MyApp());
}

class MyHttpClient implements HttpClient {
  HttpClient _realClient;
  MyHttpClient(this._realClient) {
    debugPrint('MyHttpClient.ctor');
  }

  @override
  bool get autoUncompress => _realClient.autoUncompress;

  @override
  set autoUncompress(bool value) => _realClient.autoUncompress = value;

  @override
  Duration get connectionTimeout => _realClient.connectionTimeout;

  @override
  set connectionTimeout(Duration value) =>
      _realClient.connectionTimeout = value;

  @override
  Duration get idleTimeout => _realClient.idleTimeout;

  @override
  set idleTimeout(Duration value) => _realClient.idleTimeout = value;

  @override
  int get maxConnectionsPerHost => _realClient.maxConnectionsPerHost;

  @override
  set maxConnectionsPerHost(int value) =>
      _realClient.maxConnectionsPerHost = value;

  @override
  String get userAgent => _realClient.userAgent;

  @override
  set userAgent(String value) => _realClient.userAgent = value;

  @override
  void addCredentials(
          Uri url, String realm, HttpClientCredentials credentials) =>
      _realClient.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(String host, int port, String realm,
          HttpClientCredentials credentials) =>
      _realClient.addProxyCredentials(host, port, realm, credentials);

  @override
  set authenticate(
          Future<bool> Function(Uri url, String scheme, String realm) f) =>
      _realClient.authenticate = f;

  @override
  set authenticateProxy(
          Future<bool> Function(
                  String host, int port, String scheme, String realm)
              f) =>
      _realClient.authenticateProxy = f;

  @override
  set badCertificateCallback(
          bool Function(X509Certificate cert, String host, int port)
              callback) =>
      _realClient.badCertificateCallback = callback;

  @override
  void close({bool force = false}) => _realClient.close(force: force);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _realClient.delete(host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _realClient.deleteUrl(url);

  @override
  set findProxy(String Function(Uri url) f) => _realClient.findProxy = f;

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    debugPrint('get: host = $host');
    return _realClient.get(host, port, path);
  }

// hook Dart networking such that an HTTP GET for a relative url, e.g. /foo/bar.jpg,
// can be patched to be absolute, e.g. https://csells.github.io/sb6/foo/bar.jpg
  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    url = fixFileUrl(url);
    debugPrint('get url: url = $url');
    return _realClient.getUrl(url.replace(path: url.path));
  }

  Uri fixFileUrl(Uri input) {
    var crap = 'file://';
    if (input.toString().startsWith(crap)) {
      input = Uri.parse(
          input.toString().replaceFirst(crap, 'https://sellsbrothers.com'));
    }
    return input;
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _realClient.head(host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => _realClient.headUrl(url);

  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      _realClient.open(method, host, port, path);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _realClient.openUrl(method, url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _realClient.patch(host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _realClient.patchUrl(url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _realClient.post(host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _realClient.postUrl(url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _realClient.put(host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => _realClient.putUrl(url);
}

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
                              trailing: Image.network(item.links
                                  .firstWhere((l) => l.rel == 'enclosure',
                                      orElse: () => AtomLink(
                                          'https://csells.github.io/sb6/public/favicon.ico',
                                          null,
                                          null,
                                          null,
                                          null,
                                          null))
                                  ?.href),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DetailsPage(item))),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.spaceEvenly,
                    layoutBehavior: ButtonBarLayoutBehavior.padded,
                    children: [
                      RaisedButton(
                          child: Text('<<'),
                          onPressed: getPressedHandler('first')),
                      RaisedButton(
                          child: Text('<'),
                          onPressed: getPressedHandler('previous')),
                      RaisedButton(
                          child: Text('>'),
                          onPressed: getPressedHandler('next')),
                      RaisedButton(
                          child: Text('>>'),
                          onPressed: getPressedHandler('last')),
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

    var relatedFeed =
        feed.links.firstWhere((l) => l.rel == rel, orElse: () => null);
    if (relatedFeed == null) return null;

    var selfFeed =
        feed.links.firstWhere((l) => l.rel == 'self', orElse: () => null);
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
