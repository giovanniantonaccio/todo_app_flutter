import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  final _todoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    readData().then((data) {
      print(data);
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addTodo() {
    Map<String, dynamic> newTodo = Map();
    newTodo['title'] = _todoController.text;
    newTodo['finished'] = false;

    _todoController.text = '';

    setState(() {
      _toDoList.add(newTodo);
    });

    saveData();
  }

  Future<File> getFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return File("${appDocDir.path}/data.json");
  }

  Future<File> saveData() async {
    String data = json.encode(_toDoList);
    File file = await getFile();
    return file.writeAsString(data);
  }

  Future<String> readData() async {
    try {
      final file = await getFile();
      return file.readAsString();
    } catch (err) {
      return null;
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a['finished'] && !b['finished'])
          return 1;
        else if (!a['finished'] && b['finished'])
          return -1;
        else
          return 0;
      });
    });

    saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: TextField(
                      controller: _todoController,
                      decoration: InputDecoration(
                        labelText: 'Add new todo',
                      ),
                    ),
                  ),
                ),
                RaisedButton(
                  child: Text(
                    'ADD',
                    style: TextStyle(
                        color: Theme.of(context).scaffoldBackgroundColor),
                  ),
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    _addTodo();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPosition = index;
          _toDoList.removeAt(index);
        });
        saveData();

        final snack = SnackBar(
          content: Text('Task \"${_lastRemoved['title']}\" removed!'),
          action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                  saveData();
                });
              }),
          duration: Duration(seconds: 2),
        );

        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(snack);
      },
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['finished'],
        secondary: CircleAvatar(
          child: Icon(
            _toDoList[index]['finished'] ? Icons.check : Icons.error,
          ),
        ),
        onChanged: (bool value) {
          setState(() {
            _toDoList[index]['finished'] = value;
          });
        },
      ),
    );
  }
}
