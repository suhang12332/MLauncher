import SwiftUI
import MetalKit

class MetalViewModel: ObservableObject {
    @Published var scale: Float = 1.0
    @Published var rotation = SIMD2<Float>(0, -1.8)
    @Published var skinName: String = "steve-skin" // 默认皮肤名
}

struct MetalView: NSViewRepresentable {
    @ObservedObject var viewModel: MetalViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let mtkView = MetalViewWithScroll(frame: .zero, viewModel: viewModel)
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = true
        let renderer = MetalRenderer(mtkView: mtkView, viewModel: viewModel)
        context.coordinator.renderer = renderer
        mtkView.delegate = renderer
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        if let renderer = context.coordinator.renderer {
            renderer.scale = viewModel.scale
            renderer.rotation = viewModel.rotation
            let oldSkin = renderer.skinName
            renderer.skinName = viewModel.skinName
            if oldSkin != viewModel.skinName {
                nsView.setNeedsDisplay(nsView.bounds)
            }
        }
    }

    class Coordinator {
        var renderer: MetalRenderer?
    }
}

class MetalViewWithScroll: MTKView {
    @ObservedObject var viewModel: MetalViewModel
    init(frame: CGRect, viewModel: MetalViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func scrollWheel(with event: NSEvent) {
        let delta = Float(event.scrollingDeltaY)
        let factor: Float = 1.05
        if delta > 0 {
            viewModel.scale *= factor
        } else if delta < 0 {
            viewModel.scale /= factor
        }
        viewModel.scale = max(0.1, min(viewModel.scale, 10.0))
        self.setNeedsDisplay(self.bounds)
    }
    override func magnify(with event: NSEvent) {
        let factor = Float(event.magnification) + 1.0
        viewModel.scale *= factor
        viewModel.scale = max(0.1, min(viewModel.scale, 10.0))
        self.setNeedsDisplay(self.bounds)
    }
    override func mouseDragged(with event: NSEvent) {
        viewModel.rotation.y += Float(event.deltaX) * 0.01
        viewModel.rotation.x += Float(event.deltaY) * 0.01
        self.setNeedsDisplay(self.bounds)
    }
}
