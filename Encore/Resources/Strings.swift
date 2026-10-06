//
//  Strings.swift
//  Encore
//

import Foundation

/// Centralized user-facing strings (EN/ES). Use with LanguageManager.sp.
enum Strings {
    // Auth
    static func welcomeTitle(_ sp: Bool) -> String { sp ? "¡Bienvenido a Encore!" : "Welcome to Encore!" }
    static func welcomeSubtitle(_ sp: Bool) -> String { sp ? "El escenario es tuyo. Nosotros llevamos el equipo" : "The stage is yours. We'll bring the gear" }
    static func loginOrSignUp(_ sp: Bool) -> String { sp ? "Iniciar sesión o registrarse como:" : "Login or sign up as:" }
    static func renter(_ sp: Bool) -> String { sp ? "Arrendatario" : "Renter" }
    static func owner(_ sp: Bool) -> String { sp ? "Propietario" : "Owner" }
    static func email(_ sp: Bool) -> String { sp ? "Correo electrónico" : "Email" }
    static func password(_ sp: Bool) -> String { sp ? "Contraseña" : "Password" }
    static func `continue`(_ sp: Bool) -> String { sp ? "Continuar" : "Continue" }
    static func forgotPassword(_ sp: Bool) -> String { sp ? "¿Olvidaste tu contraseña?" : "Forgot password?" }
    static func sendResetLink(_ sp: Bool) -> String { sp ? "Enviar enlace" : "Send reset link" }
    static func checkYourEmailReset(_ sp: Bool) -> String { sp ? "Revisa tu correo. Si existe una cuenta, te enviamos un enlace para restablecer la contraseña." : "Check your email. If an account exists, we sent you a link to reset your password." }
    static func signOut(_ sp: Bool) -> String { sp ? "Cerrar sesión" : "Sign out" }
    static func signOutConfirmTitle(_ sp: Bool) -> String { sp ? "¿Cerrar sesión?" : "Sign out?" }
    static func signOutConfirmMessage(_ sp: Bool) -> String { sp ? "Se cerrará tu sesión en este dispositivo." : "You will be signed out on this device." }
    static func agreeAndContinue(_ sp: Bool) -> String { sp ? "Aceptar y continuar" : "Agree and continue" }
    static func finishSigningUp(_ sp: Bool) -> String { sp ? "Terminar registro" : "Finish signing up" }

    // Common
    static func search(_ sp: Bool) -> String { sp ? "Buscar" : "Search" }
    static func save(_ sp: Bool) -> String { sp ? "Guardar" : "Save" }
    static func cancel(_ sp: Bool) -> String { sp ? "Cancelar" : "Cancel" }
    static func done(_ sp: Bool) -> String { sp ? "Listo" : "Done" }
    static func error(_ sp: Bool) -> String { sp ? "Error" : "Error" }
    static func loading(_ sp: Bool) -> String { sp ? "Cargando…" : "Loading…" }
    static func noResults(_ sp: Bool) -> String { sp ? "No hay resultados" : "No results" }

    // Renter
    static func home(_ sp: Bool) -> String { sp ? "Inicio" : "Home" }
    static func saved(_ sp: Bool) -> String { sp ? "Guardados" : "Saved" }
    static func favorites(_ sp: Bool) -> String { sp ? "Favoritos" : "Favorites" }
    static func myRentals(_ sp: Bool) -> String { sp ? "Mis alquileres" : "My Rentals" }
    static func profile(_ sp: Bool) -> String { sp ? "Perfil" : "Profile" }
    static func sortBy(_ sp: Bool) -> String { sp ? "Ordenar por" : "Sort by" }
    static func priceLowToHigh(_ sp: Bool) -> String { sp ? "Precio: menor a mayor" : "Price: low to high" }
    static func priceHighToLow(_ sp: Bool) -> String { sp ? "Precio: mayor a menor" : "Price: high to low" }
    static func topRated(_ sp: Bool) -> String { sp ? "Mejor valorados" : "Top rated" }
    static func nearest(_ sp: Bool) -> String { sp ? "Más cercanos" : "Nearest" }
    static func nearby(_ sp: Bool) -> String { sp ? "Cercanos" : "Nearby" }
    static func radius(_ sp: Bool) -> String { sp ? "Radio de búsqueda" : "Search radius" }
    static func useMyLocation(_ sp: Bool) -> String { sp ? "Usar mi ubicación" : "Use my location" }
    static func address(_ sp: Bool) -> String { sp ? "Dirección" : "Address" }
    static func residentialAddress(_ sp: Bool) -> String { sp ? "Dirección residencial" : "Residential address" }
    static func newest(_ sp: Bool) -> String { sp ? "Más recientes" : "Newest" }
    static func verifiedHost(_ sp: Bool) -> String { sp ? "Anfitrión verificado" : "Verified host" }
    static func messageHost(_ sp: Bool) -> String { sp ? "Mensaje" : "Message" }
    static func reserve(_ sp: Bool) -> String { sp ? "Reservar" : "Reserve" }
    static func description(_ sp: Bool) -> String { sp ? "Descripción" : "Description" }
    static func rentalLocation(_ sp: Bool) -> String { sp ? "Ubicación del alquiler" : "Rental Location" }
    static func confirmAndPay(_ sp: Bool) -> String { sp ? "Confirmar y pagar" : "Confirm and pay" }
    static func active(_ sp: Bool) -> String { sp ? "Activos" : "Active" }
    static func history(_ sp: Bool) -> String { sp ? "Historial" : "History" }
    static func rate(_ sp: Bool) -> String { sp ? "Calificar" : "Rate" }
    static func accountSettings(_ sp: Bool) -> String { sp ? "Configuración de cuenta" : "Account settings" }
    static func editProfile(_ sp: Bool) -> String { sp ? "Editar perfil" : "Edit profile" }
    static func name(_ sp: Bool) -> String { sp ? "Nombre" : "Name" }
    static func firstName(_ sp: Bool) -> String { sp ? "Nombre" : "First name" }
    static func lastName(_ sp: Bool) -> String { sp ? "Apellido" : "Last name" }
    static func phone(_ sp: Bool) -> String { sp ? "Teléfono" : "Phone" }
    static func bio(_ sp: Bool) -> String { sp ? "Bio" : "Bio" }
    static func city(_ sp: Bool) -> String { sp ? "Ciudad" : "City" }
    static func changePhoto(_ sp: Bool) -> String { sp ? "Cambiar foto" : "Change photo" }
    static func saveChanges(_ sp: Bool) -> String { sp ? "Guardar cambios" : "Save changes" }
    static func language(_ sp: Bool) -> String { sp ? "Idioma" : "Language" }
    static func switchToHostMode(_ sp: Bool) -> String { sp ? "Cambiar a modo anfitrión" : "Switch to Host Mode" }
    static func switchToRenterMode(_ sp: Bool) -> String { sp ? "Cambiar a modo arrendatario" : "Switch to Renter Mode" }

    // Host
    static func dashboard(_ sp: Bool) -> String { sp ? "Panel" : "Dashboard" }
    static func yourListings(_ sp: Bool) -> String { sp ? "Tus anuncios" : "Your listings" }
    static func addListing(_ sp: Bool) -> String { sp ? "Añadir anuncio" : "Add listing" }
    static func pending(_ sp: Bool) -> String { sp ? "Pendientes" : "Pending" }
    static func past(_ sp: Bool) -> String { sp ? "Pasados" : "Past" }
    static func approve(_ sp: Bool) -> String { sp ? "Aprobar" : "Approve" }
    static func decline(_ sp: Bool) -> String { sp ? "Rechazar" : "Decline" }
    static func earnings(_ sp: Bool) -> String { sp ? "Ganancias" : "Earnings" }
    static func menu(_ sp: Bool) -> String { sp ? "Menú" : "Menu" }
    static func createNewListing(_ sp: Bool) -> String { sp ? "Crear nuevo anuncio" : "Create a new listing" }
    static func getHelp(_ sp: Bool) -> String { sp ? "Obtener ayuda" : "Get help" }
    static func privacy(_ sp: Bool) -> String { sp ? "Privacidad" : "Privacy" }
    static func legal(_ sp: Bool) -> String { sp ? "Legal" : "Legal" }
    static func viewProfile(_ sp: Bool) -> String { sp ? "Ver perfil" : "View profile" }
    static func insights(_ sp: Bool) -> String { sp ? "Estadísticas" : "Insights" }
    static func reservations(_ sp: Bool) -> String { sp ? "Reservas" : "Reservations" }

    // Categories
    static func categories(_ sp: Bool) -> String { sp ? "Categorías" : "Categories" }
    static func popularChoices(_ sp: Bool) -> String { sp ? "Opciones populares" : "Popular Choices" }
    static func string(_ sp: Bool) -> String { sp ? "Cuerdas" : "String" }
    static func percussion(_ sp: Bool) -> String { sp ? "Percusión" : "Percussion" }
    static func keys(_ sp: Bool) -> String { sp ? "Teclados" : "Keys" }
    static func brass(_ sp: Bool) -> String { sp ? "Viento metal" : "Brass" }
    static func other(_ sp: Bool) -> String { sp ? "Otro" : "Other" }

    // Messages
    static func messages(_ sp: Bool) -> String { sp ? "Mensajes" : "Messages" }
    static func comingSoon(_ sp: Bool) -> String { sp ? "Próximamente" : "Coming soon" }
    static func messagesComingSoon(_ sp: Bool) -> String { sp ? "Los mensajes estarán disponibles pronto." : "Messages will be available soon." }
    static func typeMessage(_ sp: Bool) -> String { sp ? "Escribe un mensaje…" : "Type a message…" }
    static func send(_ sp: Bool) -> String { sp ? "Enviar" : "Send" }
    static func noConversations(_ sp: Bool) -> String { sp ? "Aún no hay conversaciones" : "No conversations yet" }
    static func noConversationsHint(_ sp: Bool) -> String { sp ? "Cuando tengas una reserva, podrás chatear con anfitriones o arrendatarios aquí." : "When you have a booking, you can message hosts or renters here." }

    // Reviews
    static func reviews(_ sp: Bool) -> String { sp ? "Reseñas" : "Reviews" }
    static func writeReview(_ sp: Bool) -> String { sp ? "Escribir reseña" : "Write a review" }
    static func submitReview(_ sp: Bool) -> String { sp ? "Enviar reseña" : "Submit review" }
    static func comment(_ sp: Bool) -> String { sp ? "Comentario" : "Comment" }
    static func reply(_ sp: Bool) -> String { sp ? "Responder" : "Reply" }
    static func addReply(_ sp: Bool) -> String { sp ? "Añadir respuesta" : "Add reply" }
}
