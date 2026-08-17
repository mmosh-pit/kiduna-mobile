enum NavMode {
  none,
  collapse,
  traverse,
  page;

  static NavMode fromUrl(String? value) => switch (value) {
        'off' => NavMode.none,
        'page' => NavMode.page,
        'traverse' => NavMode.traverse,
        _ => NavMode.collapse,
      };
}

const collapseBelowZoom = 0.7;
const demoMinZoom = 0.34;
const clustersPerPage = 5;
int clustersPerView = 5;
const traverseEnterZoom = 1.0;
const traverseDriftZoom = 0.965;
const traverseArriveZoom = 1.035;
const traverseTravelSeconds = 0.72;
