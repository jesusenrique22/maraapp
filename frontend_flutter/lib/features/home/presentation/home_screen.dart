import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/auth_redirect.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/mara_theme.dart';
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
import 'widgets/banner_carousel.dart';
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
            'Para completar tu compra necesitas una cuenta MaraPlus. '
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

    if (auth.isAuthenticated && auth.session?.user.role == 'CUSTOMER') {
      final useSession = await AccountContinueSheet.show(
        context,
        user: auth.session!.user,
        title: '¿Entrar a Medic Plus?',
        subtitle:
            'Puedes usar la misma cuenta con la que compras en la tienda.',
        confirmLabel: 'Entrar a Medic Plus',
        showPasswordHint: true,
      );

      if (!mounted) return;

      if (useSession == true) {
        context.go('/medic-plus');
        return;
      }

      if (useSession == false) {
        await ref.read(adminAuthProvider.notifier).logout();
        if (!mounted) return;
        context.go(AuthRedirect.medicPlusLoginPath(redirect: '/medic-plus'));
      }
      return;
    }

    if (!auth.isAuthenticated) {
      context.go(AuthRedirect.medicPlusLoginPath(redirect: '/medic-plus'));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medic Plus está disponible para cuentas de paciente.'),
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
                body: 'Obtén 15% de descuento en medicamentos seleccionados usando tu seguro Medic Plus.',
                time: 'Hace 2 horas',
                isNew: true,
              ),
              const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
              const _NotificationItem(
                title: 'Bienvenido a MaraPlus 🎉',
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
                    backgroundColor: MaraColors.navyMid,
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
        ref.invalidate(featuredProductsProvider);
      }
    });

    ref.listen(productsProvider(_query), (previous, next) {
      next.whenData((products) {
        ref.read(cartProvider.notifier).syncStockFromCatalog(products);
      });
    });

    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold(0, (sum, item) => sum + item.quantity);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider(_query));
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
                  color: MaraColors.navyAccent,
                  shape: BoxShape.circle,
                ),
                child: FloatingActionButton(
                  onPressed: () => AiChatSheet.show(context),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  highlightElevation: 0,
                  tooltip: 'Preguntar a Maraia (IA)',
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        color: MaraColors.navyMid,
        backgroundColor: Colors.white,
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(branchesProvider);
          ref.invalidate(productsProvider(_query));
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
                // Cuadrícula principal de Categorías
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Text(
                      'Descubre nuestras categorías',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: MaraColors.navy,
                          ),
                    ),
                  ),
                ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.92,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = categories[index];
                          return _CategoryGridCard(
                            category: category,
                            onTap: () {
                              setState(() {
                                _selectedCategorySlug = category.slug;
                              });
                            },
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
                    child: heroBannersAsync.when(
                      data: (hero) => stripBannersAsync.when(
                        data: (strip) => HomeAdvertisingSection(
                          heroBanners: hero,
                          stripBanners: strip,
                          onMedicPlusTap: _enterMedicPlus,
                        ),
                        loading: () => BannerCarousel(banners: hero),
                        error: (_, __) => BannerCarousel(banners: hero),
                      ),
                      loading: () => const _ShimmerBlock(
                        height: 196,
                        margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                      ),
                      error: (_, __) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],

              if (!_isFiltered)
                featuredAsync.when(
                  data: (products) => SliverToBoxAdapter(
                    child: ProductSectionRow(
                      title: 'Nuestros recomendados',
                      subtitle: 'Selección especial MaraPlus ✦',
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
                productsAsync.when(
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
          indicatorColor: MaraColors.lightBlue,
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
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Categorías',
            ),
            const NavigationDestination(
              icon: Icon(Icons.local_hospital_outlined),
              selectedIcon: Icon(Icons.local_hospital_rounded),
              label: 'Medic Plus',
            ),
            const NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag_rounded),
              label: 'Carrito',
            ),
            NavigationDestination(
              icon: Icon(
                ref.watch(adminAuthProvider).isAuthenticated
                    ? Icons.person_outline_rounded
                    : Icons.person_outline_rounded,
              ),
              selectedIcon: const Icon(Icons.person_rounded),
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
    ref.invalidate(heroBannersProvider);
    ref.invalidate(featuredProductsProvider);
  }
}

// ─────────────────────────────────────────────
//  TARJETA DEDICADA DE CATEGORÍAS (GRID)
// ─────────────────────────────────────────────
class _CategoryGridCard extends StatelessWidget {
  const _CategoryGridCard({
    required this.category,
    required this.onTap,
  });

  final Category category;
  final VoidCallback onTap;

  Color _colorForSlug(String slug) {
    return switch (slug) {
      'farmacia' => MaraColors.green,
      'panaderia' => MaraColors.amber,
      'mascotas' => MaraColors.violet,
      _ => MaraColors.navyMid,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForSlug(category.slug);
    final icon = CategoryChipBar.iconForSlug(category.slug);
    final gradient = CategoryChipBar.gradientForSlug(category.slug);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: MaraShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(gradient: gradient),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        icon,
                        size: 72,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    Center(
                      child: Icon(icon, color: Colors.white, size: 40),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.description ??
                        CategoryChipBar.subtitleForSlug(category.slug),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.25,
                      color: MaraColors.textSecondary,
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
                backgroundColor: MaraColors.navyMid,
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
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: MaraShadows.card,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: ProductImage(
                            imageUrl: item.product.imageUrl,
                            categorySlug: item.product.category.slug,
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: MaraColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${item.product.finalPrice.toStringAsFixed(2)} c/u',
                              style: const TextStyle(
                                fontSize: 12,
                                color: MaraColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove_rounded,
                                onTap: () => onDecrease(item.product),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: MaraColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _QtyButton(
                                icon: Icons.add_rounded,
                                onTap: item.quantity >= item.product.stock
                                    ? null
                                    : () => onIncrease(item.product),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => onRemove(item.product),
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(
                                color: MaraColors.rose,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: MaraShadows.elevated,
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
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmar y Finalizar Compra',
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
