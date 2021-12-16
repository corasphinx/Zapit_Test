import 'package:tony_flutter/config.dart';
import 'package:ably_flutter_plugin/ably_flutter_plugin.dart' as ably;
import 'package:flutter/foundation.dart';

const List<Map> _coinTypes = [
  {
    "name": "Bitcoin",
    "code": "btc",
  },
  {
    "name": "Ethereum",
    "code": "eth",
  },
  {
    "name": "Ripple",
    "code": "xrp",
  },
];

class Coin {
  final String code;
  final double price;
  final DateTime dateTime;

  Coin({
    required this.code,
    required this.price,
    required this.dateTime,
  });
}

class CoinUpdates extends ChangeNotifier {
  CoinUpdates({required this.name});
  final String name;

  Coin _coin = Coin(code: '0', price: 0.0, dateTime: DateTime.now());

  Coin get coin => _coin;
  updateCoin(value) {
    _coin = value;
    notifyListeners();
  }
}

class AblyService {
  /// This field is going to be initialized with the clientOptions from
  /// your Ably API Key, if a key isn't provided, the realtime instance
  /// will not be initialized properly.
  ///
  /// It's used for every connection happening between the app and Ably's
  /// realtime services, such as:
  /// 1. Connect to Realtime Ably service
  /// 2. Read connection status
  final ably.Realtime _realtime;

  /// to get the connection status of the realtime instance
  /// The different connection statuses are:
  /// [initialized, connecting, connected]
  /// [disconnected, suspended, closing, closed, failed, update]
  /// It's necessary to check for the connection status and make sure
  /// the user knows what's happening in case of failure.
  Stream<ably.ConnectionStateChange> get connection =>
      _realtime.connection.on();

  /// This is private constructor, as this class should only be initialized
  /// through the init() method, on the service registration at startup.
  ///
  /// The service is registered using `get_it`, to make sure we get the same
  /// instance through out the life of the app, but can be done using other
  /// solutions such as provider.
  ///
  /// Please refer to main.dart to see how registration has been done.
  AblyService._(this._realtime);

  /// The method to be called in order to create `AblyService` instance.
  /// This service is only initialized with this method, and  it's
  /// declared as static to make it accessible without making an instance
  /// of `AblyService`.
  static Future<AblyService> init() async {
    /// initialize client options for your Ably account using your private API key
    final ably.ClientOptions _clientOptions =
        ably.ClientOptions.fromKey(AblyAPIKey);

    /// initialize real-time object with the client options
    final _realtime = ably.Realtime(options: _clientOptions);

    /// connect the app to Ably's Realtime sevices supported by this SDK
    await _realtime.connect();

    /// reaturn the single instance of AblyService with the local `_realtime` instance to
    /// be set as the value of the service's `_realtime` property, so it can be used in
    /// all methods.
    return AblyService._(_realtime);
  }

  List<CoinUpdates> _coinUpdates = [];

  /// Start listening to cryptocurrency prices from Coindesk hub and return
  /// a list of `CoinUpdates` for each currency.
  ///
  /// As data is coming as a stream, we listen to the stream inside this
  /// service, and send a ChangeNotifier object to the UI, where it can
  /// recieve latest value from the `Stream` without subscribing to it, making
  /// the usage inside the UI easier.
  List<CoinUpdates> getCoinUpdates() {
    if (_coinUpdates.isEmpty) {
      for (int i = 0; i < _coinTypes.length; i++) {
        String coinName = _coinTypes[i]['name'];
        String coinCode = _coinTypes[i]['code'];

        _coinUpdates.add(CoinUpdates(name: coinName));

        //launch a channel for each coin type
        ably.RealtimeChannel channel = _realtime.channels
            .get('[product:ably-coindesk/crypto-pricing]$coinCode:usd');

        //subscribe to receive channel messages
        final Stream<ably.Message> messageStream = channel.subscribe();

        //map each stream event to a Coin and start listining
        messageStream.where((event) => event.data != null).listen((message) {
          _coinUpdates[i].updateCoin(
            Coin(
              code: coinCode,
              price: double.parse('${message.data}'),
              dateTime: message.timestamp,
            ),
          );
        });
      }
    }
    return _coinUpdates;
  }
}
