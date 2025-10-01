  // worker_login_screen.dart
  import 'package:cdgi_admin/screens/worker_dashboard.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
  import '../services/api_service.dart';

  const Color kWorkerPrimaryColor = Color(0xFF059669);
  const Color kBackgroundColor = Color(0xFFF8F9FA);
  const Color kTextColor = Color(0xFF212529);
  const Color kHintTextColor = Color(0xFF6C757D);

  class WorkerLoginScreen extends StatefulWidget {
    const WorkerLoginScreen({super.key});

    @override
    State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
  }

  class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    bool _loading = false;
    bool _obscurePassword = true;

    @override
    void dispose() {
      _emailController.dispose();
      _passwordController.dispose();
      super.dispose();
    }

    Future<void> _login() async {
      if (!_formKey.currentState!.validate()) return;

      setState(() => _loading = true);
      try {
        final success = await ApiService.workerLogin(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (success && mounted) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('worker_email', _emailController.text.trim());
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WorkerDashboard()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: $e'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: Stack(
          children: [
            _buildBackgroundShapes(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildFormCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildBackgroundShapes() {
      return Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: kWorkerPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: kWorkerPrimaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildHeader() {
      return Column(
        children: [
          Icon(Icons.engineering_outlined, size: 64, color: kWorkerPrimaryColor),
          const SizedBox(height: 16),
          const Text(
            'Worker Portal',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log in to manage your assigned tasks.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: kHintTextColor),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, curve: Curves.easeOut);
    }

    Widget _buildFormCard() {
      return Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEmailField(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 24),
                  _buildLoginButton(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSignUpLink(),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOut);
    }

    Widget _buildEmailField() {
      return TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: _inputDecoration('Email Address', Icons.email_outlined),
        validator: (value) {
          if (value == null || !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
            return 'Please enter a valid email address.';
          }
          return null;
        },
      );
    }

    Widget _buildPasswordField() {
      return TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: kHintTextColor,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password.';
          }
          return null;
        },
      );
    }

    Widget _buildLoginButton() {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: kWorkerPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: kWorkerPrimaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _loading ? null : _login,
        child: _loading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'Log In',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    Widget _buildSignUpLink() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Don't have an account?", style: TextStyle(color: kHintTextColor)),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkerSignupScreen()),
              );
            },
            child: const Text(
              'Sign Up',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kWorkerPrimaryColor,
              ),
            ),
          ),
        ],
      );
    }

    InputDecoration _inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kHintTextColor),
        prefixIcon: Icon(icon, color: kHintTextColor),
        filled: true,
        fillColor: kBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kWorkerPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      );
    }
  }

  // worker_signup_screen.dart
  class WorkerSignupScreen extends StatefulWidget {
    const WorkerSignupScreen({super.key});

    @override
    State<WorkerSignupScreen> createState() => _WorkerSignupScreenState();
  }

  class _WorkerSignupScreenState extends State<WorkerSignupScreen> {
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _passwordController = TextEditingController();
    final _specializationController = TextEditingController();
    final _experienceController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    String? _selectedDepartment;
    List<Map<String, dynamic>> _departments = [];
    bool _loading = false;
    bool _obscurePassword = true;

    @override
    void initState() {
      super.initState();
      _loadDepartments();
    }

    @override
    void dispose() {
      _nameController.dispose();
      _emailController.dispose();
      _phoneController.dispose();
      _passwordController.dispose();
      _specializationController.dispose();
      _experienceController.dispose();
      super.dispose();
    }

    Future<void> _loadDepartments() async {
      try {
        final departments = await ApiService.getDepartments();
        setState(() {
          _departments = departments.map((dept) {
            // Assuming your Department model has 'id' and 'name' properties.
            // The keys '_id' and 'name' must match what the DropdownButtonFormField expects.
            return {'_id': dept.id, 'name': dept.name};
          }).toList();
        });
      } catch (e) {
        // Use default departments if API fails
        setState(() {
          _departments = [
            {'_id': '1', 'name': 'Electricity Department'},
            {'_id': '2', 'name': 'Water Supply Department'},
            {'_id': '3', 'name': 'Road Maintenance Department'},
            {'_id': '4', 'name': 'Sanitation Department'},
          ];
        });
      }
    }

    // In worker_signup_screen.dart

    // In worker_signup_screen.dart

    Future<void> _signUp() async {
      if (_selectedDepartment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a department.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
        return;
      }

      if (!_formKey.currentState!.validate()) return;

      setState(() => _loading = true);

      // ✅ Generate a unique employee ID here
      var uuid = Uuid();
      String employeeId = 'EMP-${DateTime.now().millisecondsSinceEpoch}-${uuid.v4().substring(0, 8)}';

      final workerData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text.trim(),
        'department_id': _selectedDepartment, // Ensure this is not null
        'skills': [_specializationController.text.trim()],
        'employee_id': employeeId, // ✅ Add the generated ID to the map
      };
      print('--- VERIFYING DATA BEFORE SENDING ---');
      print(workerData);
      print('------------------------------------');

      try {
        final success = await ApiService.registerWorker(workerData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please wait for admin approval.'),
              backgroundColor: Color(0xFF059669), // kWorkerPrimaryColor
            ),
          );
          Navigator.pop(context);
        } else if (mounted) {
          // This handles the case where the API returns a failure (e.g., 400 status)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registration failed. Please check the details and try again.'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          // This handles network errors or specific errors thrown from the API service
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: $e'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text('Worker Registration'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: kHintTextColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildForm(),
                ],
              ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
            ),
          ),
        ),
      );
    }

    Widget _buildHeader() {
      return const Column(
        children: [
          Icon(Icons.person_add_outlined, size: 64, color: kWorkerPrimaryColor),
          SizedBox(height: 16),
          Text(
            'Join Our Team',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fill in your details to register as a worker.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: kHintTextColor),
          ),
        ],
      );
    }

    Widget _buildForm() {
      return Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_nameController, 'Full Name', Icons.person_outline),
              const SizedBox(height: 20),
              _buildTextField(_emailController, 'Email Address', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 20),
              _buildDepartmentDropdown(),
              const SizedBox(height: 20),
              _buildTextField(_specializationController, 'Specialization', Icons.work_outline),
              const SizedBox(height: 20),
              _buildTextField(_experienceController, 'Years of Experience', Icons.timeline_outlined,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 30),
              _buildSignUpButton(),
            ],
          ),
        ),
      );
    }

    Widget _buildTextField(TextEditingController controller, String label, IconData icon,
        {TextInputType keyboardType = TextInputType.text}) {
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label, icon),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label.';
          }
          if (label == 'Email Address' && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
            return 'Please enter a valid email address.';
          }
          return null;
        },
      );
    }

    Widget _buildPasswordField() {
      return TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: kHintTextColor,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (value) {
          if (value == null || value.length < 6) {
            return 'Password must be at least 6 characters.';
          }
          return null;
        },
      );
    }

    Widget _buildDepartmentDropdown() {
      return DropdownButtonFormField<String>(
        initialValue: _selectedDepartment,
        decoration: _inputDecoration('Department', Icons.business_outlined),
        items: _departments.map((dept) {
          return DropdownMenuItem<String>(
            value: dept['_id'],
            child: Text(dept['name']),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedDepartment = value),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a department.';
          }
          return null;
        },
      );
    }

    Widget _buildSignUpButton() {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: kWorkerPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: kWorkerPrimaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _loading ? null : _signUp,
        child: _loading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'Register',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    InputDecoration _inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kHintTextColor),
        prefixIcon: Icon(icon, color: kHintTextColor),
        filled: true,
        fillColor: kBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kWorkerPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      );
    }
  }