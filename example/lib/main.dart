import 'package:flutter/material.dart';
import 'package:scrolling_page_indicator/scrolling_page_indicator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScrollingPageIndicator Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'ScrollingPageIndicator Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);


  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PageController? _controller;

  @override
  void initState() {
    _controller = PageController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [
      buildPage("0", Colors.red),
      buildPage("1", Colors.blue),
      buildPage("2", Colors.green),
      buildPage("3", Colors.amber),
      buildPage("4", Colors.deepPurple),
      buildPage("5", Colors.teal),
      buildPage("6", Colors.pink),
      buildPage("7", Colors.brown)
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: SizedBox(
        height: 300,
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView(
                children: items,
                controller: _controller,
              ),
            ),
            ScrollingPageIndicator(
              dotColor: Colors.grey,
              dotSelectedColor: Colors.deepPurple,
              dotSize: 6,
              dotSelectedSize: 8,
              dotSpacing: 12,
              controller: _controller,
              itemCount: items.length,
              orientation: Axis.horizontal,
            ),

          ],
        ),
      ),
    );
  }

  Widget buildPage(String text, Color color) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Container(
        color: color,
        child: Center(child: Text(text, style: TextStyle(fontSize: 42, color: Colors.white),),),
      ),
    );
  }
}
