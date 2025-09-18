import 'package:flutter/material.dart';
import 'lib/Models/pet_report_model.dart';
import 'lib/Modules/add_animal/add_animal_screen.dart';

void main() {
  runApp(TestAddAnimalApp());
}

class TestAddAnimalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test AddAnimal',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: TestHomeScreen(),
    );
  }
}

class TestHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test AddAnimal Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAnimalScreen(
                      reportType: ReportType.lost,
                      title: 'Add Lost Pet',
                    ),
                  ),
                );
              },
              child: Text('Test Lost Pet'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAnimalScreen(
                      reportType: ReportType.adoption,
                      title: 'Add Adoption Pet',
                    ),
                  ),
                );
              },
              child: Text('Test Adoption Pet'),
            ),
          ],
        ),
      ),
    );
  }
} 