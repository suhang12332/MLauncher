//
//  MinecraftSkinRender.swift
//  MLauncher
//
//  Created by su on 2025/6/20.
//
import SwiftUI

struct MinecraftSkinRenderView: View {
    @StateObject var viewModel = MetalViewModel()
    var body: some View {
        MetalView(viewModel: viewModel).frame(minWidth: 235,idealWidth: 240,maxWidth: 250,minHeight: 400,maxHeight: 400)
    }
}
