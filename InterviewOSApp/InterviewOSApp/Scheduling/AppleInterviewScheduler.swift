import Foundation
import EventKit
import UserNotifications
import InterviewOSDomain
import InterviewOSUI

enum SchedulingError: LocalizedError {
    case missingDate
    case noCalendarAccess
    case noNotificationAccess
    case eventStoreFailure

    var errorDescription: String? {
        switch self {
        case .missingDate:
            "Please set a schedule date and time first."
        case .noCalendarAccess:
            "Calendar access was denied."
        case .noNotificationAccess:
            "Notification access was denied."
        case .eventStoreFailure:
            "Unable to save event in Calendar."
        }
    }
}

final class AppleInterviewScheduler: InterviewScheduler {
    private let eventStore = EKEventStore()
    private let notificationCenter = UNUserNotificationCenter.current()

    @MainActor
    func upsertCalendarEvent(
        for card: ProcessCard,
        opportunity: Opportunity,
        company: Company
    ) async throws -> String {
        guard let scheduledAt = card.scheduledAt else {
            throw SchedulingError.missingDate
        }

        let calendarGranted = try await requestCalendarAccessIfNeeded()
        guard calendarGranted else {
            throw SchedulingError.noCalendarAccess
        }

        let event: EKEvent
        if let existingID = card.calendarEventIdentifier,
           let existing = eventStore.event(withIdentifier: existingID) {
            event = existing
        } else {
            event = EKEvent(eventStore: eventStore)
        }

        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw SchedulingError.eventStoreFailure
        }

        event.calendar = calendar
        event.title = "InterviewOS: \(company.name) — \(opportunity.roleTitle) — \(card.title)"
        event.startDate = scheduledAt
        event.endDate = scheduledAt.addingTimeInterval(TimeInterval((card.durationMinutes ?? 60) * 60))
        event.notes = card.debrief.summary

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            guard let identifier = event.eventIdentifier else {
                throw SchedulingError.eventStoreFailure
            }
            return identifier
        } catch {
            throw SchedulingError.eventStoreFailure
        }
    }

    @MainActor
    func scheduleNotification(
        for card: ProcessCard,
        opportunity: Opportunity,
        company: Company
    ) async throws -> String {
        guard let scheduledAt = card.scheduledAt else {
            throw SchedulingError.missingDate
        }

        let notificationGranted = try await requestNotificationAccessIfNeeded()
        guard notificationGranted else {
            throw SchedulingError.noNotificationAccess
        }

        let identifier = card.notificationRequestIdentifier ?? "interviewos-notification-\(card.id.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        let reminderDate = max(scheduledAt.addingTimeInterval(-3600), Date().addingTimeInterval(5))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let content = UNMutableNotificationContent()
        content.title = "Interview Reminder"
        content.body = "\(company.name) - \(opportunity.roleTitle) - \(card.title) at \(formatter.string(from: scheduledAt))."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await notificationCenter.add(request)

        return identifier
    }

    private func requestCalendarAccessIfNeeded() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        }

        return try await withCheckedThrowingContinuation { continuation in
            eventStore.requestAccess(to: .event) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestNotificationAccessIfNeeded() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: granted)
            }
        }
    }
}
