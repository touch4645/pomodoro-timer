import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';



void main() {
  debugPaintSizeEnabled = false;
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
      routes: <String, WidgetBuilder> {
        '/home': (BuildContext context) => new MainPage(),
        '/pomodoro': (BuildContext context) => new PomodoroTimerPage(),
        '/gallery': (BuildContext context) => new GalleryPage(),
        '/settings': (BuildContext context) => new SettingsPage(),
      },
    );
  }
}


/// main page
class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Home'),
      ),
      body: ListView(
        children: [
          _menuItem('ポモドーロタイマー', Icon(Icons.access_alarm), '/pomodoro', context),
          _menuItem('ギャラリー', Icon(Icons.picture_in_picture), '/gallery', context),
          _menuItem('設定', Icon(Icons.settings), '/settings', context)
        ],
      )
    );
  }
}


Widget _menuItem(String title, Icon icon, String route, BuildContext context) {
  return Container(
    decoration: new BoxDecoration(
        border: new Border(bottom: BorderSide(width: 1.0, color: Colors.grey))
    ),
    child:ListTile(
      leading: icon,
      title: Text(
        title,
        style: TextStyle(
            color:Colors.black,
            fontSize: 18.0
        ),
      ),
      onTap: () {
        Navigator.of(context).pushNamed(route);
      }, // タップ
    ),
  );
}


/// setings page
class SettingsPage extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  String _text = '';

  void _handleText(String e) {
    setState(() {
      _text = e;
    });
  }

  // 設定値を保存
  void _saveSetting(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Column(
        children: [
          new TextField(
            enabled: true,
            maxLength: 8,
            style: TextStyle(color: Colors.black),
            obscureText: false,
            maxLines:1 ,
            decoration: const InputDecoration(
              icon: Icon(Icons.timer),
              hintText: '00:25:00',
              labelText: '集中時間 *',
            ),
            onChanged: (String value) {
              _handleText(value);
              _saveSetting('focusTime', value);
            },
          ),
          new TextField(
            enabled: true,
            maxLength: 8,
            style: TextStyle(color: Colors.black),
            obscureText: false,
            maxLines:1 ,
            decoration: const InputDecoration(
              icon: Icon(Icons.timer),
              hintText: '00:05:00',
              labelText: '休憩時間 *',
            ),
            onChanged: (String value) {
              _handleText(value);
              _saveSetting('restTime', value);
            },
          ),
        ],
      ),
    );
  }
}


/// pomodoroTimer page
class PomodoroTimerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(

        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(50.0),
            width: 300,
            height: 300,
            child: Center(
              child: PomodoroTimer()
            ),
          ),
        ],
      )
    );
  }
}


class PomodoroTimer extends StatefulWidget {
  @override
  _PomodoroTimerState createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Timer _timer;
  late DateTime _dateTime;
  bool _isRested = true;
  bool _isEnabled = false;

  // 設定値を取得
  _getSetting(String key) async {
    SharedPreferences prefs = await _prefs;
    return prefs.getString(key);
  }

  void _handleTimeIsOver() {
    if (_timer.isActive && _dateTime == DateTime.parse("0000-00-00 00:00:00")) {
      // _timer.cancel();
      FlutterRingtonePlayer.playAlarm();
      initState();
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(
      Duration(seconds: 1), // 1秒毎に定期実行
      (Timer timer) {
        setState(() { // 変更を画面に反映するため、setState()している
          _dateTime = _dateTime.add(Duration(seconds: -1));
          _handleTimeIsOver();
        });
      },
    );
    _isEnabled = true;
  }

  @override
  void initState() { // 初期化処理
    if (_isRested) {
      _getSetting("focusTime").then((value) {
        setState(() {
          String _time = value ?? "00:25:00";
          _dateTime = DateTime.parse("0000-00-00 ${_time}");
        });
      });
    } else {
      _getSetting("restTime").then((value) {
        setState(() {
          String _time = value ?? "00:05:00";
          _dateTime = DateTime.parse("0000-00-00 ${_time}");
        });
      });
    }
    _isRested = !_isRested;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat.ms().format(_dateTime).toString(),
          style: TextStyle(color: Colors.white70, fontSize: 60.0),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: FloatingActionButton(
                backgroundColor: Colors.blue.shade200,
                onPressed: () {
                  if (_timer.isActive) _timer.cancel();
                  FlutterRingtonePlayer.stop();
                  _isEnabled = false;
                },
                child: Text("Stop"),
              ),
              margin: EdgeInsets.all(16.0),
            ),
            Container(
              child: FloatingActionButton(
                backgroundColor: Colors.blue.shade200,
                onPressed: () { // Startボタンタップ時の処理
                  _isEnabled ? null : _startTimer();
                },
                child: Text("Start"),
              ),
              margin: EdgeInsets.all(16.0),
            ),
          ],
        )
      ]
    );
  }
}


/// Gallery Page
class GalleryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grid List'),
      ),
      body: GridView.count(
        padding: EdgeInsets.all(4.0),
        crossAxisCount: 2,
        crossAxisSpacing: 10.0, // 縦
        mainAxisSpacing: 10.0, // 横
        childAspectRatio: 1.0, // 高さ
        shrinkWrap: true,
        children: List.generate(100, (index) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                new BoxShadow(
                  color: Colors.grey,
                  offset: new Offset(5.0, 5.0),
                  blurRadius: 10.0,
                )
              ],
            ),
            child: Column(
              children: <Widget>[
                Image.asset("assets/img/DSC01291 2.JPG", fit: BoxFit.cover,),
                Container(
                  margin: EdgeInsets.all(16.0),
                  child: Text(
                    'Meeage $index',
                  ),
                ),
              ]
            ),
          );
        }),
      ),
    );
  }
}