import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/auth_redirect.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/mara_theme.dart';
import '../../../shared/widgets/cashea_brand.dart';
import '../../admin/providers/admin_providers.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/providers/orders_providers.dart';
import '../data/catalog_repository.dart';
import '../domain/models/catalog_models.dart';
import '../../auth/presentation/widgets/account_continue_sheet.dart';
import '../../branches/providers/branches_provider.dart';
import '../providers/cart_provider.dart';
import 'widgets/account_tab_view.dart';
import 'widgets/ai_chat_sheet.dart';
import 'widgets/category_chip_bar.dart';
import 'widgets/checkout_sheet.dart';
import 'widgets/home_advertising_section.dart';
import 'widgets/home_header.dart';
import 'widgets/order_success_sheet.dart';
import 'widgets/product_card.dart';
import 'widgets/product_section_row.dart';
import 'widgets/prescription_scan_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.initialTab = 0,
    this.resumeCheckout = false,
  });

  final int initialTab;
  final bool resumeCheckout;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentTab;
  String? _selectedCategorySlug;
  String _search = '';
  final _searchController = TextEditingController();
  bool _checkoutResumeHandled = false;
  int _notificationsCount = 3;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    if (widget.resumeCheckout) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryResumeCheckout();
      });
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      _currentTab = widget.initialTab;
    }
    if (widget.resumeCheckout && !oldWidget.resumeCheckout) {
      _checkoutResumeHandled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryResumeCheckout();
      });
    }
  }

  void _tryResumeCheckout() {
    if (_checkoutResumeHandled || !mounted) return;

    final auth = ref.read(adminAuthProvider);
    if (!auth.isReady) return;

    if (!auth.isAuthenticated || ref.read(cartProvider).isEmpty) return;

    _checkoutResumeHandled = true;
    if (mounted) {
      setState(() => _currentTab = 2);
    }
    _clearCheckoutQueryParams();
    _handleCheckout();
  }

  void _clearCheckoutQueryParams() {
    final params = GoRouterState.of(context).uri.queryParameters;
    if (params['checkout'] == '1') {
      context.go(params['cart'] == '1' ? '/home?cart=1' : '/home');
    }
  }

  ProductQuery get _query => ProductQuery(
        categorySlug: _selectedCategorySlug,
        search: _search.isEmpty ? null : _search,
      );

  bool get _isFiltered => _query.isFiltered;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    final error = ref.read(cartProvider.notifier).addProduct(product);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: MaraColors.rose,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡${product.name} agregado al carrito!'),
        duration: const Duration(seconds: 1),
        backgroundColor: MaraColors.green,
      ),
    );
  }

  Future<void> _handleCheckout() async {
    final items = ref.read(cartProvider);
    if (items.isEmpty) return;

    final auth = ref.read(adminAuthProvider);
    if (!auth.isAuthenticated) {
      final goLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Inicia sesión',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Para completar tu compra necesitas una cuenta Farma Express. '
            'Puedes iniciar sesión o registrarte en segundos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ir a login'),
            ),
          ],
        ),
      );

      if (goLogin == true && mounted) {
        context.go(
          AuthRedirect.storeLoginPath(redirect: AuthRedirect.checkoutReturnPath),
        );
      }
      return;
    }

    if (ref.read(adminAuthProvider).session?.user.role != 'CUSTOMER') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Las compras en la tienda están disponibles para cuentas de paciente.',
          ),
          backgroundColor: MaraColors.rose,
        ),
      );
      return;
    }

    final subtotal = ref.read(cartProvider.notifier).totalPrice;
    final branches = ref.read(branchesProvider).valueOrNull ?? [];
    final selectedBranch = ref.read(selectedBranchProvider);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CheckoutSheet(
        items: items,
        subtotal: subtotal,
        branches: branches,
        selectedBranch: selectedBranch,
        onConfirm: ({
          required fulfillmentType,
          required branchId,
          deliveryAddress,
          notes,
        }) async {
          try {
            final order = await ref.read(ordersRepositoryProvider).checkout(
                  items: items
                      .map(
                        (item) => CheckoutItem(
                          productId: item.product.id,
                          quantity: item.quantity,
                        ),
                      )
                      .toList(),
                  fulfillmentType: fulfillmentType,
                  branchId: branchId,
                  deliveryAddress: deliveryAddress,
                  notes: notes,
                );

            await ref.read(cartProvider.notifier).clear();
            ref.invalidate(myOrdersProvider);
            if (!mounted) return;
            _showOrderSuccess(order);
          } on ApiException catch (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.message),
                backgroundColor: MaraColors.rose,
              ),
            );
            rethrow;
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo procesar el pedido'),
                backgroundColor: MaraColors.rose,
              ),
            );
            rethrow;
          }
        },
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _currentTab = 0);
    }
  }

  void _showOrderSuccess(Order order) {
    OrderSuccessSheet.show(context, order);
  }

  Future<void> _enterMedicPlus() async {
    final auth = ref.read(adminAuthProvider);

    void goMedicPlus() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/medic-plus');
      });
    }

    void goMedicLogin() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(AuthRedirect.medicPlusLoginPath(redirect: '/medic-plus'));
      });
    }

    if (auth.isAuthenticated && auth.session?.user.role == 'CUSTOMER') {
      final useSession = await AccountContinueSheet.show(
        context,
        user: auth.session!.user,
        title: '¿Entrar a Medic Express?',
        subtitle:
            'Puedes usar la misma cuenta con la que compras en la tienda.',
        confirmLabel: 'Entrar a Medic Express',
        showPasswordHint: true,
      );

      if (!mounted) return;

      if (useSession == true) {
        goMedicPlus();
        return;
      }

      if (useSession == false) {
        await ref.read(adminAuthProvider.notifier).logout();
        if (!mounted) return;
        goMedicLogin();
      }
      return;
    }

    if (!auth.isAuthenticated) {
      goMedicLogin();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medic Express está disponible para cuentas de paciente.'),
        backgroundColor: MaraColors.rose,
      ),
    );
  }

  Map<String, List<Product>> _groupByCategory(List<Product> products) {
    final map = <String, List<Product>>{};
    for (final product in products) {
      map.putIfAbsent(product.category.slug, () => []).add(product);
    }
    return map;
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: MaraColors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificaciones',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: MaraColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Mantente al día con tus pedidos y promociones',
                          style: TextStyle(
                            fontSize: 12,
                            color: MaraColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _NotificationItem(
                title: '¡Pedido Despachado! 📦',
                body: 'Tu compra en la sucursal ha sido procesada con éxito y está lista para retiro.',
                time: 'Hace 10 minutos',
                isNew: true,
              ),
              const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
              const _NotificationItem(
                title: 'Nueva promoción ✦',
                body: 'Obtén 15% de descuento en medicamentos seleccionados usando tu seguro Medic Express.',
                time: 'Hace 2 horas',
                isNew: true,
              ),
              const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
              const _NotificationItem(
                title: 'Bienvenido a Farma Express 🎉',
                body: 'Explora nuestra app, agenda consultas médicas virtuales y compra en nuestra tienda.',
                time: 'Ayer',
                isNew: false,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: MaraColors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScanModal(BuildContext context) {
    PrescriptionScanSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resumeCheckout) {
      ref.listen(adminAuthProvider, (previous, next) {
        if (next.isReady &&
            next.isAuthenticated &&
            !_checkoutResumeHandled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _tryResumeCheckout();
          });
        }
      });
    }

    ref.listen(selectedBranchProvider, (previous, next) {
      if (previous?.id != next?.id) {
        ref.invalidate(productsProvider(_query));
        ref.invalidate(homeProductsProvider);
        ref.invalidate(featuredProductsProvider);
      }
    });

    ref.listen(productsProvider(_query), (previous, next) {
      next.whenData((products) {
        ref.read(cartProvider.notifier).syncStockFromCatalog(products);
      });
    });

    ref.listen(homeProductsProvider, (previous, next) {
      next.whenData((products) {
        ref.read(cartProvider.notifier).syncStockFromCatalog(products);
      });
    });

    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold(0, (sum, item) => sum + item.quantity);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider(_query));
    final homeProductsAsync = ref.watch(homeProductsProvider);
    final catalogAsync = _isFiltered ? productsAsync : homeProductsAsync;
    final heroBannersAsync = ref.watch(heroBannersProvider);
    final stripBannersAsync = ref.watch(stripBannersProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _currentTab == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: const BoxDecoration(
                  color: MaraColors.green,
                  shape: BoxShape.circle,
                ),
                child: FloatingActionButton(
                  onPressed: () => AiChatSheet.show(context),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  highlightElevation: 0,
                  tooltip: 'Preguntar a Expressia (IA)',
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        color: MaraColors.green,
        backgroundColor: Colors.white,
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(branchesProvider);
          ref.invalidate(productsProvider(_query));
          ref.invalidate(homeProductsProvider);
          ref.invalidate(heroBannersProvider);
          ref.invalidate(stripBannersProvider);
          ref.invalidate(featuredProductsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Sticky Header (Siempre visible para búsqueda e íconos) ───
            SliverToBoxAdapter(
              child: HomeHeader(
                searchController: _searchController,
                search: _search,
                onSearchChanged: (value) {
                  setState(() {
                    _search = value.trim();
                    if (_search.isNotEmpty && _currentTab == 1) {
                      // Si busca mientras está en pestaña categorías, volvemos a inicio filtrado
                      _currentTab = 0;
                    }
                  });
                },
                onClearSearch: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
                onAdminTap: null,
                onCartTap: () => setState(() => _currentTab = 2),
                onScanTap: () => _showScanModal(context),
                onNotificationsTap: () {
                  setState(() => _notificationsCount = 0);
                  _showNotifications(context);
                },
                cartCount: cartCount,
                notificationsCount: _notificationsCount,
              ),
            ),

            // ─── PESTAÑA 1: CATEGORÍAS DEDICADAS ───
            if (_currentTab == 1) ...[
              if (_selectedCategorySlug == null) ...[
                // ── Hero banner de categorías ──
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF007A46),
                          Color(0xFF00B96B),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Icono flotante tenue
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Icon(
                            Icons.grid_view_outlined,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        // Contenido principal
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Farma Express',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Explora nuestras\ncategorías',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Todo lo que necesitas, en un solo lugar',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Lista de categorías ──
                categoriesAsync.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: MaraColors.navyMid)),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(error: error, onRetry: _refreshAll),
                  ),
                  data: (categories) => SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CategoryListCard(
                              category: category,
                              onTap: () {
                                setState(() {
                                  _selectedCategorySlug = category.slug;
                                });
                              },
                            ),
                          );
                        },
                        childCount: categories.length,
                      ),
                    ),
                  ),
                ),

              ] else ...[
                // Vista de productos filtrados dentro de Categorías
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() {
                            _selectedCategorySlug = null;
                          }),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: MaraColors.navy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCategorySlug!.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: MaraColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                productsAsync.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: MaraColors.navyMid)),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(error: error, onRetry: _refreshAll),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          message: 'No hay productos en esta categoría',
                          onClear: () {
                            setState(() {
                              _selectedCategorySlug = null;
                            });
                          },
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.54,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = products[index];
                            return ProductCard(
                              product: product,
                              onAdd: () => _addToCart(product),
                            );
                          },
                          childCount: products.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ]

            // ─── PESTAÑA 2: CARRITO PLACEHOLDER ───
            else if (_currentTab == 2) ...[
              if (ref.watch(cartProvider).isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: MaraColors.lightBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shopping_bag_outlined,
                                size: 36, color: MaraColors.navyMid),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Tu carrito está vacío',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: MaraColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Explora el catálogo y agrega productos para verlos aquí.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: MaraColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => setState(() => _currentTab = 0),
                            child: const Text('Comprar ahora'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                _CartListView(
                  items: cartItems,
                  onIncrease: (product) {
                    final error =
                        ref.read(cartProvider.notifier).addProduct(product);
                    if (error != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: MaraColors.rose,
                        ),
                      );
                    }
                  },
                  onDecrease: (product) =>
                      ref.read(cartProvider.notifier).decreaseQuantity(product),
                  onRemove: (product) =>
                      ref.read(cartProvider.notifier).removeProduct(product),
                  onCheckout: _handleCheckout,
                )
            ]

            // ─── PESTAÑA 4: MI CUENTA ───
            else if (_currentTab == 3) ...[
              AccountTabView(
                onEnterMedicPlus: _enterMedicPlus,
                onGoShopping: () => setState(() => _currentTab = 0),
              ),
            ]

            // ─── PESTAÑA 0: INICIO (HOME PRINCIPAL) ───
            else ...[
              if (!_isFiltered) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: HomeAdvertisingSection(
                      heroBanners: heroBannersAsync.valueOrNull ?? const [],
                      stripBanners: stripBannersAsync.valueOrNull ?? const [],
                      onMedicPlusTap: _enterMedicPlus,
                      bannersLoading:
                          heroBannersAsync.isLoading || stripBannersAsync.isLoading,
                    ),
                  ),
                ),
              ],

              if (!_isFiltered)
                featuredAsync.when(
                  data: (products) => SliverToBoxAdapter(
                    child: ProductSectionRow(
                      title: 'Nuestros recomendados',
                      subtitle: 'Selección especial Farma Express ✦',
                      products: products,
                      accentColor: MaraColors.green,
                    ),
                  ),
                  loading: () =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

              // Secciones por categorías
              if (!_isFiltered)
                catalogAsync.when(
                  data: (products) {
                    final grouped = _groupByCategory(products);
                    final categoryColors = [
                      MaraColors.navyMid,
                      MaraColors.green,
                      MaraColors.amber,
                      MaraColors.violet,
                    ];
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = grouped.entries.elementAt(index);
                          final categoryName = products
                              .firstWhere((p) => p.category.slug == entry.key)
                              .category
                              .name;
                          return ProductSectionRow(
                            title: categoryName,
                            products: entry.value,
                            onSeeAll: () {
                              setState(() {
                                _selectedCategorySlug = entry.key;
                                _currentTab = 1; // Ir a la pestaña categorías
                              });
                            },
                            accentColor: categoryColors[
                                index % categoryColors.length],
                          );
                        },
                        childCount: grouped.length,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: MaraColors.navyMid)),
                    ),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(error: error, onRetry: _refreshAll),
                  ),
                )
              else ...[
                // Resultados filtrados
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _search.isNotEmpty
                              ? 'Resultados de búsqueda'
                              : 'Productos filtrados',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: MaraColors.textPrimary,
                          ),
                        ),
                        productsAsync.maybeWhen(
                          data: (products) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color:
                                  MaraColors.navyMid.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${products.length} items',
                              style: const TextStyle(
                                color: MaraColors.navyMid,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                productsAsync.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: MaraColors.navyMid)),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(error: error, onRetry: _refreshAll),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          message: _search.isNotEmpty
                              ? 'Sin resultados para "$_search"'
                              : 'No hay productos en esta categoría',
                          onClear: () {
                            _searchController.clear();
                            setState(() {
                              _search = '';
                              _selectedCategorySlug = null;
                            });
                          },
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.54,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = products[index];
                            return ProductCard(
                              product: product,
                              onAdd: () => _addToCart(product),
                            );
                          },
                          childCount: products.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: MaraColors.navy.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: Colors.white,
          indicatorColor: MaraColors.greenLight,
          overlayColor: WidgetStatePropertyAll(
            MaraColors.green.withValues(alpha: 0.08),
          ),
          selectedIndex: _currentTab >= 2 ? _currentTab + 1 : _currentTab,
          onDestinationSelected: (index) {
            if (index == 2) {
              _enterMedicPlus();
              return;
            }
            setState(() {
              _currentTab = index > 2 ? index - 1 : index;
              if (index != 1) {
                _selectedCategorySlug = null;
              }
            });
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: MaraColors.green),
              label: 'Inicio',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded, color: MaraColors.green),
              label: 'Categorías',
            ),
            const NavigationDestination(
              icon: Icon(Icons.local_hospital_outlined),
              selectedIcon: Icon(Icons.local_hospital_rounded, color: MaraColors.green),
              label: 'Medic',
            ),
            const NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined, color: MaraColors.green),
              selectedIcon: Icon(Icons.shopping_bag_rounded, color: MaraColors.green),
              label: 'Carrito',
            ),
            NavigationDestination(
              icon: Icon(
                ref.watch(adminAuthProvider).isAuthenticated
                    ? Icons.person_outline_rounded
                    : Icons.person_outline_rounded,
              ),
              selectedIcon: const Icon(Icons.person_rounded, color: MaraColors.green),
              label: ref.watch(adminAuthProvider).isAuthenticated
                  ? 'Mi cuenta'
                  : 'Cuenta',
            ),
          ],
        ),
      ),
    );
  }

  void _refreshAll() {
    ref.invalidate(categoriesProvider);
    ref.invalidate(productsProvider(_query));
    ref.invalidate(homeProductsProvider);
    ref.invalidate(heroBannersProvider);
    ref.invalidate(stripBannersProvider);
    ref.invalidate(featuredProductsProvider);
  }
}

// ─────────────────────────────────────────────
//  CATEGORY LIST CARD (nuevo diseño premium)
// ─────────────────────────────────────────────
class _CategoryListCard extends StatefulWidget {
  const _CategoryListCard({
    required this.category,
    required this.onTap,
  });

  final Category category;
  final VoidCallback onTap;

  @override
  State<_CategoryListCard> createState() => _CategoryListCardState();
}

class _CategoryListCardState extends State<_CategoryListCard> {
  static Color _accentForSlug(String slug) {
    return switch (slug) {
      'farmacia' => const Color(0xFF00A651),
      'panaderia' => const Color(0xFFF59E0B),
      'mascotas' => const Color(0xFF7C3AED),
      'alimentos-bebidas' => MaraColors.green,
      _ => MaraColors.navyMid,
    };
  }

  static Color _bgForSlug(String slug) {
    return switch (slug) {
      'farmacia' => const Color(0xFFE6F9F1),
      'panaderia' => const Color(0xFFFFF8E6),
      'mascotas' => const Color(0xFFF3EEFF),
      'alimentos-bebidas' => const Color(0xFFE8F0FF),
      _ => const Color(0xFFF0F4FF),
    };
  }

  static String _tagForSlug(String slug) {
    return switch (slug) {
      'farmacia' => 'Salud',
      'panaderia' => 'Alimentación',
      'mascotas' => 'Mascotas',
      'alimentos-bebidas' => 'Mercado',
      _ => 'Categoría',
    };
  }

  @override
  Widget build(BuildContext context) {
    final slug = widget.category.slug;
    final accent = _accentForSlug(slug);
    final bg = _bgForSlug(slug);
    final icon = CategoryChipBar.iconForSlug(slug);
    final subtitle = widget.category.description ??
        CategoryChipBar.subtitleForSlug(slug);
    final tag = _tagForSlug(slug);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1628).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono container (limpio, contorno circular minimalista)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF0A1628),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MaraColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Flecha (chevron clásico minimalista)
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────
//  ERROR STATE
// ─────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: MaraColors.roseLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 36, color: MaraColors.rose),
            ),
            const SizedBox(height: 20),
            const Text(
              'No pudimos cargar el catálogo',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: MaraColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MaraColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: MaraColors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onClear});

  final String message;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: MaraColors.lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 36, color: MaraColors.navyMid),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: MaraColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                foregroundColor: MaraColors.navyMid,
                side: const BorderSide(color: MaraColors.navyMid),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Limpiar filtros',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHIMMER LOADERS
// ─────────────────────────────────────────────
class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({required this.height, this.margin});

  final double height;
  final EdgeInsets? margin;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 1.5).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      margin: widget.margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(_shimmer.value - 1, 0),
                end: Alignment(_shimmer.value, 0),
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                  Colors.grey.shade200,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerCircle extends StatefulWidget {
  const _ShimmerCircle();

  @override
  State<_ShimmerCircle> createState() => _ShimmerCircleState();
}

class _ShimmerCircleState extends State<_ShimmerCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CARRITO LIST VIEW
// ─────────────────────────────────────────────
class _CartListView extends StatelessWidget {
  const _CartListView({
    required this.items,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onCheckout,
  });

  final List<CartItem> items;
  final ValueChanged<Product> onIncrease;
  final ValueChanged<Product> onDecrease;
  final ValueChanged<Product> onRemove;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    for (final item in items) {
      subtotal += item.product.finalPrice * item.quantity;
    }
    final delivery = subtotal > 20 ? 0.0 : 2.0;
    final total = subtotal + delivery;

    final itemCount = items.fold(0, (sum, item) => sum + item.quantity);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Tu Carrito ($itemCount)',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: MaraColors.navy,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEEF2F7)),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: ProductImage(
                            imageUrl: item.product.imageUrl,
                            categorySlug: item.product.category.slug,
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: MaraColors.textPrimary,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${item.product.finalPrice.toStringAsFixed(2)} c/u',
                              style: const TextStyle(
                                fontSize: 13,
                                color: MaraColors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _QtyButton(
                                  icon: Icons.remove_rounded,
                                  onTap: () => onDecrease(item.product),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: MaraColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _QtyButton(
                                  icon: Icons.add_rounded,
                                  onTap: item.quantity >= item.product.stock
                                      ? null
                                      : () => onIncrease(item.product),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => onRemove(item.product),
                                  child: const Text(
                                    'Eliminar',
                                    style: TextStyle(
                                      color: MaraColors.rose,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Cashea — card amarilla suave
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFF00),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  const CasheaBadge(height: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Paga una inicial y el resto en cuotas sin interés. Disponible al finalizar.',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.82),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MaraColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFE0CC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen del pedido',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: MaraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(label: 'Subtotal', value: '\$${subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Envío',
                    value: delivery == 0 ? 'Gratis' : '\$${delivery.toStringAsFixed(2)}',
                    isFree: delivery == 0,
                  ),
                  const Divider(height: 24, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: MaraColors.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: MaraColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Con Cashea desde \$${(total * 0.3).clamp(1, total).toStringAsFixed(2)} hoy',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MaraColors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continuar al pago',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFF8FAFC)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? MaraColors.textTertiary
              : MaraColors.textPrimary,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.isFree = false});

  final String label;
  final String value;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, color: MaraColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isFree ? MaraColors.green : MaraColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.isNew,
  });

  final String title;
  final String body;
  final String time;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNew)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: MaraColors.green,
                shape: BoxShape.circle,
              ),
            ),
          )
        else
          const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  color: MaraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
                  color: MaraColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: MaraColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
