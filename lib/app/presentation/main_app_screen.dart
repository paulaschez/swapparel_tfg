import 'package:chat_app/app/config/theme/app_theme.dart';
import 'package:chat_app/features/chat/presentation/screens/conversations_screen.dart';
import 'package:chat_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flutter/material.dart';
//import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0; // Estado para el índice seleccionado (0: Feed por defecto)

  Widget _buildProfileScreen() {
    return ProfileScreen( isCurrentUserProfile: true);
  }

  late final List<Widget> _widgetOptions;

 @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const FeedScreen(), 
      const ChatListScreen(),
      _buildProfileScreen(), // Llama al método para construir ProfileScreen
    ];
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El body cambia según el índice seleccionado
      body: LayoutBuilder(
        
        builder: (context, constraints) {

        if(constraints.maxWidth < 500){
          // --- Pantallas Estrechas (Móviles) ---
          return Column(children: [
            Expanded(child:_widgetOptions.elementAt(_selectedIndex) ),
            Theme(
        data: Theme.of(context).copyWith(
          highlightColor: AppColors.primaryGreen.withValues(alpha: 0.1), 
          splashColor: AppColors.darkGreen.withValues(alpha: 0.1),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex, 
          onTap: _onItemTapped,      
          
          // --- Ítems con lógica de icono lleno/contorno ---
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              // Elige el icono basado en si este item (índice 0) está seleccionado
              icon: Icon(_selectedIndex == 0 ? Icons.home_filled : Icons.home_outlined),
              label: 'Feed', // La etiqueta es útil para accesibilidad aunque no se muestre
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 1 ? Icons.chat_bubble : Icons.chat_bubble_outline),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 2 ? Icons.person : Icons.person_outline),
              label: 'Perfil',
            ),
          ],
        ),)
          ],);
        }
        // --- Pantallas Anchas (Tablet/Escritorio) ---
          else {
            return Row( 
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                     highlightColor: AppColors.darkGreen.withAlpha(50),
                  ),
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 800,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                    backgroundColor: Theme.of(context).colorScheme.primary, 
                    selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.surface),
                    selectedLabelTextStyle: TextStyle(color: Theme.of(context).colorScheme.surface),
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
                        label: Text('Feed'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_selectedIndex == 1 ? Icons.chat_bubble : Icons.chat_bubble_outline),
                        label: Text('Chat'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_selectedIndex == 2 ? Icons.person : Icons.person_outline),
                        label: Text('Perfil'),
                      ),
                    ],
                  ),
                ),
                Expanded( 
                  child: _widgetOptions.elementAt(_selectedIndex),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
