//
//  SplashView.swift
//  fokusai
//
//  Created by Navneet Sharma on 2026-07-16.
//

import SwiftUI

struct SplashView: View {
    @State private var orbScale: CGFloat = 0.5
    @State private var orbOpacity: Double = 0
    @State private var orbGlow: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Focus Orb with enhanced glow
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.brand.opacity(orbGlow * 0.3),
                                    Color.accent.opacity(orbGlow * 0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .blur(radius: 20)
                    
                    // The orb itself
                    FocusOrb(state: .flare, level: 3)
                        .scaleEffect(orbScale)
                }
                .opacity(orbOpacity)
                
                // FokusAI branding
                BrandLogo(size: .large)
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Stage 1: Orb appears with scale and fade
        withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
            orbScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8)) {
            orbOpacity = 1.0
        }
        
        // Stage 2: Orb glow intensifies
        withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
            orbGlow = 1.0
        }
        
        // Stage 3: Text slides up and fades in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            textOffset = 0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            textOpacity = 1.0
        }
        
        // Stage 4: Complete and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.5)) {
                orbOpacity = 0
                textOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
