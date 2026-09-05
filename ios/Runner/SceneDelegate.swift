import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

}

/// iOS'un ekran kenarı sistem hareketlerini — özellikle alt kenardan aşağı
/// kaydırınca açılan Ulaşılabilirlik ("tek el modu") — ilk kaydırmada erteler.
/// Böylece pul atarken ekran yanlışlıkla aşağı kaymaz. (iOS, Ulaşılabilirliği
/// uygulamadan tamamen KAPATMA API'si sunmaz; bu, sistemin izin verdiği en güçlü
/// engelleme yoludur: ilk kaydırma yutulur, hareket ancak ikinci kaydırmada çalışır.)
class GameFlutterViewController: FlutterViewController {
  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
    return .all
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // iOS'un erteleme değerini yeniden sorgulamasını garantiye al.
    setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
  }
}
