import 'package:flutter/cupertino.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/ui/common/modals//fullscreen_video_viewer.dart';
import 'package:wonders/ui/common/modals/fullscreen_maps_viewer.dart';
import 'package:wonders/ui/screens/artifact/artifact_carousel/artifact_carousel_screen.dart';
import 'package:wonders/ui/screens/artifact/artifact_details/artifact_details_screen.dart';
import 'package:wonders/ui/screens/artifact/artifact_search/artifact_search_screen.dart';
import 'package:wonders/ui/screens/collection/collection_screen.dart';
import 'package:wonders/ui/screens/home/wonders_home_screen.dart';
import 'package:wonders/ui/screens/intro/intro_screen.dart';
import 'package:wonders/ui/screens/timeline/timeline_screen.dart';
import 'package:wonders/ui/screens/wallpaper_photo/wallpaper_photo_screen.dart';
import 'package:wonders/ui/screens/wonder_details/wonders_details_screen.dart';

/// Shared paths / urls used across the app
class ScreenPaths {
  static String splash = '/';
  static String intro = '/welcome';
  static String home = '/home';
  static String settings = '/settings';
  static String wonderDetails(WonderType type, {int tabIndex = 0}) => '/wonder/${type.name}?t=$tabIndex';
  static String video(String id) => '/video/$id';
  static String highlights(WonderType type) => '/highlights/${type.name}';
  static String search(WonderType type) => '/search/${type.name}';
  static String artifact(String id) => '/artifact/$id';
  static String collection(String id) => '/collection?id=$id';
  static String maps(WonderType type) => '/maps/${type.name}';
  static String timeline(WonderType? type) => '/timeline?type=${type?.name ?? ''}';
  static String wallpaperPhoto(WonderType type) => '/wallpaperPhoto/${type.name}';
}

/// Routing table, matches string paths to UI Screens, optionally parses params from the paths
final appRouter = GoRouter(
  redirect: _handleRedirect,
  routes: [
    ShellRoute(
        builder: (context, router, navigator) {
          return WondersAppScaffold(child: navigator);
        },
        routes: [
          AppRoute(ScreenPaths.splash, (_) => Container(color: $styles.colors.greyStrong)), // This will be hidden
          AppRoute(ScreenPaths.home, (_) => LogScreenView(HomeScreen(), screenName: 'home_screen')),
          AppRoute(ScreenPaths.intro, (_) => LogScreenView(IntroScreen(), screenName: 'intro_screen')),
          AppRoute('/wonder/:type', (s) {
            int tab = int.tryParse(s.queryParams['t'] ?? '') ?? 0;
            return LogScreenView(
              WonderDetailsScreen(
                type: _parseWonderType(s.params['type']),
                initialTabIndex: tab,
              ),
              screenName: 'wonder_details_screen',
            );
          }, useFade: true),
          AppRoute('/timeline', (s) {
            return LogScreenView(
              TimelineScreen(type: _tryParseWonderType(s.queryParams['type']!)),
              screenName: 'timeline_screen',
            );
          }),
          AppRoute('/video/:id', (s) {
            return LogScreenView(
              FullscreenVideoViewer(id: s.params['id']!),
              screenName: 'fullscreen_video_viewer',
            );
          }),
          AppRoute('/highlights/:type', (s) {
            return LogScreenView(
              ArtifactCarouselScreen(type: _parseWonderType(s.params['type'])),
              screenName: 'artifact_carousel_screen',
            );
          }),
          AppRoute('/search/:type', (s) {
            return LogScreenView(
              ArtifactSearchScreen(type: _parseWonderType(s.params['type'])),
              screenName: 'artifact_serach_screen',
            );
          }),
          AppRoute('/artifact/:id', (s) {
            return LogScreenView(
              ArtifactDetailsScreen(artifactId: s.params['id']!),
              screenName: 'artifact_details_screen',
            );
          }),
          AppRoute('/collection', (s) {
            return LogScreenView(
              CollectionScreen(fromId: s.queryParams['id'] ?? ''),
              screenName: 'collection_screen',
            );
          }),
          AppRoute('/maps/:type', (s) {
            return LogScreenView(
              FullscreenMapsViewer(type: _parseWonderType(s.params['type'])),
              screenName: 'fullscreen_maps_viewer',
            );
          }),
          AppRoute('/wallpaperPhoto/:type', (s) {
            return LogScreenView(
              WallpaperPhotoScreen(type: _parseWonderType(s.params['type'])),
              screenName: 'wallpaper_photo_screen',
            );
          }),
        ]),
  ],
);

/// Custom GoRoute sub-class to make the router declaration easier to read
class AppRoute extends GoRoute {
  AppRoute(String path, Widget Function(GoRouterState s) builder,
      {List<GoRoute> routes = const [], this.useFade = false})
      : super(
          path: path,
          routes: routes,
          pageBuilder: (context, state) {
            final pageContent = Scaffold(
              body: builder(state),
              resizeToAvoidBottomInset: false,
            );
            if (useFade) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: pageContent,
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            }
            return CupertinoPage(child: pageContent);
          },
        );
  final bool useFade;
}

String? _handleRedirect(BuildContext context, GoRouterState state) {
  // Prevent anyone from navigating away from `/` if app is starting up.
  if (!appLogic.isBootstrapComplete && state.location != ScreenPaths.splash) {
    return ScreenPaths.splash;
  }
  debugPrint('Navigate to: ${state.location}');
  return null; // do nothing
}

WonderType _parseWonderType(String? value) {
  const fallback = WonderType.chichenItza;
  if (value == null) return fallback;
  return _tryParseWonderType(value) ?? fallback;
}

WonderType? _tryParseWonderType(String value) => WonderType.values.asNameMap()[value];

class LogScreenView extends StatelessWidget with GetItMixin {
  LogScreenView(this.child, {super.key, required this.screenName});

  final Widget child;
  final String screenName;

  @override
  Widget build(BuildContext context) {
    getX((AnalyticsLogic a) => a).logScreenView(screenName: screenName);
    return child;
  }
}
