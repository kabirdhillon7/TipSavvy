//
//  SavedDetailViewModel.swift
//  Tippy
//
//  Created by Kabir Dhillon on 3/2/24.
//

import Combine
import Foundation

/// A view model responsible for the tip for a given Saved Detail View
@MainActor
final class SavedDetailViewModel: ObservableObject {
    var tip: SavedTip

    private var tipChanges: AnyCancellable?

    init(tip: SavedTip) {
        self.tip = tip
        // Re-render when the managed object changes, e.g. after a rename.
        tipChanges = tip.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}
