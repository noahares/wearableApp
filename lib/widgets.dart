import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key key, this.result, this.onTap}) : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: RaisedButton(
        child: Text('CONNECT'),
        color: Colors.black,
        textColor: Colors.white,
        onPressed: (result.advertisementData.connectable) ? onTap : null,
      ),
    );
  }
}

class TimerWidget extends StatefulWidget {
  TimerWidget({this.device, this.notify});

  final BluetoothDevice device;
  final VoidCallback notify;

  @override
  TimerWidgetState createState() =>
      TimerWidgetState(device: device, notify: notify);
}

class TimerWidgetState extends State<TimerWidget> {
  TimerWidgetState({this.device, this.notify});

  final BluetoothDevice device;
  final VoidCallback notify;
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

  void _update() {
    setState(() {
      _seconds = (_seconds - 1) % 60;
      if (_seconds == 59) {
        if (_minutes != 0 || _hours != 0) {
          _minutes = (_minutes - 1) % 60;
          if (_minutes == 59) {
            _hours = _hours - 1;
          }
        } else {
          notify();
          reset();
        }
      }
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
  final bool _autoReconnect = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: [
            StreamBuilder<BluetoothDeviceState>(
                stream: device.state,
                initialData: BluetoothDeviceState.connecting,
                builder: (c, snapshot) {
                  final bool autoReconnect = _autoReconnect;
                  switch (snapshot.data) {
                    case BluetoothDeviceState.connecting:
                      return Text(
                        ('CONNECTING...'),
                      );
                      break;
                    case BluetoothDeviceState.disconnected:
                      if (autoReconnect) {
                        device.connect();
                        return Text(
                          ('CONNECTION LOST, TRYING TO RECONNECT...'),
                        );
                      } else {
                        return Text(
                            (''),
                        );
                      }
                      break;
                    default:
                      return Text(
                        (''),
                      );
                  }
                }),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                StreamBuilder<BluetoothDeviceState>(
                    stream: device.state,
                    initialData: BluetoothDeviceState.connecting,
                    builder: (c, snapshot) {
                      VoidCallback onPressed;
                      String text;
                      switch (snapshot.data) {
                        case BluetoothDeviceState.connected:
                          onPressed = () =>
                              device.disconnect(); //_voluntaryDisconnect();
                          text = 'DISCONNECT';
                          break;
                        case BluetoothDeviceState.disconnected:
                          onPressed =
                              () => device.connect(); //_voluntaryConnect();
                          text = 'CONNECT';
                          break;
                        default:
                          onPressed = null;
                          text = snapshot.data
                              .toString()
                              .substring(21)
                              .toUpperCase();
                          break;
                      }
                      print(snapshot.data);
                      return RaisedButton(
                        onPressed: onPressed,
                        child: Text(
                          text,
                          style: Theme.of(context)
                              .primaryTextTheme
                              .button
                              .copyWith(color: Colors.black),
                        ),
                      );
                    }),
                Text(
                  device.name,
                  style: Theme.of(context)
                      .primaryTextTheme
                      .title
                      .copyWith(color: Colors.black),
                )
              ],
            ),
          ],
        ),
      ],
    );
  }


  /*void _voluntaryDisconnect() {
    device.disconnect();
    setState(() {
      _autoReconnect = false;
    });
  }

  void _voluntaryConnect() {
    device.connect();
    setState(() {
      _autoReconnect = true;
    });
  }*/
}
