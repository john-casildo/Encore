//
//  HelpView.swift
//  Encore
//

import SwiftUI

struct HelpView: View {
    @EnvironmentObject var language: LanguageManager
    @State private var expandedId: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(faqs) { item in
                    FAQRow(item: item, isExpanded: expandedId == item.id) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedId = expandedId == item.id ? nil : item.id
                        }
                    }
                }

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.encoreTeal.opacity(0.18))
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                        Image(systemName: "envelope.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.encoreTeal)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(language.sp ? "¿Sigues teniendo preguntas?" : "Still have questions?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.encoreText)
                        Text("support@encoreapp.co")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.encorePrimary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
            }
            .padding()
        }
        .navigationTitle(Strings.getHelp(language.sp))
        .navigationBarTitleDisplayMode(.large)
    }

    private var faqs: [FAQItem] {
        language.sp ? faqsES : faqsEN
    }
}

// MARK: - FAQ Row

private struct FAQRow: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isExpanded ? Color.encorePrimary : Color.encoreLightPurple)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                        Image(systemName: isExpanded ? "minus" : "plus")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(isExpanded ? .white : Color.encorePrimary)
                    }
                    Text(item.question)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.encoreText)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.encoreTextSecondary)
                }
                .padding()
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(item.answer)
                    .font(.subheadline)
                    .foregroundStyle(Color.encoreTextSecondary)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .memphisCard(cornerRadius: 12, offset: 3, lineWidth: 1.5)
    }
}

// MARK: - Model

private struct FAQItem: Identifiable {
    let id: String
    let question: String
    let answer: String
}

// MARK: - Content

private let faqsEN: [FAQItem] = [
    FAQItem(
        id: "rent",
        question: "How do I rent an instrument?",
        answer: "Browse instruments on the Home tab, tap on one you like, pick your dates, choose a pickup method, and tap \"Reserve\". The host will confirm your booking."
    ),
    FAQItem(
        id: "list",
        question: "How do I list my instrument?",
        answer: "Switch to Host Mode from your Profile tab. Then go to Your Listings and tap the \"+\" button. Fill in the details, add photos, and publish."
    ),
    FAQItem(
        id: "payment",
        question: "How does payment work?",
        answer: "Payment is handled securely at checkout. The total includes the daily rate × days plus any deposit. Deposits are returned after the rental period ends without issues."
    ),
    FAQItem(
        id: "cancel",
        question: "Can I cancel a booking?",
        answer: "Contact the host through the Messages tab as soon as possible. Cancellation policies vary by host. If you can't resolve it, email us at support@encoreapp.co."
    ),
    FAQItem(
        id: "pickup",
        question: "How do I pick up the instrument?",
        answer: "The pickup method is set when you book: Meet Up, Host's Address, or Shipping. Once the host confirms, coordinate the exact time and place through Messages."
    ),
    FAQItem(
        id: "damage",
        question: "What if an instrument is damaged?",
        answer: "Deposits exist to cover accidental damage. Report any issue through the app immediately. Both parties should agree before the host marks the deposit as returned."
    ),
    FAQItem(
        id: "review",
        question: "How do reviews work?",
        answer: "After a rental is completed, you'll see a \"Rate\" button in My Rentals. Leave an honest star rating and comment. Hosts can reply to reviews."
    ),
    FAQItem(
        id: "verified",
        question: "What does the verified badge mean?",
        answer: "Verified users have confirmed their identity with Encore. We recommend renting from verified hosts for extra peace of mind."
    ),
    FAQItem(
        id: "contact",
        question: "How do I contact a host?",
        answer: "From any instrument detail page, tap \"Message Host\". This opens a direct conversation in the Messages tab."
    ),
]

private let faqsES: [FAQItem] = [
    FAQItem(
        id: "rent",
        question: "¿Cómo alquilo un instrumento?",
        answer: "Navega por los instrumentos en la pestaña de inicio, toca el que te interesa, elige las fechas, el método de entrega y toca \"Reservar\". El anfitrión confirmará tu reserva."
    ),
    FAQItem(
        id: "list",
        question: "¿Cómo anuncio mi instrumento?",
        answer: "Cambia al modo Anfitrión desde tu pestaña de perfil. Luego ve a Tus anuncios y toca el botón \"+\". Completa los datos, agrega fotos y publícalo."
    ),
    FAQItem(
        id: "payment",
        question: "¿Cómo funciona el pago?",
        answer: "El pago se realiza de forma segura al hacer la reserva. El total incluye la tarifa diaria × días más el depósito. Los depósitos se devuelven al terminar el período sin inconvenientes."
    ),
    FAQItem(
        id: "cancel",
        question: "¿Puedo cancelar una reserva?",
        answer: "Contacta al anfitrión a través de la pestaña de Mensajes lo antes posible. Las políticas de cancelación varían por anfitrión. Si no logras resolverlo, escríbenos a support@encoreapp.co."
    ),
    FAQItem(
        id: "pickup",
        question: "¿Cómo recojo el instrumento?",
        answer: "El método de entrega se define al reservar: Encuentro, Dirección del anfitrión o Envío. Una vez confirmado, coordina el momento exacto por Mensajes."
    ),
    FAQItem(
        id: "damage",
        question: "¿Qué pasa si el instrumento se daña?",
        answer: "Los depósitos existen para cubrir daños accidentales. Reporta cualquier problema de inmediato en la app. Ambas partes deben acordarlo antes de que el anfitrión libere el depósito."
    ),
    FAQItem(
        id: "review",
        question: "¿Cómo funcionan las reseñas?",
        answer: "Cuando un alquiler se completa, verás el botón \"Calificar\" en Mis alquileres. Deja una valoración honesta con estrellas y comentario. Los anfitriones pueden responder reseñas."
    ),
    FAQItem(
        id: "verified",
        question: "¿Qué significa la insignia de verificado?",
        answer: "Los usuarios verificados han confirmado su identidad con Encore. Recomendamos alquilar de anfitriones verificados para mayor tranquilidad."
    ),
    FAQItem(
        id: "contact",
        question: "¿Cómo contacto a un anfitrión?",
        answer: "Desde cualquier página de detalle de instrumento, toca \"Mensaje\". Esto abre una conversación directa en la pestaña de Mensajes."
    ),
]
