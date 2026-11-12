//
//  TaskScopePicker.swift
//  FocusLog
//

import SwiftUI

struct TaskScopePicker: View {
    @Binding var selection: TaskScope

    var body: some View {
        Picker("Task range", selection: $selection) {
            ForEach(TaskScope.allCases) { scope in
                Text(scope.rawValue).tag(scope)
            }
        }
        .pickerStyle(.segmented)
    }
}
