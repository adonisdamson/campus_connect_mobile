// Lightweight immutable models mapped from the API's JSON envelopes.

double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);

class University {
  final String id, name, shortName, city;
  final double lat, lng;
  final bool isActive;
  University.fromJson(Map j)
      : id = j['id'],
        name = j['name'] ?? '',
        shortName = j['shortName'] ?? '',
        city = j['city'] ?? '',
        lat = _d(j['lat']),
        lng = _d(j['lng']),
        isActive = j['isActive'] ?? false;
}

class AppUser {
  final String id;
  final String? email, phone, fullName, profilePhoto, campusRole, role, referralCode, universityId;
  final bool isVerified, isDriver, isVendor, isServiceProvider;
  final double rating;
  final List<String> adminPermissions;

  AppUser.fromJson(Map j)
      : id = j['id'],
        email = j['email'],
        phone = j['phone'],
        fullName = j['fullName'],
        profilePhoto = j['profilePhoto'],
        campusRole = j['campusRole'],
        role = j['role'],
        referralCode = j['referralCode'],
        universityId = j['universityId'],
        isVerified = j['isVerified'] ?? false,
        isDriver = j['isDriver'] ?? false,
        isVendor = j['isVendor'] ?? false,
        isServiceProvider = j['isServiceProvider'] ?? false,
        rating = _d(j['rating']),
        adminPermissions = ((j['adminPermissions'] as List?) ?? []).map((e) => '$e').toList();

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';
  bool can(String permission) => isSuperAdmin || adminPermissions.contains(permission);

  String get initials {
    final n = (fullName ?? email ?? 'U').trim();
    final parts = n.split(' ');
    return (parts.length > 1 ? parts.first[0] + parts.last[0] : n.substring(0, n.length.clamp(0, 2))).toUpperCase();
  }
}

class RideEstimate {
  final String rideClass;
  final int distanceMeters, durationSeconds;
  final double fareEstimate, surge;
  RideEstimate.fromJson(Map j)
      : rideClass = j['rideClass'],
        distanceMeters = j['distanceMeters'] ?? 0,
        durationSeconds = j['durationSeconds'] ?? 0,
        fareEstimate = _d(j['fareEstimate']),
        surge = _d(j['surgeMultiplier']);
  String get label => switch (rideClass) {
        'ECONOMY' => 'Economy',
        'PREMIUM' => 'Premium',
        'BIKE' => 'Okada',
        'SHARED' => 'Shared',
        _ => rideClass,
      };
  int get minutes => (durationSeconds / 60).round();
}

class Trip {
  final String id, status, rideClass, pickupAddress, dropoffAddress;
  final double fareEstimate;
  final Map? driver;
  Trip.fromJson(Map j)
      : id = j['id'],
        status = j['status'],
        rideClass = j['rideClass'] ?? 'ECONOMY',
        pickupAddress = j['pickupAddress'] ?? '',
        dropoffAddress = j['dropoffAddress'] ?? '',
        fareEstimate = _d(j['fareEstimate'] ?? j['fareFinal']),
        driver = j['driver'];
}

class Listing {
  final String id, title, description;
  final double price;
  final bool negotiable;
  final List<String> images;
  final Map? seller;
  Listing.fromJson(Map j)
      : id = j['id'],
        title = j['title'] ?? '',
        description = j['description'] ?? '',
        price = _d(j['price']),
        negotiable = j['negotiable'] ?? false,
        images = ((j['images'] as List?) ?? []).map((e) => '${e['url']}').toList(),
        seller = j['seller'];
}

class Vendor {
  final String id, name, category;
  final String? logoUrl, coverUrl;
  final double rating;
  final double? distanceKm;
  final int prepMinutes;
  Vendor.fromJson(Map j)
      : id = j['id'],
        name = j['name'] ?? '',
        category = j['category'] ?? '',
        logoUrl = j['logoUrl'],
        coverUrl = j['coverUrl'],
        rating = _d(j['ratingAvg']),
        distanceKm = j['distanceKm'] == null ? null : _d(j['distanceKm']),
        prepMinutes = j['prepTimeMinutes'] ?? 20;
}

class Product {
  final String id, name;
  final String? description, imageUrl;
  final double price;
  final bool available;
  // Modifier groups: [{ name, required, multi, choices:[{label, price}] }]
  final List<Map<String, dynamic>> options;
  Product.fromJson(Map j)
      : id = j['id'],
        name = j['name'] ?? '',
        description = j['description'],
        imageUrl = j['imageUrl'],
        price = _d(j['price']),
        available = j['isAvailable'] ?? true,
        options = ((j['options'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  bool get hasOptions => options.isNotEmpty;
}

class ServiceItem {
  final String id, title, description, priceType;
  final double basePrice, rating;
  final Map? provider;
  ServiceItem.fromJson(Map j)
      : id = j['id'],
        title = j['title'] ?? '',
        description = j['description'] ?? '',
        priceType = j['priceType'] ?? 'STARTING_AT',
        basePrice = _d(j['basePrice']),
        rating = _d(j['ratingAvg']),
        provider = j['provider'];
}
