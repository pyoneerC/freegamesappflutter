import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // Import the share_plus package
import 'api_service.dart';
import 'giveaway.dart';

void main() {
  runApp(const GiveawaysApp());
}

class GiveawaysApp extends StatelessWidget {
  const GiveawaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Giveaways App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const GiveawaysScreen(),
    );
  }
}

class GiveawaysScreen extends StatefulWidget {
  const GiveawaysScreen({super.key});

  @override
  _GiveawaysScreenState createState() => _GiveawaysScreenState();
}

class _GiveawaysScreenState extends State<GiveawaysScreen> {
  final ApiService apiService = ApiService();
  Future<List<Giveaway>>? _futureGiveaways;
  String _lastRefreshed = '';
  int _selectedIndex = 0; // Track the selected index for the bottom navigation
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshGiveaways();
  }

  Future<void> _refreshGiveaways() async {
    setState(() {
      switch (_selectedIndex) {
        case 0: // Game Giveaways
          _futureGiveaways = apiService.fetchGiveaways();
          break;
        case 1: // Other Giveaways
          _futureGiveaways = apiService.fetchOtherGiveaways();
          break;
        case 2: // DLC Giveaways
          _futureGiveaways = apiService.fetchDlcGiveaways();
          break;
      }
      _lastRefreshed = DateTime.now().toLocal().toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data refreshed!')),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _refreshGiveaways(); // Refresh data on selection change
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Games Tracker'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshGiveaways,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: FutureBuilder<List<Giveaway>>(
                future: _futureGiveaways,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No giveaways found.'));
                  }

                  final giveaways = snapshot.data!;
                  // Filter giveaways based on search query
                  final filteredGiveaways = giveaways.where((giveaway) {
                    return giveaway.title.toLowerCase().contains(_searchQuery);
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                    itemCount: filteredGiveaways.length,
                    itemBuilder: (context, index) {
                      final giveaway = filteredGiveaways[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 8.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  giveaway.imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Center(child: Icon(Icons.error)),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      giveaway.title.replaceAll(' Giveaway', ''),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Row(
                                      children: [
                                        if (_selectedIndex != 2) // Check if not DLC
                                          Text(
                                            giveaway.worth,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.red,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        const SizedBox(width: 8.0),
                                        const Text(
                                          "FREE!", // Discounted price or "100% off"
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        // Clock icon for end date
                                        const Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 4.0),
                                        Text(
                                          giveaway.endDate, // Display end date
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    onPressed: () async {
                                      final url = giveaway.openGiveawayUrl;
                                      if (await canLaunch(url)) {
                                        await launch(url);
                                      } else {
                                        throw 'Could not launch $url';
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.share),
                                    onPressed: () {
                                      final url = giveaway.openGiveawayUrl;
                                      Share.share('Check out this giveaway: $url');
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Last Refreshed: $_lastRefreshed\nMade by Max Comperatore',
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad),
            label: 'Game Giveaways',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Other Giveaways',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'DLC Giveaways',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.black54,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search giveaways...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0), // Make it round
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          contentPadding: const EdgeInsets.all(16.0),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.blueAccent),
          ),
        ),
      ),
    );
  }
}
