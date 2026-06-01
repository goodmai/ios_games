#if canImport(WidgetKit)
import WidgetKit
import SwiftUI

/// Entry point for the Control Center widget extension (Epic E4).
@main
struct MorseLightWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 18.0, *) {
            MorseTorchControl()
        }
    }
}
#endif
</content>
