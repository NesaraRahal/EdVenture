import Foundation

enum GlobalChallengeQuestionBank {
    static func questions(for challengeId: String) -> [EVQuizQuestion] {
        switch challengeId {
        case "weekly-neuro-sync-drift":
            return neuroSyncDrift
        case "weekly-quantum-leap":
            return quantumLeap
        case "weekly-flash-facts":
            return flashFacts
        default:
            return neuroSyncDrift
        }
    }

    private static var neuroSyncDrift: [EVQuizQuestion] {
        [
            question(
                id: "weekly-neuro-sync-drift-q1",
                lessonId: "astronomy",
                order: 1,
                difficulty: 58,
                prompt: "Which planet is known for the Great Red Spot?",
                choices: ["Mars", "Jupiter", "Saturn", "Neptune"],
                correctIndex: 1,
                explanation: "The Great Red Spot is a giant storm on Jupiter.",
                tags: ["astronomy", "planets"]
            ),
            question(
                id: "weekly-neuro-sync-drift-q2",
                lessonId: "computer_science",
                order: 2,
                difficulty: 64,
                prompt: "What does the acronym 'CPU' stand for?",
                choices: ["Central Processing Unit", "Core Protocol Utility", "Compute Performance Unit", "Control Program Upload"],
                correctIndex: 0,
                explanation: "CPU means Central Processing Unit.",
                tags: ["computer-science", "hardware"]
            ),
            question(
                id: "weekly-neuro-sync-drift-q3",
                lessonId: "philosophy",
                order: 3,
                difficulty: 71,
                prompt: "Which philosopher is most associated with the Allegory of the Cave?",
                choices: ["Aristotle", "Plato", "Socrates", "Descartes"],
                correctIndex: 1,
                explanation: "The Allegory of the Cave appears in Plato's Republic.",
                tags: ["philosophy", "classical"]
            ),
            question(
                id: "weekly-neuro-sync-drift-q4",
                lessonId: "mathematics",
                order: 4,
                difficulty: 76,
                prompt: "What is the next prime number after 29?",
                choices: ["31", "33", "35", "37"],
                correctIndex: 0,
                explanation: "31 is the next prime after 29.",
                tags: ["mathematics", "number-theory"]
            ),
            question(
                id: "weekly-neuro-sync-drift-q5",
                lessonId: "biology",
                order: 5,
                difficulty: 82,
                prompt: "What part of the cell is responsible for producing energy?",
                choices: ["Nucleus", "Ribosome", "Mitochondria", "Golgi apparatus"],
                correctIndex: 2,
                explanation: "Mitochondria generate energy for the cell.",
                tags: ["biology", "cells"]
            ),
            question(
                id: "weekly-neuro-sync-drift-q6",
                lessonId: "world_history",
                order: 6,
                difficulty: 86,
                prompt: "Which empire was centered in present-day Turkey before the fall of Constantinople?",
                choices: ["Roman", "Byzantine", "Ottoman", "Mongol"],
                correctIndex: 1,
                explanation: "Constantinople was the capital of the Byzantine Empire.",
                tags: ["history", "empires"]
            ),
            question(
                id: "weekly-neuro-sync-drift-q7",
                lessonId: "linguistics",
                order: 7,
                difficulty: 89,
                prompt: "Which language family does Spanish belong to?",
                choices: ["Germanic", "Romance", "Slavic", "Celtic"],
                correctIndex: 1,
                explanation: "Spanish is a Romance language.",
                tags: ["linguistics", "languages"]
            ),
            question(
                id: "weekly-neuro-sync-drift-q8",
                lessonId: "geography",
                order: 8,
                difficulty: 92,
                prompt: "Which line divides the Earth into the Northern and Southern Hemispheres?",
                choices: ["Prime Meridian", "Tropic of Cancer", "Equator", "International Date Line"],
                correctIndex: 2,
                explanation: "The Equator divides the Earth into northern and southern halves.",
                tags: ["geography", "earth-science"]
            )
        ]
    }

    private static var quantumLeap: [EVQuizQuestion] {
        [
            question(
                id: "weekly-quantum-leap-q1",
                lessonId: "physics",
                order: 1,
                difficulty: 60,
                prompt: "What is the SI unit of force?",
                choices: ["Joule", "Newton", "Watt", "Pascal"],
                correctIndex: 1,
                explanation: "Force is measured in newtons.",
                tags: ["physics", "units"]
            ),
            question(
                id: "weekly-quantum-leap-q2",
                lessonId: "computer_science",
                order: 2,
                difficulty: 66,
                prompt: "Which data structure uses FIFO ordering?",
                choices: ["Stack", "Queue", "Tree", "Hash map"],
                correctIndex: 1,
                explanation: "A queue is first-in, first-out.",
                tags: ["computer-science", "data-structures"]
            ),
            question(
                id: "weekly-quantum-leap-q3",
                lessonId: "economics",
                order: 3,
                difficulty: 74,
                prompt: "What happens to demand when price rises, all else equal?",
                choices: ["It increases", "It decreases", "It stays fixed", "It doubles"],
                correctIndex: 1,
                explanation: "Higher prices usually reduce demand.",
                tags: ["economics", "supply-demand"]
            ),
            question(
                id: "weekly-quantum-leap-q4",
                lessonId: "philosophy",
                order: 4,
                difficulty: 79,
                prompt: "Which branch of philosophy studies knowledge?",
                choices: ["Metaphysics", "Epistemology", "Aesthetics", "Logic"],
                correctIndex: 1,
                explanation: "Epistemology is the study of knowledge.",
                tags: ["philosophy", "epistemology"]
            ),
            question(
                id: "weekly-quantum-leap-q5",
                lessonId: "music",
                order: 5,
                difficulty: 83,
                prompt: "How many semitones are in one octave?",
                choices: ["6", "8", "10", "12"],
                correctIndex: 3,
                explanation: "An octave contains 12 semitones.",
                tags: ["music", "theory"]
            ),
            question(
                id: "weekly-quantum-leap-q6",
                lessonId: "geology",
                order: 6,
                difficulty: 87,
                prompt: "Which rock type forms from cooled magma or lava?",
                choices: ["Igneous", "Sedimentary", "Metamorphic", "Fossil"],
                correctIndex: 0,
                explanation: "Igneous rocks form from cooled molten material.",
                tags: ["geology", "rocks"]
            ),
            question(
                id: "weekly-quantum-leap-q7",
                lessonId: "astronomy",
                order: 7,
                difficulty: 90,
                prompt: "What do we call a star's apparent brightness as seen from Earth?",
                choices: ["Luminosity", "Magnitude", "Parallax", "Redshift"],
                correctIndex: 1,
                explanation: "Apparent brightness is described using magnitude.",
                tags: ["astronomy", "stars"]
            ),
            question(
                id: "weekly-quantum-leap-q8",
                lessonId: "programming",
                order: 8,
                difficulty: 93,
                prompt: "What does 'idempotent' mean in programming and APIs?",
                choices: ["Runs only once", "Can be repeated without changing the result", "Always fails safely", "Requires recursion"],
                correctIndex: 1,
                explanation: "Idempotent actions produce the same result when repeated.",
                tags: ["programming", "api"]
            )
        ]
    }

    private static var flashFacts: [EVQuizQuestion] {
        [
            question(
                id: "weekly-flash-facts-q1",
                lessonId: "medicine",
                order: 1,
                difficulty: 59,
                prompt: "What is the main function of red blood cells?",
                choices: ["Fight infection", "Carry oxygen", "Clot blood", "Digest proteins"],
                correctIndex: 1,
                explanation: "Red blood cells carry oxygen around the body.",
                tags: ["medicine", "biology"]
            ),
            question(
                id: "weekly-flash-facts-q2",
                lessonId: "logic",
                order: 2,
                difficulty: 67,
                prompt: "If all blooms are flowers and some flowers fade, what can we conclude?",
                choices: ["All blooms fade", "Some blooms may fade", "No blooms fade", "Flowers are not blooms"],
                correctIndex: 1,
                explanation: "The statement supports that some blooms may fade, but not all.",
                tags: ["logic", "reasoning"]
            ),
            question(
                id: "weekly-flash-facts-q3",
                lessonId: "architecture",
                order: 3,
                difficulty: 72,
                prompt: "What is a common purpose of a load-bearing wall?",
                choices: ["Support structural weight", "Store water", "Improve Wi-Fi", "Generate electricity"],
                correctIndex: 0,
                explanation: "Load-bearing walls support the structure above them.",
                tags: ["architecture", "structures"]
            ),
            question(
                id: "weekly-flash-facts-q4",
                lessonId: "civics",
                order: 4,
                difficulty: 78,
                prompt: "Which branch of government typically interprets laws?",
                choices: ["Legislative", "Executive", "Judicial", "Administrative"],
                correctIndex: 2,
                explanation: "Courts in the judicial branch interpret laws.",
                tags: ["civics", "government"]
            ),
            question(
                id: "weekly-flash-facts-q5",
                lessonId: "ecology",
                order: 5,
                difficulty: 84,
                prompt: "What term describes species from different regions evolving similar traits?",
                choices: ["Mutation", "Convergent evolution", "Speciation", "Extinction"],
                correctIndex: 1,
                explanation: "Convergent evolution produces similar traits in unrelated species.",
                tags: ["ecology", "evolution"]
            ),
            question(
                id: "weekly-flash-facts-q6",
                lessonId: "literature",
                order: 6,
                difficulty: 88,
                prompt: "What is the term for a hint of events to come in a story?",
                choices: ["Foreshadowing", "Hyperbole", "Irony", "Alliteration"],
                correctIndex: 0,
                explanation: "Foreshadowing gives clues about future events.",
                tags: ["literature", "writing"]
            ),
            question(
                id: "weekly-flash-facts-q7",
                lessonId: "statistics",
                order: 7,
                difficulty: 91,
                prompt: "Which measure is most sensitive to extreme outliers?",
                choices: ["Median", "Mode", "Mean", "Range"],
                correctIndex: 2,
                explanation: "The mean is pulled by extreme values.",
                tags: ["statistics", "analysis"]
            ),
            question(
                id: "weekly-flash-facts-q8",
                lessonId: "chemistry",
                order: 8,
                difficulty: 94,
                prompt: "What is the pH of a neutral solution at room temperature?",
                choices: ["0", "7", "10", "14"],
                correctIndex: 1,
                explanation: "Neutral solutions are typically pH 7.",
                tags: ["chemistry", "acids-bases"]
            )
        ]
    }

    private static func question(id: String,
                                 lessonId: String,
                                 order: Int,
                                 difficulty: Int,
                                 prompt: String,
                                 choices: [String],
                                 correctIndex: Int,
                                 explanation: String,
                                 tags: [String]) -> EVQuizQuestion {
        EVQuizQuestion(
            id: id,
            lessonId: lessonId,
            level: 1,
            order: order,
            difficulty: difficulty,
            xpMin: max(10, difficulty - 15),
            xpMax: difficulty + 20,
            xpSuggested: max(12, difficulty / 5),
            prompt: prompt,
            choices: choices,
            correctIndex: correctIndex,
            explanation: explanation,
            tags: tags,
            isActive: true
        )
    }
}