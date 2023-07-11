import 'package:flutter/material.dart';

class App extends StatelessWidget{
  @override
  Widget build(context){
  return MaterialApp(
      home: Scaffold(
    appBar: AppBar(
      title: const Text("Let's see some Images"),
    ),
    floatingActionButton: FloatingActionButton(onPressed: ()=>{
      print("The button is pressed!"),
    },
    child: const Icon(Icons.add),
    ),
  ));
  }

}