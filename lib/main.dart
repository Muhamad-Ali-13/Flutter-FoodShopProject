import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FoodBottomBarSelectionService()),
        ChangeNotifierProvider(create: (_) => FoodService()..loadFoods()),
        ChangeNotifierProvider(create: (_) => FoodShoppingCartService()),
        ChangeNotifierProvider(create: (_) => FavoriteService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: Utils.mainAppNav, // ✅ Pastikan Utils.mainAppNav sudah dideklarasikan dengan benar
        initialRoute: '/',
        routes: {
          '/': (context) => SplashPage(),
          '/main': (context) => FoodShopMain(),
          '/details': (context) => FoodShopDetails(),
          '/favorites': (context) => FavoritesPage(),
          '/shoppingcart': (context) => FoodShoppingCartPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/details') {
            final food = settings.arguments as FoodModel?;
            if (food == null) {
              return MaterialPageRoute(builder: (context) => FoodShopMain()); // ✅ Fallback jika argumen null
            }
            return MaterialPageRoute(
              builder: (context) => FoodShopDetails(),
              settings: settings,
            );
          }
          return null;
        },
      ),
    ),
  );
}


class Utils {
  static GlobalKey<NavigatorState> mainListNav = GlobalKey();
  static GlobalKey<NavigatorState> mainAppNav = GlobalKey();
  static const Color mainDark = Color(0xFFFF5252);
}

class SplashPage extends StatefulWidget {
  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isAnimationLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Utils.mainAppNav.currentState?.pushReplacementNamed('/main');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.mainDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder(
              future: _loadAnimation(),
              builder: (context, snapshot) {
                if (_isAnimationLoaded) {
                  return Lottie.asset(
                    'assets/food.json',
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height * 0.5,
                    controller: _controller,
                    onLoaded: (composition) {
                      _controller
                        ..duration = composition.duration
                        ..forward();
                    },
                  );
                } else {
                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAnimation() async {
    try {
      await rootBundle.load('assets/food.json');
      if (mounted) {
        setState(() => _isAnimationLoaded = true);
      }
    } catch (e) {
      print("Error loading animation: $e");
      setState(() => _isAnimationLoaded = false);
    }
  }
}

class FoodShopMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(child: FoodSideMenu()),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Utils.mainDark),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Food Shop', style: TextStyle(color: Utils.mainDark)),
      ),
      body: Column(
        children: [
          FoodPager(),
          FoodFilterBar(),
          Expanded(
            child: Consumer<FoodService>(
              builder: (context, foodService, child) {
                if (foodService.filteredFoods.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }
                return FoodList(foods: foodService.filteredFoods);
              },
            ),
          ),
          FoodBottomBar(),
        ],
      ),
    );
  }
}

class FoodPager extends StatefulWidget {
  @override
  State<FoodPager> createState() => _FoodPagerState();
}

class _FoodPagerState extends State<FoodPager> {
  List<String> promoImages = [
    'https://cdn.pixabay.com/photo/2017/12/09/08/18/pizza-3007395_1280.jpg',
    'https://asset.kompas.com/crops/CIiodr6ePijJKc5OD7U7jqvT3Is=/141x330:1273x1084/750x500/data/photo/2020/02/27/5e57d0b63b0bf.jpg',
    'https://asset.kompas.com/crops/XpSCCV4YR5WOsN4mrms3-3Qife0=/137x72:798x513/1200x800/data/photo/2022/07/21/62d8ed0d485d4.jpg',
    'https://i.gojekapi.com/darkroom/gofood-indonesia/v2/images/uploads/98de0753-e6d3-483a-b706-43a922e40446_85930485-222a-4978-a155-23511f90ecf6_Go-Biz_20191209_015207.jpeg',
    'https://asset.kompas.com/crops/YhyVl2Yi4elqlkSc0xWy6gxEMT0=/0x0:1000x667/750x500/data/photo/2021/08/29/612ae4c73f1cd.jpeg',
  ];
  int currentPage = 0;
  late PageController controller;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: controller,
              onPageChanged: (int page) => setState(() => currentPage = page),
              children: promoImages.map((url) => _buildPromoImage(url)).toList(),
            ),
          ),
          PageViewIndicator(
            controller: controller,
            numberOfPages: promoImages.length,
            currentPage: currentPage,
          )
        ],
      ),
    );
  }

  Widget _buildPromoImage(String url) {
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class PageViewIndicator extends StatelessWidget {
  final PageController controller;
  final int numberOfPages;
  final int currentPage;

  const PageViewIndicator({
    required this.controller,
    required this.numberOfPages,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(numberOfPages, (index) {
        return GestureDetector(
          onTap: () => controller.animateToPage(
            index,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 250),
            width: 15,
            height: 15,
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: currentPage == index
                  ? Utils.mainDark
                  : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class FoodSideMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.redAccent[50], // Background color for the side menu
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header Section
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                        "https://images.unsplash.com/photo-1541745537411-b8046dc6d66c"),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Food App",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Your Favorite Foods",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            _buildMenuItem(context, Icons.fastfood, "Food Shop", () {
              Navigator.pop(context); // Close the drawer
            }),
            _buildMenuItem(context, Icons.favorite, "Favorites", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavoritesPage()),
              );
            }),
            _buildMenuItem(context, Icons.shopping_cart, "Shopping Cart", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FoodShoppingCartPage()),
              );
            }),
             _buildMenuItem(context, Icons.person, "Profile", () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => ProfilePage()),
               );
            }),
            _buildMenuItem(context, Icons.settings, "Setting", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            }),
          ],
        ),
      ),
    );
  }
  // Helper function to build a menu item with consistent styling
  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        size: 28,
        color: Colors.redAccent, // Icon color
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      splashColor: Colors.red[200], // Ripple effect color
      hoverColor: Colors.red[100], // Hover effect color (for web)
    );
  }
}


class FoodBottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FoodBottomBarSelectionService>(
      builder: (context, service, _) {
        return BottomNavigationBar(
          currentIndex: service.currentIndex,
          onTap: (index) {
            service.setTabSelection(index);

            // ✅ Navigasi ke halaman sesuai index
            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/main'); // Halaman Home
                break;
              case 1:
                Navigator.pushNamed(context, '/favorites'); // Halaman Favorites
                break;
              case 2:
                Navigator.pushNamed(context, '/shoppingcart'); // Halaman Keranjang
                break;
            }
          },
          type: BottomNavigationBarType.fixed, // Pastikan tipe fixed agar semua item ditampilkan
          selectedFontSize: 12, // Kurangi ukuran font label terpilih
          unselectedFontSize: 10, // Kurangi ukuran font label tidak terpilih
          iconSize: 24, // Kurangi ukuran ikon
          selectedItemColor: Colors.redAccent, // Warna item terpilih
          unselectedItemColor: Colors.grey, // Warna item tidak terpilih
          backgroundColor: Colors.white, // Latar belakang putih
          elevation: 5, // Efek bayangan
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Consumer<FoodShoppingCartService>(
                builder: (context, cart, _) => Stack(
                  alignment: Alignment.center, // Pusatkan elemen di dalam stack
                  children: [
                    Icon(Icons.shopping_cart),
                    if (cart.cartItems.isNotEmpty)
                      Positioned(
                        right: -3, // Sesuaikan posisi badge ke kanan
                        top: -3, // Sesuaikan posisi badge ke atas
                        child: CircleAvatar(
                          radius: 6, // Kurangi ukuran badge
                          backgroundColor: Colors.red,
                          child: Text(
                            cart.cartItems.length.toString(),
                            style: TextStyle(fontSize: 8), // Kurangi ukuran teks badge
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              label: 'Cart',
            ),
          ],
        );
      },
    );
  }
}

class FoodFilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FoodService>(
      builder: (context, service, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: service.categories.map((category) {
              final isSelected = service.selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilterChip(
                  label: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: isSelected ? Colors.redAccent : Colors.grey[300],
                  onSelected: (_) => service.filterByCategory(category),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class FoodList extends StatelessWidget {
  final List<FoodModel> foods;

  const FoodList({required this.foods});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: foods.length,
        itemBuilder: (context, index) => Container(
          width: MediaQuery.of(context).size.width * 0.8,
          margin: EdgeInsets.symmetric(horizontal: 10),
          child: FoodCard(food: foods[index]),
        ),
      ),
    );
  }
}

class FoodCard extends StatelessWidget {
  final FoodModel food;

  const FoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.pushNamed(context, '/details', arguments: food),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Mencegah overflow
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    image: DecorationImage(
                      image: NetworkImage(food.food_image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded( // Membatasi tinggi agar tidak overflow
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Pastikan tidak melebihi batas
                      children: [
                        Text(
                          food.food_name!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.category, size: 16, color: Colors.grey),
                                SizedBox(width: 5),
                                Text(
                                  food.food_category!,
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.scale, size: 16, color: Colors.grey),
                                SizedBox(width: 5),
                                Text(
                                  '${food.food_weight}g',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Stok: ${food.food_quantity}',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Consumer<FavoriteService>(
              builder: (context, favoriteService, _) => Positioned(
                right: 5,
                top: 5,
                child: IconButton(
                  icon: Icon(
                    favoriteService.isFavorite(food)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () => favoriteService.toggleFavorite(food),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FoodShopDetails extends StatefulWidget {
  @override
  _FoodShopDetailsState createState() => _FoodShopDetailsState();
}

class _FoodShopDetailsState extends State<FoodShopDetails> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final food = ModalRoute.of(context)!.settings.arguments as FoodModel;

    void _updateQuantity(int newQuantity) {
      if (newQuantity >= 1 && newQuantity <= food.food_quantity) {
        setState(() => _quantity = newQuantity);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(food.food_name!),
        actions: [
          Consumer<FoodShoppingCartService>(
            builder: (context, cart, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart),
                    onPressed: () => Navigator.pushNamed(context, '/shoppingcart'),
                  ),
                  if (cart.cartItems.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(
                          cart.totalQuantity.toString(),
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gambar dengan lebar penuh dan tinggi proporsional
            Container(
              height: MediaQuery.of(context).size.height * 0.4, // Tinggi lebih besar
              width: double.infinity, // Lebar penuh
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(food.food_image!),
                  fit: BoxFit.cover, // Gambar menutupi area tanpa distorsi
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          food.food_name!,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Consumer<FavoriteService>(
                        builder: (context, favoriteService, _) => IconButton(
                          icon: Icon(
                            favoriteService.isFavorite(food)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                            size: 30,
                          ),
                          onPressed: () {
                            favoriteService.toggleFavorite(food);
                            if (favoriteService.isFavorite(food)) {
                              Navigator.pushNamed(context, '/favorites');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    children: [
                      _buildDetailItem('Kategori', food.food_category!),
                      _buildDetailItem('Tipe', food.food_type!),
                      _buildDetailItem('Berat', '${food.food_weight}g'),
                      _buildDetailItem('Stok', food.food_quantity.toString()),
                      _buildDetailItem('Deskripsi', food.food_description.toString()),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () => _updateQuantity(_quantity - 1),
                      ),
                      Text('$_quantity', style: TextStyle(fontSize: 20)),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _updateQuantity(_quantity + 1),
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                  Consumer<FoodShoppingCartService>(
                    builder: (context, cart, _) {
                      final isInCart =
                      cart.cartItems.any((item) => item.food.food_id == food.food_id);

                      return ElevatedButton(
                        onPressed: isInCart
                            ? null
                            : () {
                          cart.addToCart(food, _quantity);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${_quantity} item ditambahkan ke keranjang!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 1),
                            ),
                          );
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInCart ? Colors.grey : Utils.mainDark,
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text(
                          isInCart ? 'Sudah di Keranjang' : 'Tambahkan ke Keranjang',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class CartItem {
  final FoodModel food;
  int quantity;

  CartItem({required this.food, required this.quantity});
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favorit')),
      body: Consumer<FavoriteService>(
        builder: (context, favoriteService, _) {
          if (favoriteService.favorites.isEmpty) {
            return Center(child: Text('Belum ada item favorit'));
          }
          return ListView.separated(
            itemCount: favoriteService.favorites.length,
            separatorBuilder: (context, index) => Divider(), // ✅ Tambahkan pemisah antar item
            itemBuilder: (context, index) {
              final food = favoriteService.favorites[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    food.food_image ?? 'https://via.placeholder.com/50',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(food.food_name ?? 'Nama Tidak Tersedia',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kategori: ${food.food_category}'),
                    Text('Tipe: ${food.food_type}'),
                    Text('Jumlah: ${food.food_quantity}'),
                    Text('Berat: ${food.food_weight} gram'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    _showRemoveDialog(context, food, favoriteService);
                  },
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/details',
                  arguments: food,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRemoveDialog(
      BuildContext context, FoodModel food, FavoriteService favoriteService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus dari Favorit?'),
          content: Text('Apakah Anda yakin ingin menghapus ${food.food_name} dari daftar favorit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Batal
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                favoriteService.toggleFavorite(food);
                Navigator.pop(context); // Tutup dialog
              },
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class FoodShoppingCartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Keranjang Belanja')),
      body: Consumer<FoodShoppingCartService>(
        builder: (context, cart, _) {
          if (cart.cartItems.isEmpty) {
            return Center(child: Text('Keranjang belanja kosong'));
          }
          return ListView.builder(
            itemCount: cart.cartItems.length,
            itemBuilder: (context, index) {
              final item = cart.cartItems[index];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Image.network(
                    item.food.food_image!,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(item.food.food_name!),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategori: ${item.food.food_category!}'),
                      Text('Tipe: ${item.food.food_type!}'),
                      Text('Berat: ${item.food.food_weight * item.quantity}g'),
                      Text('Jumlah: ${item.quantity}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          if (item.quantity > 1) {
                            cart.updateQuantity(item.food, item.quantity - 1);
                          } else {
                            cart.removeFromCart(item.food);
                          }
                        },
                      ),
                      Text('${item.quantity}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          if (item.quantity < item.food.food_quantity) {
                            cart.updateQuantity(item.food, item.quantity + 1);
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => cart.removeFromCart(item.food),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Consumer<FoodShoppingCartService>(
        builder: (context, cart, _) => Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Item: ${cart.totalQuantity}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Total Berat: ${cart.cartItems.fold(0, (sum, item) => sum + (item.food.food_weight * item.quantity))}g',
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  cart.clearCart();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Keranjang telah dibersihkan!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: Text('Bersihkan Keranjang',style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FoodModel {
  final int food_id;
  final String food_name;
  final String food_category;
  final int food_weight;
  final String food_type;
  final String food_description;
  final String food_image;
  final int food_quantity;

  FoodModel({
    required this.food_id,
    required this.food_name,
    required this.food_category,
    required this.food_weight,
    required this.food_type,
    required this.food_description,
    required this.food_image,
    required this.food_quantity,
  });
}

class FoodBottomBarSelectionService extends ChangeNotifier {
  int currentIndex = 0;

  void setTabSelection(int index) {
    currentIndex = index;
    switch (index) {
      case 0:
        Utils.mainListNav.currentState?.pushReplacementNamed('/main');
        break;
      case 1:
        Utils.mainListNav.currentState?.pushReplacementNamed('/favorites');
        break;
      case 2:
        Utils.mainListNav.currentState?.pushReplacementNamed('/shoppingcart');
        break;
    }
    notifyListeners();
  }
}

class FavoriteService extends ChangeNotifier {
  final List<FoodModel> _favorites = [];

  List<FoodModel> get favorites => _favorites;

  void toggleFavorite(FoodModel food) {
    if (_favorites.contains(food)) {
      _favorites.remove(food);
    } else {
      _favorites.add(food);
    }
    notifyListeners();
  }

  bool isFavorite(FoodModel food) => _favorites.contains(food);
}

class FoodShoppingCartService extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  int get totalQuantity => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// 🔥 Menambahkan item ke keranjang
  void addToCart(FoodModel food, int quantity) {
    final existingItem = _cartItems.firstWhere(
          (item) => item.food.food_id == food.food_id,
      orElse: () => CartItem(food: food, quantity: 0),
    );

    if (_cartItems.contains(existingItem)) {
      existingItem.quantity += quantity;
    } else {
      _cartItems.add(CartItem(food: food, quantity: quantity));
    }

    notifyListeners(); // 🔥 Update UI
  }

  /// 🔥 Memperbarui jumlah item dalam keranjang
  void updateQuantity(FoodModel food, int newQuantity) {
    final index = _cartItems.indexWhere((item) => item.food.food_id == food.food_id);
    if (index != -1) {
      _cartItems[index].quantity = newQuantity;
      notifyListeners();
    }
  }

  /// 🔥 Menghapus item dari keranjang
  void removeFromCart(FoodModel food) {
    _cartItems.removeWhere((item) => item.food.food_id == food.food_id);
    notifyListeners();
  }

  /// 🔥 Mengosongkan seluruh keranjang
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}

class FoodService extends ChangeNotifier {
  List<FoodModel> foods = [];
  List<String> categories = ['Semua', 'Roti', 'Pizza', 'Martabak', 'Pisang Goreng', 'Bakso'];
  String selectedCategory = 'Semua';

  List<FoodModel> get filteredFoods => selectedCategory == 'Semua'
      ? foods
      : foods.where((f) => f.food_category == selectedCategory).toList();

  void filterByCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void loadFoods() {
    foods = [
      // ROTI (5 macam)
      FoodModel(
        food_id: 1,
        food_name: 'Roti Keju',
        food_category: 'Roti',
        food_type: 'Roti keju lumer',
        food_weight: 200,
        food_quantity: 15,
        food_image:
        'https://asset.kompas.com/crops/CIiodr6ePijJKc5OD7U7jqvT3Is=/141x330:1273x1084/750x500/data/photo/2020/02/27/5e57d0b63b0bf.jpg',
        food_description: 'Roti dengan isian keju lembut',
      ),
      FoodModel(
        food_id: 2,
        food_name: 'Roti Coklat',
        food_category: 'Roti',
        food_type: 'Roti manis isi coklat',
        food_weight: 150,
        food_quantity: 20,
        food_image:
        'https://static.promediateknologi.id/crop/0x0:0x0/750x500/webp/photo/p1/995/2024/09/03/Roti-Coklat-Belepotan-4067907849.jpg',
        food_description: 'Roti manis dengan isi coklat leleh',
      ),
      FoodModel(
        food_id: 3,
        food_name: 'Roti Sosis',
        food_category: 'Roti',
        food_type: 'Roti isi sosis panggang',
        food_weight: 250,
        food_quantity: 10,
        food_image:
        'https://cdn.yummy.co.id/content-images/images/20220329/ZylkubwPCqfGddDmzYp7jrJA1Qf71Y3d-31363438353636383032d41d8cd98f00b204e9800998ecf8427e.jpg?x-oss-process=image/format,webp',
        food_description: 'Roti empuk dengan sosis panggang',
      ),
      FoodModel(
        food_id: 4,
        food_name: 'Roti Abon',
        food_category: 'Roti',
        food_type: 'Roti isi abon sapi',
        food_weight: 180,
        food_quantity: 12,
        food_image:
        'https://asset.kompas.com/crops/0vvzOS9ufiAMwihtnm3urS-zjfM=/3x0:700x465/1200x800/data/photo/2020/08/07/5f2cf0fc1592a.jpg',
        food_description: 'Roti renyah dengan taburan abon sapi gurih',
      ),
      FoodModel(
        food_id: 5,
        food_name: 'Roti Gandum',
        food_category: 'Roti',
        food_type: 'Roti sehat dari gandum utuh',
        food_weight: 220,
        food_quantity: 18,
        food_image:
        'https://akcdn.detik.net.id/api/wm/2020/05/04/818b3fa0-93fc-4c2a-a29b-07fe68889f22_169.jpeg',
        food_description: 'Roti sehat dengan bahan dasar gandum utuh',
      ),

      // PIZZA (5 macam)
      FoodModel(
        food_id: 6,
        food_name: 'Pizza Pepperoni',
        food_category: 'Pizza',
        food_type: 'Pizza pepproni Manis',
        food_weight: 500,
        food_quantity: 8,
        food_image:
        'https://cdn.pixabay.com/photo/2017/12/09/08/18/pizza-3007395_1280.jpg',
        food_description: 'Pizza dengan topping pepperoni',
      ),
      FoodModel(
        food_id: 7,
        food_name: 'Pizza Margherita',
        food_category: 'Pizza',
        food_type: 'Pizza klasik Italia',
        food_weight: 450,
        food_quantity: 10,
        food_image:
        'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=60',
        food_description: 'Pizza klasik dengan saus tomat, keju, dan basil',
      ),
      FoodModel(
        food_id: 8,
        food_name: 'Pizza Keju Ekstra',
        food_category: 'Pizza',
        food_type: 'Pizza dengan keju mozzarella ekstra',
        food_weight: 600,
        food_quantity: 5,
        food_image:
        'https://img.pikbest.com/backgrounds/20250220/pizza-with-extra-cheese-the-ultimate-gooey-delight_11541089.jpg!w700wp',
        food_description: 'Pizza dengan lapisan keju mozzarella melimpah',
      ),
      FoodModel(
        food_id: 9,
        food_name: 'Pizza Sayuran',
        food_category: 'Pizza',
        food_type: 'Pizza vegetarian',
        food_weight: 500,
        food_quantity: 7,
        food_image:
        'https://static.cdntap.com/tap-assets-prod/wp-content/uploads/sites/24/2022/07/Sumber-Instagram-%40jinnys_pizzeria.jpg?width=450&quality=10',
        food_description: 'Pizza dengan berbagai sayuran segar',
      ),
      FoodModel(
        food_id: 10,
        food_name: 'Pizza BBQ Ayam',
        food_category: 'Pizza',
        food_type: 'Pizza dengan saus BBQ dan ayam',
        food_weight: 550,
        food_quantity: 6,
        food_image:
        'https://img.pikbest.com/backgrounds/20250205/a-bbq-chicken-pizza-with-smoky-barbecue-sauce-grilled-red-onions-and-cilantro_11495753.jpg!w700wp',
        food_description: 'Pizza dengan saus BBQ dan potongan daging ayam',
      ),

      // MARTABAK (5 macam)
      FoodModel(
        food_id: 11,
        food_name: 'Martabak Manis',
        food_category: 'Martabak',
        food_type: 'Martabak manis keju coklat',
        food_weight: 300,
        food_quantity: 20,
        food_image:
        'https://pict.sindonews.net/webp/732/pena/news/2024/06/30/185/1406521/5-martabak-terenak-di-jakarta-dengan-topping-melimpah-ydj.webp',
        food_description: 'Martabak manis dengan topping keju dan coklat',
      ),
      FoodModel(
        food_id: 12,
        food_name: 'Martabak Telur',
        food_category: 'Martabak',
        food_type: 'Martabak telur spesial',
        food_weight: 400,
        food_quantity: 15,
        food_image:
        'https://asset.kompas.com/crops/Xzs709vgbAaytq00ufQuV8MSnEw=/2x0:700x465/1200x800/data/photo/2024/06/20/6673ca79b28ca.jpg',
        food_description: 'Martabak telur dengan isian daging sapi',
      ),
      FoodModel(
        food_id: 13,
        food_name: 'Martabak Pandan',
        food_category: 'Martabak',
        food_type: 'Martabak manis aroma pandan',
        food_weight: 350,
        food_quantity: 18,
        food_image:
        'https://asset.kompas.com/crops/IsYzuuy8CmzugJqm0m173yZd2lI=/100x67:900x600/1200x800/data/photo/2021/10/13/6166d287a512f.jpg',
        food_description: 'Martabak manis dengan aroma pandan yang harum',
      ),
      FoodModel(
        food_id: 14,
        food_name: 'Martabak Keju Mozarella',
        food_category: 'Martabak',
        food_type: 'Martabak telor dengan keju mozarella',
        food_weight: 300,
        food_quantity: 10,
        food_image:
        'https://i.gojekapi.com/darkroom/gofood-indonesia/v2/images/uploads/98de0753-e6d3-483a-b706-43a922e40446_85930485-222a-4978-a155-23511f90ecf6_Go-Biz_20191209_015207.jpeg',
        food_description: 'Martabak manis dengan taburan keju mozarella',
      ),
      FoodModel(
        food_id: 15,
        food_name: 'Martabak Coklat Kacang',
        food_category: 'Martabak',
        food_type: 'Martabak manis dengan coklat dan kacang',
        food_weight: 300,
        food_quantity: 12,
        food_image:
        'https://martabakpizzaorins.com/wp-content/uploads/2018/02/MM-CKW.jpg',
        food_description: 'Martabak manis dengan topping coklat dan kacang',
      ),

      // PISANG GORENG (5 macam)
      FoodModel(
        food_id: 16,
        food_name: 'Pisang Crispy',
        food_category: 'Pisang Goreng',
        food_type: 'Pisang goreng crispy',
        food_weight: 300,
        food_quantity: 20,
        food_image:
        'https://asset.kompas.com/crops/XpSCCV4YR5WOsN4mrms3-3Qife0=/137x72:798x513/1200x800/data/photo/2022/07/21/62d8ed0d485d4.jpg',
        food_description: 'Pisang crispy enak, manis dan cruncy',
      ),
      FoodModel(
        food_id: 17,
        food_name: 'Pisang Madu',
        food_category: 'Pisang Goreng',
        food_type: 'Pisang goreng dengan madu',
        food_weight: 250,
        food_quantity: 15,
        food_image:
        'https://akcdn.detik.net.id/community/media/visual/2022/08/01/pisang-goreng-madu.jpeg?w=700&q=90',
        food_description: 'Pisang goreng dengan balutan madu manis',
      ),
      FoodModel(
        food_id: 18,
        food_name: 'Pisang Coklat',
        food_category: 'Pisang Goreng',
        food_type: 'Pisang goreng isi coklat',
        food_weight: 200,
        food_quantity: 18,
        food_image:
        'https://editor.pasundanekspres.id/storage/uploads/conten/rrwqEKrDNLPvuxFf.webp',
        food_description: 'Pisang goreng dengan isian coklat leleh',
      ),
      FoodModel(
        food_id: 19,
        food_name: 'Pisang Keju',
        food_category: 'Pisang Goreng',
        food_type: 'Pisang goreng tabur keju',
        food_weight: 250,
        food_quantity: 10,
        food_image:
        'https://static.promediateknologi.id/crop/0x0:0x0/0x0/webp/photo/p2/01/2024/08/19/Resep-Pisang-Keju-yang-Enak-dan-Crispy-Dijamin-Bikin-Nagih-35877987.jpg',
        food_description: 'Pisang goreng dengan taburan keju parut',
      ),
      FoodModel(
        food_id: 20,
        food_name: 'Pisang Karamel',
        food_category: 'Pisang Goreng',
        food_type: 'Pisang goreng dengan karamel',
        food_weight: 300,
        food_quantity: 12,
        food_image:
        'https://asset-2.tstatic.net/tribunnewswiki/foto/bank/images/pisang-karamell.jpg',
        food_description: 'Pisang goreng dengan saus karamel manis',
      ),

      // BAKSO (5 macam)
      FoodModel(
        food_id: 21,
        food_name: 'Bakso Pentol',
        food_category: 'Bakso',
        food_type: 'Bakso pentol super pedas',
        food_weight: 200,
        food_quantity: 20,
        food_image:
        'https://static.promediateknologi.id/crop/0x0:0x0/750x500/webp/photo/p1/995/2024/03/31/C6F8E7D5-59C5-464F-B414-9B8F123DA607-894366844.jpeg',
        food_description: 'Bakso pentol rasa poll wenak',
      ),
      FoodModel(
        food_id: 22,
        food_name: 'Bakso Urat',
        food_category: 'Bakso',
        food_type: 'Bakso urat kenyal',
        food_weight: 250,
        food_quantity: 15,
        food_image:
        'https://i.pinimg.com/736x/c1/8a/3c/c18a3c1c7244436f9e87ed19822d0976.jpg',
        food_description: 'Bakso dengan tekstur kenyal dan urat',
      ),
      FoodModel(
        food_id: 23,
        food_name: 'Bakso Kuah Pedas',
        food_category: 'Bakso',
        food_type: 'Bakso kuah super pedas',
        food_weight: 300,
        food_quantity: 10,
        food_image:
        'https://cdn.idntimes.com/content-images/post/20240611/snapinstaapp-42003823-241325386729135-1009400321390767005-n-1080-950c242e80d9295be7ef8dabbe12b8ab_600x400.jpg',
        food_description: 'Bakso dengan kuah pedas yang menggugah selera',
      ),
      FoodModel(
        food_id: 24,
        food_name: 'Bakso Goreng',
        food_category: 'Bakso',
        food_type: 'Bakso goreng renyah',
        food_weight: 200,
        food_quantity: 12,
        food_image:
        'https://asset.kompas.com/crops/YhyVl2Yi4elqlkSc0xWy6gxEMT0=/0x0:1000x667/750x500/data/photo/2021/08/29/612ae4c73f1cd.jpeg',
        food_description: 'Bakso goreng dengan tekstur renyah di luar',
      ),
      FoodModel(
        food_id: 25,
        food_name: 'Bakso Tahu',
        food_category: 'Bakso',
        food_type: 'Bakso tahu campur',
        food_weight: 350,
        food_quantity: 8,
        food_image:
        'https://asset.kompas.com/crops/EVrkqpkbpWEAxfuov_spqCxhuco=/0x404:667x848/1200x800/data/photo/2023/03/09/64091bf4b8300.jpeg',
        food_description: 'Bakso dengan campuran tahu yang lezat',
      ),
    ];
    notifyListeners();
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Avatar and User Info
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(
                        "https://siakad.plb.ac.id/siamhs/photos/202302056.jpg?17110",
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Muhamad Ali",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "muhamad13aliakbar@gmail.com",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Profile Options
            _buildProfileOption(context, Icons.person, "Edit Profile", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helper function to build profile options
  Widget _buildProfileOption(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        size: 28,
        color: Colors.redAccent,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      splashColor: Colors.red[100],
      hoverColor: Colors.red[50],
    );
  }

  // Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              // Perform logout action here
              Navigator.pop(context); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SplashPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }
}

// Edit Profile Page
class EditProfilePage extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController(text: "Muhamad Ali");
  final TextEditingController _emailController = TextEditingController(text: "muhamad13aliakbar@gmail.com");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar Section
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                  "https://siakad.plb.ac.id/siamhs/photos/202302056.jpg?17110",
                ),
              ),
            ),
            SizedBox(height: 20),

            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Email Field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: () {
                // Save changes logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Profile updated successfully!")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text("Save Changes", style: TextStyle(color: Colors.white),),

            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Colors.redAccent, // Warna biru sesuai tema
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Section
            Text(
              "Account",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),

            // Opsi Change Password
            _buildProfileOption(
              context,
              Icons.lock,
              "Change Password",
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordPage(),
                  ),
                );
              },
            ),

            // Opsi Notifications
            _buildProfileOption(
              context,
              Icons.notifications,
              "Notifications",
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsSettingsPage(),
                  ),
                );
              },
            ),


            SizedBox(height: 20),

            // Judul Section Logout
            Text(
              "Other",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),

            // Opsi Logout
            _buildProfileOption(
              context,
              Icons.logout,
              "Logout",
                  () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build profile options
  Widget _buildProfileOption(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        size: 28,
        color: Colors.redAccent,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      splashColor: Colors.red[100], // Efek ripple kuning
      hoverColor: Colors.red[50], // Efek hover kuning (untuk web)
    );
  }

  // Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Perform logout action here
              Navigator.pop(context); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SplashPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Placeholder Pages for Navigation
class ChangePasswordPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Password"),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Change Your Password",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Current Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your current password";
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_open),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a new password";
                  } else if (value.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm New Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please confirm your new password";
                  } else if (value != _newPasswordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Simpan perubahan password di sini
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Password changed successfully!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationsSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications Settings"),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Manage Your Notifications",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildNotificationOption(context, Icons.notifications, "Order Updates", true),
            _buildNotificationOption(context, Icons.email, "Promotions", false),
            _buildNotificationOption(context, Icons.message, "Messages", true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Simpan pengaturan notifikasi di sini
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Notification settings saved!")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                "Save Changes",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption(BuildContext context, IconData icon, String title, bool initialValue) {
    bool isSwitched = initialValue;
    return ListTile(
      leading: Icon(icon, size: 28, color: Colors.redAccent),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Switch(
        value: isSwitched,
        onChanged: (value) {
          // Update state switch
          isSwitched = value;
        },
        activeColor: Colors.redAccent,
      ),
    );
  }
}




