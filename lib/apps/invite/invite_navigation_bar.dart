import 'package:flutter/material.dart';

class InviteNavigatorBar extends StatelessWidget {
  final String _name;
  const InviteNavigatorBar(this._name, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (idx) {
        switch (idx) {
          case 0:
            Navigator.pop(context);
            break;
          case 1:
            Navigator.pushNamed(context, '/apps/invite/list', arguments: _name);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: "Received")
      ],
    );
  }
}
