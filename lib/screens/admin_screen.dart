import 'package:flutter/material.dart';
import 'package:flutter_app/models/task_model.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _pointsController = TextEditingController();
  TaskType _taskType = TaskType.dailyVisit;

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
                  DropdownMenuItem(value: TaskType.dailyVisit, child: Text('Daily Visit')),
                  DropdownMenuItem(value: TaskType.dailyWatchAd, child: Text('Daily Watch')),
                  DropdownMenuItem(value: TaskType.invite, child: Text('Invite Task')),
                ],
                onChanged: (value) => setState(() => _taskType = value!),
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
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task added successfully!')),
        );
        _titleController.clear();
        _descController.clear();
        _pointsController.clear();
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
    super.dispose();
  }
}