import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scan_screen.dart';
import 'location_screen.dart';
import 'doctor_details.dart';
import 'chatbotScreen.dart';
import 'profile_screen.dart';
import 'doctor_data.dart';
import 'doctors_list_screen.dart';
import 'tips_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Styling
  final Color primaryBlue = const Color(0xFF0056D2);
  final Color surfaceWhite = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF1E293B);

  // State & Logic
  int _currentIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _homeSearchController = TextEditingController();
  final FocusNode _homeFocusNode = FocusNode();
  List<Doctor> _searchResults = [];

  @override
  void dispose() {
    _homeSearchController.dispose();
    _homeFocusNode.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = allDoctors.where((doc) {
          final input = query.toLowerCase();
          return doc.name.toLowerCase().contains(input) ||
              doc.specialty.toLowerCase().contains(input) ||
              doc.district.toLowerCase().contains(input);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _homeFocusNode.unfocus(),
      child: Scaffold(
        backgroundColor: surfaceWhite,
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeContent(),
              const Center(
                child: Text(
                  "Bookings Screen",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const Center(
                child: Text(
                  "History Screen",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        // Bottom Navigation
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: primaryBlue,
            unselectedItemColor: Colors.grey.shade400,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            showUnselectedLabels: true,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            onTap: (index) {
              _homeFocusNode.unfocus();
              setState(() => _currentIndex = index);
            },
            items: [
              _buildNavItem(Icons.home_filled, Icons.home_outlined, "Home", 0),
              _buildNavItem(
                Icons.calendar_today,
                Icons.calendar_today_outlined,
                "Bookings",
                1,
              ),
              _buildNavItem(
                Icons.history,
                Icons.history_toggle_off,
                "History",
                2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Helper for "Soft-Touch" Active Icons
  BottomNavigationBarItem _buildNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
  ) {
    bool isActive = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(isActive ? activeIcon : inactiveIcon, size: 24),
      ),
      label: label,
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 25),
          _buildSearchBar(),
          if (_homeSearchController.text.isNotEmpty) _buildSearchDropdown(),
          const SizedBox(height: 25),
          _buildHeroCard(context),
          const SizedBox(height: 30),
          Text(
            "Our Services",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 15),
          _buildServiceGrid(context),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Top Specialists",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  _homeFocusNode.unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DoctorsListScreen(),
                    ),
                  );
                },
                child: Text("See All", style: TextStyle(color: primaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: allDoctors
                .where((doc) => double.parse(doc.rating) >= 4.8)
                .take(2)
                .map((doc) => _buildDoctorCard(context, doc))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 280),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _searchResults.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "No specialists found.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final doctor = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(doctor.image),
                    radius: 20,
                  ),
                  title: Text(
                    doctor.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "${doctor.specialty} • ${doctor.district}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    _homeFocusNode.unfocus();
                    setState(() {
                      _homeSearchController.clear();
                      _searchResults = [];
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorDetails(doctor: doctor),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildHeader() {
    String displayName = user?.displayName ?? "User";
    int hour = DateTime.now().hour;
    String greeting = (hour < 12)
        ? "Good Morning"
        : (hour < 17)
        ? "Good Afternoon"
        : "Good Evening";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            _homeFocusNode.unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(Icons.person_outline, color: textDark),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: _homeSearchController,
        focusNode: _homeFocusNode,
        onChanged: _runSearch,
        decoration: InputDecoration(
          hintText: "Search doctor, specialty, or district...",
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _homeSearchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _homeFocusNode.unfocus();
                    setState(() {
                      _homeSearchController.clear();
                      _runSearch("");
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, const Color(0xFF003D96)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Instant Skin Check",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Get professional-level analysis for your skin conditions in seconds.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    _homeFocusNode.unfocus();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Start Analysis",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.biotech, size: 70, color: Colors.white.withOpacity(0.2)),
        ],
      ),
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _serviceItem(
          context,
          Icons.menu_book_outlined,
          "Tips",
          Colors.orange,
          const TipsScreen(),
        ),
        _serviceItem(
          context,
          Icons.location_on_outlined,
          "Nearby",
          Colors.blue,
          LocationScreen(),
        ),
        _serviceItem(
          context,
          Icons.monitor_heart_outlined,
          "Monitor",
          Colors.purple,
          null,
        ),
        _serviceItem(
          context,
          Icons.chat_bubble_outline,
          "AI Chat",
          Colors.green,
          const ChatbotIntroApp(),
        ),
      ],
    );
  }

  Widget _serviceItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    Widget? screen,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (screen != null) {
          _homeFocusNode.unfocus();
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor doctor) {
    return GestureDetector(
      onTap: () {
        _homeFocusNode.unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorDetails(doctor: doctor)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                doctor.image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textDark,
                    ),
                  ),
                  Text(
                    doctor.specialty,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    doctor.rating,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
