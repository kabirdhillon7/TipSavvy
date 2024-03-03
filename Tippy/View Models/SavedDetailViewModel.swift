//
//  SavedDetailViewModel.swift
//  Tippy
//
//  Created by Kabir Dhillon on 3/2/24.
//

import Foundation

/// A view model responsible for the tip for a given Saved Detail View
final class SavedDetailViewModel: ObservableObject {
    var tip: SavedTip
    
    init(tip: SavedTip) {
        self.tip = tip
    }
}
