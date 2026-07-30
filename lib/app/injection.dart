/// Dependency injection — register all providers here.
///
/// Feature controllers may live in their own feature folder but must be
/// re-exported from this file so there is a single lookup point.
library;

export '../features/field/controllers/field_controller.dart'
    show fieldControllerProvider;
