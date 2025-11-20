import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/country.dart';

DateTime getLocalTimeForOffset(double offsetHours) {
  final nowUtc = DateTime.now().toUtc();
  final hours = offsetHours.truncate();
  final minutes = ((offsetHours - hours) * 60).round();
  return nowUtc.add(Duration(hours: hours, minutes: minutes));
}

class DetailPage extends StatefulWidget {
  final Country country;
  const DetailPage({required this.country, Key? key}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late DateTime localTime;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    localTime = getLocalTimeForOffset(widget.country.utcOffset);
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        localTime = getLocalTimeForOffset(widget.country.utcOffset);
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  bool get isDaytime {
    final hour = localTime.hour;
    return hour >= 6 && hour < 18;
  }

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('yyyy-MM-dd – HH:mm:ss').format(localTime);
    return Scaffold(
      appBar: AppBar(title: Text(widget.country.name)),
      body: Stack(
        children: [
          Positioned.fill(
            child: isDaytime
                ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.lightBlue.shade200, Colors.blue.shade800], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                image: DecorationImage(image: AssetImage('assets/images/day_bg.png'), fit: BoxFit.cover, opacity: 0.08),
              ),
            )
                : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                image: DecorationImage(image: AssetImage('assets/images/night_bg.png'), fit: BoxFit.cover, opacity: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(widget.country.flagAsset, width: 60),
                      SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.country.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Capital: ${widget.country.capital}'),
                        Text('UTC Offset: ${widget.country.utcOffset >= 0 ? '+' : ''}${widget.country.utcOffset}'),
                      ]),
                    ],
                  ),
                  Spacer(),
                  Text(DateFormat('HH:mm:ss').format(localTime), style: TextStyle(fontSize: 64, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text(formatted, style: TextStyle(fontSize: 16)),
                  Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
