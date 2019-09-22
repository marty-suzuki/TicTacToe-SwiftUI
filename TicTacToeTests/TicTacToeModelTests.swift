//
//  TicTacToeModelTests.swift
//  TicTacToeTests
//
//  Created by marty-suzuki on 2019/09/22.
//  Copyright © 2019 jp.marty-suzuki. All rights reserved.
//

import XCTest
@testable import TicTacToe

class TicTacToeModelTests: XCTestCase {

    private var dependecy: Dependency!

    override func setUp() {
        self.dependecy = Dependency()
    }

    func test_initial_states() {

        XCTAssertNil(dependecy.store.winner)
        XCTAssertEqual(dependecy.store.currentPlayer, .o)
        XCTAssertFalse(dependecy.store.isGameEnded)

        let expectedBoard = (0..<3).map { section in
            (0..<3).map { TicTacToeModel.Address(id: $0 + section * 3, player: nil) }
        }
        XCTAssertEqual(dependecy.store.board, expectedBoard)
    }
}

extension TicTacToeModelTests {

    private struct Dependency {

        let store = TicTacToeModel.Store()

        let testTarget: TicTacToeModel

        init() {
            self.testTarget = TicTacToeModel(input: .init(), store: store, extra: .init())
        }
    }
}
