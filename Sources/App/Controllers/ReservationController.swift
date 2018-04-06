import Vapor
import FluentMySQL

struct ReservationController {
    static func saveReservation(req: Request, pubReservation: Reservation.PublicIncomingReservation) throws -> Future<Reservation> {
        let abortReason = "\(pubReservation.user) already has an open reservation"
        let potentialError = Abort(.notFound, reason: abortReason)

        return try Reservation
            .query(on: req)
            .filter(\.isInQueue == true)
            .filter(\.user == pubReservation.user)
            .first()
            .isNil(or: potentialError)
            .flatMap(to: Reservation.self) { _ in
                return pubReservation.toReservation().save(on: req)
        }
    }
}
