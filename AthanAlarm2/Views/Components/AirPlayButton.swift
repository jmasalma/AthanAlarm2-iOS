import SwiftUI
import AVKit

#if canImport(UIKit)
import UIKit

public struct AirPlayButton: UIViewRepresentable {
    public init() {}

    public func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = .clear
        routePickerView.tintColor = UIColor(Color(hex: "0E3A2F"))
        routePickerView.activeTintColor = UIColor(Color(hex: "E6C280"))
        routePickerView.prioritizesVideoDevices = false
        return routePickerView
    }

    public func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = UIColor(Color(hex: "0E3A2F"))
        uiView.activeTintColor = UIColor(Color(hex: "E6C280"))
    }
}
#else
public struct AirPlayButton: View {
    public init() {}
    public var body: some View {
        Image(systemName: "airplayaudio")
    }
}
#endif
