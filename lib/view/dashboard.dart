import 'package:flutter/material.dart';
import 'package:tony_flutter/main.dart';

class DashboardView extends StatelessWidget {
  DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tony Robin Test", style: TextStyle(fontSize: 16)),
        bottom: PreferredSize(
          child: Container(
            color: Colors.white,
            height: 1.0,
          ),
          preferredSize: Size.fromHeight(1.0),
        ),
      ),
      body: FutureBuilder(
        future: getIt.allReady(),
        builder: (context, snapshot) {
          // if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
          // else
          // return GraphsList();
        },
      ),
    );
  }
}
