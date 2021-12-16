import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:tony_flutter/main.dart';
import 'package:tony_flutter/service/ably_service.dart';
import 'package:ably_flutter_plugin/ably_flutter_plugin.dart' as ably;
import 'package:intl/intl.dart' as intl;
import 'package:syncfusion_flutter_charts/charts.dart';

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
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          else
            return GraphsList();
        },
      ),
    );
  }
}

class GraphsList extends StatefulWidget {
  const GraphsList({Key? key}) : super(key: key);

  @override
  _GraphsListState createState() => _GraphsListState();
}

class _GraphsListState extends State<GraphsList> {
  List<CoinUpdates> prices = [];

  @override
  void initState() {
    prices = getIt<AblyService>().getCoinUpdates();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StreamBuilder<ably.ConnectionStateChange>(
        stream: getIt<AblyService>().connection,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox();
          } else if (snapshot.data!.event == ably.ConnectionEvent.connected) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  for (CoinUpdates update in prices)
                    CoinGraphItem(coinUpdates: update),
                ],
              ),
            );
          } else if (snapshot.data!.event == ably.ConnectionEvent.failed) {
            return // Center(child: Text("No connection."));
                SingleChildScrollView(
              child: Column(
                children: [
                  for (CoinUpdates update in prices)
                    CoinGraphItem(coinUpdates: update),
                ],
              ),
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class CoinGraphItem extends StatefulWidget {
  const CoinGraphItem({Key? key, required this.coinUpdates}) : super(key: key);
  final CoinUpdates coinUpdates;
  @override
  _CoinGraphItemState createState() => _CoinGraphItemState();
}

class _CoinGraphItemState extends State<CoinGraphItem> {
  Queue<Coin> queue = Queue();
  String coinName = '';
  late VoidCallback _listener;

  @override
  void initState() {
    widget.coinUpdates.addListener(
      _listener = () {
        setState(() {
          queue.add(widget.coinUpdates.coin);
        });

        if (queue.length > 100) {
          queue.removeFirst();
        }
      },
    );

    if (coinName.isEmpty) coinName = widget.coinUpdates.name;

    super.initState();
  }

  @override
  void dispose() {
    widget.coinUpdates.removeListener(_listener);
    super.dispose();
  }

  /// open a page that shows a list of tweets with the cryptocurrency tag
  void _navigateToDetail(String hashtag) {}

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(15),
      padding: EdgeInsets.all(15),
      height: 410,
      decoration: BoxDecoration(
          color: Color(0xffEDEDED).withOpacity(0.05),
          borderRadius: BorderRadius.circular(8.0)),
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        child: queue.isEmpty
            ? Center(
                key: UniqueKey(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 24,
                    ),
                    Text('Waiting for coin data...')
                  ],
                ),
              )
            : Column(
                key: ValueKey(coinName),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FlatButton(
                        onPressed: () => _navigateToDetail(coinName),
                        textColor: Colors.white,
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icon_awesome_twitter.png',
                              height: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "#$coinName",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: Text(
                          "\$${widget.coinUpdates.coin.price.toStringAsFixed(2)}",
                          key: ValueKey(widget.coinUpdates.coin.price),
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                  SfCartesianChart(
                    enableAxisAnimation: true,
                    primaryXAxis: DateTimeAxis(
                      dateFormat: intl.DateFormat.Hms(),
                      intervalType: DateTimeIntervalType.minutes,
                      desiredIntervals: 10,
                      axisLine: AxisLine(width: 2, color: Colors.white),
                      majorTickLines: MajorTickLines(color: Colors.transparent),
                    ),
                    primaryYAxis: NumericAxis(
                      numberFormat: intl.NumberFormat('##,###.00'),
                      desiredIntervals: 5,
                      decimalPlaces: 2,
                      axisLine: AxisLine(width: 2, color: Colors.white),
                      majorTickLines: MajorTickLines(color: Colors.transparent),
                    ),
                    plotAreaBorderColor: Colors.white.withOpacity(0.2),
                    plotAreaBorderWidth: 0.2,
                    series: <LineSeries<Coin, DateTime>>[
                      LineSeries<Coin, DateTime>(
                        animationDuration: 0.0,
                        width: 2,
                        color: Theme.of(context).primaryColor,
                        dataSource: queue.toList(),
                        xValueMapper: (Coin coin, _) => coin.dateTime,
                        yValueMapper: (Coin coin, _) => coin.price,
                      )
                    ],
                  )
                ],
              ),
      ),
    );
  }
}
