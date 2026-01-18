import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class Employee {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;

  Employee({required this.firstName, required this.lastName, required this.phone, required this.email});
}

// --- UPDATED NETWORKING LOGIC ---
Future<void> sendStaffToServer(BuildContext context, String fname, String lname, String phone, String email) async {
  try {
    // 1. CHANGE THIS to your laptop's IPv4 Address (found via 'ipconfig')
    // If this is wrong, the mobile app will never find the server.
    String laptopIP = "192.168.0.103"; 
    
    // 2. Connect to the Python socket
    Socket socket = await Socket.connect(laptopIP, 5555, timeout: const Duration(seconds: 5));
    
    // 3. Create a JSON map (This satisfies the Python Database requirement)
    Map<String, String> staffData = {
      "fname": fname,
      "lname": lname,
      "phone": phone,
      "email": email
    };

    // 4. Send encoded JSON across the socket bridge
    socket.write(jsonEncode(staffData));

    // 5. Listen for confirmation from the Python server
    socket.listen((data) {
      final response = String.fromCharCodes(data);
      print("Server confirmation: $response");
      
      // Show a little popup on the phone to prove it worked
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response), backgroundColor: Colors.green),
      );
      
      socket.destroy();
    });
    
  } catch (e) {
    print("Connection failed: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
    );
  }
}

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: EmployeeListScreen()));

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final List<Employee> _employees = [];

  void _navigateAndAddEmployee() async {
    final newEmployee = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateStaffScreen()),
    );

    if (newEmployee != null && newEmployee is Employee) {
      setState(() {
        _employees.add(newEmployee);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Staff List"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: _employees.isEmpty
                ? const Center(child: Text("No employees added yet."))
                : ListView.builder(
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final emp = _employees[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text("${emp.firstName} ${emp.lastName}"),
                        subtitle: Text("${emp.email} • ${emp.phone}"),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _navigateAndAddEmployee,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("Add New Employee", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateStaffScreen extends StatefulWidget {
  const CreateStaffScreen({super.key});

  @override
  State<CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends State<CreateStaffScreen> {
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.blue), onPressed: () => Navigator.pop(context)),
        title: const Text("Create Staff", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[100],
                    child: const Icon(Icons.person_outline, size: 60, color: Colors.blue),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue[800],
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _buildTextField("First Name", "Enter first name", _fNameController)),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField("Last Name", "Enter last name", _lNameController)),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField("Phone Number", "Enter phone number", _phoneController),
            const SizedBox(height: 20),
            _buildTextField("Email", "Enter email address", _emailController),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // --- TRIGGER THE SOCKET BRIDGE ---
                  sendStaffToServer(
                    context,
                    _fNameController.text,
                    _lNameController.text,
                    _phoneController.text,
                    _emailController.text,
                  );

                  final emp = Employee(
                    firstName: _fNameController.text,
                    lastName: _lNameController.text,
                    phone: _phoneController.text,
                    email: _emailController.text,
                  );

                  Navigator.pop(context, emp);
                },
                child: const Text("Save Employee"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }
}