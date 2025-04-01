import 'package:flutter/material.dart';
import 'package:flutter_app/models/task_model.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _pointsController = TextEditingController();
  final _linkController = TextEditingController(); // New field for visit tasks
  TaskType _taskType = TaskType.dailyWatchAd; // Updated default type

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Task Title'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _pointsController,
                decoration: InputDecoration(labelText: 'Points'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<TaskType>(
                value: _taskType,
                items: [
                  DropdownMenuItem(value: TaskType.dailyWatchAd, child: Text('Daily Watch Ad Task')),
                  DropdownMenuItem(value: TaskType.dailyVisit, child: Text('Daily Visit Task')),
                  DropdownMenuItem(value: TaskType.invite, child: Text('Invite Task')),
                ],
                onChanged: (value) => setState(() => _taskType = value!),
              ),
              // Show link input only for "visit" tasks
              if (_taskType == TaskType.dailyVisit)
                TextFormField(
                  controller: _linkController,
                  decoration: InputDecoration(labelText: 'Visit Link (URL)'),
                  validator: (value) => 
                      _taskType == TaskType.dailyVisit && value!.isEmpty ? 'Required' : null,
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Add Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Provider.of<AdminProvider>(context, listen: false).addTask(
          title: _titleController.text,
          description: _descController.text,
          points: int.parse(_pointsController.text),
          type: _taskType,
          link: _taskType == TaskType.dailyVisit ? _linkController.text : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task added successfully!')),
        );
        _titleController.clear();
        _descController.clear();
        _pointsController.clear();
        _linkController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pointsController.dispose();
    _linkController.dispose(); // Dispose the new controller
    super.dispose();
  }
}
