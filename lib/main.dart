import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await SupabaseService.init();
     runApp(const HelmetApp());
   }

/* ================= SUPABASE SERVICE ================= */

class SupabaseService {
  static final supabase = Supabase.instance.client;

  // Initialize Supabase (call this in main.dart before runApp)
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://hoczdzegcfhcgkajflhw.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhvY3pkemVnY2ZoY2drYWpmbGh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzNjgzODYsImV4cCI6MjA4NTk0NDM4Nn0.SMJnHWU17DVM_0IlAuLjjE8fjjymm9DOQWz_ik-tpjY',
    );
  }

  // Sign up new user
  static Future<String?> signup(
      String email, String password, String helmetCode) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Store helmet code in profiles table
        await supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'helmet_code': helmetCode,
          'role': 'OWNER',
        });
        return null; // Success
      }
      return "Signup failed";
    } catch (e) {
      if (e.toString().contains('already registered')) {
        return "Email already exists";
      }
      return e.toString();
    }
  }

  // Login user
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Fetch helmet code from profiles table
        final profile = await supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();

        return {
          'email': response.user!.email,
          'helmetCode': profile['helmet_code'],
          'role': profile['role'] ?? 'OWNER',
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Get current user profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return {
        'email': user.email,
        'helmetCode': profile['helmet_code'],
        'role': profile['role'] ?? 'OWNER',
      };
    } catch (e) {
      return null;
    }
  }
}

/* ================= SESSION ================= */

class UserSession {
  static String email = '';
  static String helmetCode = '';
  static String role = 'OWNER';

  static void setUser(Map<String, dynamic> user) {
    email = user['email'] ?? '';
    helmetCode = user['helmetCode'] ?? '';
    role = user['role'] ?? 'OWNER';
  }

  static void clear() {
    email = '';
    helmetCode = '';
    role = 'OWNER';
  }
}

/* ================= APP ROOT ================= */

class HelmetApp extends StatelessWidget {
  const HelmetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const AuthCheck(),
    );
  }
}

// Optional: Auto-login if session exists
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = SupabaseService.supabase.auth.currentUser;
    if (user != null) {
      final profile = await SupabaseService.getCurrentUserProfile();
      if (profile != null && mounted) {
        UserSession.setUser(profile);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        return;
      }
    }
    // No session, stay on login
  }

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}

/* ================= LOGIN ================= */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: glassCard(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_motorsports,
                  size: 60, color: Colors.cyanAccent),
              const SizedBox(height: 16),
              cyberField("Email", controller: email),
              const SizedBox(height: 12),
              cyberField("Password", controller: password, obscure: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: neonButton(),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          
                          final user = await SupabaseService.login(
                              email.text, password.text);
                          
                          setState(() => _isLoading = false);

                          if (user != null && mounted) {
                            UserSession.setUser(user);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HomePage()),
                            );
                          } else {
                            if (mounted) snack(context, "Invalid login");
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("LOGIN"),
                ),
              ),
              const SizedBox(height: 12),
              socialButton(
                icon: Icons.g_mobiledata,
                text: "Sign in with Google",
                onTap: () => snack(context, "UI only"),
              ),
              if (Platform.isIOS)
                socialButton(
                  icon: Icons.apple,
                  text: "Sign in with Apple",
                  onTap: () => snack(context, "UI only"),
                ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                ),
                child: const Text("Create account"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= SIGNUP ================= */

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final helmet = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: glassCard(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sports_motorsports,
                size: 60,
                color: Colors.cyanAccent,
              ),
              const SizedBox(height: 16),
              cyberField("Email", controller: email),
              const SizedBox(height: 12),
              cyberField("Password", controller: password, obscure: true),
              const SizedBox(height: 12),
              cyberField("Helmet Code", controller: helmet),
              const SizedBox(height: 20),
              ElevatedButton(
                style: neonButton(),
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);

                        final err = await SupabaseService.signup(
                            email.text, password.text, helmet.text);

                        setState(() => _isLoading = false);

                        if (mounted) {
                          if (err == null) {
                            snack(context, "Signup successful! Check your email to verify.");
                            Navigator.pop(context);
                          } else {
                            snack(context, err);
                          }
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("SIGN UP"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= HOME PAGE ================= */

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool helmetSecured = true;

  @override
  Widget build(BuildContext context) {
    final color =
        helmetSecured ? Colors.cyanAccent : Colors.redAccent;

    return Scaffold(
      bottomNavigationBar: const AppNav(index: 0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // ⭐ centers vertically
            children: [
              const Text(
                "Saturday, Jan 31, 2026   14:24 IST",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              GestureDetector(
                onTap: () => setState(
                    () => helmetSecured = !helmetSecured),
                child: statusRing(color),
              ),

              const SizedBox(height: 16),

              Text(
                helmetSecured ? "SECURED" : "UNSECURED",
                style:
                    TextStyle(fontSize: 26, color: color),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.lock,
                        color: color, size: 30),
                    onPressed: () => setState(
                        () => helmetSecured = !helmetSecured),
                  ),
                  const Icon(Icons.notifications,
                      color: Colors.cyanAccent),
                  const Icon(Icons.location_on,
                      color: Colors.cyanAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/* ================= TRACK PAGE (UNCHANGED UI) ================= */

class TrackPage extends StatelessWidget {
  const TrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppNav(index: 1),
      body: const SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            Text("Helmet Location",
                style: TextStyle(fontSize: 22)),
            Expanded(child: CyberMap()),
          ],
        ),
      ),
    );
  }
}

/* ================= MY ACCOUNT PAGE (YOUR UI + DB) ================= */

class MyAccountPage extends StatelessWidget {
  const MyAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const AppNav(index: 2),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("My Account",
                style: TextStyle(fontSize: 26)),
            const SizedBox(height: 20),
            Row(
              children: [
                const CircleAvatar(radius: 35),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(UserSession.email),
                    Text(
                      "Helmet: ${UserSession.helmetCode}",
                      style: const TextStyle(
                          color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            glassSection("Profile Information", [
              listTile(Icons.email, UserSession.email),
              listTile(Icons.verified,
                  UserSession.helmetCode),
              listTile(Icons.security,
                  UserSession.role),
            ]),
            glassSection("My Devices", [
              listTile(Icons.sports_motorsports,
                  "Helmet (Active)",
                  trailing: const Icon(
                      Icons.battery_full,
                      color: Colors.green)),
            ]),
            glassSection("App Preferences", [
              switchTile(
                  "Notification Preferences"),
            ]),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const LoginPage()),
                );
              },
              child: const Text("Log Out"),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= NAV ================= */

class AppNav extends StatelessWidget {
  final int index;
  const AppNav({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: index,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.cyanAccent,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        if (i == index) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                i == 0
                    ? const HomePage()
                    : i == 1
                        ? const TrackPage()
                        : const MyAccountPage(),
          ),
        );
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.shield), label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.map), label: "Track"),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: "Account"),
      ],
    );
  }
}

/* ================= MAP ================= */

class CyberMap extends StatelessWidget {
  const CyberMap({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(12.9716, 77.5946),
        initialZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate:
              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'helmet.app',
        ),
        const MarkerLayer(
          markers: [
            Marker(
              point: LatLng(12.9716, 77.5946),
              width: 60,
              height: 60,
              child: Icon(Icons.location_pin,
                  color: Colors.redAccent, size: 50),
            ),
          ],
        ),
      ],
    );
  }
}

/* ================= UI HELPERS (UNCHANGED) ================= */

Widget cyberField(String hint,
    {TextEditingController? controller,
    bool obscure = false}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      hintText: hint,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Colors.cyanAccent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Colors.cyanAccent),
      ),
    ),
  );
}

Widget glassCard(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter:
          ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  Colors.cyanAccent.withOpacity(0.3)),
        ),
        child: child,
      ),
    ),
  );
}

Widget statusRing(Color color) {
  return Container(
    width: 170,
    height: 170,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 4),
      boxShadow: [
        BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 20),
      ],
    ),
    child: Center(
      child: Icon(Icons.sports_motorsports,
          size: 60, color: color),
    ),
  );
}

Widget glassSection(
    String title, List<Widget> children) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: glassCard(
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );
}

Widget listTile(IconData icon, String text,
    {Widget? trailing}) {
  return ListTile(
    leading:
        Icon(icon, color: Colors.cyanAccent),
    title: Text(text),
    trailing: trailing,
  );
}

Widget switchTile(String text) {
  return SwitchListTile(
    value: true,
    onChanged: (_) {},
    activeColor: Colors.cyanAccent,
    title: Text(text),
  );
}

ButtonStyle neonButton() =>
    ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black);

Widget socialButton(
    {required IconData icon,
    required String text,
    required VoidCallback onTap}) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(text),
      onPressed: onTap,
    ),
  );
}

void snack(BuildContext c, String t) =>
    ScaffoldMessenger.of(c)
        .showSnackBar(SnackBar(content: Text(t)));

