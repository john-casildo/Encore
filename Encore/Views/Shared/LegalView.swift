//
//  LegalView.swift
//  Encore
//

import SwiftUI

struct LegalView: View {
    @EnvironmentObject var language: LanguageManager
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach([0, 1], id: \.self) { tab in
                    let isSelected = selectedTab == tab
                    let label = tab == 0
                        ? (language.sp ? "Términos" : "Terms")
                        : (language.sp ? "Privacidad" : "Privacy")
                    Button { withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab } } label: {
                        Text(label)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isSelected ? .white : Color.encoreText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.encorePrimary : Color(.systemBackground))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary, lineWidth: 1.5))
                            .shadow(color: isSelected ? .black : .clear, radius: 0, x: isSelected ? 2 : 0, y: isSelected ? 2 : 0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.encoreFrame)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if selectedTab == 0 {
                        LegalSection(
                            title: language.sp ? "Términos de Servicio" : "Terms of Service",
                            lastUpdated: language.sp ? "Marzo 2026" : "March 2026",
                            items: language.sp ? termsES : termsEN,
                            sp: language.sp
                        )
                    } else {
                        LegalSection(
                            title: language.sp ? "Política de Privacidad" : "Privacy Policy",
                            lastUpdated: language.sp ? "Marzo 2026" : "March 2026",
                            items: language.sp ? privacyES : privacyEN,
                            sp: language.sp
                        )
                    }
                }
                .padding()
            }
            .background(Color.encoreFrame)
        }
        .background(Color.encoreFrame.ignoresSafeArea())
        .navigationTitle(Strings.legal(language.sp))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section view

private struct LegalSection: View {
    let title: String
    let lastUpdated: String
    let items: [LegalItem]
    var sp: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color.encoreText)
                Text(sp ? "Última actualización: \(lastUpdated)" : "Last updated: \(lastUpdated)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.encoreTextSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.encorePrimary.opacity(0.08))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.encorePrimary, lineWidth: 1.5))

            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.heading)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.encoreText)
                    Text(item.body)
                        .font(.subheadline)
                        .foregroundStyle(Color.encoreTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .memphisCard(cornerRadius: 12, offset: 2, lineWidth: 1.5)
            }
        }
    }
}

// MARK: - Model

private struct LegalItem: Identifiable {
    let id: String
    let heading: String
    let body: String
}

// MARK: - Terms (EN)

private let termsEN: [LegalItem] = [
    LegalItem(id: "t1", heading: "1. Acceptance of Terms",
              body: "By using Encore, you agree to these Terms of Service. If you do not agree, please stop using the app."),
    LegalItem(id: "t2", heading: "2. Eligibility",
              body: "You must be at least 18 years old to use Encore. By creating an account you confirm that you meet this requirement."),
    LegalItem(id: "t3", heading: "3. Renter Responsibilities",
              body: "Renters are responsible for treating instruments with care, returning them in the same condition, and honoring the agreed rental period and pickup method."),
    LegalItem(id: "t4", heading: "4. Host Responsibilities",
              body: "Hosts must accurately describe their instruments, respond to booking requests in a timely manner, and ensure the instrument is in playable condition at pickup."),
    LegalItem(id: "t5", heading: "5. Deposits",
              body: "Hosts may require a deposit. Deposits are returned at the end of the rental period provided no damage occurred. Disputes should be resolved through the in-app messaging system."),
    LegalItem(id: "t6", heading: "6. Prohibited Use",
              body: "You may not use Encore for any unlawful purpose, to list instruments you do not own or have authority to rent, or to harass other users."),
    LegalItem(id: "t7", heading: "7. Limitation of Liability",
              body: "Encore is a marketplace platform. We are not responsible for the condition of instruments, the behavior of users, or any disputes between renters and hosts. Use the app at your own risk."),
    LegalItem(id: "t8", heading: "8. Changes to Terms",
              body: "We may update these terms at any time. Continued use of the app after changes constitutes acceptance of the new terms."),
    LegalItem(id: "t9", heading: "9. Contact",
              body: "For legal inquiries, email us at legal@encoreapp.co."),
]

// MARK: - Terms (ES)

private let termsES: [LegalItem] = [
    LegalItem(id: "t1", heading: "1. Aceptación de los Términos",
              body: "Al usar Encore, aceptas estos Términos de Servicio. Si no estás de acuerdo, deja de usar la aplicación."),
    LegalItem(id: "t2", heading: "2. Elegibilidad",
              body: "Debes tener al menos 18 años para usar Encore. Al crear una cuenta confirmas que cumples este requisito."),
    LegalItem(id: "t3", heading: "3. Responsabilidades del Arrendatario",
              body: "Los arrendatarios son responsables de tratar los instrumentos con cuidado, devolverlos en el mismo estado y respetar el período de alquiler y el método de entrega acordados."),
    LegalItem(id: "t4", heading: "4. Responsabilidades del Anfitrión",
              body: "Los anfitriones deben describir sus instrumentos con precisión, responder a las solicitudes de reserva a tiempo y asegurarse de que el instrumento esté en condición tocable al momento de la entrega."),
    LegalItem(id: "t5", heading: "5. Depósitos",
              body: "Los anfitriones pueden requerir un depósito. Los depósitos se devuelven al finalizar el período de alquiler siempre que no haya daños. Las disputas deben resolverse a través del sistema de mensajería en la app."),
    LegalItem(id: "t6", heading: "6. Uso Prohibido",
              body: "No puedes usar Encore para fines ilegales, para publicar instrumentos que no posees o no tienes autoridad para alquilar, ni para acosar a otros usuarios."),
    LegalItem(id: "t7", heading: "7. Limitación de Responsabilidad",
              body: "Encore es una plataforma de mercado. No somos responsables del estado de los instrumentos, el comportamiento de los usuarios ni los conflictos entre arrendatarios y anfitriones. Usa la app bajo tu propia responsabilidad."),
    LegalItem(id: "t8", heading: "8. Cambios en los Términos",
              body: "Podemos actualizar estos términos en cualquier momento. El uso continuado de la app después de los cambios constituye la aceptación de los nuevos términos."),
    LegalItem(id: "t9", heading: "9. Contacto",
              body: "Para consultas legales, escríbenos a legal@encoreapp.co."),
]

// MARK: - Privacy (EN)

private let privacyEN: [LegalItem] = [
    LegalItem(id: "p1", heading: "1. Information We Collect",
              body: "We collect the information you provide when creating an account (name, email, city, phone) and data generated by your use of the app (rentals, messages, reviews)."),
    LegalItem(id: "p2", heading: "2. How We Use Your Information",
              body: "Your information is used to operate the platform, connect renters with hosts, process bookings, and send you relevant notifications. We do not sell your data."),
    LegalItem(id: "p3", heading: "3. Data Storage",
              body: "Data is stored securely via Supabase. Profile photos and instrument images are stored in Supabase Storage with access controlled by bucket policies."),
    LegalItem(id: "p4", heading: "4. Sharing",
              body: "Your public profile (name, city, rating) is visible to other users. Your phone number is only shared if you enable it in Privacy Settings. We never share your data with advertising third parties."),
    LegalItem(id: "p5", heading: "5. Your Rights",
              body: "You can update or delete your profile information at any time through the app. To request full account deletion, contact us at support@encoreapp.co."),
    LegalItem(id: "p6", heading: "6. Cookies & Analytics",
              body: "The app does not use cookies. We may use anonymized analytics to improve the product, but no personally identifiable data is included in analytics."),
    LegalItem(id: "p7", heading: "7. Changes to This Policy",
              body: "We may update this policy at any time. We'll notify you of significant changes through the app."),
    LegalItem(id: "p8", heading: "8. Contact",
              body: "For privacy-related requests, email privacy@encoreapp.co."),
]

// MARK: - Privacy (ES)

private let privacyES: [LegalItem] = [
    LegalItem(id: "p1", heading: "1. Información que Recopilamos",
              body: "Recopilamos la información que proporcionas al crear una cuenta (nombre, correo, ciudad, teléfono) y los datos generados por tu uso de la app (alquileres, mensajes, reseñas)."),
    LegalItem(id: "p2", heading: "2. Cómo Usamos tu Información",
              body: "Tu información se usa para operar la plataforma, conectar arrendatarios con anfitriones, procesar reservas y enviarte notificaciones relevantes. No vendemos tus datos."),
    LegalItem(id: "p3", heading: "3. Almacenamiento de Datos",
              body: "Los datos se almacenan de forma segura a través de Supabase. Las fotos de perfil e instrumentos se almacenan en Supabase Storage con acceso controlado por políticas de bucket."),
    LegalItem(id: "p4", heading: "4. Compartir",
              body: "Tu perfil público (nombre, ciudad, calificación) es visible para otros usuarios. Tu número de teléfono solo se comparte si lo habilitas en Ajustes de privacidad. Nunca compartimos tus datos con terceros publicitarios."),
    LegalItem(id: "p5", heading: "5. Tus Derechos",
              body: "Puedes actualizar o eliminar tu información de perfil en cualquier momento desde la app. Para solicitar la eliminación completa de tu cuenta, contáctanos en support@encoreapp.co."),
    LegalItem(id: "p6", heading: "6. Cookies y Analítica",
              body: "La app no usa cookies. Podemos utilizar análisis anónimos para mejorar el producto, pero no se incluye información de identificación personal en dichos análisis."),
    LegalItem(id: "p7", heading: "7. Cambios en esta Política",
              body: "Podemos actualizar esta política en cualquier momento. Te notificaremos sobre cambios importantes a través de la app."),
    LegalItem(id: "p8", heading: "8. Contacto",
              body: "Para solicitudes relacionadas con privacidad, escribe a privacy@encoreapp.co."),
]
