import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var textOpacity: CGFloat = 0
    @State private var showSecondaryElements = false
    @State private var showPermissions = false
    @State private var logoOpacity: CGFloat = 0
    
    // Animation timing
    private let animationDelay = 0.2
    private let textAnimationDuration = 0.6
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    // Reusable background
                    OnboardingBackgroundView()
                    
                    // Content container - 모든 요소를 한 화면에 배치
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Content Area
                        VStack(spacing: 30) {
                            // Logo image (크기 줄임)
                            Group {
                                if let logoPath = Bundle.main.path(forResource: "badasugi logo macVer - Edited (1)", ofType: "png"),
                                   let logoImage = NSImage(contentsOfFile: logoPath) {
                                    Image(nsImage: logoImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: min(geometry.size.width * 0.18, 150), height: min(geometry.size.width * 0.18, 150))
                                        .opacity(logoOpacity)
                                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                } else {
                                    // Fallback to Assets if bundle resource not found
                                    Image("BadasugiLogoMac")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: min(geometry.size.width * 0.18, 150), height: min(geometry.size.width * 0.18, 150))
                                        .opacity(logoOpacity)
                                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                            }
                            
                            // Title and subtitle
                            VStack(spacing: 12) {
                                Text("말하면 끝, 받아쓰기")
                                    .font(.system(size: min(geometry.size.width * 0.05, 38), weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .opacity(textOpacity)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Text("한국인을 위한 완벽한 음성인식 앱")
                                    .font(.system(size: min(geometry.size.width * 0.028, 20), weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .opacity(textOpacity)
                                    .multilineTextAlignment(.center)
                            }
                            
                            if showSecondaryElements {
                                // Typewriter roles animation (높이 줄임)
                                TypewriterRoles()
                                    .frame(height: 100)
                                    .transition(.scale.combined(with: .opacity))
                                    .padding(.horizontal, 40)
                            }
                        }
                        
                        Spacer()
                        
                        // Bottom navigation
                        if showSecondaryElements {
                            VStack(spacing: 16) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        showPermissions = true
                                    }
                                }) {
                                    Text("시작하기")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                        .frame(width: min(geometry.size.width * 0.3, 200), height: 50)
                                        .background(Color.white)
                                        .cornerRadius(25)
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                SkipButton(text: "건너뛰기") {
                                    hasCompletedOnboarding = true
                                }
                            }
                            .padding(.bottom, 40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            // Placeholder to maintain layout
                            VStack(spacing: 16) {
                                Spacer()
                            }
                            .frame(height: 80)
                            .padding(.bottom, 40)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            if showPermissions {
                OnboardingPermissionsView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Logo fade in (appears first)
        withAnimation(.easeOut(duration: textAnimationDuration)) {
            logoOpacity = 1
        }
        
        // Text fade in
        withAnimation(.easeOut(duration: textAnimationDuration).delay(animationDelay)) {
            textOpacity = 1
        }
        
        // Show secondary elements
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay * 3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showSecondaryElements = true
            }
        }
    }
}

// MARK: - Supporting Views
struct TypewriterRoles: View {
    private let roles = [
        "당신의 받아쓰기 AI",
        "어디서나 클릭 한 번으로",
        "100% 완전한 프라이버시",
        "우리의 시간은 소중하니까"
    ]
    
    @State private var displayedText = ""
    @State private var currentIndex = 0
    @State private var showCursor = true
    @State private var isTyping = false
    @State private var isDeleting = false
    
    // Animation timing
    private let typingSpeed = 0.05  // Time between each character
    private let deleteSpeed = 0.03   // Faster deletion
    private let pauseDuration = 1.0  // How long to show completed text
    private let cursorBlinkSpeed = 0.6
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Text(displayedText)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.8),
                                Color.white.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Blinking cursor
                Text("|")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(showCursor ? 1 : 0)
                    .animation(.easeInOut(duration: cursorBlinkSpeed).repeatForever(), value: showCursor)
            }
            .multilineTextAlignment(.center)
            .shadow(color: Color.accentColor.opacity(0.5), radius: 15, x: 0, y: 0)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            startTypingAnimation()
            // Start cursor blinking
            withAnimation(.easeInOut(duration: cursorBlinkSpeed).repeatForever()) {
                showCursor.toggle()
            }
        }
    }
    
    private func startTypingAnimation() {
        guard currentIndex < roles.count else { return }
        let targetText = roles[currentIndex]
        isTyping = true
        
        // Type out the text
        var charIndex = 0
        func typeNextCharacter() {
            guard charIndex < targetText.count else {
                // Typing complete, pause then delete
                isTyping = false
                DispatchQueue.main.asyncAfter(deadline: .now() + pauseDuration) {
                    startDeletingAnimation()
                }
                return
            }
            
            let nextChar = String(targetText[targetText.index(targetText.startIndex, offsetBy: charIndex)])
            displayedText += nextChar
            charIndex += 1
            
            // Schedule next character
            DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed) {
                typeNextCharacter()
            }
        }
        
        typeNextCharacter()
    }
    
    private func startDeletingAnimation() {
        isDeleting = true
        
        func deleteNextCharacter() {
            guard !displayedText.isEmpty else {
                isDeleting = false
                currentIndex = (currentIndex + 1) % roles.count
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startTypingAnimation()
                }
                return
            }
            
            displayedText.removeLast()
            
            // Schedule next deletion
            DispatchQueue.main.asyncAfter(deadline: .now() + deleteSpeed) {
                deleteNextCharacter()
            }
        }
        
        deleteNextCharacter()
    }
}

struct SkipButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.white.opacity(0.2))
            .onTapGesture(perform: action)
    }
}

struct OnboardingBackgroundView: View {
    @State private var glowOpacity: CGFloat = 0
    @State private var glowScale: CGFloat = 0.8
    @State private var particlesActive = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base background with black gradient
                Color.black
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black,
                                Color.black.opacity(0.8),
                                Color.black.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Animated glow effect
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.4)
                    .blur(radius: 100)
                    .opacity(glowOpacity)
                    .scaleEffect(glowScale)
                    .position(
                        x: geometry.size.width * 0.5,
                        y: geometry.size.height * 0.3
                    )
                
                // Enhanced particles with reduced opacity
                ParticlesView(isActive: $particlesActive)
                    .opacity(0.2)
                    .drawingGroup()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Glow animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowOpacity = 0.3
            glowScale = 1.2
        }
        
        // Start particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            particlesActive = true
        }
    }
}

// MARK: - Particles
struct ParticlesView: View {
    @Binding var isActive: Bool
    let particleCount = 60 // Increased particle count
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let timeOffset = timeline.date.timeIntervalSinceReferenceDate
                
                for i in 0..<particleCount {
                    let position = particlePosition(index: i, time: timeOffset, size: size)
                    let opacity = particleOpacity(index: i, time: timeOffset)
                    let scale = particleScale(index: i, time: timeOffset)
                    
                    context.opacity = opacity
                    context.fill(
                        Circle().path(in: CGRect(
                            x: position.x - scale/2,
                            y: position.y - scale/2,
                            width: scale,
                            height: scale
                        )),
                        with: .color(.white)
                    )
                }
            }
        }
        .opacity(isActive ? 1 : 0)
    }
    
    private func particlePosition(index: Int, time: TimeInterval, size: CGSize) -> CGPoint {
        let relativeIndex = Double(index) / Double(particleCount)
        let speed = 0.3 // Slower, more graceful movement
        let radius = min(size.width, size.height) * 0.45
        
        let angle = time * speed + relativeIndex * .pi * 4
        let x = sin(angle) * radius + size.width * 0.5
        let y = cos(angle * 0.5) * radius + size.height * 0.5
        
        return CGPoint(x: x, y: y)
    }
    
    private func particleOpacity(index: Int, time: TimeInterval) -> Double {
        let relativeIndex = Double(index) / Double(particleCount)
        return (sin(time + relativeIndex * .pi * 2) + 1) * 0.3 // Reduced opacity for subtlety
    }
    
    private func particleScale(index: Int, time: TimeInterval) -> CGFloat {
        let relativeIndex = Double(index) / Double(particleCount)
        let baseScale: CGFloat = 3
        return baseScale + sin(time * 2 + relativeIndex * .pi) * 2
    }
}

// MARK: - Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
} 

