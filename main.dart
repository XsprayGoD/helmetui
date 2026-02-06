

import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  runApp(const HelmetApp());
}

/* ================= DATABASE ================= */

class DatabaseService {
  static late Database db;

  static Future<void> init() async {
    final path = join(await getDatabasesPath(), 'helmet.db');
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            password TEXT,
            helmetCode TEXT
          )
        ''');
      },
    );
  }

  static Future<String?> signup(
      String email, String password, String helmetCode) async {
    try {
      await db.insert('users', {
        'email': email,
        'password': password,
        'helmetCode': helmetCode,
      });
      return null;
    } catch (e) {
      return "Email already exists";
    }
  }

  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    final res = await db.query(
      'users',
      where: 'email=? AND password=?',
      whereArgs: [email, password],
    );
    return res.isNotEmpty ? res.first : null;
  }
}

/* ================= SESSION ================= */

class UserSession {
  static String email = '';
  static String helmetCode = '';
  static String role = 'OWNER';
}

/* ================= APP ROOT ================= */

class HelmetApp extends StatelessWidget {
  const HelmetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LoginPage(),
    );
  }
}

/* ================= LOGIN (UNCHANGED) ================= */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

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
              cyberField("Password",
                  controller: password, obscure: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: neonButton(),
                  onPressed: () async {
                    final user = await DatabaseService.login(
                        email.text, password.text);
                    if (user != null) {
                      UserSession.email = user['email'];
                      UserSession.helmetCode =
                          user['helmetCode'];
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const HomePage()),
                      );
                    } else {
                      snack(context, "Invalid login");
                    }
                  },
                  child: const Text("LOGIN"),
                ),
              ),
              const SizedBox(height: 12),
              socialButton(
                icon: Icons.g_mobiledata,
                text: "Sign in with Google",
                onTap: () =>
                    snack(context, "UI only"),
              ),
              if (Platform.isIOS)
                socialButton(
                  icon: Icons.apple,
                  text: "Sign in with Apple",
                  onTap: () =>
                      snack(context, "UI only"),
                ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const SignupPage()),
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

/* ================= SIGNUP (UNCHANGED) ================= */

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() =>
      _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final helmet = TextEditingController();

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
              cyberField("Password",
                  controller: password, obscure: true),
              const SizedBox(height: 12),
              cyberField("Helmet Code",
                  controller: helmet),
              const SizedBox(height: 20),
              ElevatedButton(
                style: neonButton(),
                onPressed: () async {
                  final err =
                      await DatabaseService.signup(
                          email.text,
                          password.text,
                          helmet.text);
                  if (err == null) {
                    snack(context,
                        "Signup successful");
                    Navigator.pop(context);
                  } else {
                    snack(context, err);
                  }
                },
                child: const Text("SIGN UP"),
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

