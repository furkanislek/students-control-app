import 'package:Tudora/pages/home/menu-home.dart';
import 'package:Tudora/pages/timer/timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SetTimer extends StatefulWidget {
  const SetTimer({super.key});

  @override
  State<SetTimer> createState() => _SetTimerState();
}

class _SetTimerState extends State<SetTimer> {
  final TextEditingController _minuteController = TextEditingController();
  Color mycolor = Colors.white;

  void starts() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              Timer(color: mycolor, timer: int.parse(_minuteController.text))),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        title: const Text("Odak Sayacı Ayarlama"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MenuHome()),
              );
            },
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(
            left: width / 13.7, right: width / 13.7, top: height / 17.8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    vertical: height / 74.16, horizontal: width / 34.25),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _minuteController,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Dakika Giriniz.",
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: Icon(Icons.timer_sharp),
                        ),
                        hintStyle: TextStyle(
                            color: _minuteController.text.isEmpty
                                ? const Color.fromARGB(220, 168, 163, 161)
                                : const Color(0xFF282625)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height / 45),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Pick a color!'),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: mycolor, //default color
                            onColorChanged: (Color color) {
                              //on color picked
                              setState(() {
                                mycolor = color;
                              });
                            },
                          ),
                        ),
                        actions: <Widget>[
                          ElevatedButton(
                            child: const Text('DONE'),
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(); //dismiss the color picker
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      vertical: height / 74.16, horizontal: width / 34.25),
                  decoration: BoxDecoration(
                    color: mycolor,
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    width: double.infinity,
                    child: const Text(
                      "Odak Rengini Seciniz.",
                      style: const TextStyle(
                        color: Color(0xFF282625),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: height / 45),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: starts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8256DF),
                    padding: EdgeInsets.symmetric(
                        vertical: height / 56.33, horizontal: width / 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: Text(
                    'Başla',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: height / 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: height / 45),
            ],
          ),
        ),
      ),
    );
  }
}
