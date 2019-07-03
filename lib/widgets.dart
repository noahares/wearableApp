import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibrate/vibrate.dart';

class TimerWidget extends StatefulWidget {
  TimerWidget({this.device});

  final BluetoothDevice device;

  @override
  TimerWidgetState createState() =>
      TimerWidgetState(device: device);
}

class TimerWidgetState extends State<TimerWidget> {
  TimerWidgetState({this.device});

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();

    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');

    var ios = new IOSInitializationSettings();

    var settings = new InitializationSettings(android, ios);

    flutterLocalNotificationsPlugin.initialize(settings, onSelectNotification: selectNotification);

  }

  Future selectNotification(String payload) async {
    showDialog(context: context,
    builder: (_) {
      return new AlertDialog(
        title: Text("Message"),
        content: Text(payload),
      );
    });
  }

  Future _disconnectNotification(String message) async {
    var android = new AndroidNotificationDetails('my channel id', 'my channel name', 'my channel description', playSound: false, importance: Importance.Max, priority: Priority.High);
    var ios = new IOSNotificationDetails(presentSound: false);
    var platformSpecifics = new NotificationDetails(android, ios);
    await flutterLocalNotificationsPlugin.show(0, 'Error', message, platformSpecifics, payload: message);
  }

  final BluetoothDevice device;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  String _hoursFormatted;
  String _minutesFormatted;
  String _secondsFormatted;
  Timer timer;
  bool countdownRunning = false;

  @override
  Widget build(BuildContext context) {
    _hoursFormatted = _hours < 10 ? '0' + '$_hours' : '$_hours';
    _minutesFormatted = (_minutes < 10 ? '0' + '$_minutes' : '$_minutes');
    _secondsFormatted = (_seconds < 10 ? '0' + '$_seconds' : '$_seconds');
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        // the timer columns
        _buildSetTimerColumn(_hoursFormatted, _incrementHours, _decrementHours),
        Text(
          ':',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        _buildSetTimerColumn(
            _minutesFormatted, _incrementMinutes, _decrementMinutes),
        Text(
          ':',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        _buildSetTimerColumn(
            _secondsFormatted, _incrementSeconds, _decrementSeconds),
      ]),
      TimerButton(
          color: Colors.green,
          icon: Icons.play_arrow,
          label: 'START',
          onPressed: (countdownRunning ? null : initTimer)),
      TimerButton(
          color: Colors.red,
          icon: Icons.stop,
          label: 'STOP',
          onPressed: (countdownRunning ? reset : null)),
    ]);
  }

  Column _buildSetTimerColumn(
      String text, VoidCallback incr, VoidCallback decr) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        new ChangeTimeButton(label: '+', onPressed: incr),
        Text(
          text,
          style: TextStyle(
            fontSize: 50,
          ),
        ),
        new ChangeTimeButton(label: '-', onPressed: decr),
      ],
    );
  }

  void initTimer() {
    setState(() {
      countdownRunning = true;
      timer = Timer.periodic(Duration(seconds: 1), (timer) {
        _update();
      });
    });
  }

  void _update() async {
    int seconds = (_seconds - 1) % 60;
    int minutes = _minutes;
    int hours = _hours;
    if (seconds == 59) {
        if (minutes != 0 || hours != 0) {
          minutes = (minutes - 1) % 60;
          if (minutes == 59) {
            hours = hours - 1;
          }
        } else {
          try {
            await sendSignal();
          } on ConnectivityException catch (e) {
            _disconnectNotification(e.message);
            if (await Vibrate.canVibrate) Vibrate.vibrate();
          }
          reset();
          return;
        }
      }
    setState(() {
      _seconds = seconds;
      _minutes = minutes;
      _hours = hours;

    });
  }

  void reset() {
    setState(() {
      timer.cancel();
      countdownRunning = false;
      _seconds = 0;
      _minutes = 0;
      _hours = 0;
    });
  }

  void _incrementHours() {
    setState(() {
      _hours++;
      _minutes = _minutes;
      _seconds = _seconds;
    });
    print('$_hours');
  }

  void _decrementHours() {
    if (_hours > 0) {
      setState(() {
        _hours--;
      });
    }
  }

  void _incrementMinutes() {
    setState(() {
      _minutes = (_minutes + 1) % 60;
    });
  }

  void _decrementMinutes() {
    setState(() {
      _minutes = (_minutes - 1) % 60;
    });
  }

  void _incrementSeconds() {
    setState(() {
      _seconds = (_seconds + 1) % 60;
    });
  }

  void _decrementSeconds() {
    setState(() {
      _seconds = (_seconds - 1) % 60;
    });
  }

  Future sendSignal() async {
    BluetoothCharacteristic characteristic;
    List<int> numMotors;
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        var characteristics = service.characteristics;
        for (BluetoothCharacteristic c in characteristics) {
          if (c.uuid.toString().substring(4, 8) == '0001')
            numMotors = await c.read();
          if (c.uuid.toString().substring(4, 8) == '0003') characteristic = c;
        }
      }
      List<int> message = [0xFF, 0xFF, 0xFF, 0xFF];
      List<int> stop = [0x00, 0x00, 0x00, 0x00];
      if (numMotors.first == 5) {
        message.add(0xFF);
        stop.add(0x00);
      }
      await characteristic.write(message);
      Timer(Duration(seconds: 2), () async => await characteristic.write(stop));
    } catch (e) {
      throw new ConnectivityException('No device connected as timer finished!');
    }

  }
}

// Start and Stop buttons. trigger update and cancel it
class TimerButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  TimerButton({this.color, this.icon, this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
        color: Theme.of(context).accentColor,
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            Container(
                margin: const EdgeInsets.only(right: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                )),
          ],
        ));
  }
}

// increment or decrement hours, minutes or seconds
class ChangeTimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  ChangeTimeButton({this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
        color: Theme.of(context).accentColor,
        onPressed: onPressed,
        child: new Text(
          label,
          style: TextStyle(color: Colors.white),
        ));
  }
}

class DeviceWidget extends StatefulWidget {
  DeviceWidget({this.device});

  final BluetoothDevice device;

  @override
  DeviceWidgetState createState() => DeviceWidgetState(device: device);
}

class DeviceWidgetState extends State<DeviceWidget> {
  DeviceWidgetState({this.device});

  final BluetoothDevice device;
  bool autoReconnect = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback onPressed;
              String text;
              String infoText;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () {
                    autoReconnect = false;
                    device.disconnect();
                  };
                  text = 'DISCONNECT';
                  infoText = "CONNECTED";
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () {
                    autoReconnect = true;
                    device.connect();
                  };
                  text = 'CONNECT';
                  infoText = autoReconnect
                      ? 'CONNECTION LOST, TRYING TO RECONNECT...'
                      : 'DISCONNECTED';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  infoText = ('');
                  break;
              }
              print(snapshot.data);
              return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      (infoText),
                      style: Theme.of(context)
                          .primaryTextTheme
                          .subtitle
                          .copyWith(color: Colors.black),
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          RaisedButton(
                            onPressed: onPressed,
                            child: Text(
                              text,
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .button
                                  .copyWith(color: Colors.black),
                            ),
                          ),
                          Text(
                            device.name,
                            style: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .copyWith(color: Colors.black),
                          )
                        ])
                  ]);
            }),
    );
  }
}

class ConnectivityException implements Exception {
  String message;

  ConnectivityException(String message) {
    this.message = message;
  }
}
