import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
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
  int _selectedIndex = 1; // Initially set to middle tab (Game Giveaways)
  String _searchQuery = '';
  String _selectedPlatform = 'All'; // Add selected platform for filtering
  final List<String> platforms = ['All', 'PC', 'Steam', 'Epic Games', 'Android', 'iOS'];

  @override
  void initState() {
    super.initState();
    _refreshGiveaways();
  }

  Future<void> _refreshGiveaways() async {
    setState(() {
      switch (_selectedIndex) {
        case 0: // Other Giveaways
          _futureGiveaways = apiService.fetchOtherGiveaways();
          break;
        case 1: // Game Giveaways
          _futureGiveaways = apiService.fetchGiveaways();
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
                    return const Center(child: Text('No giveaways found. 😢'));
                  }

                  final giveaways = snapshot.data!;
                  // Filter giveaways based on search query and platform
                  final filteredGiveaways = giveaways.where((giveaway) {
                    final matchesSearch = giveaway.title.toLowerCase().contains(_searchQuery);
                    final matchesPlatform = _selectedPlatform == 'All' || giveaway.platforms.contains(_selectedPlatform);
                    return matchesSearch && matchesPlatform;
                  }).toList();

                  if (filteredGiveaways.isEmpty) {
                    return const Center(child: Text('No giveaways found. 😢'));
                  }

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
                                          "FREE!",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        const Icon(
                                          Icons.store,
                                          size: 16,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 4.0),
                                        Text(
                                          giveaway.platforms,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        const Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 4.0),
                                        Text(
                                          giveaway.endDate,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_selectedIndex == 2 && giveaway.description != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          '"${giveaway.description}"',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
            label: 'Other Giveaways',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Game Giveaways',
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
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search for giveaways...',
                hintStyle: TextStyle(color: Color(0xFF000000)),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          DropdownButton<String>(
            value: _selectedPlatform,
            items: platforms.map((String platform) {
              return DropdownMenuItem<String>(
                value: platform,
                child: Text(platform),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedPlatform = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }
}
