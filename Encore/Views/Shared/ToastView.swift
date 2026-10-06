//
//  ToastView.swift
//  Encore
//

import SwiftUI

// MARK: - Toast model

struct Toast: Equatable {
    var message: String
    var style: Style = .success

    enum Style { case success, error }
}

// MARK: - Toast view

struct ToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.style == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(toast.style == .success ? Color.encorePrimary : Color.white)
            Text(toast.message)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(toast.style == .success ? Color.black : Color.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(toast.style == .success ? Color.encoreAccent : Color.encoreCoral)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.primary, lineWidth: 1.5))
        .shadow(color: Color.encorePrimary, radius: 0, x: 3, y: 3)
    }
}

// MARK: - ViewModifier

private struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let t = toast {
                    ToastView(toast: t)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.easeOut(duration: 0.3)) { toast = nil }
                            }
                        }
                        .zIndex(100)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: toast)
    }
}

extension View {
    func toast(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
