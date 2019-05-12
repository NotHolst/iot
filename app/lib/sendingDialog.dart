import 'package:flutter/material.dart';

typedef FutureFunction = Future Function();

class SendingDialog extends StatefulWidget {
  SendingDialog(this.tasks, {this.onCompleted});

  final List<FutureFunction> tasks;

  final VoidCallback onCompleted;

  @override
  _SendingDialogState createState() => _SendingDialogState();
}

class _SendingDialogState extends State<SendingDialog> {
  var totalTasks = 0;
  var completedTasks = 0;

  @override
  void initState() {
    super.initState();
    totalTasks = widget.tasks.length;
    executeTasks().then((onValue) {
      widget.onCompleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(8),
            child: Text('$completedTasks / $totalTasks'),
          ),
          CircularProgressIndicator()
        ],
      ),
    );
  }

  Future executeTasks() async {
    var iterator = widget.tasks.iterator;
    return Future.doWhile(() async {
      if (!iterator.moveNext()) return false;
      await iterator.current();
      setState(() {
        completedTasks++;
      });
      return true;
    });
  }
}
