//cuando son nos palabras para nombrar el archivo se recomienda usar guion bajo

import 'package:flutter/material.dart';
import 'shared/theme/util.dart';
import 'shared/theme/theme.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
        TextTheme textTheme = createTextTheme(context, "Macondo Swash Caps", "Roboto");
        MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
//staful si o si nesecita un estado mientras que un stateless no lo nesecita


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

 
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
     
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
     
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      
        title: Text(widget.title),
      ),
      body: Center(
   
        child: Column(
       
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
