import SwiftUI
#if canImport(AthanCore)
import AthanCore
#endif

public struct AthkarView: View {
    @State private var selectedCategory: AthkarCategory = .morning
    @State private var counterCounts: [String: Int] = [:]
    @State private var showingTasbeehSheet: Bool = false
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AthkarCategory.allCases) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                VStack(spacing: 3) {
                                    Text(category.titleArabic)
                                        .font(.system(size: 15, weight: .bold))
                                    Text(category.titleEnglish)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? Color(hex: "0E3A2F") : Color(uiColor: .secondarySystemGroupedBackground))
                                .foregroundColor(selectedCategory == category ? Color(hex: "E6C280") : .primary)
                                .cornerRadius(14)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color(uiColor: .systemGroupedBackground))

                Divider()

                // Adhkar List
                List {
                    let items = AthkarRepository.getAthkar(category: selectedCategory)
                    ForEach(items) { item in
                        let count = counterCounts[item.id] ?? 0
                        let isCompleted = count >= item.targetCount

                        VStack(alignment: .leading, spacing: 12) {
                            // Arabic Text
                            Text(item.arabic)
                                .font(.system(size: 20, weight: .semibold, design: .serif))
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.primary)
                                .padding(.top, 4)

                            // Transliteration
                            Text(item.transliteration)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "0E3A2F"))

                            // English Translation
                            Text(item.english)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            // Virtue if available
                            if !item.virtue.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "quote.opening")
                                        .font(.system(size: 10))
                                    Text(item.virtue)
                                        .font(.system(size: 11, weight: .regular))
                                        .italic()
                                }
                                .foregroundColor(Color(hex: "B38B3F"))
                            }

                            // Counter button
                            HStack {
                                Spacer()
                                Button(action: {
                                    let next = count + 1
                                    counterCounts[item.id] = next
                                    feedbackGenerator.impactOccurred()
                                    if next == item.targetCount {
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "hand.tap.fill")
                                        Text("\(min(count, item.targetCount)) / \(item.targetCount)")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(isCompleted ? Color.green.opacity(0.15) : Color(hex: "0E3A2F"))
                                    .foregroundColor(isCompleted ? Color.green : Color(hex: "E6C280"))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(isCompleted ? Color.green.opacity(0.04) : Color(uiColor: .secondarySystemGroupedBackground))
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Adhkar & Supplications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingTasbeehSheet = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.grid.cross.fill")
                            Text("Tasbeeh")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "0E3A2F"))
                    }
                }
            }
            .sheet(isPresented: $showingTasbeehSheet) {
                DigitalTasbeehSheet()
            }
        }
    }
}

public struct DigitalTasbeehSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPreset: TasbeehPreset = AthkarRepository.tasbeehPresets[0]
    @State private var currentCount: Int = 0
    @State private var totalSessionsCount: Int = 0
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    public var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Preset Selector
                Picker("Tasbeeh Preset", selection: $selectedPreset) {
                    ForEach(AthkarRepository.tasbeehPresets) { preset in
                        Text("\(preset.nameArabic) (\(preset.target))").tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                .onChange(of: selectedPreset) { _ in
                    currentCount = 0
                }

                // Preset Titles
                VStack(spacing: 6) {
                    Text(selectedPreset.nameArabic)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "0E3A2F"))

                    Text(selectedPreset.nameEnglish)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Large Interactive Counter Circle
                Button(action: {
                    currentCount += 1
                    feedbackGenerator.impactOccurred()
                    if currentCount >= selectedPreset.target {
                        totalSessionsCount += 1
                        currentCount = 0
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "0E3A2F"), Color(hex: "174D3F")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 240, height: 240)
                            .shadow(color: Color(hex: "0E3A2F").opacity(0.35), radius: 16, x: 0, y: 8)

                        VStack(spacing: 8) {
                            Text("\(currentCount)")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()

                            Text("Target: \(selectedPreset.target)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "E6C280"))

                            Text("Tap to count")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Reset and Session Info
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Completed Cycles")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(totalSessionsCount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "0E3A2F"))
                    }

                    Spacer()

                    Button("Reset Count") {
                        currentCount = 0
                    }
                    .foregroundColor(.red)
                    .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            .navigationTitle("Digital Tasbeeh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
