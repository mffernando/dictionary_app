import 'dart:async';
import 'dart:convert';
import 'package:dictionary_app/api/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dictionary App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override

  //controllers
  TextEditingController _controller = TextEditingController();
  late StreamController _streamController;
  late Stream _stream;
  Timer? _debounce;

  //initialize
  @override
  void initState() {
    super.initState();

    _streamController = StreamController();
    _stream = _streamController.stream;

  }

  Future _search() async {
    //if search box empty
    if(_controller.text == null || _controller.text.length == 0) {
      _streamController.add(null);
      return;
    }
    _streamController.add("loading");
    Response response = await get(Uri.parse(url + _controller.text.trim()), headers: {"Authorization": "Token " + token});
    _streamController.add(json.decode(response.body));
  }
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dictionary App"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: TextFormField(
                    //search
                    onChanged: (String text) async {
                      if(_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 1000), () {
                        _search();
                      });
                    },
                    //get user text value
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Search for a word",
                      contentPadding: EdgeInsets.only(left: 24.0),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  _search();
                },
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),
              ),

            ],
          ),
        ),
      ),
      //data from api to stream
      body: Container(
        margin: const EdgeInsets.all(8.0),
        child: StreamBuilder(
          stream: _stream,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if(snapshot.data == null) {
              return const Center(
                child: Text("Enter a search word"),
              );
            }

            //loading
            if(snapshot.data == "loading") {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return ListView.builder(
                itemCount: snapshot.data["definitions"].length,
                itemBuilder: (BuildContext context, int index) {
                  return ListBody(
                    children: <Widget>[
                      Container(
                        color: Colors.grey[300],
                        child: ListTile(
                          //word image
                          leading: snapshot.data["definitions"][index]["image_url"] == null ? null : CircleAvatar(
                            backgroundImage: NetworkImage(snapshot.data["definitions"][index]["image_url"]),
                          ),
                          title: Text(_controller.text.trim() + "(" + snapshot.data["definitions"][index]["type"] + ")"),
                        ),
                      ),
                      //definition
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(snapshot.data["definitions"][index]["definition"]),
                      ),
                    ],
                  );
                }
            );
          },
        ),
      ),
    );
  }
}
