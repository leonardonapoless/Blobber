//
//  ContentView.swift
//  BlobGen
//
//  Created by Leonardo Nápoles on 12/20/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var evolution: Float = 0.0
    @State private var complexity: Float = 3.0
    @State private var color: Color = .primary
    @State private var lastTapDate: Date = .distantPast
    
    @State private var mouseLocation: CGPoint? = nil
    @State private var lastMouseLocation: CGPoint? = nil
    @State private var mouseSpeed: Float = 0.0
    
    @State private var appearanceOverride: ColorScheme? = nil
    
    @FocusState private var isFocused: Bool
    
    private let darkColors: [Color] = [
        Color(red: 0.55, green: 0.35, blue: 0.90),
        Color(red: 0.85, green: 0.25, blue: 0.55),
        Color(red: 0.20, green: 0.75, blue: 0.65),
    ]
    
    private let lightColors: [Color] = [
        Color(red: 0.15, green: 0.00, blue: 0.05),
        Color(red: 0.25, green: 0.00, blue: 0.00),
        Color(red: 0.35, green: 0.00, blue: 0.00),
    ]

    var body: some View {
        let currentEvolution = evolution
        let currentComplexity = complexity
        let currentColor = color
        let tapDate = lastTapDate
        let currentMouseLoc = mouseLocation
        let currentMouseSpeed = mouseSpeed
        
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
            
            TimelineView(.animation) { context in
                let time = Float(context.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 2000.0))
                let tapElapsed = Float(context.date.timeIntervalSince(tapDate))
                
                Rectangle()
                    .foregroundStyle(currentColor)
                    .modifier(BlobModifier(
                        time: time,
                        complexity: currentComplexity,
                        evolution: currentEvolution,
                        tapElapsed: tapElapsed,
                        mouseLocation: currentMouseLoc,
                        mouseSpeed: currentMouseSpeed
                    ))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture {
                        triggerMorph()
                    }
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            /// compute speed from distance between frames
                            if let prev = lastMouseLocation {
                                let dx = Float(location.x - prev.x)
                                let dy = Float(location.y - prev.y)
                                let dist = sqrt(dx * dx + dy * dy)
                                /// smooth it out so it doesnt jump around
                                mouseSpeed = mouseSpeed * 0.7 + dist * 0.3
                            }
                            lastMouseLocation = location
                            mouseLocation = location
                            NSCursor.pointingHand.push()
                        case .ended:
                            mouseLocation = nil
                            lastMouseLocation = nil
                            /// let speed decay instead of snapping to zero
                            mouseSpeed = mouseSpeed * 0.1
                            NSCursor.pop()
                        @unknown default:
                            break
                        }
                    }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Toggle(isOn: Binding(
                        get: { colorScheme == .dark },
                        set: { isDark in
                            withAnimation(.easeInOut(duration: 1.2)) {
                                appearanceOverride = isDark ? .dark : .light
                            }
                        }
                    )) {
                        Label(
                            colorScheme == .dark ? "Dark Mode" : "Light Mode",
                            systemImage: colorScheme == .dark ? "moon.fill" : "sun.max.fill"
                        )
                    }
                    .toggleStyle(.switch)
                    .padding(12)
                    .glassEffect(.regular.interactive())
                    .clipShape(.capsule)
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                    .padding(20)
                }
            }
            .tint(.red)
        }
        .preferredColorScheme(appearanceOverride)
        .focusable()
        .focused($isFocused)
        .onAppear { isFocused = true }
        .onKeyPress(.space) {
            triggerMorph()
            return .handled
        }
    }
    
    private func triggerMorph() {
        lastTapDate = Date()
        withAnimation(.interpolatingSpring(stiffness: 100, damping: 12)) {
            evolution += Float.random(in: 40...50)
            complexity = Float.random(in: 2.0...8.0)
            let pool = colorScheme == .dark ? darkColors : lightColors
            color = pool.randomElement() ?? Color(red: 0.15, green: 0.55, blue: 0.85)
        }
    }
}

struct BlobModifier: ViewModifier, Animatable {
    var time: Float
    var complexity: Float
    var evolution: Float
    var tapElapsed: Float
    var mouseLocation: CGPoint?
    var mouseSpeed: Float
    
    var animatableData: AnimatablePair<Float, Float> {
        get { AnimatablePair(complexity, evolution) }
        set {
            complexity = newValue.first
            evolution = newValue.second
        }
    }

    func body(content: Content) -> some View {
        content.visualEffect { content, proxy in
            /// convert mouse pixel pos to normalized uv coords matching the shader
            let minDim = min(proxy.size.width, proxy.size.height)
            let mx: Float
            let my: Float
            if let loc = mouseLocation, minDim > 0 {
                mx = Float((loc.x - proxy.size.width * 0.5) / minDim * 2.0)
                my = Float((loc.y - proxy.size.height * 0.5) / minDim * 2.0)
            } else {
                mx = -99.0
                my = -99.0
            }
            
            return content.colorEffect(
                ShaderLibrary.dynamicBlob(
                    .float2(proxy.size),
                    .float(time),
                    .float(complexity),
                    .float(evolution),
                    .float(tapElapsed),
                    .float2(Float(mx), Float(my)),
                    .float(mouseSpeed)
                )
            )
        }
    }
}

#Preview {
    ContentView()
}
