import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _users = [];
  String _selectedFilter = 'todos';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await DatabaseService.getAllUsers();
      
      if (mounted) {
        setState(() {
          _users = users.map((u) => {
            ...u,
            'nombre': u['nombre_completo'] ?? 'Sin nombre',
            'estado': u['estado'] ?? 'activo',
            'created_at': u['created_at'] != null ? DateTime.parse(u['created_at']) : DateTime.now(),
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var filtered = _users;
    if (_selectedFilter != 'todos') {
      filtered = filtered.where((u) => u['rol'] == _selectedFilter).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((u) =>
        u['nombre'].toLowerCase().contains(query) ||
        u['email'].toLowerCase().contains(query)
      ).toList();
    }
    return filtered;
  }

  void _toggleUserStatus(Map<String, dynamic> user) {
    setState(() {
      user['estado'] = user['estado'] == 'activo' ? 'inactivo' : 'activo';
    });
    // TODO: Actualizar en Supabase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Usuario ${user['estado'] == 'activo' ? 'activado' : 'desactivado'}'),
        backgroundColor: const Color(0xFF555879),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: AppBar(
        title: const Text(
          'Gestion de Usuarios',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF555879),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o email...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF98A1BC)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF98A1BC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF98A1BC)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['todos', 'cliente', 'tecnico'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter == 'todos' ? 'Todos' : filter == 'cliente' ? 'Clientes' : 'Tecnicos',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF555879),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['estado'] == 'activo';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF98A1BC)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF555879),
            child: Text(
              user['nombre'].substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user['nombre'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555879),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: user['rol'] == 'tecnico'
                            ? const Color(0xFF27AE60).withOpacity(0.2)
                            : const Color(0xFF3498DB).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user['rol'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: user['rol'] == 'tecnico'
                              ? const Color(0xFF27AE60)
                              : const Color(0xFF3498DB),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  user['email'],
                  style: const TextStyle(fontSize: 12, color: Color(0xFF98A1BC)),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (_) => _toggleUserStatus(user),
            activeColor: const Color(0xFF27AE60),
          ),
        ],
      ),
    );
  }
}
