import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/facility_model.dart';
import 'facility_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({Key? key, this.onNavigateToTab}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FacilityModel> _facilities = [];
  bool _isLoading = true;
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  void _fetchFacilities() async {
    try {
      final list = await ApiService.getFacilities();
      if (mounted) {
        setState(() {
          _facilities = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      _fetchFacilities();
      return;
    }
    try {
      final results = await ApiService.searchFacilities(query.trim());
      if (mounted) {
        setState(() {
          _facilities = results;
        });
      }
    } catch (_) {}
  }

  IconData _getCategoryIcon(String cat) {
    if (cat.contains("Mall")) return Icons.shopping_bag_rounded;
    if (cat.contains("Supermarket")) return Icons.shopping_cart_rounded;
    if (cat.contains("Hospital")) return Icons.local_hospital_rounded;
    if (cat.contains("Office") || cat.contains("Tech")) return Icons.business_rounded;
    if (cat.contains("Airport")) return Icons.flight_takeoff_rounded;
    return Icons.local_parking_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    final filteredFacilities = _facilities.where((f) {
      if (_selectedCategory == "All") return true;
      return f.category.toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_parking_rounded, color: AppTheme.primary, size: 28),
            SizedBox(width: 8),
            Text("ParkEazy Marketplace", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchFacilities();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: () async => _fetchFacilities(),
              color: AppTheme.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.9),
                            AppTheme.primary.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hello, ${user?.fullName ?? 'Driver'} 👋",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Discover & reserve parking across all enrolled locations",
                                  style: TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.store_rounded, color: Colors.white, size: 30),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search Location Input Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Search parking location (e.g., Phoenix Mall, D-Mart)",
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchFacilities();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCatChip("All Facilities", "All"),
                          const SizedBox(width: 8),
                          _buildCatChip("Malls", "Mall"),
                          const SizedBox(width: 8),
                          _buildCatChip("Supermarkets", "Supermarket"),
                          const SizedBox(width: 8),
                          _buildCatChip("Hospitals", "Hospital"),
                          const SizedBox(width: 8),
                          _buildCatChip("Tech Parks", "Office"),
                          const SizedBox(width: 8),
                          _buildCatChip("Airports", "Airport"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Enrolled Locations Marketplace Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Enrolled Parking Facilities",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          "${filteredFacilities.length} Facilities",
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Enrolled Parking Facility Cards List
                    filteredFacilities.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.search_off_rounded, color: AppTheme.textSecondary, size: 40),
                                SizedBox(height: 8),
                                Text(
                                  "No matching parking facilities found.",
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredFacilities.length,
                            itemBuilder: (context, index) {
                              final fac = filteredFacilities[index];
                              return _buildFacilityCard(fac);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCatChip(String label, String val) {
    final isSelected = _selectedCategory == val;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.cardBg,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = val;
          });
        }
      },
    );
  }

  Widget _buildFacilityCard(FacilityModel facility) {
    final catIcon = _getCategoryIcon(facility.category);

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => FacilityDetailScreen(facilityId: facility.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category Avatar Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(catIcon, color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.emeraldGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                facility.category.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.near_me_rounded, color: AppTheme.textSecondary, size: 13),
                                const SizedBox(width: 3),
                                Text(
                                  "${facility.distanceKm} km away",
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          facility.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          facility.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppTheme.cardBorder),

              // Availability Info & Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "${facility.availableSlots} spaces available",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Rate: ₹${facility.pricePerHour.toStringAsFixed(0)} / hour",
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),

                  // Reserve Button - Redirects directly to Facility Slots Map
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => FacilityDetailScreen(facilityId: facility.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.grid_view_rounded, size: 18),
                    label: const Text("Reserve Slot"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
