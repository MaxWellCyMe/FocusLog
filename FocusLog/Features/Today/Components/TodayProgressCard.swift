//
//  TodayProgressCard.swift
//  FocusLog
//

import SwiftUI

struct TodayProgressCard: View {
    let completedCount: Int
    let totalCount: Int

    private var progress: Double {
        totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("A little progress adds up.")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text(totalCount == 0 ? "Add a task to shape your day." : "You have completed \(completedCount) of \(totalCount) tasks.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.75))
                }

                Spacer(minLength: 12)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.20))
                    Capsule()
                        .fill(.white)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 7)
            .accessibilityLabel("Task completion")
            .accessibilityValue("\(Int(progress * 100)) percent")
        }
        .foregroundStyle(.white)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.indigo.gradient)
        }
    }
}
