import 'package:flutter/material.dart';

class SendingDialog extends StatefulWidget {
  SendingDialog(this.tasks, {this.onCompleted});

  final List<Future> tasks;

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

    widget.tasks.forEach((task) {
      task.then((res) {
        setState(() {
          completedTasks++;
          if (completedTasks >= totalTasks) {
            widget.onCompleted();
          }
        });
      });
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
}
