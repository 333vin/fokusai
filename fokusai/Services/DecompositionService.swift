//
//  DecompositionService.swift
//  fokusai
//
//  Mock decomposition generator for the frontend rework. Respects the two
//  hard rules: the FIRST step is tiny (≤2 min, near-zero activation energy)
//  and EVERY step is a concrete physical action. Real AI replaces this when
//  the backend is wired.
//

import Foundation

enum DecompositionService {
    /// Generates 4–6 microtasks for a task title plus optional context.
    static func decompose(title: String, format: String? = nil, timeAvailableMinutes: Int? = nil) -> [Microtask] {
        let steps = template(for: title, format: format)
        return steps.enumerated().map { index, step in
            Microtask(orderIndex: index + 1, text: step.text, estimatedMinutes: step.minutes)
        }
    }

    private struct Step {
        let text: String
        let minutes: Int
    }

    private static func template(for title: String, format: String?) -> [Step] {
        let lowered = (title + " " + (format ?? "")).lowercased()

        func matches(_ keywords: [String]) -> Bool {
            keywords.contains { lowered.contains($0) }
        }

        if matches(["essay", "write", "writing", "paper", "report", "story", "paragraph"]) {
            return [
                Step(text: "Open a doc and give it any title.", minutes: 2),
                Step(text: "Write one ugly sentence about the topic.", minutes: 3),
                Step(text: "List 3 points you could make.", minutes: 3),
                Step(text: "Turn the first point into two sentences.", minutes: 4),
                Step(text: "Find one quote or source that fits.", minutes: 4),
            ]
        }

        if matches(["study", "test", "quiz", "exam", "review", "revise", "flashcard"]) {
            return [
                Step(text: "Open your notes to the right chapter.", minutes: 2),
                Step(text: "Read just the first page of the summary.", minutes: 3),
                Step(text: "Write down 3 terms you don't know yet.", minutes: 3),
                Step(text: "Look those 3 terms up.", minutes: 4),
                Step(text: "Quiz yourself on them out loud.", minutes: 3),
            ]
        }

        if matches(["read", "reading", "chapter", "book", "article"]) {
            return [
                Step(text: "Put the reading in front of you, open to the start.", minutes: 2),
                Step(text: "Read only the first paragraph.", minutes: 2),
                Step(text: "Read to the end of the first page.", minutes: 4),
                Step(text: "Jot one sentence about what you just read.", minutes: 2),
                Step(text: "Read the next two pages.", minutes: 5),
            ]
        }

        if matches(["math", "problem", "worksheet", "physics", "chem", "calc", "algebra", "homework set"]) {
            return [
                Step(text: "Open the set and just read problem 1.", minutes: 2),
                Step(text: "Copy problem 1 onto your paper.", minutes: 2),
                Step(text: "Attempt it. Wrong answers totally allowed.", minutes: 5),
                Step(text: "Check the closest example in your notes.", minutes: 3),
                Step(text: "Do the next problem.", minutes: 5),
            ]
        }

        if matches(["clean", "room", "tidy", "chore", "dishes", "laundry", "organize"]) {
            return [
                Step(text: "Pick up 5 things and put them where they live.", minutes: 2),
                Step(text: "Clear one surface completely.", minutes: 3),
                Step(text: "Toss anything that's actual trash.", minutes: 2),
                Step(text: "Make the bed. Blanket pulled up counts.", minutes: 2),
                Step(text: "Do one 5-minute tidy sprint. Timer on.", minutes: 5),
            ]
        }

        if matches(["email", "apply", "application", "form", "sign up", "message", "reply"]) {
            return [
                Step(text: "Open the page or app you need. Just open it.", minutes: 2),
                Step(text: "Fill in the easy basics (name, date, etc.).", minutes: 3),
                Step(text: "Draft the first sentence, badly.", minutes: 3),
                Step(text: "Finish the draft without fixing anything.", minutes: 5),
                Step(text: "Read it once, then hit send/submit.", minutes: 2),
            ]
        }

        if matches(["project", "presentation", "slides", "poster", "video"]) {
            return [
                Step(text: "Create the file and name it. Done? Done.", minutes: 2),
                Step(text: "Write the title on slide/page one.", minutes: 2),
                Step(text: "List the 3–5 parts it needs, as bullets.", minutes: 4),
                Step(text: "Rough out the first part only.", minutes: 5),
                Step(text: "Drop in one image or fact you already have.", minutes: 3),
            ]
        }

        // Generic fallback: still tiny, still physical.
        return [
            Step(text: "Get everything you need in front of you.", minutes: 2),
            Step(text: "Do just the first tiny piece of it.", minutes: 3),
            Step(text: "Keep going for 3 more minutes. Timer's got you.", minutes: 3),
            Step(text: "Write down what the next step would be.", minutes: 2),
            Step(text: "Do that step.", minutes: 5),
        ]
    }
}
